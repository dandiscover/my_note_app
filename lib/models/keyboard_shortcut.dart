// lib/models/keyboard_shortcut.dart
// 快捷键数据模型

class KeyboardShortcut {
  final String id;
  final String name;
  final String description;
  String key;
  bool isCtrlRequired;
  bool isShiftRequired;
  bool isAltRequired;

  KeyboardShortcut({
    required this.id,
    required this.name,
    required this.description,
    required this.key,
    this.isCtrlRequired = false,
    this.isShiftRequired = false,
    this.isAltRequired = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'key': key,
      'is_ctrl': isCtrlRequired ? 1 : 0,
      'is_shift': isShiftRequired ? 1 : 0,
      'is_alt': isAltRequired ? 1 : 0,
    };
  }

  factory KeyboardShortcut.fromMap(Map<String, dynamic> map) {
    return KeyboardShortcut(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      key: map['key'],
      isCtrlRequired: (map['is_ctrl'] ?? 0) == 1,
      isShiftRequired: (map['is_shift'] ?? 0) == 1,
      isAltRequired: (map['is_alt'] ?? 0) == 1,
    );
  }

  // ─── 序列化（SharedPreferences 存储用） ─────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'key': key,
      'isCtrlRequired': isCtrlRequired,
      'isShiftRequired': isShiftRequired,
      'isAltRequired': isAltRequired,
    };
  }

  factory KeyboardShortcut.fromJson(Map<String, dynamic> json) {
    return KeyboardShortcut(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      key: json['key'],
      isCtrlRequired: json['isCtrlRequired'] ?? false,
      isShiftRequired: json['isShiftRequired'] ?? false,
      isAltRequired: json['isAltRequired'] ?? false,
    );
  }

  // ─── 默认快捷键列表 ─────────────────────────────
  static List<KeyboardShortcut> get defaults {
    return [
      KeyboardShortcut(
        id: 'save',
        name: '保存',
        description: '保存当前内容',
        key: 's',
        isCtrlRequired: true,
      ),
      KeyboardShortcut(
        id: 'undo',
        name: '撤销',
        description: '撤销上一步操作',
        key: 'z',
        isCtrlRequired: true,
      ),
      KeyboardShortcut(
        id: 'redo',
        name: '重做',
        description: '重做已撤销的操作',
        key: 'z',
        isCtrlRequired: true,
        isShiftRequired: true,
      ),
      KeyboardShortcut(
        id: 'bold',
        name: '加粗',
        description: '插入加粗标记',
        key: 'b',
        isCtrlRequired: true,
      ),
      KeyboardShortcut(
        id: 'italic',
        name: '斜体',
        description: '插入斜体标记',
        key: 'i',
        isCtrlRequired: true,
      ),
      KeyboardShortcut(
        id: 'escape',
        name: '返回/关闭',
        description: '关闭对话框或返回上一页',
        key: 'escape',
      ),
    ];
  }

  // ─── 获取显示名称 ─────────────────────────────
  String get displayName {
    final parts = <String>[];
    if (isCtrlRequired) parts.add('Ctrl');
    if (isShiftRequired) parts.add('Shift');
    if (isAltRequired) parts.add('Alt');
    final keyDisplay = key == 'escape' ? 'Esc' : key.toUpperCase();
    parts.add(keyDisplay);
    return parts.join('+');
  }

  // ─── 🆕 从显示名称解析为 KeyboardShortcut ─────────────────────────────
  static KeyboardShortcut? fromDisplayName(String displayName) {
    final parts = displayName.split('+');
    if (parts.isEmpty) return null;

    String? key;
    bool isCtrl = false;
    bool isShift = false;
    bool isAlt = false;

    for (var part in parts) {
      final lower = part.toLowerCase();
      if (lower == 'ctrl') {
        isCtrl = true;
      } else if (lower == 'shift') {
        isShift = true;
      } else if (lower == 'alt') {
        isAlt = true;
      } else {
        key = lower;
      }
    }

    if (key == null || key.isEmpty) return null;

    final matchedKey = key.toLowerCase();

    // 先在 defaults 中查找匹配的 id，再构建新对象
    final matched = defaults.firstWhere(
      (s) => s.key.toLowerCase() == matchedKey &&
          s.isCtrlRequired == isCtrl &&
          s.isShiftRequired == isShift &&
          s.isAltRequired == isAlt,
      orElse: () => defaults.first,
    );

    return KeyboardShortcut(
      id: matched.id,
      name: matched.name,
      description: matched.description,
      key: key,
      isCtrlRequired: isCtrl,
      isShiftRequired: isShift,
      isAltRequired: isAlt,
    );
  }

  // ─── 重置为默认值 ─────────────────────────────
  KeyboardShortcut resetToDefault() {
    final defaultShortcut = KeyboardShortcut.defaults.firstWhere(
      (s) => s.id == id,
      orElse: () => this,
    );
    return KeyboardShortcut(
      id: id,
      name: name,
      description: description,
      key: defaultShortcut.key,
      isCtrlRequired: defaultShortcut.isCtrlRequired,
      isShiftRequired: defaultShortcut.isShiftRequired,
      isAltRequired: defaultShortcut.isAltRequired,
    );
  }

  // ─── 复制（用于更新） ─────────────────────────────
  KeyboardShortcut copyWith({
    String? key,
    bool? isCtrlRequired,
    bool? isShiftRequired,
    bool? isAltRequired,
  }) {
    return KeyboardShortcut(
      id: id,
      name: name,
      description: description,
      key: key ?? this.key,
      isCtrlRequired: isCtrlRequired ?? this.isCtrlRequired,
      isShiftRequired: isShiftRequired ?? this.isShiftRequired,
      isAltRequired: isAltRequired ?? this.isAltRequired,
    );
  }
}