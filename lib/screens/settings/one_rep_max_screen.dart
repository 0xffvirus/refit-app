import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_theme.dart';

const _percentageTable = [
  (percent: 100, reps: '1'),
  (percent: 95, reps: '2'),
  (percent: 90, reps: '4'),
  (percent: 85, reps: '6'),
  (percent: 80, reps: '8'),
  (percent: 75, reps: '10'),
  (percent: 70, reps: '12'),
  (percent: 65, reps: '15'),
];

class OneRepMaxScreen extends StatefulWidget {
  const OneRepMaxScreen({super.key});

  @override
  State<OneRepMaxScreen> createState() => _OneRepMaxScreenState();
}

class _OneRepMaxScreenState extends State<OneRepMaxScreen> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  double? _epley;
  double? _brzycki;
  double? _lombardi;
  double? _average;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());
    if (weight == null || weight <= 0 || reps == null || reps < 1) {
      setState(() => _average = null);
      return;
    }

    if (reps == 1) {
      setState(() {
        _epley = weight;
        _brzycki = weight;
        _lombardi = weight;
        _average = weight;
      });
      return;
    }

    final epley = weight * (1 + reps / 30);
    final brzycki = weight * (36 / (37 - reps));
    final lombardi = weight * pow(reps, 0.10);

    setState(() {
      _epley = epley;
      _brzycki = brzycki;
      _lombardi = lombardi.toDouble();
      _average = (epley + brzycki + lombardi) / 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.oneRmTitle)),
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
            _buildFormulas(),
            const SizedBox(height: 16),
            _buildPercentageTable(),
          ],
          const SizedBox(height: 16),
          _buildDisclaimer(),
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
          _inputField(_weightController, l.liftedWeight, l.kg),
          const SizedBox(height: 10),
          _inputField(_repsController, l.repsCount, '', decimal: false),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(l.estimatedMax, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _average!),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Text(
                '${value.toStringAsFixed(1)} ${l.kg}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.error),
              );
            },
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
          _formulaRow('Epley', _epley!),
          _formulaRow('Brzycki', _brzycki!),
          _formulaRow('Lombardi', _lombardi!),
        ],
      ),
    );
  }

  Widget _formulaRow(String name, double value) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text(
            '${value.toStringAsFixed(1)} ${l.kg}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageTable() {
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
          Text(l.percentageTable, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ..._percentageTable.map((row) {
            final weight = _average! * row.percent / 100;
            final isMax = row.percent == 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMax ? AppColors.error.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isMax ? Border.all(color: AppColors.error.withValues(alpha: 0.3)) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 45,
                    child: Text(
                      '${row.percent}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMax ? AppColors.error : AppColors.accent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${row.reps} ${l.rep}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    '${weight.toStringAsFixed(1)} ${l.kg}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isMax ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
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
            child: Text(
              l.oneRmDisclaimer,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, String suffix, {bool decimal = true}) {
    return TextField(
      controller: controller,
      keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix.isNotEmpty ? suffix : null,
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
