import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/features/volunteer/models/volunteer_incident.dart';

void main() {
  test('parses the backend incident serializer shape', () {
    final incident = VolunteerIncident.fromJson({
      'id': 17,
      'user': {'id': 3, 'username': 'resident_test', 'role': 'resident'},
      'latitude': '3.139000',
      'longitude': '101.686900',
      'message': 'Need help near the entrance',
      'incident_type': 'medical',
      'status': 'pending',
      'created_at': '2026-10-19T09:00:00Z',
      'escalation_level': 0,
    });

    expect(incident.id, 17);
    expect(incident.username, 'resident_test');
    expect(incident.latitude, closeTo(3.139, 0.000001));
    expect(incident.longitude, closeTo(101.6869, 0.000001));
    expect(incident.readableType, 'Medical emergency');
    expect(incident.readableStatus, 'Awaiting response');
  });

  test('parses acknowledged and resolved responder attributes', () {
    final incident = VolunteerIncident.fromJson({
      'id': 18,
      'user': {'id': 5, 'username': 'caller_user'},
      'latitude': '3.139000',
      'longitude': '101.686900',
      'message': 'Small kitchen fire',
      'incident_type': 'fire',
      'status': 'resolved',
      'created_at': '2026-10-19T09:00:00Z',
      'escalation_level': 1,
      'acknowledged_by': {'id': 8, 'username': 'volunteer_hero'},
      'acknowledged_at': '2026-10-19T09:03:00Z',
      'resolved_at': '2026-10-19T09:20:00Z',
      'resolution_note': 'Extinguished with fire blanket.',
    });

    expect(incident.acknowledgedByUsername, 'volunteer_hero');
    expect(incident.acknowledgedAt, DateTime.parse('2026-10-19T09:03:00Z'));
    expect(incident.resolvedAt, DateTime.parse('2026-10-19T09:20:00Z'));
    expect(incident.resolutionNote, 'Extinguished with fire blanket.');
    expect(incident.readableStatus, 'Resolved');
  });
}
