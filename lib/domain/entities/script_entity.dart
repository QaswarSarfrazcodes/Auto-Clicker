import 'dart:convert';

/// Represents a single click point coordinate.
class ClickPointEntity {
  const ClickPointEntity({
    required this.id,
    required this.x,
    required this.y,
    this.delayMs = 0,
  });

  final String id;
  final double x;
  final double y;
  final int delayMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'delayMs': delayMs,
      };

  factory ClickPointEntity.fromJson(Map<String, dynamic> json) =>
      ClickPointEntity(
        id: json['id'] as String? ?? '',
        x: (json['x'] as num? ?? 0.0).toDouble(),
        y: (json['y'] as num? ?? 0.0).toDouble(),
        delayMs: json['delayMs'] as int? ?? 0,
      );
}

/// Represents a swipe configuration.
class SwipeConfigEntity {
  const SwipeConfigEntity({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.durationMs = 300,
    this.delayMs = 0,
    this.loopSequence = false,
  });

  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final int durationMs;
  final int delayMs;
  final bool loopSequence;

  Map<String, dynamic> toJson() => {
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'durationMs': durationMs,
        'delayMs': delayMs,
        'loopSequence': loopSequence,
      };

  factory SwipeConfigEntity.fromJson(Map<String, dynamic> json) =>
      SwipeConfigEntity(
        startX: (json['startX'] as num? ?? 0.0).toDouble(),
        startY: (json['startY'] as num? ?? 0.0).toDouble(),
        endX: (json['endX'] as num? ?? 0.0).toDouble(),
        endY: (json['endY'] as num? ?? 0.0).toDouble(),
        durationMs: json['durationMs'] as int? ?? 300,
        delayMs: json['delayMs'] as int? ?? 0,
        loopSequence: json['loopSequence'] as bool? ?? false,
      );
}

/// Main domain model for an Auto Clicker script.
class ScriptEntity {
  ScriptEntity({
    required this.id,
    required this.name,
    required this.actionType, // 'click' or 'swipe'
    this.intervalValue = 1,
    this.intervalUnit = 'Sec', // 'Sec' or 'ms'
    this.repeatType = 'infinite', // 'infinite' or 'custom'
    this.repeatCount = 10,
    this.randomDelayEnabled = false,
    this.randomDelayMin = 1,
    this.randomDelayMax = 5,
    this.clickPoints = const [],
    this.swipeConfig,
    DateTime? createdAt,
    this.lastRunAt,
    // Feature B — Video-Aware Scroll Hold
    this.holdOnVideoEnabled = false,
    this.maxVideoWaitSeconds = 180,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String actionType;
  final int intervalValue;
  final String intervalUnit;
  final String repeatType;
  final int repeatCount;
  final bool randomDelayEnabled;
  final int randomDelayMin;
  final int randomDelayMax;
  final List<ClickPointEntity> clickPoints;
  final SwipeConfigEntity? swipeConfig;
  final DateTime createdAt;
  /// When this script was last started. Null if never run.
  final DateTime? lastRunAt;

  // Feature B — Video-Aware Scroll Hold fields
  /// When true, the engine holds the next scroll while a video is playing.
  final bool holdOnVideoEnabled;
  /// Maximum seconds to wait for a video to end before forcing the scroll.
  /// Default 180s (3 min) — the hard safety valve from solution.md §2.
  final int maxVideoWaitSeconds;

  /// Convenience getter: [maxVideoWaitSeconds] as a [Duration].
  Duration get maxVideoWaitDuration => Duration(seconds: maxVideoWaitSeconds);

  /// Human-readable relative time since [lastRunAt] (e.g. "3h ago", "Never run").
  String get lastRunLabel {
    if (lastRunAt == null) return 'Never run';
    final diff = DateTime.now().difference(lastRunAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'actionType': actionType,
        'intervalValue': intervalValue,
        'intervalUnit': intervalUnit,
        'repeatType': repeatType,
        'repeatCount': repeatCount,
        'randomDelayEnabled': randomDelayEnabled,
        'randomDelayMin': randomDelayMin,
        'randomDelayMax': randomDelayMax,
        'clickPoints': clickPoints.map((cp) => cp.toJson()).toList(),
        'swipeConfig': swipeConfig?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastRunAt': lastRunAt?.toIso8601String(),
        // Feature B
        'holdOnVideoEnabled': holdOnVideoEnabled,
        'maxVideoWaitSeconds': maxVideoWaitSeconds,
      };

  factory ScriptEntity.fromJson(Map<String, dynamic> json) => ScriptEntity(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled Script',
        actionType: json['actionType'] as String? ?? 'click',
        intervalValue: json['intervalValue'] as int? ?? 1,
        intervalUnit: json['intervalUnit'] as String? ?? 'Sec',
        repeatType: json['repeatType'] as String? ?? 'infinite',
        repeatCount: json['repeatCount'] as int? ?? 10,
        randomDelayEnabled: json['randomDelayEnabled'] as bool? ?? false,
        randomDelayMin: json['randomDelayMin'] as int? ?? 1,
        randomDelayMax: json['randomDelayMax'] as int? ?? 5,
        clickPoints: (json['clickPoints'] as List<dynamic>?)
                ?.map((e) => ClickPointEntity.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        swipeConfig: json['swipeConfig'] != null
            ? SwipeConfigEntity.fromJson(
                json['swipeConfig'] as Map<String, dynamic>)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        lastRunAt: json['lastRunAt'] != null
            ? DateTime.tryParse(json['lastRunAt'] as String)
            : null,
        // Feature B — default false/180 keeps old scripts working unchanged
        holdOnVideoEnabled: json['holdOnVideoEnabled'] as bool? ?? false,
        maxVideoWaitSeconds: json['maxVideoWaitSeconds'] as int? ?? 180,
      );

  ScriptEntity copyWith({
    String? id,
    String? name,
    String? actionType,
    int? intervalValue,
    String? intervalUnit,
    String? repeatType,
    int? repeatCount,
    bool? randomDelayEnabled,
    int? randomDelayMin,
    int? randomDelayMax,
    List<ClickPointEntity>? clickPoints,
    SwipeConfigEntity? swipeConfig,
    DateTime? createdAt,
    DateTime? lastRunAt,
    // Feature B
    bool? holdOnVideoEnabled,
    int? maxVideoWaitSeconds,
  }) =>
      ScriptEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        actionType: actionType ?? this.actionType,
        intervalValue: intervalValue ?? this.intervalValue,
        intervalUnit: intervalUnit ?? this.intervalUnit,
        repeatType: repeatType ?? this.repeatType,
        repeatCount: repeatCount ?? this.repeatCount,
        randomDelayEnabled: randomDelayEnabled ?? this.randomDelayEnabled,
        randomDelayMin: randomDelayMin ?? this.randomDelayMin,
        randomDelayMax: randomDelayMax ?? this.randomDelayMax,
        clickPoints: clickPoints ?? this.clickPoints,
        swipeConfig: swipeConfig ?? this.swipeConfig,
        createdAt: createdAt ?? this.createdAt,
        lastRunAt: lastRunAt ?? this.lastRunAt,
        holdOnVideoEnabled: holdOnVideoEnabled ?? this.holdOnVideoEnabled,
        maxVideoWaitSeconds: maxVideoWaitSeconds ?? this.maxVideoWaitSeconds,
      );

  String encodeJson() => jsonEncode(toJson());

  factory ScriptEntity.decodeJson(String source) =>
      ScriptEntity.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
