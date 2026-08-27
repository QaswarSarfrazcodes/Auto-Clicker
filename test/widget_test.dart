import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auto_clicker/core/constants/app_strings.dart';
import 'package:auto_clicker/presentation/widgets/common/error_state_widget.dart';
import 'package:auto_clicker/presentation/widgets/dashboard/app_drawer.dart';
import 'package:auto_clicker/presentation/widgets/dashboard/import_validation_dialog.dart';
import 'package:auto_clicker/presentation/widgets/forms/swipe_preview_canvas.dart';
import 'package:auto_clicker/presentation/widgets/settings/hotkey_capture_dialog.dart';
import 'package:auto_clicker/presentation/widgets/settings/language_picker_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Widget Tests — UI Components (§19)', () {
    testWidgets('SwipePreviewCanvas renders start/end coordinates and duration label',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipePreviewCanvas(
              startX: 120,
              startY: 240,
              endX: 480,
              endY: 720,
              durationMs: 450,
            ),
          ),
        ),
      );

      expect(find.byType(SwipePreviewCanvas), findsOneWidget);
      expect(find.text('450ms'), findsOneWidget);
    });

    testWidgets('ErrorStateWidget renders message and triggers onRetry callback',
        (tester) async {
      bool retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Failed to load scripts',
              onRetry: () => retryClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to load scripts'), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);

      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();

      expect(retryClicked, isTrue);
    });

    testWidgets('ImportValidationDialog lists all errors accurately',
        (tester) async {
      final errors = [
        'name: missing or empty',
        'intervalValue: must be integer >= 10',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportValidationDialog(errors: errors),
          ),
        ),
      );

      expect(find.text(AppStrings.importFailed), findsOneWidget);
      expect(find.text('name: missing or empty'), findsOneWidget);
      expect(find.text('intervalValue: must be integer >= 10'), findsOneWidget);
    });

    testWidgets('LanguagePickerDialog renders English and Urdu options',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguagePickerDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appLanguage), findsOneWidget);
      expect(find.text(AppStrings.languageEnglish), findsOneWidget);
      expect(find.text(AppStrings.languageUrdu), findsOneWidget);
    });

    testWidgets('HotkeyCaptureDialog renders and shows instructions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HotkeyCaptureDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.globalHotkeysDialog), findsOneWidget);
      expect(find.text(AppStrings.pressAnyKey), findsOneWidget);
    });

    testWidgets('AppDrawer renders app title and navigation entries',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(),
            body: Text('Home'),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appTitle), findsOneWidget);
      expect(find.text(AppStrings.createScript), findsOneWidget);
      expect(find.text(AppStrings.savedScriptsTitle), findsOneWidget);
      expect(find.text(AppStrings.settingsTitle), findsOneWidget);
      expect(find.text(AppStrings.rateApp), findsOneWidget);
      expect(find.text(AppStrings.contactSupport), findsOneWidget);
    });
  });
}
