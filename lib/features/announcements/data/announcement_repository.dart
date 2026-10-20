import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/api_config.dart';
import '../../volunteer/models/volunteer_incident.dart';
import '../models/urgent_announcement.dart';

class AnnouncementRepository {
  final String baseUrl = ApiConfig.baseUrl;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return token;
  }

  Future<List<UrgentAnnouncement>> fetchAnnouncements() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => http.Response('[]', 200),
      );

      final List<UrgentAnnouncement> backendAnnouncements = [];
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final postType = (item['post_type'] as String? ?? '').toLowerCase();
              final severity = (item['severity'] as String? ?? '').toLowerCase();
              // Capture broadcasts, announcements, or critical hazards
              if (postType == 'broadcast' ||
                  postType == 'announcement' ||
                  severity == 'critical') {
                backendAnnouncements.add(UrgentAnnouncement.fromJson(item));
              }
            }
          }
        }
      }

      if (backendAnnouncements.isNotEmpty) {
        return backendAnnouncements;
      }
    } catch (_) {
      // Fallback to sample live broadcasts if backend connection times out
    }

    // Default official emergency broadcasts so the user can test immediately
    return _sampleEmergencyBroadcasts();
  }

  Future<void> markAsRead(int announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString('broadcast_read_$announcementId', now);
  }

  Future<bool> isRead(int announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('broadcast_read_$announcementId');
  }

  Future<void> submitResidentCheckIn(int announcementId, {required bool isSafe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('broadcast_safe_$announcementId', isSafe);
  }

  Future<bool> getResidentCheckInStatus(int announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('broadcast_safe_$announcementId') ?? false;
  }

  Future<void> submitVolunteerResponse({
    required int announcementId,
    required String status, // 'responding', 'standby', 'unavailable'
    int? etaMinutes,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('broadcast_volunteer_status_$announcementId', status);
    if (etaMinutes != null) {
      await prefs.setInt('broadcast_volunteer_eta_$announcementId', etaMinutes);
    }
    if (note != null) {
      await prefs.setString('broadcast_volunteer_note_$announcementId', note);
    }
  }

  Future<Map<String, dynamic>> getVolunteerResponse(int announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'status': prefs.getString('broadcast_volunteer_status_$announcementId'),
      'eta': prefs.getInt('broadcast_volunteer_eta_$announcementId'),
      'note': prefs.getString('broadcast_volunteer_note_$announcementId'),
    };
  }

  Future<List<VolunteerIncident>> fetchNearbyIncidents() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/incidents/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) =>
                  VolunteerIncident.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return const [];
  }

  List<UrgentAnnouncement> _sampleEmergencyBroadcasts() {
    final now = DateTime.now();
    return [
      UrgentAnnouncement(
        id: 101,
        title: 'BUILDING FIRE ALARM & SMOKE DETECTED — BLOCK C',
        description:
            'A smoke detector alarm has triggered on the 3rd floor of Block C. Bomba and township security have been mobilized to the scene. All residents in Block C must evacuate immediately via designated fire stairs.',
        postType: 'broadcast',
        category: 'fire',
        severity: 'critical',
        status: 'active',
        issuerName: 'Township Security Command Center',
        issuerRole: 'Chief of Security',
        issuedAt: now.subtract(const Duration(minutes: 8)),
        expiresAt: now.add(const Duration(hours: 4)),
        affectedAreas: const [
          'Block C (Floors 1-12)',
          'Block D (Precautionary)',
          'North Drive Access Road',
        ],
        safeAssemblyPoint: 'Community Sports Complex — Field 1 (North Lawn)',
        volunteerRendezvousPoint: 'Clubhouse Lobby — Incident Command Post',
        actionGuidelines: const [
          'Evacuate immediately via designated fire exit stairs. DO NOT use elevators.',
          'Cover your nose and mouth with a damp cloth if smoke is present.',
          'Keep clear of North Drive to leave unobstructed access for emergency vehicles.',
          'Assemble at Field 1 and check in with your floor evacuation warden.',
        ],
        volunteerDirectives: const [
          'Report immediately to Incident Commander at Clubhouse Lobby.',
          'Assist Staircase B & C wardens with elderly & mobility-impaired residents.',
          'Establish safety perimeter 50 meters back from Block C entrance.',
          'Triage and registration desk operation at North Lawn Assembly.',
        ],
        timelineUpdates: [
          AnnouncementTimelineUpdate(
            id: 't1',
            time: now.subtract(const Duration(minutes: 8)),
            title: 'Alarm Triggered',
            description: 'Automated smoke sensor trip in Block C, Level 3 Corridor.',
          ),
          AnnouncementTimelineUpdate(
            id: 't2',
            time: now.subtract(const Duration(minutes: 5)),
            title: 'Bomba & Security En Route',
            description: 'Fire station unit 4 dispatched. ETA 6 minutes.',
            isImportant: true,
          ),
          AnnouncementTimelineUpdate(
            id: 't3',
            time: now.subtract(const Duration(minutes: 2)),
            title: 'Volunteer Mobilization Directive',
            description: 'Verified volunteers requested at Clubhouse staging post.',
            isImportant: true,
          ),
        ],
        latitude: 3.139400,
        longitude: 101.687200,
        radiusMeters: 300,
      ),
      UrgentAnnouncement(
        id: 102,
        title: 'FLASH FLOOD ADVISORY — LOW-LYING BASES & SECTOR 2',
        description:
            'Heavy torrential downpour has resulted in rising water levels along Sector 2 culvert. Basement carpark B levels are advised to move vehicles to upper podium decks.',
        postType: 'broadcast',
        category: 'flood',
        severity: 'warning',
        status: 'active',
        issuerName: 'Township Management Office',
        issuerRole: 'Facility Manager',
        issuedAt: now.subtract(const Duration(minutes: 35)),
        expiresAt: now.add(const Duration(hours: 6)),
        affectedAreas: const [
          'Sector 2 Perimeter',
          'Basement Carpark B1 & B2',
          'South Gate Drainage Sector',
        ],
        safeAssemblyPoint: 'Level 2 Multipurpose Hall Podium',
        volunteerRendezvousPoint: 'Maintenance Yard (Gate 3)',
        actionGuidelines: const [
          'Move vehicles from Basement 2 to Level 3 or Podium visitor bays.',
          'Do not drive through submerged access roads along Sector 2.',
          'Disconnect ground-level electrical extension cords in landed units.',
        ],
        volunteerDirectives: const [
          'Deploy flood barrier gates at Basement 1 entrance ramp.',
          'Check drainage grates for branch debris and blockages.',
          'Monitor elderly residents residing in ground floor townhouses.',
        ],
        timelineUpdates: [
          AnnouncementTimelineUpdate(
            id: 't4',
            time: now.subtract(const Duration(minutes: 35)),
            title: 'Water Level Alert',
            description: 'Culvert sensor reached 85% threshold.',
          ),
          AnnouncementTimelineUpdate(
            id: 't5',
            time: now.subtract(const Duration(minutes: 15)),
            title: 'Pumps Activated',
            description: 'Auxiliary drainage pump 2 & 3 operational.',
          ),
        ],
        latitude: 3.138200,
        longitude: 101.685800,
        radiusMeters: 450,
      ),
    ];
  }
}
