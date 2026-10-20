import '../../../core/session/user_role.dart';

class UserSession {
  const UserSession({
    required this.username,
    this.email,
    this.role = UserRole.resident,
    this.volunteerApplicationStatus = VolunteerApplicationStatus.notApplied,
    this.isVolunteerOptedIn = false,
    this.isVerifiedVolunteer = false,
  });

  final String username;
  final String? email;
  final UserRole role;
  final VolunteerApplicationStatus volunteerApplicationStatus;
  final bool isVolunteerOptedIn;
  final bool isVerifiedVolunteer;

  /// Creates the local session from a profile returned by Django.
  /// A Volunteer UI is shown only when Django returns the volunteer role
  /// AND marks the account as verified.
  factory UserSession.fromBackend(Map<String, dynamic> json) {
    final backendRole = (json['role'] as String? ?? 'resident').toLowerCase();
    final isOptedIn = json['is_volunteer_opted_in'] == true;
    final isVerified = json['is_verified_volunteer'] == true;

    final UserRole role;
    if (backendRole == 'volunteer') {
      // Fail closed if backend data is inconsistent: never display the
      // Volunteer Dashboard unless the account is also verified.
      role = isVerified && isOptedIn ? UserRole.volunteer : UserRole.resident;
    } else {
      role = switch (backendRole) {
        'security' => UserRole.security,
        'admin' => UserRole.townshipAdmin,
        _ => UserRole.resident,
      };
    }

    final VolunteerApplicationStatus applicationStatus;
    if (role == UserRole.volunteer && isVerified && isOptedIn) {
      applicationStatus = VolunteerApplicationStatus.approved;
    } else if (isOptedIn) {
      applicationStatus = VolunteerApplicationStatus.pending;
    } else {
      applicationStatus = VolunteerApplicationStatus.notApplied;
    }

    return UserSession(
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      role: role,
      volunteerApplicationStatus: applicationStatus,
      isVolunteerOptedIn: isOptedIn,
      isVerifiedVolunteer: isVerified,
    );
  }

  UserSession copyWith({
    String? username,
    String? email,
    UserRole? role,
    VolunteerApplicationStatus? volunteerApplicationStatus,
    bool? isVolunteerOptedIn,
    bool? isVerifiedVolunteer,
  }) {
    return UserSession(
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      volunteerApplicationStatus:
          volunteerApplicationStatus ?? this.volunteerApplicationStatus,
      isVolunteerOptedIn: isVolunteerOptedIn ?? this.isVolunteerOptedIn,
      isVerifiedVolunteer: isVerifiedVolunteer ?? this.isVerifiedVolunteer,
    );
  }
}
