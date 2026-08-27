import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_clicker/core/constants/app_strings.dart';
import 'package:auto_clicker/presentation/screens/splash/splash_screen.dart';

void main() {
  testWidgets('TC_SPL_01 & TC_SPL_05: Splash screen renders branding elements', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Verify app wordmark components and tagline
    expect(find.text(AppStrings.splashWordmarkRegular), findsOneWidget);
    expect(find.text(AppStrings.splashWordmarkBold), findsOneWidget);
    expect(find.text(AppStrings.splashTagline), findsOneWidget);

    // Drain pending splash timer
    await tester.pump(const Duration(seconds: 3));
  });
}
