import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import 'guests_list.dart';
import 'bookings_management.dart';

/// Admin dashboard with key stats.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(ApiConfig.adminDashboardUrl);
      if (response.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(response.body);
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
        title: const Text('ADMIN'),
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
              onRefresh: _fetchStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_stats != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Guests',
                            '${_stats!['total_guests'] ?? 0}',
                            Icons.people_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'Today',
                            '${_stats!['bookings_today'] ?? 0}',
                            Icons.calendar_today,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Pending',
                            '${_stats!['bookings_pending'] ?? 0}',
                            Icons.schedule,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'Calls',
                            '${_stats!['calls_today'] ?? 0}',
                            Icons.phone,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  _navButton(
                    context,
                    'Manage Guests',
                    Icons.people_outline,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GuestsListScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _navButton(
                    context,
                    'Manage Bookings',
                    Icons.calendar_today_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingsManagementScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: CoreSyncTheme.textMuted, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CoreSyncTheme.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: CoreSyncTheme.textSecondary),
        title: Text(label),
        trailing: const Icon(
          Icons.chevron_right,
          color: CoreSyncTheme.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}
