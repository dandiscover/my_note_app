// lib/models/node.dart
// 树形节点模型 — 标准格式（不处理脏数据）

class Node {
  final String id;
  final String title;
  final String? parentId;
  final bool isFolder;
  final String nodeType;
  final String? targetId;
  final int sortOrder;
  final List<String> tags;
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSystemFolder {
    return isFolder &&
        parentId == null &&
        ['图书馆', '已归档', '卡片盒', '复盘'].contains(title);
  }

  String get iconEmoji {
    if (isFolder) {
      if (title == '图书馆') return '📚';
      if (title == '已归档') return '📦';
      if (title == '卡片盒') return '📇';
      if (title == '复盘') return '📝';
      return '📁';
    }
    if (nodeType == 'note') return '📄';
    if (nodeType == 'book') return '📖';
    return '📄';
  }
}