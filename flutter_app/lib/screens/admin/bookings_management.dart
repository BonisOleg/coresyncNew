import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

/// Admin: manage all bookings.
class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(ApiConfig.adminBookingsUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(results);
        });
      }
    } catch (_) {
      // Fetch failed
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALL BOOKINGS'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CoreSyncTheme.textMuted,
                strokeWidth: 2,
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final b = _bookings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        '${b['guest_name'] ?? 'Guest'} — ${b['date'] ?? ''}',
                      ),
                      subtitle: Text(
                        '${b['time_start'] ?? ''} — ${b['time_end'] ?? ''} | ${b['status'] ?? ''}',
                        style: const TextStyle(color: CoreSyncTheme.textMuted),
                      ),
                      trailing: Text(
                        (b['source'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: CoreSyncTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
