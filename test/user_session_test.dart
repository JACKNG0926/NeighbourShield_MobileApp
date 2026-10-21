import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_shield_mobile/core/session/user_role.dart';
import 'package:neighbour_shield_mobile/features/auth/models/user_session.dart';

void main() {
  group('UserSession.fromBackend', () {
    test('keeps an opted-in resident pending until verified by Django', () {
      final user = UserSession.fromBackend({
        'username': 'resident1',
        'email': 'resident1@example.com',
        'role': 'resident',
        'is_volunteer_opted_in': true,
        'is_verified_volunteer': false,
      });

      expect(user.role, UserRole.resident);
      expect(user.isVolunteerOptedIn, isTrue);
      expect(user.isVerifiedVolunteer, isFalse);
      expect(
        user.volunteerApplicationStatus,
        VolunteerApplicationStatus.pending,
      );
    });

    test('recognizes volunteer only when backend marks account verified', () {
      final user = UserSession.fromBackend({
        'username': 'volunteer1',
        'role': 'volunteer',
        'is_volunteer_opted_in': true,
        'is_verified_volunteer': true,
      });

      expect(user.role, UserRole.volunteer);
      expect(
        user.volunteerApplicationStatus,
        VolunteerApplicationStatus.approved,
      );
    });

    test('does not grant volunteer UI for an unverified backend role', () {
      final user = UserSession.fromBackend({
        'username': 'unverified1',
        'role': 'volunteer',
        'is_volunteer_opted_in': true,
        'is_verified_volunteer': false,
      });

      expect(user.role, UserRole.resident);
      expect(
        user.volunteerApplicationStatus,
        VolunteerApplicationStatus.pending,
      );
    });

    test('parses full profile attributes including address and phone', () {
      final user = UserSession.fromBackend({
        'id': 42,
        'username': 'johndoe',
        'email': 'john@example.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'phone_number': '+60123456789',
        'unit_address': 'Block B-12-04',
        'role': 'resident',
        'is_volunteer_opted_in': false,
        'is_verified_volunteer': false,
      });

      expect(user.id, 42);
      expect(user.username, 'johndoe');
      expect(user.email, 'john@example.com');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.fullName, 'John Doe');
      expect(user.phoneNumber, '+60123456789');
      expect(user.unitAddress, 'Block B-12-04');
    });
  });
}
