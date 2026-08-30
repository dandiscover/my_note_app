// lib/models/task.dart
// 任务数据模型 — 难度/紧急性/必要性 + 子任务 + 复盘关联 + 提醒时间


// ─── 枚举定义 ─────────────────────────────

enum TaskType {
  quick,   // 速通：简单小任务
  explore, // 探究：复杂任务，可拆分子任务
}

enum Difficulty {
  easy,   // 易
  medium, // 中
  hard,   // 难
}

enum Urgency {
  low,    // 低
  medium, // 中
  high,   // 高
}

enum Necessity {
  optional,  // 可选
  important, // 重要
  critical,  // 必要
}

// ─── 枚举扩展 ─────────────────────────────

extension TaskTypeExt on TaskType {
  String get string {
    switch (this) {
      case TaskType.quick:
        return 'quick';
      case TaskType.explore:
        return 'explore';
    }
  }

  static TaskType fromString(String value) {
    switch (value) {
      case 'quick':
        return TaskType.quick;
      case 'explore':
        return TaskType.explore;
      default:
        return TaskType.quick;
    }
  }
}

extension DifficultyExt on Difficulty {
  String get string {
    switch (this) {
      case Difficulty.easy:
        return 'easy';
      case Difficulty.medium:
        return 'medium';
      case Difficulty.hard:
        return 'hard';
    }
  }

  static Difficulty fromString(String value) {
    switch (value) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      default:
        return Difficulty.medium;
    }
  }

  String get label {
    switch (this) {
      case Difficulty.easy:
        return '易';
      case Difficulty.medium:
        return '中';
      case Difficulty.hard:
        return '难';
    }
  }

  String get icon {
    switch (this) {
      case Difficulty.easy:
        return '🟢';
      case Difficulty.medium:
        return '🟡';
      case Difficulty.hard:
        return '🔴';
    }
  }
}

extension UrgencyExt on Urgency {
  String get string {
    switch (this) {
      case Urgency.low:
        return 'low';
      case Urgency.medium:
        return 'medium';
      case Urgency.high:
        return 'high';
    }
  }

  static Urgency fromString(String value) {
    switch (value) {
      case 'low':
        return Urgency.low;
      case 'medium':
        return Urgency.medium;
      case 'high':
        return Urgency.high;
      default:
        return Urgency.medium;
    }
  }

  String get label {
    switch (this) {
      case Urgency.low:
        return '低';
      case Urgency.medium:
        return '中';
      case Urgency.high:
        return '高';
    }
  }

  String get icon {
    switch (this) {
      case Urgency.low:
        return '🟢';
      case Urgency.medium:
        return '🟡';
      case Urgency.high:
        return '🔴';
    }
  }
}

extension NecessityExt on Necessity {
  String get string {
    switch (this) {
      case Necessity.optional:
        return 'optional';
      case Necessity.important:
        return 'important';
      case Necessity.critical:
        return 'critical';
    }
  }

  static Necessity fromString(String value) {
    switch (value) {
      case 'optional':
        return Necessity.optional;
      case 'important':
        return Necessity.important;
      case 'critical':
        return Necessity.critical;
      default:
        return Necessity.important;
    }
  }

  String get label {
    switch (this) {
      case Necessity.optional:
        return '可选';
      case Necessity.important:
        return '重要';
      case Necessity.critical:
        return '必要';
    }
  }
}

// ─── 子任务模型 ─────────────────────────────

class Subtask {
  final String id;
  final String parentTaskId;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;

  Subtask({
    required this.id,
    required this.parentTaskId,
    required this.title,
    this.isDone = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'parentTaskId': parentTaskId,
    'title': title,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id: json['id'] as String,
    parentTaskId: json['parentTaskId'] as String,
    title: json['title'] as String,
    isDone: json['isDone'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );

  Subtask copyWith({
    String? id,
    String? parentTaskId,
    String? title,
    bool? isDone,
    DateTime? createdAt,
    DateTime? completedAt,
  }) => Subtask(
    id: id ?? this.id,
    parentTaskId: parentTaskId ?? this.parentTaskId,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt ?? this.completedAt,
  );
}

// ─── 主任务模型 ─────────────────────────────

class Task {
  final String id;
  final String title;
  final TaskType type;
  final String? description;
  final Difficulty difficulty;
  final Urgency urgency;
  final Necessity necessity;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? noteId;
  final List<String> subtaskIds;
  final DateTime? reminderTime;

  Task({
    required this.id,
    required this.title,
    this.type = TaskType.quick,
    this.description,
    this.difficulty = Difficulty.medium,
    this.urgency = Urgency.medium,
    this.necessity = Necessity.important,
    this.isDone = false,
    DateTime? createdAt,
    this.completedAt,
    this.noteId,
    this.subtaskIds = const [],
    this.reminderTime,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.string,
    'description': description,
    'difficulty': difficulty.string,
    'urgency': urgency.string,
    'necessity': necessity.string,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'noteId': noteId,
    'subtaskIds': subtaskIds,
    'reminderTime': reminderTime?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    type: json['type'] != null
        ? TaskTypeExt.fromString(json['type'] as String)
        : TaskType.quick,
    description: json['description'] as String?,
    difficulty: json['difficulty'] != null
        ? DifficultyExt.fromString(json['difficulty'] as String)
        : Difficulty.medium,
    urgency: json['urgency'] != null
        ? UrgencyExt.fromString(json['urgency'] as String)
        : Urgency.medium,
    necessity: json['necessity'] != null
        ? NecessityExt.fromString(json['necessity'] as String)
        : Necessity.important,
    isDone: json['isDone'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    noteId: json['noteId'] as String?,
    subtaskIds: (json['subtaskIds'] as List?)?.map((e) => e as String).toList() ?? [],
    reminderTime: json['reminderTime'] != null
        ? DateTime.parse(json['reminderTime'] as String)
        : null,
  );

  Task copyWith({
    String? id,
    String? title,
    TaskType? type,
    String? description,
    Difficulty? difficulty,
    Urgency? urgency,
    Necessity? necessity,
    bool? isDone,
    DateTime? createdAt,
    DateTime? completedAt,
    String? noteId,
    List<String>? subtaskIds,
    DateTime? reminderTime,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    description: description ?? this.description,
    difficulty: difficulty ?? this.difficulty,
    urgency: urgency ?? this.urgency,
    necessity: necessity ?? this.necessity,
    isDone: isDone ?? this.isDone,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt ?? this.completedAt,
    noteId: noteId ?? this.noteId,
    subtaskIds: subtaskIds ?? this.subtaskIds,
    reminderTime: reminderTime ?? this.reminderTime,
  );
}