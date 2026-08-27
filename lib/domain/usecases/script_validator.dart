import '../../core/error/failure.dart';
import '../entities/script_entity.dart';

class ClickPointData {
  const ClickPointData({
    required this.x,
    required this.y,
    required this.delayMs,
  });

  final double x;
  final double y;
  final int delayMs;
}

class ScriptData {
  const ScriptData({
    required this.id,
    required this.name,
    required this.clickPoints,
  });

  final String id;
  final String name;
  final List<ClickPointData> clickPoints;
}

/// Defensive bounds-checking for user inputs & imported script files (§9.4).
class ScriptValidator {
  static const int _maxClickPoints = 200;
  static const int _maxDelayMs = 60000;
  static const int _minDelayMs = 0;

  Result<Failure, void> validate(ScriptData script) {
    return ScriptValidator.validateScriptData(script);
  }

  static Result<Failure, void> validateScriptData(ScriptData script) {
    if (script.name.trim().isEmpty) {
      return const Result.failure(
        Failure.validation('Script name cannot be empty'),
      );
    }
    if (script.clickPoints.length > _maxClickPoints) {
      return const Result.failure(
        Failure.validation('Too many click points (max 200)'),
      );
    }
    for (final p in script.clickPoints) {
      if (p.delayMs < _minDelayMs || p.delayMs > _maxDelayMs) {
        return const Result.failure(
          Failure.validation('Delay out of bounds (0-60000ms)'),
        );
      }
      if (p.x.isNaN || p.y.isNaN || p.x < 0 || p.y < 0) {
        return const Result.failure(
          Failure.validation('Invalid coordinate value'),
        );
      }
    }
    return const Result.success(null);
  }

  static Result<Failure, void> validateEntity(ScriptEntity script) {
    if (script.name.trim().isEmpty) {
      return const Result.failure(
        Failure.validation('Script name cannot be empty'),
      );
    }
    if (script.clickPoints.length > _maxClickPoints) {
      return const Result.failure(
        Failure.validation('Too many click points (max 200)'),
      );
    }
    if (script.actionType != 'click' && script.actionType != 'swipe') {
      return const Result.failure(
        Failure.validation('Action type must be click or swipe'),
      );
    }
    if (script.intervalValue < 1 ||
        (script.intervalUnit != 'Sec' && script.intervalUnit != 'ms')) {
      return const Result.failure(Failure.validation('Invalid interval'));
    }
    if (script.repeatType == 'custom' && script.repeatCount < 1) {
      return const Result.failure(Failure.validation('Invalid repeat count'));
    }
    if (script.repeatType != 'custom' && script.repeatType != 'infinite') {
      return const Result.failure(Failure.validation('Invalid repeat type'));
    }
    if (script.randomDelayMin < 0 ||
        script.randomDelayMax < script.randomDelayMin) {
      return const Result.failure(
        Failure.validation('Invalid random delay range'),
      );
    }
    if (script.actionType == 'click' && script.clickPoints.isEmpty) {
      return const Result.failure(
        Failure.validation('At least one click point is required'),
      );
    }
    final swipe = script.swipeConfig;
    if (script.actionType == 'swipe' &&
        (swipe == null ||
            swipe.durationMs < 10 ||
            swipe.delayMs < 0 ||
            swipe.startX < 0 ||
            swipe.startY < 0 ||
            swipe.endX < 0 ||
            swipe.endY < 0)) {
      return const Result.failure(
        Failure.validation('Invalid swipe configuration'),
      );
    }
    for (final p in script.clickPoints) {
      if (p.delayMs < _minDelayMs || p.delayMs > _maxDelayMs) {
        return const Result.failure(
          Failure.validation('Delay out of bounds (0-60000ms)'),
        );
      }
      if (p.x.isNaN || p.y.isNaN || p.x < 0 || p.y < 0) {
        return const Result.failure(
          Failure.validation('Invalid coordinate value'),
        );
      }
    }
    return const Result.success(null);
  }

  /// Field-level validation on untrusted imported JSON (§12/§0b).
  /// Returns a list of human-readable error strings — empty list means valid.
  static List<String> validateImportedJson(Map<String, dynamic> json) {
    const int minIntervalMs = 10;
    const int maxClickPoints = 200;
    final errors = <String>[];

    // name
    if (json['name'] is! String || (json['name'] as String).trim().isEmpty) {
      errors.add('name: missing or empty string');
    }

    // actionType
    final type = json['actionType'];
    if (type != 'click' && type != 'swipe') {
      errors.add('actionType: must be "click" or "swipe", got "$type"');
    }

    // intervalValue
    final intervalValue = json['intervalValue'];
    if (intervalValue is! int || intervalValue < 1) {
      errors.add('intervalValue: must be an integer ≥ 1');
    }

    // intervalUnit
    final unit = json['intervalUnit'];
    if (unit != 'Sec' && unit != 'ms') {
      errors.add('intervalUnit: must be "Sec" or "ms"');
    }

    // clickPoints for click scripts
    if (type == 'click') {
      final points = json['clickPoints'];
      if (points is! List || points.isEmpty) {
        errors.add(
          'clickPoints: required and must be non-empty for a click script',
        );
      } else if (points.length > maxClickPoints) {
        errors.add('clickPoints: exceeds max of $maxClickPoints entries');
      } else {
        for (var i = 0; i < points.length; i++) {
          final p = points[i];
          if (p is! Map) {
            errors.add('clickPoints[$i]: must be an object');
            continue;
          }
          if (p['x'] is! num || p['y'] is! num) {
            errors.add('clickPoints[$i]: x and y must be numeric');
          }
          final delay = p['delayMs'];
          if (delay is! int || delay < minIntervalMs) {
            errors.add(
              'clickPoints[$i]: delayMs must be an integer ≥ $minIntervalMs',
            );
          }
        }
      }
    }

    // swipeConfig for swipe scripts
    if (type == 'swipe') {
      final swipe = json['swipeConfig'];
      if (swipe is! Map) {
        errors.add('swipeConfig: required for a swipe script');
      } else {
        for (final key in ['startX', 'startY', 'endX', 'endY']) {
          if (swipe[key] is! num) {
            errors.add('swipeConfig.$key: must be numeric');
          }
        }
        final dur = swipe['durationMs'];
        if (dur is! int || dur < minIntervalMs) {
          errors.add(
            'swipeConfig.durationMs: must be an integer ≥ $minIntervalMs',
          );
        }
      }
    }

    return errors;
  }
}
