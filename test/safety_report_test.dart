import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/features/reports/models/safety_report.dart';

void main() {
  group('SafetyReport model', () {
    test('parses Django SafetyPost JSON correctly', () {
      final json = {
        'id': 1,
        'author': {
          'id': 2,
          'username': 'win',
          'role': 'volunteer',
        },
        'post_type': 'hazard',
        'category': 'broken_light',
        'title': 'Broken street lamp near Block C',
        'description': 'The lamp post is flickering and completely dark at night.',
        'latitude': '3.139200',
        'longitude': '101.687000',
        'severity': 'warning',
        'status': 'open',
        'is_verified': false,
        'created_at': '2026-10-20T11:41:14.821894Z',
      };

      final report = SafetyReport.fromJson(json);

      expect(report.id, 1);
      expect(report.authorUsername, 'win');
      expect(report.category, 'broken_light');
      expect(report.categoryLabel, 'Street Light');
      expect(report.severity, 'warning');
      expect(report.severityLabel, 'Warning');
      expect(report.status, 'open');
      expect(report.statusLabel, 'Open');
      expect(report.latitude, closeTo(3.1392, 0.0001));
      expect(report.longitude, closeTo(101.6870, 0.0001));
      expect(report.isVerified, false);
    });

    test('handles null author, coordinates, and default values gracefully', () {
      final json = {
        'id': 2,
        'title': 'Pothole on main lane',
      };

      final report = SafetyReport.fromJson(json);

      expect(report.id, 2);
      expect(report.authorUsername, 'Anonymous');
      expect(report.category, 'other');
      expect(report.severity, 'info');
      expect(report.status, 'open');
      expect(report.latitude, isNull);
      expect(report.longitude, isNull);
      expect(report.description, '');
    });
  });
}
