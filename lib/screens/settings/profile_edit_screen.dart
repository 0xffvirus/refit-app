import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_form.dart';

class ProfileEditScreen extends StatelessWidget {
  final UserProfile profile;

  const ProfileEditScreen({super.key, required this.profile});

  Future<void> _save(BuildContext context, UserProfile updated) async {
    final db = DatabaseService();
    await db.updateUserProfile(updated);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.profileSaved)),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ProfileForm(
            initial: profile,
            buttonLabel: l.save,
            onSave: (updated) => _save(context, updated),
          ),
        ],
      ),
    );
  }
}
