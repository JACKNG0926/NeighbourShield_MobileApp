import '../../../core/session/user_role.dart';

class UserSession {
  const UserSession({
    this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.unitAddress,
    this.role = UserRole.resident,
    this.volunteerApplicationStatus = VolunteerApplicationStatus.notApplied,
    this.isVolunteerOptedIn = false,
    this.isVerifiedVolunteer = false,
  });

  
  final int? id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? unitAddress;
  final UserRole role;
  final VolunteerApplicationStatus volunteerApplicationStatus;
  final bool isVolunteerOptedIn;
  final bool isVerifiedVolunteer;

  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    final combined = '$first $last'.trim();
    return combined.isNotEmpty ? combined : username;
  }

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
      id: json['id'] as int?,
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      unitAddress: json['unit_address'] as String?,
      role: role,
      volunteerApplicationStatus: applicationStatus,
      isVolunteerOptedIn: isOptedIn,
      isVerifiedVolunteer: isVerified,
    );
  }

  UserSession copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? unitAddress,
    UserRole? role,
    VolunteerApplicationStatus? volunteerApplicationStatus,
    bool? isVolunteerOptedIn,
    bool? isVerifiedVolunteer,
  }) {
    return UserSession(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      unitAddress: unitAddress ?? this.unitAddress,
      role: role ?? this.role,
      volunteerApplicationStatus:
          volunteerApplicationStatus ?? this.volunteerApplicationStatus,
      isVolunteerOptedIn: isVolunteerOptedIn ?? this.isVolunteerOptedIn,
      isVerifiedVolunteer: isVerifiedVolunteer ?? this.isVerifiedVolunteer,
    );
  }
}
