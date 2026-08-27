import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_clicker/core/constants/app_strings.dart';
import 'package:auto_clicker/presentation/screens/create_script/create_script_screen.dart';

void main() {
  testWidgets('TC_CS_01 & TC_CS_03: Create Script screen renders form fields and segmented controls', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: CreateScriptScreen(),
      ),
    );

    expect(find.text(AppStrings.createScript), findsOneWidget);
    expect(find.text(AppStrings.scriptName), findsOneWidget);
    expect(find.text(AppStrings.actionType), findsOneWidget);
    expect(find.text(AppStrings.saveScript), findsOneWidget);
  });
}
