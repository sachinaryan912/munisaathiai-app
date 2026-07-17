/// Mirrors the backend `User` entity's JSON shape (`entity/User.java`).
/// Unknown/extra keys (Jackson's `UserDetails`-derived `username`,
/// `authorities`, etc.) are ignored on parse.
class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? schoolName;
  final String? className;
  final String? section;
  final String? designation;
  final bool emailVerified;
  final bool enabled;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.schoolName,
    this.className,
    this.section,
    this.designation,
    required this.emailVerified,
    required this.enabled,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      schoolName: json['schoolName'] as String?,
      className: json['className'] as String?,
      section: json['section'] as String?,
      designation: json['designation'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'schoolName': schoolName,
        'className': className,
        'section': section,
        'designation': designation,
        'emailVerified': emailVerified,
        'enabled': enabled,
      };

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? schoolName,
    String? className,
    String? section,
    String? designation,
    bool? emailVerified,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
      section: section ?? this.section,
      designation: designation ?? this.designation,
      emailVerified: emailVerified ?? this.emailVerified,
      enabled: enabled,
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

/// `POST /api/auth/login` / `/register` response — an [AppUser] plus a JWT
/// and a `message`.
class AuthSession {
  final String token;
  final AppUser user;
  final String message;

  AuthSession({required this.token, required this.user, required this.message});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? '',
      user: AppUser.fromJson(json),
      message: json['message'] as String? ?? '',
    );
  }
}
