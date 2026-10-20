import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/features/announcements/models/urgent_announcement.dart';

void main() {
  group('UrgentAnnouncement model', () {
    test('parses Django announcement JSON properly', () {
      final json = {
        'id': 10,
        'title': 'Chemical Leak in Block B',
        'description': 'Keep windows closed.',
        'post_type': 'broadcast',
        'category': 'fire',
        'severity': 'critical',
        'status': 'active',
        'author': {
          'username': 'admin_sec',
          'role': 'security',
        },
        'affected_areas': ['Block B', 'Sector 1'],
        'created_at': '2026-10-20T10:00:00.000000Z',
        'latitude': 3.140000,
        'longitude': 101.688000,
      };

      final a = UrgentAnnouncement.fromJson(json);

      expect(a.id, 10);
      expect(a.title, 'Chemical Leak in Block B');
      expect(a.severity, 'critical');
      expect(a.severityLabel, 'CRITICAL');
      expect(a.postType, 'broadcast');
      expect(a.issuerName, 'admin_sec');
      expect(a.affectedAreas.length, 2);
      expect(a.isUserZoneAffected('Block B'), true);
      expect(a.isUserZoneAffected('Block Z'), false);
      expect(a.actionGuidelines.isNotEmpty, true);
      expect(a.volunteerDirectives.isNotEmpty, true);
    });

    test('copyWith updates mobilization and check-in fields', () {
      final a = UrgentAnnouncement.fromJson({'id': 1});

      final updated = a.copyWith(
        isSafeCheckedIn: true,
        volunteerResponseStatus: 'responding',
        volunteerEtaMinutes: 10,
        volunteerNote: 'Bringing stretcher',
      );

      expect(updated.isSafeCheckedIn, true);
      expect(updated.volunteerResponseStatus, 'responding');
      expect(updated.volunteerEtaMinutes, 10);
      expect(updated.volunteerNote, 'Bringing stretcher');
    });
  });
}
