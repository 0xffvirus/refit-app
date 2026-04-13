import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../utils/app_theme.dart';

class ProfileForm extends StatefulWidget {
  final UserProfile? initial;
  final String buttonLabel;
  final ValueChanged<UserProfile> onSave;

  const ProfileForm({
    super.key,
    this.initial,
    required this.buttonLabel,
    required this.onSave,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _nameController.text = p.name ?? '';
      _ageController.text = p.age?.toString() ?? '';
      _heightController.text = p.heightCm?.toString() ?? '';
      _weightController.text = p.weightKg?.toString() ?? '';
      _gender = p.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    final profile = UserProfile(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      gender: _gender,
      age: int.tryParse(_ageController.text),
      heightCm: double.tryParse(_heightController.text),
      weightKg: double.tryParse(_weightController.text),
      onboardingSeen: true,
    );
    widget.onSave(profile);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: l.profileName),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Gender toggle
        Text(l.gender, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = Gender.male),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _gender == Gender.male ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gender == Gender.male ? AppColors.accent : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l.male,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _gender == Gender.male ? AppColors.background : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = Gender.female),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _gender == Gender.female ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gender == Gender.female ? AppColors.accent : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l.female,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _gender == Gender.female ? AppColors.background : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Age
        TextField(
          controller: _ageController,
          decoration: InputDecoration(labelText: l.profileAge),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Height
        TextField(
          controller: _heightController,
          decoration: InputDecoration(labelText: l.profileHeight),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Weight
        TextField(
          controller: _weightController,
          decoration: InputDecoration(labelText: l.profileWeight),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 24),

        // Submit button
        FilledButton(
          onPressed: _submit,
          child: Text(widget.buttonLabel),
        ),
      ],
    );
  }
}
