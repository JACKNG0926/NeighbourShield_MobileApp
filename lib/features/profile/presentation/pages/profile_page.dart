import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/session/user_role.dart';
import '../../../auth/models/user_session.dart';
import '../../../../core/widgets/phone_input_field.dart';
import '../../data/profile_repository.dart';

/// Profile tab shared by Resident, Volunteer and Security accounts.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.session});

  final AppSession session;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _repository = ProfileRepository();
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _hidePasswords = true;

  @override
  void initState() {
    super.initState();
    final user = widget.session.currentUser;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(text: user?.phoneNumber ?? '');
    _address = TextEditingController(text: user?.unitAddress ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _clean(Object error) => error.toString().replaceFirst('Exception: ', '');

  Future<void> _saveProfile() async {
    if (_savingProfile || !_profileFormKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      final profile = await _repository.updateProfile(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        phone: _phone.text,
        unitAddress: _address.text,
      );
      if (!mounted) return;
      widget.session.updateCurrentUser(UserSession.fromBackend(profile));
      _toast('Profile saved.');
    } catch (error) {
      if (mounted) _toast(_clean(error));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_savingPassword || !_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    try {
      await _repository.changePassword(
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      _toast('Password changed.');
    } catch (error) {
      if (mounted) _toast(_clean(error));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.clearToken();
    widget.session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFD9EBE6),
                      child: Icon(Icons.person, color: AppTheme.primaryColor, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? '',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '@${user?.username ?? ''} · ${user?.role.label ?? ''}',
                            style: const TextStyle(color: AppTheme.mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Your phone number and unit address are sent to responders with every SOS.',
                  style: TextStyle(color: AppTheme.mutedColor, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Form(
                  key: _profileFormKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstName,
                              decoration: const InputDecoration(hintText: 'First name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastName,
                              decoration: const InputDecoration(hintText: 'Last name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return null;
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      PhoneInputField(controller: _phone),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(
                          hintText: 'Unit address (e.g. A-12-03)',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Unit address is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _savingProfile ? null : _saveProfile,
                          icon: _savingProfile
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_savingProfile ? 'Saving...' : 'Save changes'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Change password',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Form(
                  key: _passwordFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _oldPassword,
                        obscureText: _hidePasswords,
                        decoration: InputDecoration(
                          hintText: 'Current password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hidePasswords = !_hidePasswords),
                            icon: Icon(_hidePasswords
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your current password' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPassword,
                        obscureText: _hidePasswords,
                        decoration: const InputDecoration(
                          hintText: 'New password (min 8 characters)',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter a new password';
                          if (v.length < 8) return 'Use at least 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: _hidePasswords,
                        decoration: const InputDecoration(
                          hintText: 'Confirm new password',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        validator: (v) =>
                            v != _newPassword.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _savingPassword ? null : _changePassword,
                          icon: _savingPassword
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.key_outlined),
                          label: Text(_savingPassword ? 'Updating...' : 'Update password'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _logOut,
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
