import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auto_clicker/core/constants/app_strings.dart';
import 'package:auto_clicker/presentation/screens/dashboard/dashboard_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TC_DASH_01 & TC_DASH_02: Dashboard renders title and action cards', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.appTitle), findsWidgets);
    expect(find.text(AppStrings.newScript), findsOneWidget);
    expect(find.text(AppStrings.savedScript), findsOneWidget);
    expect(find.text(AppStrings.importScript), findsOneWidget);
    expect(find.text(AppStrings.exportScript), findsOneWidget);
  });
}
