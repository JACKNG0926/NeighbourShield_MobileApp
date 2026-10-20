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
}
