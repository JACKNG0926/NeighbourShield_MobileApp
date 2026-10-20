import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/session/user_role.dart';
import '../../../auth/models/user_session.dart';
import '../../data/volunteer_repository.dart';

class VolunteerApplicationPage extends StatefulWidget {
  const VolunteerApplicationPage({super.key, required this.session});

  final AppSession session;

  @override
  State<VolunteerApplicationPage> createState() =>
      _VolunteerApplicationPageState();
}

class _VolunteerApplicationPageState extends State<VolunteerApplicationPage> {
  final VolunteerRepository _repository = VolunteerRepository();
  bool _isSubmitting = false;

  Future<void> _handleApply() async {
    if (_isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.volunteer_activism_outlined,
            color: AppTheme.primaryColor,
            size: 40,
          ),
          title: const Text('Apply to be a Volunteer?'),
          content: const Text(
            'Your application will be recorded in Django and sent for '
            'administrator verification. You will remain a Resident until '
            'an administrator approves your application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Submit application'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    Map<String, dynamic>? updatedProfile;
    String? errorMessage;

    try {
      // Django records the opt-in. It does not grant the Volunteer role here.
      updatedProfile = await _repository.submitVolunteerOptIn();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    if (updatedProfile == null) return;

    final updatedUser = UserSession.fromBackend(updatedProfile);
    widget.session.updateCurrentUser(updatedUser);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Application submitted. Your account will remain Resident until '
          'an administrator verifies it.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.currentUser;
    final isResident = user?.role == UserRole.resident;
    final hasPendingApplication = isResident && user!.isVolunteerOptedIn;
    final canApply = isResident && !user!.isVolunteerOptedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Application')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F1EE),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(
                        Icons.volunteer_activism_outlined,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Make a difference in your community',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Volunteers can help neighbours respond to emergencies '
                      'and keep the community informed about local safety issues.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.mutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'What volunteers can help with',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const _BenefitTile(
                icon: Icons.notifications_active_outlined,
                title: 'Receive community alerts',
                description: 'Stay aware of urgent situations in your area.',
              ),
              const _BenefitTile(
                icon: Icons.health_and_safety_outlined,
                title: 'Support neighbours',
                description:
                    'Help connect residents with the appropriate responders.',
              ),
              const _BenefitTile(
                icon: Icons.campaign_outlined,
                title: 'Share safety information',
                description: 'Help your community stay informed.',
              ),
              const SizedBox(height: 18),
              if (hasPendingApplication)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE4B96A)),
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFFFF8E8),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.hourglass_top, color: Color(0xFF8A6415)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your application has been submitted and is awaiting '
                          'administrator verification. You can continue using '
                          'the Resident features while it is under review.',
                          style: TextStyle(color: Color(0xFF72551A)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFB8D9D0)),
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFF0F8F5),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your request will be reviewed by a township '
                          'administrator. Submitting the form does not grant '
                          'Volunteer access immediately.',
                          style: TextStyle(color: AppTheme.textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              if (canApply)
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _handleApply,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Application',
                    ),
                  ),
                )
              else if (hasPendingApplication)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Back to Resident Home'),
                  ),
                )
              else
                const Text(
                  'Only a signed-in Resident can apply.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.mutedColor, fontSize: 12),
                ),
              const SizedBox(height: 8),
              if (user != null)
                Text(
                  'Account: ${user.username}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.mutedColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: AppTheme.mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
