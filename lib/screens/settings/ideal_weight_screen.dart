import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_theme.dart';

enum _IwGender { male, female }

enum _FrameSize { small, medium, large }

class IdealWeightScreen extends StatefulWidget {
  const IdealWeightScreen({super.key});

  @override
  State<IdealWeightScreen> createState() => _IdealWeightScreenState();
}

class _IdealWeightScreenState extends State<IdealWeightScreen> {
  final _heightController = TextEditingController();
  final _wristController = TextEditingController();

  _IwGender _gender = _IwGender.male;

  double? _devine;
  double? _robinson;
  double? _miller;
  double? _hamwi;
  double? _bmiLow;
  double? _bmiHigh;
  double? _average;
  _FrameSize? _frame;

  @override
  void dispose() {
    _heightController.dispose();
    _wristController.dispose();
    super.dispose();
  }

  void _calculate() {
    final heightCm = double.tryParse(_heightController.text.trim());
    if (heightCm == null || heightCm <= 0) {
      setState(() => _average = null);
      return;
    }

    final inches = heightCm / 2.54;
    final aboveFiveFeet = inches - 60;
    final heightM = heightCm / 100;

    double devine, robinson, miller, hamwi;

    if (_gender == _IwGender.male) {
      devine = 50 + 2.3 * aboveFiveFeet;
      robinson = 52 + 1.9 * aboveFiveFeet;
      miller = 56.2 + 1.41 * aboveFiveFeet;
      hamwi = 48 + 2.7 * aboveFiveFeet;
    } else {
      devine = 45.5 + 2.3 * aboveFiveFeet;
      robinson = 49 + 1.7 * aboveFiveFeet;
      miller = 53.1 + 1.36 * aboveFiveFeet;
      hamwi = 45.5 + 2.2 * aboveFiveFeet;
    }

    final bmiLow = 18.5 * heightM * heightM;
    final bmiHigh = 24.9 * heightM * heightM;
    final average = (devine + robinson + miller + hamwi) / 4;

    // Frame size
    _FrameSize? frame;
    final wrist = double.tryParse(_wristController.text.trim());
    if (wrist != null && wrist > 0) {
      if (_gender == _IwGender.male) {
        if (wrist < 16.5) {
          frame = _FrameSize.small;
        } else if (wrist <= 19) {
          frame = _FrameSize.medium;
        } else {
          frame = _FrameSize.large;
        }
      } else {
        if (wrist < 14) {
          frame = _FrameSize.small;
        } else if (wrist <= 16) {
          frame = _FrameSize.medium;
        } else {
          frame = _FrameSize.large;
        }
      }
    }

    setState(() {
      _devine = devine;
      _robinson = robinson;
      _miller = miller;
      _hamwi = hamwi;
      _bmiLow = bmiLow;
      _bmiHigh = bmiHigh;
      _average = average;
      _frame = frame;
    });
  }

  double _frameAdjusted(double value) {
    if (_frame == null || _frame == _FrameSize.medium) return value;
    if (_frame == _FrameSize.small) return value * 0.9;
    return value * 1.1;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.idealWeightTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputs(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () { FocusScope.of(context).unfocus(); _calculate(); },
              child: Text(l.calculate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_average != null) ...[
            const SizedBox(height: 20),
            _buildResult(),
            const SizedBox(height: 16),
            _buildBmiRange(),
            const SizedBox(height: 16),
            _buildFormulas(),
            if (_frame != null) ...[
              const SizedBox(height: 16),
              _buildFrameResult(),
            ],
          ],
          const SizedBox(height: 16),

          _buildDisclaimer(),
          const SizedBox(height: 16),

          _buildSources(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputs() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.dataSection, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _choiceChip(l.male, _gender == _IwGender.male, () => setState(() => _gender = _IwGender.male)),
              const SizedBox(width: 8),
              _choiceChip(l.female, _gender == _IwGender.female, () => setState(() => _gender = _IwGender.female)),
            ],
          ),
          const SizedBox(height: 12),
          _inputField(_heightController, l.heightField, l.cm),
          const SizedBox(height: 10),
          _inputField(_wristController, l.wristCircumference, l.cm),
          const SizedBox(height: 4),
          Text(
            l.wristHint,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final l = AppLocalizations.of(context);
    final adjusted = _frameAdjusted(_average!);
    final frameSizeLabels = {
      _FrameSize.small: l.frameSizeLabels['small']!,
      _FrameSize.medium: l.frameSizeLabels['medium']!,
      _FrameSize.large: l.frameSizeLabels['large']!,
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(l.estimatedIdealWeight, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: adjusted),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Text(
                '${value.toStringAsFixed(1)} ${l.kg}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.accent),
              );
            },
          ),
          if (_frame != null) ...[
            const SizedBox(height: 4),
            Text(
              l.frameAdjusted(frameSizeLabels[_frame]!),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBmiRange() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten, size: 20, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.healthyRange, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                const SizedBox(height: 4),
                Text(
                  '${_bmiLow!.toStringAsFixed(1)} - ${_bmiHigh!.toStringAsFixed(1)} ${l.kg}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulas() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.formulaBreakdown, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _formulaRow('Devine', _devine!),
          _formulaRow('Robinson', _robinson!),
          _formulaRow('Miller', _miller!),
          _formulaRow('Hamwi', _hamwi!),
        ],
      ),
    );
  }

  Widget _formulaRow(String name, double value) {
    final l = AppLocalizations.of(context);
    final adjusted = _frameAdjusted(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
          if (_frame != null && _frame != _FrameSize.medium)
            Text(
              '${value.toStringAsFixed(1)} → ',
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, decoration: TextDecoration.lineThrough),
            ),
          Text(
            '${adjusted.toStringAsFixed(1)} ${l.kg}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameResult() {
    final l = AppLocalizations.of(context);
    final frameSizeLabels = {
      _FrameSize.small: l.frameSizeLabels['small']!,
      _FrameSize.medium: l.frameSizeLabels['medium']!,
      _FrameSize.large: l.frameSizeLabels['large']!,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.boneFrameSize, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: _FrameSize.values.map((f) {
              final isActive = _frame == f;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? AppColors.accent : AppColors.border,
                      width: isActive ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        frameSizeLabels[f]!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f == _FrameSize.small ? '-10%' : f == _FrameSize.large ? '+10%' : '±0%',
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive ? AppColors.accent.withValues(alpha: 0.7) : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSources() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.sources, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(l.idealWeightSources, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight')),
            child: const Text(
              'who.int — Healthy BMI Range',
              style: TextStyle(fontSize: 12, color: AppColors.info, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.idealWeightDisclaimer, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(l.medicalDisclaimer, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: selected ? 1.5 : 0.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, String suffix) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
