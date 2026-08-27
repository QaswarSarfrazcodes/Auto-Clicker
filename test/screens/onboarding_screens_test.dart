import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_clicker/core/constants/app_strings.dart';
import 'package:auto_clicker/presentation/screens/onboarding/onboarding_automate_screen.dart';
import 'package:auto_clicker/presentation/screens/onboarding/onboarding_custom_scripts_screen.dart';
import 'package:auto_clicker/presentation/screens/onboarding/onboarding_no_root_required_screen.dart';

void main() {
  testWidgets('TC_OB_01: Onboarding screen 1 renders headline and controls', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingAutomateScreen(),
      ),
    );

    expect(find.text(AppStrings.onboardingAutomateHeadline), findsOneWidget);
    expect(find.text(AppStrings.next), findsOneWidget);
    expect(find.text(AppStrings.skip), findsOneWidget);
  });

  testWidgets('TC_OB_02: Onboarding screen 2 renders headline', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingNoRootRequiredScreen(),
      ),
    );

    expect(find.text(AppStrings.onboardingNoRootHeadline), findsOneWidget);
  });

  testWidgets('TC_OB_06 & TC_OB_07: Final onboarding screen renders Get Started button', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingCustomScriptsScreen(),
      ),
    );

    expect(find.text(AppStrings.onboardingCustomScriptsHeadline), findsOneWidget);
    expect(find.text(AppStrings.getStarted), findsOneWidget);
  });
}
