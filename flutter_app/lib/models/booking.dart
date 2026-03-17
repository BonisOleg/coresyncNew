class Booking {
  final int id;
  final int guestId;
  final String date;
  final String timeStart;
  final String timeEnd;
  final String status;
  final Map<String, dynamic> preferences;
  final String source;
  final String notes;
  final bool hasCheckedIn;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.guestId,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.status,
    required this.preferences,
    required this.source,
    required this.notes,
    required this.hasCheckedIn,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      guestId: json['guest_id'] as int? ?? json['guest'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      timeStart: json['time_start'] as String? ?? '',
      timeEnd: json['time_end'] as String? ?? '',
      status: json['status'] as String? ?? '',
      preferences:
          (json['preferences'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      source: json['source'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      hasCheckedIn: json['has_checked_in'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'date': date,
      'time_start': timeStart,
      'time_end': timeEnd,
      'status': status,
      'preferences': preferences,
      'source': source,
      'notes': notes,
      'has_checked_in': hasCheckedIn,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BookingSlot {
  final int id;
  final String date;
  final String timeStart;
  final String timeEnd;
  final bool isAvailable;
  final int maxCapacity;
  final int remainingCapacity;

  const BookingSlot({
    required this.id,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.isAvailable,
    required this.maxCapacity,
    required this.remainingCapacity,
  });

  factory BookingSlot.fromJson(Map<String, dynamic> json) {
    return BookingSlot(
      id: json['id'] as int,
      date: json['date'] as String? ?? '',
      timeStart: json['time_start'] as String? ?? '',
      timeEnd: json['time_end'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? false,
      maxCapacity: json['max_capacity'] as int? ?? 0,
      remainingCapacity: json['remaining_capacity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time_start': timeStart,
      'time_end': timeEnd,
      'is_available': isAvailable,
      'max_capacity': maxCapacity,
      'remaining_capacity': remainingCapacity,
    };
  }
}
