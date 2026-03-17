import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  Booking? _booking;
  bool _isLoading = true;
  bool _isActioning = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    final id = int.tryParse(widget.bookingId) ?? 0;
    final booking = await ref.read(bookingServiceProvider).getBooking(id);
    if (!mounted) return;
    setState(() {
      _booking = booking;
      _isLoading = false;
    });
  }

  bool get _isToday {
    if (_booking == null) return false;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _booking!.date == todayStr;
  }

  bool get _canCheckIn {
    final b = _booking;
    if (b == null) return false;
    return _isToday &&
        (b.status == 'confirmed' || b.status == 'pending') &&
        !b.hasCheckedIn;
  }

  bool get _canCheckOut {
    final b = _booking;
    if (b == null) return false;
    return b.hasCheckedIn && b.status != 'completed';
  }

  bool get _canCancel {
    final b = _booking;
    if (b == null) return false;
    return b.status == 'pending' || b.status == 'confirmed';
  }

  Future<void> _handleCheckIn() async {
    if (_booking == null) return;
    setState(() => _isActioning = true);
    try {
      await ref.read(bookingServiceProvider).checkIn(_booking!.id);
      await _loadBooking();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in failed')),
      );
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _handleCheckOut() async {
    if (_booking == null) return;
    setState(() => _isActioning = true);
    try {
      await ref.read(bookingServiceProvider).checkOut(_booking!.id);
      await _loadBooking();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out failed')),
      );
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _handleCancel() async {
    if (_booking == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CoreSyncColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cancel Booking',
          style: TextStyle(color: CoreSyncColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(color: CoreSyncColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActioning = true);
    try {
      await ref.read(apiClientProvider).patch(
        '/api/bookings/${_booking!.id}/',
        data: {'status': 'cancelled'},
      );
      await _loadBooking();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cancellation failed')),
      );
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '--:--';
    final parts = time.split(':');
    if (parts.length < 2) return time;
    return '${parts[0]}:${parts[1]}';
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      const weekdays = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ];
      return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return date;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return CoreSyncColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'BOOKING',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: CoreSyncColors.accent,
                strokeWidth: 1.5,
              ),
            )
          : _booking == null
              ? const Center(
                  child: Text(
                    'Booking not found',
                    style: TextStyle(color: CoreSyncColors.textSecondary),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final b = _booking!;
    final statusClr = _statusColor(b.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: statusClr.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusClr.withAlpha(80)),
              ),
              child: Text(
                b.status.isNotEmpty
                    ? '${b.status[0].toUpperCase()}${b.status.substring(1)}'
                    : '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusClr,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Date & Time card
          GlassPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: CoreSyncColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatDate(b.date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CoreSyncColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: CoreSyncColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_formatTime(b.timeStart)} – ${_formatTime(b.timeEnd)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CoreSyncColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (b.hasCheckedIn) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Checked in',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preferences
          if (b.preferences.isNotEmpty) ...[
            const Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: CoreSyncColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            GlassPanel(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: b.preferences.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatKey(e.key),
                          style: const TextStyle(
                            fontSize: 14,
                            color: CoreSyncColors.textSecondary,
                          ),
                        ),
                        Text(
                          e.value.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: CoreSyncColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (b.notes.isNotEmpty) ...[
            const Text(
              'NOTES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: CoreSyncColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            GlassPanel(
              padding: const EdgeInsets.all(20),
              child: Text(
                b.notes,
                style: const TextStyle(
                  fontSize: 14,
                  color: CoreSyncColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 8),

          // Action buttons
          if (_canCheckIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isActioning ? null : _handleCheckIn,
                child: _isActioning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: CoreSyncColors.bg,
                        ),
                      )
                    : const Text('Check In'),
              ),
            ),

          if (_canCheckOut) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isActioning ? null : _handleCheckOut,
                child: _isActioning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: CoreSyncColors.bg,
                        ),
                      )
                    : const Text('Check Out'),
              ),
            ),
          ],

          if (_canCancel) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isActioning ? null : _handleCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel Booking'),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }
}
