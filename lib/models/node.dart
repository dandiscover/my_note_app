// lib/models/node.dart
// 树形节点模型 — 标准格式（不处理脏数据）
// ✅ 子笔记嵌套：加 kMaxSubNoteDepth 常量（集中定义，不散落）
// ✅ 批 BUG-003：加 systemTag 字段——系统文件夹按字段判定，不靠 title

/// 子笔记嵌套最大深度（含自身）。第 1 层是笔记本身。
const int kMaxSubNoteDepth = 3;

class Node {
  final String id;
  final String title;
  final String? parentId;
  final bool isFolder;
  final String nodeType;
  final String? targetId;
  final int sortOrder;
  final List<String> tags;
  final String? systemTag;    // 批 BUG-003：系统标记——null=用户文件夹
  final DateTime createdAt;
  final DateTime updatedAt;

  const Node({
    required this.id,
    required this.title,
    this.parentId,
    required this.isFolder,
    required this.nodeType,
    this.targetId,
    this.sortOrder = 0,
    this.tags = const [],
    this.systemTag,
    required this.createdAt,
    required this.updatedAt,
  });

  static final Node empty = Node(
    id: '',
    title: '',
    parentId: null,
    isFolder: false,
    nodeType: 'folder',
    targetId: null,
    sortOrder: 0,
    tags: const [],
    systemTag: null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// ✅ fromMap 只接受标准格式（tags 已是 List，parentId 已是 null 或有效值）
  factory Node.fromMap(Map<String, dynamic> map) {
    return Node(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      parentId: map['parentId'],
      isFolder: (map['isFolder'] ?? 0) == 1,
      nodeType: map['nodeType'] ?? 'folder',
      targetId: map['targetId'],
      sortOrder: map['sortOrder'] ?? 0,
      tags: (map['tags'] as List?)?.cast<String>() ?? [],
      systemTag: map['systemTag'] as String?,    // 批 BUG-003
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'parentId': parentId,
      'isFolder': isFolder ? 1 : 0,
      'nodeType': nodeType,
      'targetId': targetId,
      'sortOrder': sortOrder,
      'tags': tags,
      'systemTag': systemTag,                    // 批 BUG-003
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Node copyWith({
    String? id,
    String? title,
    String? parentId,
    bool? isFolder,
    String? nodeType,
    String? targetId,
    int? sortOrder,
    List<String>? tags,
    String? systemTag,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Node(
      id: id ?? this.id,
      title: title ?? this.title,
      parentId: parentId ?? this.parentId,
      isFolder: isFolder ?? this.isFolder,
      nodeType: nodeType ?? this.nodeType,
      targetId: targetId ?? this.targetId,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      systemTag: systemTag ?? this.systemTag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSystemFolder {
    // 批 BUG-003：改按字段判定——不靠 title
    // 例外：'expand' 是半系统——系统建但用户可管
    return isFolder &&
        parentId == null &&
        systemTag != null &&
        systemTag != 'expand';
  }

  String get iconEmoji {
    if (isFolder) {
      // 批 BUG-003：改按 systemTag 判定——不靠 title
      if (systemTag == 'library') return '📚';
      if (systemTag == 'archived') return '📦';
      if (systemTag == 'cardbox') return '📇';
      if (systemTag == 'review') return '📝';
      if (systemTag == 'expand') return '✏️';
      return '📁';
    }
    if (nodeType == 'note') return '📄';
    if (nodeType == 'book') return '📖';
    return '📄';
  }
}