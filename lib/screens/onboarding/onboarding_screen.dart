import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/profile_form.dart';
import '../../main.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _skip(BuildContext context) async {
    final db = DatabaseService();
    await db.updateUserProfile(UserProfile(onboardingSeen: true));
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _save(BuildContext context, UserProfile profile) async {
    final db = DatabaseService();
    await db.updateUserProfile(profile);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => _skip(context),
            child: Text(l.skip, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Text(
              l.welcomeTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.welcomeSubtitle,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ProfileForm(
              buttonLabel: l.start,
              onSave: (profile) => _save(context, profile),
            ),
          ],
        ),
      ),
    );
  }
}
