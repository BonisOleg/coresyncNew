import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class NewBookingScreen extends ConsumerStatefulWidget {
  const NewBookingScreen({super.key});

  @override
  ConsumerState<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends ConsumerState<NewBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  List<BookingSlot> _slots = [];
  BookingSlot? _selectedSlot;
  final _notesController = TextEditingController();
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _dateString(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });
    final slots = await ref
        .read(bookingServiceProvider)
        .getSlots(date: _dateString(_selectedDate));
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _isLoadingSlots = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: CoreSyncColors.accent,
              onPrimary: CoreSyncColors.bg,
              surface: CoreSyncColors.surface,
              onSurface: CoreSyncColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: CoreSyncColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadSlots();
    }
  }

  Future<void> _handleBook() async {
    if (_selectedSlot == null) return;

    setState(() => _isBooking = true);
    try {
      await ref.read(bookingServiceProvider).createBooking({
        'slot_id': _selectedSlot!.id,
        'date': _dateString(_selectedDate),
        'notes': _notesController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created successfully')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create booking')),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '--:--';
    final parts = time.split(':');
    if (parts.length < 2) return time;
    return '${parts[0]}:${parts[1]}';
  }

  String _formatDateDisplay(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
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
          'NEW BOOKING',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date selector
                  const Text(
                    'SELECT DATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: GlassPanel(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 22,
                            color: CoreSyncColors.accent,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _formatDateDisplay(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: CoreSyncColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: CoreSyncColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Time slots
                  const Text(
                    'AVAILABLE SLOTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingSlots)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CoreSyncColors.accent,
                          strokeWidth: 1.5,
                        ),
                      ),
                    )
                  else if (_slots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_busy_outlined,
                              size: 40,
                              color: CoreSyncColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No available slots for this date',
                              style: TextStyle(
                                fontSize: 14,
                                color: CoreSyncColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _slots.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final slot = _slots[index];
                        final isSelected =
                            _selectedSlot?.id == slot.id;
                        return _SlotCard(
                          slot: slot,
                          isSelected: isSelected,
                          formatTime: _formatTime,
                          onTap: slot.isAvailable
                              ? () => setState(
                                    () => _selectedSlot = slot,
                                  )
                              : null,
                        );
                      },
                    ),

                  const SizedBox(height: 28),

                  // Notes
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
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Any special requests or preferences...',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Book button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(
              color: CoreSyncColors.surface,
              border: Border(
                top: BorderSide(color: CoreSyncColors.glassBorder),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _selectedSlot != null && !_isBooking
                        ? _handleBook
                        : null,
                child: _isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: CoreSyncColors.bg,
                        ),
                      )
                    : const Text('Book Session'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final BookingSlot slot;
  final bool isSelected;
  final String Function(String) formatTime;
  final VoidCallback? onTap;

  const _SlotCard({
    required this.slot,
    required this.isSelected,
    required this.formatTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = slot.isAvailable;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? CoreSyncColors.accent.withAlpha(12)
              : CoreSyncColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? CoreSyncColors.accent
                : CoreSyncColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 20,
              color: available
                  ? CoreSyncColors.accent
                  : CoreSyncColors.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatTime(slot.timeStart)} – ${formatTime(slot.timeEnd)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: available
                          ? CoreSyncColors.textPrimary
                          : CoreSyncColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    available
                        ? '${slot.remainingCapacity} spots remaining'
                        : 'Fully booked',
                    style: TextStyle(
                      fontSize: 12,
                      color: available
                          ? CoreSyncColors.textSecondary
                          : CoreSyncColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 22,
                color: CoreSyncColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
