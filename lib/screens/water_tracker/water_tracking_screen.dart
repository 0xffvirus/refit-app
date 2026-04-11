import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/water_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/tutorial_service.dart';
import '../../widgets/tutorial/tutorial_steps.dart';

const _waterColor = Color(0xFF4FC3F7);
const _waterColorDark = Color(0xFF0288D1);

const _bottlePresets = [
  (ml: 200, icon: Icons.coffee),
  (ml: 330, icon: Icons.local_drink),
  (ml: 600, icon: Icons.water_drop),
  (ml: 1500, icon: Icons.water),
];

class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  State<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _splashController;
  late Animation<double> _splashAnimation;
  final _bottlesKey = GlobalKey();
  final _goalKey = GlobalKey();
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _splashAnimation = CurvedAnimation(
      parent: _splashController,
      curve: Curves.easeOut,
    );

    Future.microtask(() {
      if (!mounted) return;
      context.read<WaterProvider>().initialize();
    });

    TutorialService.instance.pendingTab.addListener(_onPendingTab);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _splashController.dispose();
    TutorialService.instance.pendingTab.removeListener(_onPendingTab);
    super.dispose();
  }

  void _onPendingTab() {
    if (TutorialService.instance.pendingTab.value != TabId.water) return;
    if (!mounted || _tutorialShown) return;
    _tutorialShown = true;
    TutorialService.instance.clearPending(TabId.water);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTour();
    });
  }

  void _showTour() {
    showCoachMarks(
      context: context,
      targets: waterTargets(
        context: context,
        bottlesKey: _bottlesKey,
        goalKey: _goalKey,
      ),
      onSeen: () async {
        await TutorialService.instance.markSeen(TabId.water);
      },
    );
  }

  void _onAddWater(int ml) {
    context.read<WaterProvider>().addWater(ml);
    _splashController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaterProvider>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.waterTracking),
        actions: [
          IconButton(
            key: _goalKey,
            icon: const Icon(Icons.tune_rounded, size: 22),
            onPressed: () => _showSetGoalDialog(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildWaterTank(provider),
          const SizedBox(height: 24),
          _buildBottleButtons(provider),
          const SizedBox(height: 12),
          _buildCustomAmountButton(context, provider),
          const SizedBox(height: 24),
          _buildHistory(provider),
        ],
      ),
    );
  }

  Widget _buildWaterTank(WaterProvider provider) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SizedBox(
        width: 220,
        height: 280,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: provider.percentage),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          builder: (context, animatedFill, child) {
            return AnimatedBuilder(
              animation: Listenable.merge([_waveController, _splashAnimation]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _WaterTankPainter(
                    fillPercentage: animatedFill,
                    wavePhase: _waveController.value,
                    splashValue: _splashAnimation.value,
                  ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: provider.totalMl),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) {
                        return Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: provider.percentage > 0.5
                                ? AppColors.background
                                : AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                    Text(
                      l.ofGoalMl(provider.dailyGoalMl),
                      style: TextStyle(
                        fontSize: 14,
                        color: provider.percentage > 0.5
                            ? AppColors.background.withValues(alpha: 0.7)
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (provider.goalReached)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${l.goalReached} 🎉',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
          },
        ),
      ),
    );
  }

  Widget _buildBottleButtons(WaterProvider provider) {
    final l = AppLocalizations.of(context);
    return Row(
      key: _bottlesKey,
      children: _bottlePresets.map((preset) {
        final label = preset.ml >= 1000
            ? '${(preset.ml / 1000).toStringAsFixed(1)} ${l.liter}'
            : '${preset.ml} ${l.ml}';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _BottleButton(
              label: label,
              icon: preset.icon,
              onTap: () => _onAddWater(preset.ml),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomAmountButton(
      BuildContext context, WaterProvider provider) {
    return GestureDetector(
      onTap: () => _showCustomAmountDialog(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).customAmount,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(WaterProvider provider) {
    final l = AppLocalizations.of(context);
    final entries = provider.entries;
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(Icons.water_drop_outlined,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(l.noWaterYet,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(l.tapToLog,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l.todayLog,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...entries.map((entry) {
          final time =
              '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
          return Dismissible(
            key: ValueKey(entry.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.delete_rounded, color: Colors.white),
            ),
            onDismissed: (_) => provider.removeEntry(entry.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _waterColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.water_drop,
                        size: 18, color: _waterColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.mlAmount(entry.amountMl),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showSetGoalDialog(BuildContext context, WaterProvider provider) {
    final l = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: provider.dailyGoalMl.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.dailyGoal),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: l.exampleGoal,
            suffixText: l.ml,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                provider.setGoal(value);
                Navigator.pop(ctx);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showCustomAmountDialog(
      BuildContext context, WaterProvider provider) {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customAmount),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: l.exampleAmount,
            suffixText: l.ml,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                _onAddWater(value);
                Navigator.pop(ctx);
              }
            },
            child: Text(l.add),
          ),
        ],
      ),
    );
  }
}

class _BottleButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _BottleButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_BottleButton> createState() => _BottleButtonState();
}

class _BottleButtonState extends State<_BottleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _waterColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _waterColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 28, color: _waterColor),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _waterColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaterTankPainter extends CustomPainter {
  final double fillPercentage;
  final double wavePhase;
  final double splashValue;

  _WaterTankPainter({
    required this.fillPercentage,
    required this.wavePhase,
    required this.splashValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(30));

    // Background
    final bgPaint = Paint()..color = AppColors.surface;
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    if (fillPercentage <= 0) return;

    // Clip to rounded rect
    canvas.save();
    canvas.clipRRect(rrect);

    // Water fill level
    final waterHeight = size.height * fillPercentage;
    final waterTop = size.height - waterHeight;

    // Wave amplitude decreases as fill increases
    final waveAmplitude = 6.0 * (1 - fillPercentage * 0.5) + (splashValue * 8);

    // Draw water with wave
    final waterPath = Path();
    waterPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final wave1 = sin((normalizedX * 2 * pi) + (wavePhase * 2 * pi)) *
          waveAmplitude;
      final wave2 =
          sin((normalizedX * 4 * pi) + (wavePhase * 2 * pi * 1.5)) *
              (waveAmplitude * 0.4);
      final y = waterTop + wave1 + wave2;
      waterPath.lineTo(x, y);
    }

    waterPath.lineTo(size.width, size.height);
    waterPath.close();

    // Gradient fill
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _waterColor.withValues(alpha: 0.7),
          _waterColorDark.withValues(alpha: 0.9),
        ],
      ).createShader(rect);

    canvas.drawPath(waterPath, waterPaint);

    // Second wave layer for depth
    final wave2Path = Path();
    wave2Path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final wave = sin((normalizedX * 2.5 * pi) +
              (wavePhase * 2 * pi) +
              pi * 0.5) *
          (waveAmplitude * 0.6);
      final y = waterTop + wave + 4;
      wave2Path.lineTo(x, y);
    }

    wave2Path.lineTo(size.width, size.height);
    wave2Path.close();

    final wave2Paint = Paint()
      ..color = _waterColorDark.withValues(alpha: 0.3);
    canvas.drawPath(wave2Path, wave2Paint);

    // Splash bubbles
    if (splashValue > 0) {
      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4 * (1 - splashValue));
      final rng = Random(42);
      for (int i = 0; i < 6; i++) {
        final bx = size.width * (0.2 + rng.nextDouble() * 0.6);
        final by = waterTop - (splashValue * 30 * (1 + rng.nextDouble()));
        final br = 2.0 + rng.nextDouble() * 3;
        canvas.drawCircle(Offset(bx, by), br, bubblePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaterTankPainter oldDelegate) => true;
}
