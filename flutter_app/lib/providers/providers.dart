import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guest.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/scene_service.dart';
import '../services/scent_service.dart';
import '../services/order_service.dart';
import '../services/wallet_service.dart';
import '../services/concierge_service.dart';
import '../services/spa_control_service.dart';

// ── Service Providers ─────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiClientProvider)),
);

final bookingServiceProvider = Provider<BookingService>(
  (ref) => BookingService(ref.watch(apiClientProvider)),
);

final sceneServiceProvider = Provider<SceneService>(
  (ref) => SceneService(ref.watch(apiClientProvider)),
);

final scentServiceProvider = Provider<ScentService>(
  (ref) => ScentService(ref.watch(apiClientProvider)),
);

final orderServiceProvider = Provider<OrderService>(
  (ref) => OrderService(ref.watch(apiClientProvider)),
);

final walletServiceProvider = Provider<WalletService>(
  (ref) => WalletService(ref.watch(apiClientProvider)),
);

final conciergeServiceProvider = Provider<ConciergeService>(
  (ref) => ConciergeService(ref.watch(apiClientProvider)),
);

final spaControlServiceProvider = Provider<SpaControlService>(
  (ref) => SpaControlService(ref.watch(apiClientProvider)),
);

// ── Auth State ────────────────────────────────────────────────────────────

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final Guest? guest;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.guest,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Guest? guest,
    String? error,
    bool clearGuest = false,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      guest: clearGuest ? null : (guest ?? this.guest),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final AuthService _authService;

  AuthStateNotifier(this._apiClient, this._authService)
      : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loggedIn = await _apiClient.isLoggedIn();
      if (loggedIn) {
        await loadProfile();
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> login(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.login(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _authService.verifyOtp(phone, otp);
      if (data != null) {
        state = state.copyWith(isAuthenticated: true);
        await loadProfile();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Verification failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadProfile() async {
    try {
      final guest = await _authService.getProfile();
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        guest: guest,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.deleteAccount();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authService = ref.watch(authServiceProvider);
  return AuthStateNotifier(apiClient, authService);
});
