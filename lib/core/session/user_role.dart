enum UserRole { resident, volunteer, security, townshipAdmin }

enum VolunteerApplicationStatus { notApplied, pending, approved, rejected }

extension UserRoleDisplay on UserRole {
  String get label => switch (this) {
    UserRole.resident => 'Resident',
    UserRole.volunteer => 'Volunteer',
    UserRole.security => 'Security',
    UserRole.townshipAdmin => 'Township Admin',
  };
}
