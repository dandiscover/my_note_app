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

  String get displayName {
    final parts = <String>[];
    if (isCtrlRequired) parts.add('Ctrl');
    if (isShiftRequired) parts.add('Shift');
    if (isAltRequired) parts.add('Alt');
    final keyDisplay = key == 'escape' ? 'Esc' : key.toUpperCase();
    parts.add(keyDisplay);
    return parts.join('+');
  }

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

    // ✅ 判空
    if (key == null || key.isEmpty) return null;

    final matchedKey = key.toLowerCase(); // key 已非空，安全

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
}