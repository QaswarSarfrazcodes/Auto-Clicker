import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auto_clicker/core/constants/app_strings.dart';
import 'package:auto_clicker/presentation/screens/running/running_screen.dart';
import 'package:auto_clicker/presentation/screens/saved_scripts/saved_scripts_screen.dart';
import 'package:auto_clicker/presentation/screens/settings/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TC_RUN_01 & TC_RUN_02: Running screen renders header, status, and control actions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: RunningScreen(),
      ),
    );

    expect(find.text(AppStrings.runningStatus), findsWidgets);
    expect(find.text(AppStrings.pauseButton), findsOneWidget);

    await tester.tap(find.text(AppStrings.stopButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('TC_SS_01 & TC_SS_02: Saved Scripts screen renders filter tabs and title', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: SavedScriptsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.savedScriptsTitle), findsOneWidget);
    expect(find.text(AppStrings.filterAll), findsOneWidget);
    expect(find.text(AppStrings.filterClick), findsOneWidget);
    expect(find.text(AppStrings.filterSwipe), findsOneWidget);
  });

  testWidgets('TC_SET_01 & TC_SET_03: Settings screen renders general and automation sections', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.settingsTitle), findsOneWidget);
    expect(find.text(AppStrings.generalSectionTitle), findsOneWidget);
    expect(find.text(AppStrings.automationSectionTitle), findsOneWidget);
  });
}
