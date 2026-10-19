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
    );
  }

  String get readableType => switch (incidentType) {
    'medical' => 'Medical emergency',
    'crime' => 'Crime / security',
    'fire' => 'Fire',
    'accident' => 'Accident',
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
