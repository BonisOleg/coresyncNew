import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/concierge_service.dart';
import 'services/spa_control_service.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CoreSyncApp());
}

/// Root application widget for CoreSync Private.
class CoreSyncApp extends StatelessWidget {
  const CoreSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ConciergeService()),
        ChangeNotifierProvider(create: (_) => SpaControlService()),
      ],
      child: MaterialApp(
        title: 'CoreSync Private',
        debugShowCheckedModeBanner: false,
        theme: CoreSyncTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
