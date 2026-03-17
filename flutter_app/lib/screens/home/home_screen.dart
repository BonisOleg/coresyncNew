import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/timer_display.dart';
import '../../widgets/booking_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Booking> _bookings = [];
  Booking? _activeBooking;
  Map<String, dynamic>? _sessionData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final bookingService = ref.read(bookingServiceProvider);

    final results = await Future.wait([
      bookingService.getBookings(),
      bookingService.getActiveBooking(),
      bookingService.getSessionTimer(),
    ]);

    if (!mounted) return;
    setState(() {
      _bookings = results[0] as List<Booking>;
      _activeBooking = results[1] as Booking?;
      _sessionData = results[2] as Map<String, dynamic>?;
      _isLoading = false;
    });
  }

  Booking? get _upcomingBooking {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final upcoming = _bookings.where((b) {
      final isFuture = b.date.compareTo(todayStr) >= 0;
      final isActionable =
          b.status == 'confirmed' || b.status == 'pending';
      return isFuture && isActionable;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  bool get _canCheckIn {
    final booking = _upcomingBooking;
    if (booking == null) return false;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return booking.date == todayStr &&
        (booking.status == 'confirmed' || booking.status == 'pending') &&
        !booking.hasCheckedIn;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final guest = authState.guest;
    final firstName = guest?.firstName ?? '';

    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      body: RefreshIndicator(
        color: CoreSyncColors.accent,
        backgroundColor: CoreSyncColors.surface,
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(firstName),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: CoreSyncColors.accent,
                    strokeWidth: 1.5,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_activeBooking != null) ...[
                      _buildActiveSessionCard(),
                      const SizedBox(height: 20),
                    ],
                    if (_upcomingBooking != null &&
                        _activeBooking == null) ...[
                      _buildUpcomingBookingSection(),
                      const SizedBox(height: 20),
                    ],
                    if (_bookings.isEmpty && _activeBooking == null)
                      _buildEmptyState(),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 32),
                    if (_bookings.isNotEmpty) ...[
                      _buildRecentBookings(),
                      const SizedBox(height: 32),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String firstName) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CORESYNC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: CoreSyncColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                firstName.isNotEmpty
                    ? 'Welcome back, $firstName'
                    : 'Welcome back',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: CoreSyncColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard() {
    final totalSeconds =
        (_sessionData?['total_seconds'] as int?) ?? 3600;
    final remainingSeconds =
        (_sessionData?['remaining_seconds'] as int?) ?? totalSeconds;
    final sceneName =
        (_sessionData?['scene_name'] as String?) ?? '';
    final scentName =
        (_sessionData?['scent_name'] as String?) ?? '';

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ACTIVE SESSION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TimerDisplay(
            totalSeconds: totalSeconds,
            remainingSeconds: remainingSeconds,
          ),
          if (sceneName.isNotEmpty || scentName.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: CoreSyncColors.glassBorder),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (sceneName.isNotEmpty)
                  _SessionInfoChip(
                    icon: Icons.landscape_outlined,
                    label: sceneName,
                  ),
                if (scentName.isNotEmpty)
                  _SessionInfoChip(
                    icon: Icons.air_outlined,
                    label: scentName,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GlassButton(
                  icon: Icons.tune_outlined,
                  label: 'Controls',
                  onTap: () => context.go('/room'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassButton(
                  icon: Icons.room_service_outlined,
                  label: 'Order',
                  onTap: () => context.go('/orders'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookingSection() {
    final booking = _upcomingBooking!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UPCOMING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: CoreSyncColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        BookingCard(booking: booking),
        if (_canCheckIn) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleCheckIn(booking.id),
              child: const Text('Check In'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleCheckIn(int bookingId) async {
    final bookingService = ref.read(bookingServiceProvider);
    try {
      await bookingService.checkIn(bookingId);
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in failed. Please try again.')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Icon(
              Icons.spa_outlined,
              size: 48,
              color: CoreSyncColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No upcoming sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: CoreSyncColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book your first spa session and experience\npersonalised wellness.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CoreSyncColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home/new-booking'),
              child: const Text('Book a Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      _QuickActionData(
        icon: Icons.calendar_month_outlined,
        label: 'Book\nSession',
        route: '/home/new-booking',
      ),
      _QuickActionData(
        icon: Icons.tune_outlined,
        label: 'Room\nControls',
        route: '/room',
      ),
      _QuickActionData(
        icon: Icons.room_service_outlined,
        label: 'Order\nAdd-ons',
        route: '/orders',
      ),
      _QuickActionData(
        icon: Icons.auto_awesome_outlined,
        label: 'AI\nConcierge',
        route: '/profile/concierge',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: CoreSyncColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: actions
              .map((a) => _QuickActionCard(data: a))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRecentBookings() {
    final recent = _bookings.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT BOOKINGS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: CoreSyncColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...recent.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BookingCard(booking: b),
            )),
      ],
    );
  }
}

// ── Private helper widgets ──────────────────────────────────────────────────

class _SessionInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SessionInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: CoreSyncColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: CoreSyncColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: CoreSyncColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CoreSyncColors.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: CoreSyncColors.accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CoreSyncColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final String route;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(data.route),
        child: Container(
          decoration: BoxDecoration(
            color: CoreSyncColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CoreSyncColors.glassBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                data.icon,
                size: 24,
                color: CoreSyncColors.accent,
              ),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CoreSyncColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
