import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/routing/app_route_names.dart';
import 'core/routing/app_router.dart';
import 'core/util/logger.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Warm up SharedPreferences in parallel (native read completed before first render)
    unawaited(SharedPreferences.getInstance());

    // §6.2 Cap image cache ceiling to 50MB to prevent memory bloat
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

    // §9.2 Global error handlers as last resort
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      logDebug('FlutterError: ${details.exception}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      logDebug('PlatformDispatcher Error: $error');
      return true; // handled — don't crash release build
    };

    runApp(const AutoClickerApp());
  }, (error, stack) {
    logDebug('Uncaught Zoned Error: $error');
  });
}


class AutoClickerApp extends StatelessWidget {
  const AutoClickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Clicker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.surfaceWhite,
        fontFamily: 'Roboto', // swap for the confirmed brand font later
      ),
      initialRoute: AppRouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
