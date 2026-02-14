import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/guest.dart';
import '../../services/api_service.dart';

/// Admin: list all guests.
class GuestsListScreen extends StatefulWidget {
  const GuestsListScreen({super.key});

  @override
  State<GuestsListScreen> createState() => _GuestsListScreenState();
}

class _GuestsListScreenState extends State<GuestsListScreen> {
  final ApiService _api = ApiService();
  List<Guest> _guests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGuests();
  }

  Future<void> _fetchGuests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(ApiConfig.adminGuestsUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        setState(() {
          _guests = (results as List).map((g) => Guest.fromJson(g)).toList();
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
        title: const Text('GUESTS'),
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
              onRefresh: _fetchGuests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _guests.length,
                itemBuilder: (context, index) {
                  final guest = _guests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: CoreSyncTheme.surfaceColor,
                        child: Text(
                          guest.fullName.isNotEmpty
                              ? guest.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: CoreSyncTheme.textPrimary),
                        ),
                      ),
                      title: Text(guest.fullName.isNotEmpty ? guest.fullName : guest.phone),
                      subtitle: Text(
                        guest.email.isNotEmpty ? guest.email : guest.phone,
                        style: const TextStyle(color: CoreSyncTheme.textMuted),
                      ),
                      trailing: guest.isRegistered
                          ? const Icon(Icons.verified, size: 16, color: CoreSyncTheme.textSecondary)
                          : null,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
