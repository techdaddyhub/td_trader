// TD TRADER - Main Application Entry Point
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/providers/app_state_providers.dart';
import 'features/dashboard/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadSavedBaseUrl();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => RiskProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
      ],
      child: const TDTraderApp(),
    ),
  );
}

class TDTraderApp extends StatelessWidget {
  const TDTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Clamp text scaler to keep layout crisp, clean, and proportional on all displays
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.10,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}

