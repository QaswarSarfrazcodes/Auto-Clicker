import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_clicker/core/constants/app_strings.dart';
import 'package:auto_clicker/presentation/screens/permission/accessibility_permission_screen.dart';
import 'package:auto_clicker/presentation/screens/permission/overlay_permission_screen.dart';

void main() {
  testWidgets('TC_PERM_01 & TC_PERM_04: Accessibility screen renders headline and action buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AccessibilityPermissionScreen(),
      ),
    );

    expect(find.text(AppStrings.accessibilityHeadline), findsOneWidget);
    expect(find.text(AppStrings.enable), findsOneWidget);
    expect(find.text(AppStrings.howItWorks), findsOneWidget);
  });

  testWidgets('TC_PERM_05: Overlay permission screen renders grant button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OverlayPermissionScreen(),
      ),
    );

    expect(find.text(AppStrings.overlayHeadline), findsOneWidget);
    expect(find.text(AppStrings.grantPermission), findsOneWidget);
  });
}
