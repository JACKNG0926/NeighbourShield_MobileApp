import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class AnnouncementTimelineUpdate {
  const AnnouncementTimelineUpdate({
    required this.id,
    required this.time,
    required this.title,
    required this.description,
    this.isImportant = false,
  });

  final String id;
  final DateTime time;
  final String title;
  final String description;
  final bool isImportant;

  String get timeFormatted {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class UrgentAnnouncement {
  const UrgentAnnouncement({
    required this.id,
    required this.title,
    required this.description,
    required this.postType,
    required this.category,
    required this.severity,
    required this.status,
    required this.issuerName,
    required this.issuerRole,
    required this.issuedAt,
    this.expiresAt,
    required this.affectedAreas,
    required this.safeAssemblyPoint,
    required this.volunteerRendezvousPoint,
    required this.actionGuidelines,
    required this.volunteerDirectives,
    required this.timelineUpdates,
    this.latitude,
    this.longitude,
    this.radiusMeters = 300,
    this.isSafeCheckedIn = false,
    this.volunteerResponseStatus,
    this.volunteerEtaMinutes,
    this.volunteerNote,
  });

  final int id;
  final String title;
  final String description;
  final String postType;
  final String category;
  final String severity;
  final String status;
  final String issuerName;
  final String issuerRole;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final List<String> affectedAreas;
  final String safeAssemblyPoint;
  final String volunteerRendezvousPoint;
  final List<String> actionGuidelines;
  final List<String> volunteerDirectives;
  final List<AnnouncementTimelineUpdate> timelineUpdates;
  final double? latitude;
  final double? longitude;
  final double radiusMeters;
  final bool isSafeCheckedIn;
  final String? volunteerResponseStatus; // 'responding', 'standby', 'unavailable'
  final int? volunteerEtaMinutes;
  final String? volunteerNote;

  factory UrgentAnnouncement.fromJson(Map<String, dynamic> json) {
    double? parseCoord(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final authorData = json['author'];
    String authorName = 'Township Security Command';
    String authorRole = 'Township Administration';
    if (authorData is Map) {
      authorName = authorData['username'] as String? ?? 'Township Admin';
      authorRole = authorData['role'] as String? ?? 'Admin';
    }

    DateTime createdDate;
    if (json['created_at'] != null) {
      createdDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    DateTime? expires;
    if (json['expires_at'] != null) {
      expires = DateTime.tryParse(json['expires_at'].toString());
    }

    List<String> areas = [];
    if (json['affected_areas'] is List) {
      for (final a in json['affected_areas']) {
        if (a is Map && a.containsKey('name')) {
          areas.add(a['name'].toString());
        } else if (a is String) {
          areas.add(a);
        }
      }
    }
    if (areas.isEmpty) {
      areas = ['Zone B (Block C & D)', 'North Gate Perimeter'];
    }

    final categoryStr = (json['category'] as String? ?? 'fire').toLowerCase();
    final severityStr = (json['severity'] as String? ?? 'critical').toLowerCase();

    return UrgentAnnouncement(
      id: json['id'] as int? ?? 1,
      title: json['title'] as String? ?? 'Urgent Emergency Broadcast',
      description: json['description'] as String? ?? 'Official emergency alert issued for township residents and volunteer response teams.',
      postType: (json['post_type'] as String? ?? 'broadcast').toLowerCase(),
      category: categoryStr,
      severity: severityStr,
      status: (json['status'] as String? ?? 'active').toLowerCase(),
      issuerName: authorName,
      issuerRole: authorRole,
      issuedAt: createdDate,
      expiresAt: expires,
      affectedAreas: areas,
      safeAssemblyPoint: 'Community Sports Complex (Field 1 / North Lawn)',
      volunteerRendezvousPoint: 'Clubhouse Lobby - Incident Command Post',
      actionGuidelines: _defaultGuidelines(categoryStr),
      volunteerDirectives: _defaultVolunteerDirectives(categoryStr),
      timelineUpdates: [
        AnnouncementTimelineUpdate(
          id: '1',
          time: createdDate.subtract(const Duration(minutes: 12)),
          title: 'Incident Reported',
          description: 'Initial alert received by security control room.',
        ),
        AnnouncementTimelineUpdate(
          id: '2',
          time: createdDate.subtract(const Duration(minutes: 5)),
          title: 'Emergency Services Dispatched',
          description: 'Emergency response units and Bomba notified. En route.',
          isImportant: true,
        ),
        AnnouncementTimelineUpdate(
          id: '3',
          time: createdDate,
          title: 'Broadcast & Volunteer Mobilization Initiated',
          description: 'Perimeter secured. Volunteer response requested.',
          isImportant: true,
        ),
      ],
      latitude: parseCoord(json['latitude']) ?? 3.139200,
      longitude: parseCoord(json['longitude']) ?? 101.687000,
      radiusMeters: 250,
    );
  }

  static List<String> _defaultGuidelines(String cat) {
    return switch (cat) {
      'fire' => const [
          'Evacuate immediately via fire escape stairs. DO NOT use elevators.',
          'Keep close to the floor to avoid smoke inhalation.',
          'Head directly to the designated assembly point at Community Field 1.',
          'Do not re-enter the building until official clearance is given.',
        ],
      'flood' => const [
          'Move valuable electrical equipment and documents to upper levels.',
          'Do not attempt to walk or drive through flowing water.',
          'Shut off main electrical circuit breaker if safe to do so.',
          'Keep emergency radio/phone charged and listen for updates.',
        ],
      'suspicious' => const [
          'Lock all doors and windows immediately.',
          'Keep exterior safety lights on; avoid confronting any intruders.',
          'Report any sightings directly to Guardhouse hotline.',
          'Remain indoors until security completes the perimeter sweep.',
        ],
      _ => const [
          'Stay indoors and keep personal communication lines clear.',
          'Follow instructions issued by verified security personnel.',
          'Check in on family and elderly neighbours if safe to do so.',
          'Check the live updates feed for changes in status.',
        ],
    };
  }

  static List<String> _defaultVolunteerDirectives(String cat) {
    return switch (cat) {
      'fire' => const [
          'Report to Incident Commander at Clubhouse Lobby Command Post.',
          'Assist building evacuation wardens at Staircase exits.',
          'Maintain clear access route along North Drive for fire engines.',
          'Set up triage registration desk at North Lawn Assembly Point.',
        ],
      'flood' => const [
          'Assist elderly and mobility-impaired residents to higher ground.',
          'Coordinate sandbag barrier deployment at basement car park entrance.',
          'Monitor drainage culvert water levels along Sector 3.',
        ],
      _ => const [
          'Report for duty at Clubhouse Lobby Command Post.',
          'Maintain situational awareness and relay local updates to control.',
          'Assist security personnel with crowd coordination and guidance.',
        ],
    };
  }

  UrgentAnnouncement copyWith({
    bool? isSafeCheckedIn,
    String? volunteerResponseStatus,
    int? volunteerEtaMinutes,
    String? volunteerNote,
  }) {
    return UrgentAnnouncement(
      id: id,
      title: title,
      description: description,
      postType: postType,
      category: category,
      severity: severity,
      status: status,
      issuerName: issuerName,
      issuerRole: issuerRole,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      affectedAreas: affectedAreas,
      safeAssemblyPoint: safeAssemblyPoint,
      volunteerRendezvousPoint: volunteerRendezvousPoint,
      actionGuidelines: actionGuidelines,
      volunteerDirectives: volunteerDirectives,
      timelineUpdates: timelineUpdates,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      isSafeCheckedIn: isSafeCheckedIn ?? this.isSafeCheckedIn,
      volunteerResponseStatus: volunteerResponseStatus ?? this.volunteerResponseStatus,
      volunteerEtaMinutes: volunteerEtaMinutes ?? this.volunteerEtaMinutes,
      volunteerNote: volunteerNote ?? this.volunteerNote,
    );
  }

  Color get severityColor {
    return switch (severity) {
      'critical' => AppTheme.dangerColor,
      'warning' => const Color(0xFFD97706),
      _ => const Color(0xFF2563EB),
    };
  }

  Color get severityHeaderGradientEnd {
    return switch (severity) {
      'critical' => const Color(0xFF8E1B29),
      'warning' => const Color(0xFF92400E),
      _ => const Color(0xFF1E40AF),
    };
  }

  IconData get severityIcon {
    return switch (category) {
      'fire' => Icons.local_fire_department,
      'flood' => Icons.flood,
      'suspicious' => Icons.shield_outlined,
      'road_closure' => Icons.traffic,
      _ => Icons.campaign_rounded,
    };
  }

  String get severityLabel => severity.toUpperCase();

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(issuedAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  bool isUserZoneAffected(String? userZone) {
    if (userZone == null || userZone.isEmpty) return true;
    final lowerUser = userZone.toLowerCase();
    for (final area in affectedAreas) {
      if (area.toLowerCase().contains(lowerUser) || lowerUser.contains(area.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
