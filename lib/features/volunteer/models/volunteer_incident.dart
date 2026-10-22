class VolunteerIncident {
  const VolunteerIncident({
    required this.id,
    required this.username,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.incidentType,
    required this.message,
    required this.createdAt,
    required this.escalationLevel,
    this.acknowledgedByUsername,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionNote = '',
    this.locationNotes = '', // <-- ADDED
    this.contactPhone = '',  // <-- ADDED
  });

  final int id;
  final String username;
  final double latitude;
  final double longitude;
  final String status;
  final String incidentType;
  final String message;
  final DateTime createdAt;
  final int escalationLevel;
  final String? acknowledgedByUsername;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String resolutionNote;
  final String locationNotes; // <-- ADDED
  final String contactPhone;  // <-- ADDED

  factory VolunteerIncident.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : <String, dynamic>{};

    double parseCoordinate(Object? value, String field) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      throw FormatException('Missing or invalid incident $field.');
    }

    final rawCreatedAt = json['created_at'];
    final createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt)
        : null;

    final rawAckBy = json['acknowledged_by'];
    String? ackByUsername;
    if (rawAckBy is Map) {
      ackByUsername = rawAckBy['username'] as String?;
    }

    final rawAckAt = json['acknowledged_at'];
    final acknowledgedAt =
        rawAckAt is String ? DateTime.tryParse(rawAckAt) : null;

    final rawResolvedAt = json['resolved_at'];
    final resolvedAt =
        rawResolvedAt is String ? DateTime.tryParse(rawResolvedAt) : null;

    final resolutionNote = json['resolution_note'] as String? ?? '';

    return VolunteerIncident(
      id:
          (json['id'] as num?)?.toInt() ??
          int.tryParse('${json['id']}') ??
          (throw const FormatException('Missing incident id.')),
      username: user['username'] as String? ?? 'Resident',
      latitude: parseCoordinate(json['latitude'], 'latitude'),
      longitude: parseCoordinate(json['longitude'], 'longitude'),
      status: json['status'] as String? ?? 'pending',
      incidentType: json['incident_type'] as String? ?? 'other',
      message: json['message'] as String? ?? '',
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      escalationLevel: (json['escalation_level'] as num?)?.toInt() ?? 0,
      acknowledgedByUsername: ackByUsername,
      acknowledgedAt: acknowledgedAt,
      resolvedAt: resolvedAt,
      resolutionNote: resolutionNote,
      locationNotes: json['location_notes'] as String? ?? '', // <-- ADDED
      contactPhone: json['contact_phone'] as String? ?? '',   // <-- ADDED
    );
  }

  String get readableType => switch (incidentType) {
    'medical' => 'Medical emergency',
    'crime' => 'Crime / security',
    'fire' => 'Fire',
    'accident' => 'Accident',
    'backup' => 'Backup request',
    _ => 'Other emergency',
  };

  String get readableStatus => switch (status) {
    'pending' => 'Awaiting response',
    'escalated' => 'Escalated',
    'acknowledged' => 'Acknowledged',
    'resolved' => 'Resolved',
    'cancelled' => 'Cancelled',
    _ => status,
  };
}