import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/home/shell_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
import '../screens/bookings/new_booking_screen.dart';
import '../screens/room/room_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/cart_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/wallet/top_up_screen.dart';
import '../screens/wallet/add_card_screen.dart';
import '../screens/wallet/transactions_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/concierge_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final location = state.matchedLocation;

      final isOnAuth = location == '/auth' || location.startsWith('/auth/');
      final isOnSplash = location == '/';

      if (!isAuth && !isOnAuth && !isOnSplash) return '/auth';
      if (isAuth && (isOnAuth || isOnSplash)) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (context, state) {
              final phone = state.extra as String? ?? '';
              return OtpScreen(phone: phone);
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'booking/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '0';
                      return BookingDetailScreen(bookingId: id);
                    },
                  ),
                  GoRoute(
                    path: 'new-booking',
                    builder: (context, state) => const NewBookingScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/room',
                builder: (context, state) => const RoomScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'cart',
                    builder: (context, state) => const CartScreen(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const OrderHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
                routes: [
                  GoRoute(
                    path: 'top-up',
                    builder: (context, state) => const TopUpScreen(),
                  ),
                  GoRoute(
                    path: 'add-card',
                    builder: (context, state) => const AddCardScreen(),
                  ),
                  GoRoute(
                    path: 'transactions',
                    builder: (context, state) => const TransactionsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'concierge',
                    builder: (context, state) => const ConciergeScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
