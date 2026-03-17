class Guest {
  final int id;
  final String phone;
  final String email;
  final String firstName;
  final String lastName;
  final bool isRegistered;
  final Map<String, dynamic> preferences;

  const Guest({
    required this.id,
    required this.phone,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isRegistered,
    required this.preferences,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] as int,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      isRegistered: json['is_registered'] as bool? ?? false,
      preferences:
          (json['preferences'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_registered': isRegistered,
      'preferences': preferences,
    };
  }
}
