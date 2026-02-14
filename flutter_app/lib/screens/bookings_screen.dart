import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

/// View and manage bookings.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final ApiService _api = ApiService();
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(ApiConfig.bookingsUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        setState(() {
          _bookings = (results as List).map((b) => Booking.fromJson(b)).toList();
        });
      }
    } catch (_) {
      // Fetch failed
    }
    setState(() => _isLoading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green.withAlpha(180);
      case 'pending':
        return Colors.amber.withAlpha(180);
      case 'cancelled':
        return Colors.red.withAlpha(180);
      case 'completed':
        return CoreSyncTheme.textMuted;
      default:
        return CoreSyncTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BOOKINGS'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CoreSyncTheme.textMuted,
                strokeWidth: 2,
              ),
            )
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: CoreSyncTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookings yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Talk to the concierge to book an evening',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: CoreSyncTheme.textMuted,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    booking.date,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(booking.status).withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      booking.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 1,
                                        color: _statusColor(booking.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${booking.timeStart} — ${booking.timeEnd}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: CoreSyncTheme.textSecondary,
                                    ),
                              ),
                              if (booking.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  booking.notes,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: CoreSyncTheme.textMuted,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
