/// Booking model matching the Django Booking model.
class Booking {
  final String id;
  final String date;
  final String timeStart;
  final String timeEnd;
  final String status;
  final Map<String, dynamic> preferences;
  final String notes;
  final String createdAt;

  Booking({
    required this.id,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    this.status = 'pending',
    this.preferences = const {},
    this.notes = '',
    this.createdAt = '',
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      timeStart: json['time_start'] ?? '',
      timeEnd: json['time_end'] ?? '',
      status: json['status'] ?? 'pending',
      preferences: json['preferences'] ?? {},
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
