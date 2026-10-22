import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // <-- Added for location
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/services/new_incident_detector.dart';
import '../../../../core/services/siren_service.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/siren_banner.dart';
import '../../../community/presentation/pages/community_board_page.dart';
import '../../../reports/presentation/pages/community_safety_reports_page.dart';
import '../../../volunteer/data/volunteer_incident_repository.dart';
import '../../../volunteer/models/volunteer_incident.dart';
import '../../../volunteer/presentation/pages/volunteer_incident_detail_page.dart';

class SecurityHomePage extends StatefulWidget {
  const SecurityHomePage({super.key, required this.session});

  final AppSession session;

  @override
  State<SecurityHomePage> createState() => _SecurityHomePageState();
}

class _SecurityHomePageState extends State<SecurityHomePage> {
  final VolunteerIncidentRepository _repository = VolunteerIncidentRepository();
  final NewIncidentDetector _detector = NewIncidentDetector();
  Timer? _pollTimer;

  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _error;
  List<VolunteerIncident> _incidents = const [];

  // Map states
  LatLng? _currentUserLocation;
  final MapController _mapController = MapController();

  static const _openStatuses = {'pending', 'acknowledged', 'escalated'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIncidents());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadIncidents(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    Future.microtask(SirenService.instance.stop);
    super.dispose();
  }

  // Added Geolocator method so security gets the blue dot too
  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Future<void> _loadIncidents({bool silent = false}) async {
    if (_isLoading || !mounted) return;
    setState(() {
      _isLoading = true;
      if (!silent) _error = null;
    });

    try {
      // 1. Get current location
      final position = await _getCurrentPosition();
      if (position != null) {
        await _repository.updateMyLocation(latitude: position.latitude, longitude: position.longitude);
      }

      // 2. Fetch incidents
      final all = await _repository.fetchNearbyIncidents(); // security gets all
      final open = all.where((i) => _openStatuses.contains(i.status)).toList();

      if (!mounted) return;
      final needsResponse = open.where((i) => i.status == 'pending' || i.status == 'escalated');
      if (_detector.update(needsResponse.map((i) => i.id))) {
        SirenService.instance.play();
      }
      
      setState(() {
        _incidents = open;
        _error = null;
        _hasLoadedOnce = true;
        if (position != null) {
          _currentUserLocation = LatLng(position.latitude, position.longitude); // Save location
        }
      });
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openIncident(VolunteerIncident incident) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VolunteerIncidentDetailPage(
          incident: incident,
          repository: _repository,
          isSecurity: true,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadIncidents();
    }
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.session.currentUser?.username ?? 'Security';
    final unacknowledged = _incidents
        .where((i) => i.status == 'pending' || i.status == 'escalated')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh SOS alerts',
            onPressed: _isLoading ? null : _loadIncidents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadIncidents,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const SirenBanner(),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF123B36),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.white, size: 34),
                        SizedBox(width: 12),
                        Text('TOWNSHIP SECURITY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Welcome, $username', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${_incidents.length} open incident(s) township-wide, $unacknowledged awaiting acknowledgement.', style: const TextStyle(color: Color(0xFFE5F3F0), height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              
              // --- MAP SECTION ---
              Stack(
                children: [
                  Container(
                    height: 400, // BIGGER MAP
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4EBE8)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentUserLocation ??
                              (_incidents.isNotEmpty
                                  ? LatLng(_incidents.first.latitude, _incidents.first.longitude)
                                  : const LatLng(3.1390, 101.6869)),
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.neighbourshield.app',
                          ),
                          MarkerLayer(
                            markers: [
                              // 1. BLUE MARKER FOR "YOU ARE HERE"
                              if (_currentUserLocation != null)
                                Marker(
                                  point: _currentUserLocation!,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                                  ),
                                ),
                              // 2. RED/ORANGE MARKERS FOR SOS
                              ..._incidents.map((incident) {
                                return Marker(
                                  point: LatLng(incident.latitude, incident.longitude),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () => _openIncident(incident),
                                    child: Icon(
                                      Icons.location_on,
                                      color: incident.status == 'acknowledged' ? Colors.orange : Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 3. RECENTER BUTTON
                  if (_currentUserLocation != null)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(_currentUserLocation!, 16);
                        },
                        child: const Icon(Icons.my_location, color: Colors.blue),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              
              const Text('Open SOS incidents', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              if (_isLoading && !_hasLoadedOnce)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _SecurityInfoPanel(
                  icon: Icons.cloud_off_outlined,
                  title: 'Unable to load incidents',
                  message: _error!,
                  actionLabel: 'Try again',
                  onAction: _loadIncidents,
                )
              else if (_incidents.isEmpty)
                const _SecurityInfoPanel(
                  icon: Icons.check_circle_outline,
                  title: 'No open incidents',
                  message: 'New SOS alerts appear here automatically.',
                )
              else
                ..._incidents.map(
                  (incident) => _SecurityIncidentCard(
                    incident: incident,
                    onTap: () => _openIncident(incident),
                  ),
                ),
              const SizedBox(height: 16),
              _SecurityLinkCard(
                icon: Icons.shield_outlined,
                title: 'Community safety reports',
                description: 'Review resident-submitted safety reports & hazards.',
                onTap: () => _push(const CommunitySafetyReportsPage()),
              ),
              _SecurityLinkCard(
                icon: Icons.forum_outlined,
                title: 'Community board',
                description: 'Neighbourhood notices, queries & updates.',
                onTap: () => _push(const CommunityBoardPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityIncidentCard extends StatelessWidget {
  const _SecurityIncidentCard({required this.incident, required this.onTap});

  final VolunteerIncident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = incident.createdAt.millisecondsSinceEpoch == 0
        ? 'Unknown time'
        : incident.createdAt.toLocal().toString().split('.').first;
    final needsResponse = incident.status == 'pending' || incident.status == 'escalated';

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
                    color: needsResponse ? AppTheme.dangerColor : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SOS #${incident.id} · ${incident.readableType}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 9),
              Text('Status: ${incident.readableStatus}'),
              const SizedBox(height: 4),
              Text('Reported by ${incident.username} · $createdAt'),
              if (incident.locationNotes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Location: ${incident.locationNotes}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent),
                ),
              ],
              if (incident.contactPhone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Phone: ${incident.contactPhone}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityInfoPanel extends StatelessWidget {
  const _SecurityInfoPanel({
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
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.mutedColor, height: 1.4)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _SecurityLinkCard extends StatelessWidget {
  const _SecurityLinkCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
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
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(color: AppTheme.mutedColor)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.mutedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}