import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

enum _BfGender { male, female }

class BodyFatScreen extends StatefulWidget {
  const BodyFatScreen({super.key});

  @override
  State<BodyFatScreen> createState() => _BodyFatScreenState();
}

class _BodyFatScreenState extends State<BodyFatScreen> {
  final _heightController = TextEditingController();
  final _neckController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();

  _BfGender _gender = _BfGender.male;
  double? _bodyFat;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final profile = await DatabaseService().fetchUserProfile();
    if (!mounted) return;
    if (profile.heightCm != null && _heightController.text.isEmpty) {
      _heightController.text = profile.heightCm!.toStringAsFixed(0);
    }
    if (profile.gender != null) {
      setState(() {
        _gender = profile.gender == Gender.male ? _BfGender.male : _BfGender.female;
      });
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _neckController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  void _calculate() {
    final height = double.tryParse(_heightController.text.trim());
    final neck = double.tryParse(_neckController.text.trim());
    final waist = double.tryParse(_waistController.text.trim());

    if (height == null || height <= 0 || neck == null || neck <= 0 || waist == null || waist <= 0) {
      setState(() => _bodyFat = null);
      return;
    }

    if (waist <= neck) {
      setState(() => _bodyFat = null);
      return;
    }

    double bf;
    if (_gender == _BfGender.male) {
      bf = 495 / (1.0324 - 0.19077 * log(waist - neck) / ln10 + 0.15456 * log(height) / ln10) - 450;
    } else {
      final hip = double.tryParse(_hipController.text.trim());
      if (hip == null || hip <= 0) {
        setState(() => _bodyFat = null);
        return;
      }
      bf = 495 / (1.29579 - 0.35004 * log(waist + hip - neck) / ln10 + 0.22100 * log(height) / ln10) - 450;
    }

    setState(() => _bodyFat = bf.clamp(1, 60));
  }

  List<({String label, String range, double min, double max})> _getCategories(AppLocalizations l) {
    if (_gender == _BfGender.male) {
      return [
        (label: l.essentialFat, range: '2-5%', min: 2.0, max: 5.0),
        (label: l.athlete, range: '6-13%', min: 6.0, max: 13.0),
        (label: l.fitnessCategory, range: '14-17%', min: 14.0, max: 17.0),
        (label: l.averageCategory, range: '18-24%', min: 18.0, max: 24.0),
        (label: l.obeseCategory, range: '25%+', min: 25.0, max: 100.0),
      ];
    }
    return [
      (label: l.essentialFat, range: '10-13%', min: 10.0, max: 13.0),
      (label: l.athleteFemale, range: '14-20%', min: 14.0, max: 20.0),
      (label: l.fitnessCategory, range: '21-24%', min: 21.0, max: 24.0),
      (label: l.averageCategory, range: '25-31%', min: 25.0, max: 31.0),
      (label: l.obeseCategory, range: '32%+', min: 32.0, max: 100.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.bodyFatTitle)),
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
          if (_bodyFat != null) ...[
            const SizedBox(height: 20),
            _buildResult(),
            const SizedBox(height: 16),
            _buildCategories(),
          ],
          const SizedBox(height: 16),
          _buildMeasurementGuide(),
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
              _choiceChip(l.male, _gender == _BfGender.male, () => setState(() => _gender = _BfGender.male)),
              const SizedBox(width: 8),
              _choiceChip(l.female, _gender == _BfGender.female, () => setState(() => _gender = _BfGender.female)),
            ],
          ),
          const SizedBox(height: 12),
          _inputField(_heightController, l.heightField, l.cm),
          const SizedBox(height: 10),
          _inputField(_neckController, l.neckCircumference, l.cm),
          const SizedBox(height: 10),
          _inputField(_waistController, l.waistCircumference, l.cm),
          if (_gender == _BfGender.female) ...[
            const SizedBox(height: 10),
            _inputField(_hipController, l.hipCircumference, l.cm),
          ],
        ],
      ),
    );
  }

  Widget _buildResult() {
    final l = AppLocalizations.of(context);
    final categories = _getCategories(l);
    final category = _getCategoryLabel(categories);
    final color = _getCategoryColor(categories);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(l.estimatedBodyFat, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _bodyFat!),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: color),
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              category,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final l = AppLocalizations.of(context);
    final categories = _getCategories(l);
    final colors = [AppColors.info, AppColors.accent, AppColors.success, AppColors.warning, AppColors.error];

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
          Text(l.categories, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...List.generate(categories.length, (i) {
            final cat = categories[i];
            final isActive = _bodyFat! >= cat.min && _bodyFat! < cat.max;
            final color = colors[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? color : AppColors.border,
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? color : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(cat.range, style: TextStyle(fontSize: 12, color: isActive ? color : AppColors.textTertiary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMeasurementGuide() {
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
          Text(l.measurementGuide, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _guideRow(Icons.circle_outlined, l.neck, l.neckMeasure),
          _guideRow(Icons.circle_outlined, l.waist, _gender == _BfGender.male ? l.waistMeasureMale : l.waistMeasureFemale),
          if (_gender == _BfGender.female)
            _guideRow(Icons.circle_outlined, l.hips, l.hipMeasure),
          const SizedBox(height: 8),
          Text(
            l.measurementTip,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _guideRow(IconData icon, String part, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.mood),
          const SizedBox(width: 8),
          Text('$part: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
          Text(l.bodyFatSources, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://www.ncbi.nlm.nih.gov/books/NBK235939/')),
            child: const Text(
              'NCBI — Body Composition Standards & Methods',
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
                Text(l.bodyFatDisclaimer, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(l.medicalDisclaimer, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(List<({String label, String range, double min, double max})> categories) {
    for (final cat in categories) {
      if (_bodyFat! >= cat.min && _bodyFat! < cat.max) return cat.label;
    }
    return categories.first.label;
  }

  Color _getCategoryColor(List<({String label, String range, double min, double max})> categories) {
    final colors = [AppColors.info, AppColors.accent, AppColors.success, AppColors.warning, AppColors.error];
    for (int i = 0; i < categories.length; i++) {
      if (_bodyFat! >= categories[i].min && _bodyFat! < categories[i].max) return colors[i];
    }
    return colors.first;
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
