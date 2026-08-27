import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auto_clicker/data/datasources/script_local_datasource.dart';

import 'package:auto_clicker/core/error/failure.dart';
import 'package:auto_clicker/core/util/logger.dart';
import 'package:auto_clicker/data/datasources/native_automation_channel.dart';
import 'package:auto_clicker/data/datasources/preferences_local_datasource.dart';
import 'package:auto_clicker/domain/entities/script_entity.dart';
import 'package:auto_clicker/domain/usecases/execute_script_usecase.dart';
import 'package:auto_clicker/domain/usecases/import_export_script_usecase.dart';
import 'package:auto_clicker/domain/usecases/script_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScriptValidator & Domain Models', () {
    final validator = ScriptValidator();

    test('validates valid ScriptData successfully', () {
      const validScript = ScriptData(
        id: 'script_1',
        name: 'Auto Like',
        clickPoints: [
          ClickPointData(x: 100, y: 200, delayMs: 500),
          ClickPointData(x: 150, y: 250, delayMs: 1000),
        ],
      );

      final result = validator.validate(validScript);
      expect(result.isSuccess, isTrue);
    });

    test('rejects script with empty name', () {
      const invalidScript = ScriptData(
        id: 'script_2',
        name: '   ',
        clickPoints: [],
      );

      final result = validator.validate(invalidScript);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('cannot be empty'));
    });

    test('rejects script with negative delay', () {
      const invalidScript = ScriptData(
        id: 'script_3',
        name: 'Invalid Delay',
        clickPoints: [ClickPointData(x: 50, y: 50, delayMs: -10)],
      );

      final result = validator.validate(invalidScript);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Delay out of bounds'));
    });

    test('rejects incomplete click and swipe entities', () {
      final missingClickPoint = ScriptEntity(
        id: 'missing_click',
        name: 'Missing Click',
        actionType: 'click',
      );
      final missingSwipe = ScriptEntity(
        id: 'missing_swipe',
        name: 'Missing Swipe',
        actionType: 'swipe',
      );

      expect(
        ScriptValidator.validateEntity(
          missingClickPoint,
        ).failureOrNull?.message,
        contains('click point'),
      );
      expect(
        ScriptValidator.validateEntity(missingSwipe).failureOrNull?.message,
        contains('swipe'),
      );
    });

    test('ScriptEntity JSON serialization & decoding roundtrip', () {
      final script = ScriptEntity(
        id: 'test_123',
        name: 'Gaming Tap Script',
        actionType: 'click',
        intervalValue: 250,
        intervalUnit: 'ms',
        repeatType: 'custom',
        repeatCount: 50,
        randomDelayEnabled: true,
        randomDelayMin: 1,
        randomDelayMax: 3,
        clickPoints: const [
          ClickPointEntity(id: 'p1', x: 120.5, y: 340.0, delayMs: 100),
          ClickPointEntity(id: 'p2', x: 220.0, y: 440.5, delayMs: 200),
        ],
        swipeConfig: const SwipeConfigEntity(
          startX: 100,
          startY: 200,
          endX: 300,
          endY: 400,
          durationMs: 500,
          delayMs: 50,
          loopSequence: true,
        ),
      );

      final jsonString = script.encodeJson();
      final decoded = ScriptEntity.decodeJson(jsonString);

      expect(decoded.id, equals('test_123'));
      expect(decoded.name, equals('Gaming Tap Script'));
      expect(decoded.actionType, equals('click'));
      expect(decoded.intervalValue, equals(250));
      expect(decoded.intervalUnit, equals('ms'));
      expect(decoded.repeatType, equals('custom'));
      expect(decoded.repeatCount, equals(50));
      expect(decoded.randomDelayEnabled, isTrue);
      expect(decoded.clickPoints.length, equals(2));
      expect(decoded.clickPoints.first.x, equals(120.5));
      expect(decoded.swipeConfig?.durationMs, equals(500));
      expect(decoded.swipeConfig?.loopSequence, isTrue);
    });
  });

  group('ExecuteScriptUseCase Tests', () {
    test('starts and pauses and stops execution cleanly', () async {
      final script = ScriptEntity(
        id: 'exec_test',
        name: 'Execution Test Script',
        actionType: 'click',
        intervalValue: 50,
        intervalUnit: 'ms',
        repeatType: 'custom',
        repeatCount: 5,
        clickPoints: const [
          ClickPointEntity(id: '1', x: 100, y: 200, delayMs: 10),
        ],
      );

      final useCase = ExecuteScriptUseCase(script: script);
      expect(useCase.state, equals(ExecutionState.idle));

      useCase.start(onTick: (clicks, seconds) {}, onComplete: () {});

      expect(useCase.state, equals(ExecutionState.running));

      useCase.pause();
      expect(useCase.state, equals(ExecutionState.paused));

      useCase.resume();
      expect(useCase.state, equals(ExecutionState.running));

      useCase.stop();
      expect(useCase.state, equals(ExecutionState.stopped));
    });

    test('resumes execution after pausing during an interval', () async {
      final script = ScriptEntity(
        id: 'pause_test',
        name: 'Pause Test',
        actionType: 'click',
        intervalValue: 10,
        intervalUnit: 'ms',
        repeatType: 'custom',
        repeatCount: 2,
        clickPoints: const [ClickPointEntity(id: '1', x: 1, y: 1)],
      );
      var dispatches = 0;
      final completed = Completer<void>();
      final useCase = ExecuteScriptUseCase(
        script: script,
        dispatchClick: (x, y, {durationMs = 50}) async {
          dispatches++;
          return true;
        },
      );

      useCase.start(onTick: (_, _) {}, onComplete: completed.complete);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      useCase.pause();
      final pausedDispatches = dispatches;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(dispatches, equals(pausedDispatches));
      useCase.resume();
      await completed.future.timeout(const Duration(seconds: 1));
      expect(dispatches, equals(2));
    });

    test('does not count a failed gesture and completes once', () async {
      final script = ScriptEntity(
        id: 'failure_test',
        name: 'Failure Test',
        actionType: 'swipe',
        intervalValue: 10,
        intervalUnit: 'ms',
        repeatType: 'custom',
        repeatCount: 2,
        swipeConfig: const SwipeConfigEntity(
          startX: 1,
          startY: 1,
          endX: 2,
          endY: 2,
          durationMs: 10,
        ),
      );
      var completions = 0;
      final completed = Completer<void>();
      final useCase = ExecuteScriptUseCase(
        script: script,
        dispatchSwipe: (_, _, _, _, {durationMs = 300}) async => false,
      );

      useCase.start(
        onTick: (_, _) => fail('failed gestures must not tick'),
        onComplete: () {
          completions++;
          completed.complete();
        },
      );
      await completed.future.timeout(const Duration(seconds: 1));
      expect(useCase.clicksCompleted, equals(0));
      expect(completions, equals(1));
      expect(useCase.state, equals(ExecutionState.stopped));
    });

    test('executes reverse swipe when loop sequence is enabled', () async {
      final script = ScriptEntity(
        id: 'loop_swipe_test',
        name: 'Loop Swipe Test',
        actionType: 'swipe',
        intervalValue: 10,
        intervalUnit: 'ms',
        repeatType: 'custom',
        repeatCount: 1,
        swipeConfig: const SwipeConfigEntity(
          startX: 1,
          startY: 2,
          endX: 3,
          endY: 4,
          loopSequence: true,
        ),
      );
      final swipes = <List<double>>[];
      final completed = Completer<void>();
      final useCase = ExecuteScriptUseCase(
        script: script,
        dispatchSwipe: (startX, startY, endX, endY, {durationMs = 300}) async {
          swipes.add([startX, startY, endX, endY]);
          return true;
        },
      );

      useCase.start(onTick: (_, _) {}, onComplete: completed.complete);
      await completed.future.timeout(const Duration(seconds: 1));
      expect(
        swipes,
        equals([
          [1, 2, 3, 4],
          [3, 4, 1, 2],
        ]),
      );
      expect(useCase.clicksCompleted, equals(1));
    });
  });

  group('ImportExportScriptUseCase Tests', () {
    test('exports script into valid JSON string', () {
      final script = ScriptEntity(
        id: 'exp_1',
        name: 'Export Test',
        actionType: 'swipe',
        swipeConfig: const SwipeConfigEntity(
          startX: 50,
          startY: 100,
          endX: 50,
          endY: 500,
        ),
      );

      final json = ImportExportScriptUseCase.exportScriptToJson(script);
      expect(json, contains('"name":"Export Test"'));
      expect(json, contains('"actionType":"swipe"'));
    });
  });

  group('PreferencesLocalDataSource Tests', () {
    test('stores and retrieves settings flags correctly', () async {
      final prefs = PreferencesLocalDataSource.instance;

      await prefs.setOnboardingComplete(true);
      expect(await prefs.isOnboardingComplete(), isTrue);

      await prefs.setDarkMode(true);
      expect(await prefs.getDarkMode(), isTrue);

      await prefs.setCollisionDetection(false);
      expect(await prefs.getCollisionDetection(), isFalse);

      await prefs.setProUser(true);
      expect(await prefs.isProUser(), isTrue);
    });
  });

  group('NativeAutomationChannel Cross-Platform Tests', () {
    test('checks accessibility and overlay gracefully', () async {
      expect(NativeAutomationChannel.isNativeGestureSupported, isNotNull);
      final isGranted = await NativeAutomationChannel.isAccessibilityGranted();
      expect(isGranted, isA<bool>());

      final isOverlay = await NativeAutomationChannel.isOverlayGranted();
      expect(isOverlay, isA<bool>());
    });
  });

  group('Failure & Result Types', () {
    test('creates correct failure instances', () {
      const storageFailure = StorageFailure('Disk full');
      expect(storageFailure.message, equals('Disk full'));

      const permissionFailure = PermissionDeniedFailure();
      expect(permissionFailure.message, equals('Permission denied'));
    });

    test('logDebug executes without error', () {
      expect(() => logDebug('Testing logger output'), returnsNormally);
    });
  });

  group('ScriptLocalDataSource CRUD Tests', () {
    final ds = ScriptLocalDataSource.instance;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ds.clearAll();
    });

    test('saves and retrieves a single script', () async {
      final script = ScriptEntity(
        id: 'crud_1',
        name: 'CRUD Save Test',
        actionType: 'click',
        clickPoints: const [
          ClickPointEntity(id: 'p1', x: 100, y: 200, delayMs: 50),
        ],
      );
      final saved = await ds.saveScript(script);
      expect(saved, isTrue);

      final retrieved = await ds.getSavedScripts();
      expect(retrieved.length, equals(1));
      expect(retrieved.first.id, equals('crud_1'));
      expect(retrieved.first.name, equals('CRUD Save Test'));
    });

    test('updates an existing script without duplicating', () async {
      final original = ScriptEntity(
        id: 'crud_update',
        name: 'Original Name',
        actionType: 'click',
      );
      await ds.saveScript(original);

      final updated = ScriptEntity(
        id: 'crud_update',
        name: 'Updated Name',
        actionType: 'swipe',
        swipeConfig: const SwipeConfigEntity(
          startX: 0,
          startY: 0,
          endX: 100,
          endY: 300,
        ),
      );
      final success = await ds.updateScript(updated);
      expect(success, isTrue);

      final allScripts = await ds.getSavedScripts();
      expect(allScripts.length, equals(1)); // no duplicate
      expect(allScripts.first.name, equals('Updated Name'));
      expect(allScripts.first.actionType, equals('swipe'));
    });

    test('deletes a script by ID', () async {
      final s1 = ScriptEntity(
        id: 'del_1',
        name: 'Script A',
        actionType: 'click',
      );
      final s2 = ScriptEntity(
        id: 'del_2',
        name: 'Script B',
        actionType: 'swipe',
      );
      await ds.saveScript(s1);
      await ds.saveScript(s2);

      final deleted = await ds.deleteScript('del_1');
      expect(deleted, isTrue);

      final remaining = await ds.getSavedScripts();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('del_2'));
    });

    test('clearAll removes all scripts', () async {
      await ds.saveScript(
        ScriptEntity(id: 'c1', name: 'A', actionType: 'click'),
      );
      await ds.saveScript(
        ScriptEntity(id: 'c2', name: 'B', actionType: 'click'),
      );
      await ds.clearAll();

      final result = await ds.getSavedScripts();
      expect(result.isEmpty, isTrue);
    });

    test('getSavedScripts returns empty list when no scripts saved', () async {
      final result = await ds.getSavedScripts();
      expect(result, isEmpty);
    });
  });

  group('PreferencesLocalDataSource — launchOnStartup Tests', () {
    test('persists launchOnStartup setting correctly', () async {
      final prefs = PreferencesLocalDataSource.instance;

      // Default should be true
      expect(await prefs.getLaunchOnStartup(), isTrue);

      await prefs.setLaunchOnStartup(false);
      expect(await prefs.getLaunchOnStartup(), isFalse);

      await prefs.setLaunchOnStartup(true);
      expect(await prefs.getLaunchOnStartup(), isTrue);
    });

    test('persists appLanguage setting correctly (§4)', () async {
      final prefs = PreferencesLocalDataSource.instance;

      // Default should be 'en'
      expect(await prefs.getAppLanguage(), equals('en'));

      await prefs.setAppLanguage('ur');
      expect(await prefs.getAppLanguage(), equals('ur'));
    });

    test('persists globalHotkey setting correctly (§5)', () async {
      final prefs = PreferencesLocalDataSource.instance;

      expect(await prefs.getGlobalHotkey(), isNull);

      await prefs.setGlobalHotkey('F9');
      expect(await prefs.getGlobalHotkey(), equals('F9'));
    });
  });

  group('ScriptValidator validateImportedJson Tests (§12)', () {
    test('accepts valid click script json', () {
      final json = {
        'name': 'Test Script',
        'actionType': 'click',
        'intervalValue': 2,
        'intervalUnit': 'Sec',
        'clickPoints': [
          {'x': 100, 'y': 200, 'delayMs': 500},
        ],
      };
      final errors = ScriptValidator.validateImportedJson(json);
      expect(errors, isEmpty);
    });

    test('accepts valid swipe script json', () {
      final json = {
        'name': 'Swipe Script',
        'actionType': 'swipe',
        'intervalValue': 1,
        'intervalUnit': 'Sec',
        'swipeConfig': {
          'startX': 100,
          'startY': 200,
          'endX': 100,
          'endY': 800,
          'durationMs': 300,
        },
      };
      final errors = ScriptValidator.validateImportedJson(json);
      expect(errors, isEmpty);
    });

    test('detects multiple field-level errors in malformed json', () {
      final json = {
        'name': ' ',
        'actionType': 'invalid_type',
        'intervalValue': -5,
        'intervalUnit': 'Hours',
      };
      final errors = ScriptValidator.validateImportedJson(json);
      expect(errors.length, greaterThanOrEqualTo(3));
      expect(errors.any((e) => e.contains('name')), isTrue);
      expect(errors.any((e) => e.contains('actionType')), isTrue);
      expect(errors.any((e) => e.contains('intervalValue')), isTrue);
      expect(errors.any((e) => e.contains('intervalUnit')), isTrue);
    });
  });
}
