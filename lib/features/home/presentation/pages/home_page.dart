import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/session/user_role.dart';
import '../../../auth/models/user_session.dart';
import '../../data/incident_repository.dart';
import '../../../volunteer/data/volunteer_repository.dart';
import '../../../volunteer/presentation/pages/volunteer_application_page.dart';

class HomePage extends StatefulWidget {
  final String email;
  final AppSession session;

  const HomePage({super.key, required this.email, required this.session});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final IncidentRepository _incidentRepository = IncidentRepository();
  final VolunteerRepository _volunteerRepository = VolunteerRepository();
  bool _isSendingSos = false;
  bool _isCheckingVolunteerStatus = false;

  Future<void> _handleSosTrigger() async {
    setState(() {
      _isSendingSos = true;
    });

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled on your device.');
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // 3. Get actual GPS coordinates
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 4. Send to Django backend
      await _incidentRepository.sendSos(position.latitude, position.longitude);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Alert sent successfully! Help is on the way.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingSos = false;
        });
      }
    }
  }

  Future<void> _refreshVolunteerStatus() async {
    if (_isCheckingVolunteerStatus) return;

    setState(() => _isCheckingVolunteerStatus = true);
    UserSession? refreshedUser;
    String? errorMessage;

    try {
      final profile = await _volunteerRepository.fetchCurrentProfile();
      refreshedUser = UserSession.fromBackend(profile);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() => _isCheckingVolunteerStatus = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    if (refreshedUser == null) return;

    // If Django now reports an approved role, SessionGate replaces this page
    // with the appropriate role dashboard. The client never grants the role.
    if (refreshedUser.role != UserRole.resident) {
      widget.session.updateCurrentUser(refreshedUser);
      return;
    }

    widget.session.updateCurrentUser(refreshedUser);

    final String message;
    if (refreshedUser.isVolunteerOptedIn &&
        !refreshedUser.isVerifiedVolunteer) {
      message =
          'Your application is still awaiting administrator verification.';
    } else if (refreshedUser.isVolunteerOptedIn &&
        refreshedUser.isVerifiedVolunteer) {
      message = 'Your account is verified, but Django has not assigned the Volunteer role yet. Please contact the administrator.';
    } else {
      message =
          'No pending volunteer application was found. You can apply below.';
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPendingVolunteerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4B96A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_top, color: Color(0xFF8A6415), size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Volunteer application pending',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Your application has been received. You can continue using '
            'Resident features while a township administrator reviews it. '
            'After approval, check the status here to open your Volunteer Dashboard.',
            style: TextStyle(color: AppTheme.mutedColor, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCheckingVolunteerStatus
                  ? null
                  : _refreshVolunteerStatus,
              icon: _isCheckingVolunteerStatus
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _isCheckingVolunteerStatus
                      ? 'Checking status...'
                      : 'Check Application Status',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerApplicationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                color: AppTheme.primaryColor,
                size: 30,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Help keep your community safe',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Join the volunteer response team and help neighbours during emergencies.',
            style: TextStyle(color: AppTheme.mutedColor),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        VolunteerApplicationPage(session: widget.session),
                  ),
                );
              },
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Become a Volunteer'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSosConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            size: 42,
            color: AppTheme.dangerColor,
          ),
          title: const Text('Emergency SOS'),
          content: const Text(
            'Are you sure you want to trigger an emergency alert? '
            'This will share your current location with local responders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleSosTrigger();
              },
              child: const Text('TRIGGER ALERT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.session.currentUser;
    final hasPendingVolunteerApplication =
        currentUser != null &&
        currentUser.role == UserRole.resident &&
        currentUser.isVolunteerOptedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeighbourShield'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: widget.session.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'WELCOME BACK',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your community,\nyour safety.',
                style: TextStyle(
                  fontSize: 29,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFD9EBE6),
                    child: Icon(
                      Icons.person_outline,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resident',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.mutedColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE4EBE8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Need urgent help?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Request assistance from your community.',
                      style: TextStyle(color: AppTheme.mutedColor),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 62,
                      child: FilledButton.icon(
                        onPressed: _isSendingSos
                            ? null
                            : () => _showSosConfirmation(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.dangerColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isSendingSos
                            ? const SizedBox.shrink()
                            : const Icon(Icons.sos, size: 30),
                        label: _isSendingSos
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'SEND SOS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (hasPendingVolunteerApplication)
                _buildPendingVolunteerCard()
              else
                _buildVolunteerApplicationCard(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F1EE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your safety matters',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Location access is required for emergency services to find you quickly.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
