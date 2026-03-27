import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'config/router.dart';
import 'config/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const stripeKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  assert(
    stripeKey.isNotEmpty || kDebugMode,
    'STRIPE_PUBLISHABLE_KEY must be set via --dart-define for release builds',
  );

  if (stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
  }
  Stripe.merchantIdentifier = 'merchant.com.coresync.app';

  runApp(const ProviderScope(child: CoreSyncApp()));
}

class CoreSyncApp extends ConsumerWidget {
  const CoreSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CoreSync',
      debugShowCheckedModeBanner: false,
      theme: CoreSyncTheme.dark,
      routerConfig: router,
    );
  }
}
