class Node {
  final String id;
  String title;
  String? parentId;
  bool isFolder;
  String nodeType; // 'folder' | 'note' | 'book'
  String? targetId; // 如果 nodeType 是 note/book，关联到对应内容 ID
  int sortOrder;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;

  Node({
    required this.id,
    required this.title,
    this.parentId,
    this.isFolder = false,
    this.nodeType = 'folder',
    this.targetId,
    this.sortOrder = 0,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'parent_id': parentId,
      'is_folder': isFolder ? 1 : 0,
      'node_type': nodeType,
      'target_id': targetId,
      'sort_order': sortOrder,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Node.fromMap(Map<String, dynamic> map) {
    return Node(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      parentId: map['parent_id'],
      isFolder: (map['is_folder'] ?? 0) == 1,
      nodeType: map['node_type'] ?? 'folder',
      targetId: map['target_id'],
      sortOrder: map['sort_order'] ?? 0,
      tags: (map['tags'] ?? '').toString().split(',').where((t) => t.isNotEmpty).toList(),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
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

  /// 获取节点图标
  String get iconEmoji {
    switch (nodeType) {
      case 'folder':
        return '📁';
      case 'note':
        return '📄';
      case 'book':
        return '📘';
      default:
        return '📄';
    }
  }

  /// 获取节点颜色（用于缩略图背景）
  int get colorIndex {
    // 根据 id 哈希生成稳定的颜色索引
    final hash = id.hashCode.abs();
    return hash % 8;
  }

  /// 是否为叶子节点（非文件夹）
  bool get isLeaf => !isFolder;
}