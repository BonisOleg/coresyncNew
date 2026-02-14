/// Guest profile model matching the Django Guest model.
class Guest {
  final String id;
  final String phone;
  final String email;
  final String firstName;
  final String lastName;
  final bool isRegistered;
  final Map<String, dynamic> preferences;

  Guest({
    required this.id,
    required this.phone,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.isRegistered = false,
    this.preferences = const {},
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      isRegistered: json['is_registered'] ?? false,
      preferences: json['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'preferences': preferences,
    };
  }
}
