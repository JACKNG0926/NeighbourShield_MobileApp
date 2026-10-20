import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/session/app_session.dart';
import '../../data/volunteer_incident_repository.dart';
import '../../models/volunteer_incident.dart';
import '../../../announcements/presentation/pages/urgent_announcements_list_page.dart';
import '../../../reports/presentation/pages/community_safety_reports_page.dart';
import 'volunteer_incident_detail_page.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key, required this.session});

  final AppSession session;

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  final VolunteerIncidentRepository _repository = VolunteerIncidentRepository();
  bool _isLoading = false;
  String? _error;
  List<VolunteerIncident> _incidents = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIncidents());
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Turn on Location Services to find nearby SOS alerts.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission was denied. Allow location to view nearby alerts.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in Android Settings.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      return Position(
        latitude: 3.139000,
        longitude: 101.686900,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }

  Future<void> _loadIncidents() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Refresh the server-side last-known location before querying the queue.
      // Django uses this location and its configured radius to filter incidents.
      final position = await _getCurrentPosition();
      await _repository.updateMyLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final incidents = await _repository.fetchNearbyIncidents();

      if (!mounted) return;
      setState(() => _incidents = incidents);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openIncident(VolunteerIncident incident) async {
    final acknowledged = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VolunteerIncidentDetailPage(
          incident: incident,
          repository: _repository,
        ),
      ),
    );
    if (acknowledged == true && mounted) {
      await _loadIncidents();
    }
  }

  void _openCommunityReports() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CommunitySafetyReportsPage(),
      ),
    );
  }

  void _openUrgentAnnouncements() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UrgentAnnouncementsListPage(session: widget.session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.session.currentUser?.username ?? 'Volunteer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh nearby SOS alerts',
            onPressed: _isLoading ? null : _loadIncidents,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: widget.session.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadIncidents,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'VOLUNTEER RESPONSE TEAM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome, $username',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nearby SOS alerts are filtered by the server using your latest location and the configured response radius.',
                      style: TextStyle(color: Color(0xFFE5F3F0), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nearby SOS alerts',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Text(
                    '${_incidents.length} active',
                    style: const TextStyle(
                      color: AppTheme.mutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoading && _incidents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _InfoPanel(
                  icon: Icons.location_off_outlined,
                  title: 'Unable to load nearby alerts',
                  message: _error!,
                  actionLabel: 'Try again',
                  onAction: _loadIncidents,
                )
              else if (_incidents.isEmpty)
                _InfoPanel(
                  icon: Icons.check_circle_outline,
                  title: 'No nearby SOS alerts',
                  message: 'There are no pending SOS alerts in your current response radius. Pull down to refresh.',
                )
              else
                ..._incidents.map(
                  (incident) => _IncidentCard(
                    incident: incident,
                    onTap: () => _openIncident(incident),
                  ),
                ),
              const SizedBox(height: 16),
              _ActionFeatureCard(
                icon: Icons.shield_outlined,
                title: 'Community safety reports',
                description: 'Review resident-submitted safety reports & hazards.',
                badgeText: 'Active',
                onTap: _openCommunityReports,
              ),
              _ActionFeatureCard(
                icon: Icons.campaign_outlined,
                title: 'Urgent announcements',
                description:
                    'Emergency broadcasts, safety directives & mobilization.',
                badgeText: 'Alert',
                onTap: _openUrgentAnnouncements,
              ),
              const SizedBox(height: 8),
              const Text(
                'Location-based SOS data is visible only to authorised responders within the configured radius. Acknowledge an alert only when you are able to respond.',
                style: TextStyle(
                  color: AppTheme.mutedColor,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});

  final VolunteerIncident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = incident.createdAt.millisecondsSinceEpoch == 0
        ? 'Unknown time'
        : incident.createdAt.toLocal().toString().split('.').first;
    final isEscalated = incident.status == 'escalated';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: isEscalated
                        ? AppTheme.dangerColor
                        : AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SOS #${incident.id} · ${incident.readableType}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 9),
              Text('Status: ${incident.readableStatus}'),
              const SizedBox(height: 4),
              Text('Reported by ${incident.username} · $createdAt'),
              if (incident.message.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  incident.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppTheme.primaryColor),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.mutedColor, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ActionFeatureCard extends StatelessWidget {
  const _ActionFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(color: AppTheme.mutedColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.mutedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
