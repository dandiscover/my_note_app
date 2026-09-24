// lib/widgets/workbench/note_map_view.dart
// 笔记导图 —— 阅读态树状视图
import 'package:flutter/material.dart';
import '../../database_service.dart';
import '../../models/node.dart';
import '../../models/note.dart';

class NoteMapView extends StatefulWidget {
  final NotebookEntry entry;
  final String? nodeId;
  final int refreshTick;                            // 外部刷新信号
  final void Function(Node target) onSubNoteTap;    // 子笔记名 → 换根
  final void Function(Node parentNote) onNewSubNote; // + 号 → 在父笔记下新建

  const NoteMapView({
    super.key,
    required this.entry,
    required this.nodeId,
    required this.refreshTick,
    required this.onSubNoteTap,
    required this.onNewSubNote,
  });

  @override
  State<NoteMapView> createState() => _NoteMapViewState();
}

class _NoteMapViewState extends State<NoteMapView> {
  final DatabaseService _db = DatabaseService();

  List<_MapNode> _roots = [];
  bool _loading = true;

  final Set<String> _expandedIds = {};
  final Map<String, List<_MapNode>> _expandedChildren = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NoteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeId != widget.nodeId ||
        oldWidget.entry.updatedAt != widget.entry.updatedAt ||
        oldWidget.refreshTick != widget.refreshTick) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final titles = _parseHeadingsTree(widget.entry.content);
    final subNotes = await _loadDirectSubNotes(widget.nodeId);

    final roots = <_MapNode>[];
    roots.addAll(titles.map((h) => _MapNode.innerHeading(
          id: 'h_${h.text}_${h.offset}',
          level: h.level,
          text: h.text,
          ownerNote: null,      // 主笔记标题 —— 主体不可点
          children: h.children.map(_treeToMap).toList(),
        )));
    for (final n in subNotes) {
      roots.add(_MapNode.subNote(n));
    }

    if (mounted) {
      setState(() {
        _roots = roots;
        _loading = false;
        _expandedIds.clear();
        _expandedChildren.clear();
      });
    }
  }

  _MapNode _treeToMap(_HeadingTree h) => _MapNode.innerHeading(
        id: 'h_${h.text}_${h.offset}',
        level: h.level,
        text: h.text,
        ownerNote: null,
        children: h.children.map(_treeToMap).toList(),
      );

  Future<List<Node>> _loadDirectSubNotes(String? parentNodeId) async {
    if (parentNodeId == null) return [];
    final children = await _db.getChildren(parentNodeId);
    return children.where((n) => n.nodeType == 'note').toList();
  }

  /// 展开子笔记 —— 读该子笔记正文，parse 标题树 + 拉直接子笔记
  Future<void> _expandSubNote(_MapNode node) async {
    if (node.node == null) return;
    if (_expandedChildren.containsKey(node.id)) {
      setState(() => _expandedIds.add(node.id));
      return;
    }

    final subEntry = await _db.getNoteByNodeId(node.node!.id);
    final children = <_MapNode>[];

    if (subEntry != null) {
      final trees = _parseHeadingsTree(subEntry.content);
      for (final t in trees) {
        children.add(_treeWithOwner(t, node.node!));
      }
    }
    final grandChildren = await _loadDirectSubNotes(node.node!.id);
    for (final gc in grandChildren) {
      children.add(_MapNode.subNote(gc));
    }

    if (mounted) {
      setState(() {
        _expandedChildren[node.id] = children;
        _expandedIds.add(node.id);
      });
    }
  }

  _MapNode _treeWithOwner(_HeadingTree h, Node owner) => _MapNode.innerHeading(
        id: '${owner.id}_h_${h.text}_${h.offset}',
        level: h.level,
        text: h.text,
        ownerNote: owner,
        children: h.children.map((c) => _treeWithOwner(c, owner)).toList(),
      );

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final rootExpanded = _expandedIds.contains('__root__');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRootNode(rootExpanded),
          const SizedBox(height: 8),
          if (_roots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '这篇笔记没有标题也没有子笔记',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else if (rootExpanded)
            ..._roots.map((r) => _buildNode(r, depth: 1)),
        ],
      ),
    );
  }

  Widget _buildRootNode(bool expanded) {
    return InkWell(
      onTap: null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            _foldArrow(
              hasChildren: _roots.isNotEmpty,
              expanded: expanded,
              onTap: () => _toggleExpand('__root__'),
            ),
            const SizedBox(width: 4),
            const Text(
              '[主笔记]',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foldArrow({
    required bool hasChildren,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    if (!hasChildren) return const SizedBox(width: 36, height: 36);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          expanded ? Icons.expand_more : Icons.chevron_right,
          size: 20,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _newButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: const SizedBox(
        width: 36,
        height: 36,
        child: Icon(Icons.add, size: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildNode(_MapNode node, {required int depth}) {
    final indent = depth * 20.0;
    final expanded = _expandedIds.contains(node.id);
    final loadedChildren = _expandedChildren[node.id] ?? node.children;
    final hasChildren = loadedChildren.isNotEmpty;

    switch (node.kind) {
      // 主笔记标题 —— 主体不可点 —— 箭头折叠
      case _MapKind.innerHeading:
        final owner = node.ownerNote;
        final isSubInner = owner != null;
        // 子笔记内部标题：主体=折叠；主笔记标题：主体无动作
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
              child: Row(
                children: [
                  _foldArrow(
                    hasChildren: hasChildren,
                    expanded: expanded,
                    onTap: () => _toggleExpand(node.id),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: isSubInner
                        // 子笔记内部标题 —— 主体点击 = 折叠（与箭头同功能）
                        ? InkWell(
                            onTap: () => _toggleExpand(node.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              child: Text(
                                node.text ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: node.level == 1 ? 14 : 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          )
                        // 主笔记标题 —— 主体无动作
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 4),
                            child: Text(
                              node.text ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize:
                                    node.level == 1 ? 15 : (node.level == 2 ? 14 : 13),
                                fontWeight: node.level == 1
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                  ),
                  // + 号 —— 在该层所属笔记下新建
                  if (isSubInner)
                    _newButton(() => widget.onNewSubNote(owner))
                  else if (widget.nodeId != null)
                    _newButton(() async {
                      final n = await _db.getNode(widget.nodeId!);
                      if (n != null && mounted) widget.onNewSubNote(n);
                    }),
                ],
              ),
            ),
            if (expanded && hasChildren)
              ...loadedChildren.map((c) => _buildNode(c, depth: depth + 1)),
          ],
        );

      // 子笔记节点 —— 主体换根 —— 箭头折叠
      case _MapKind.subNote:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    _foldArrow(
                      hasChildren: true,
                      expanded: expanded,
                      onTap: () {
                        if (expanded) {
                          _toggleExpand(node.id);
                        } else {
                          _expandSubNote(node);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (node.node != null) {
                            widget.onSubNoteTap(node.node!);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              const Text('📎 ',
                                  style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  node.node!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (node.node != null)
                      _newButton(() => widget.onNewSubNote(node.node!)),
                  ],
                ),
              ),
            ),
            if (expanded)
              ...loadedChildren.map((c) => _buildNode(c, depth: depth + 1)),
          ],
        );
    }
  }

  // ─── 标题解析 —— 树状（支持 H1 > H2 > H3）───────────────

  List<_HeadingTree> _parseHeadingsTree(String md) {
    final flat = <_HeadingFlat>[];
    var offset = 0;
    for (final line in md.split('\n')) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('#')) {
        var level = 0;
        while (level < trimmed.length && trimmed[level] == '#') {
          level++;
        }
        if (level >= 1 &&
            level <= 6 &&
            level < trimmed.length &&
            trimmed[level] == ' ') {
          final text = trimmed.substring(level + 1).trim();
          if (text.isNotEmpty) {
            flat.add(_HeadingFlat(level: level, text: text, offset: offset));
          }
        }
      }
      offset += line.length + 1;
    }

    final roots = <_HeadingTree>[];
    final stack = <_HeadingTree>[];
    for (final f in flat) {
      final node = _HeadingTree(level: f.level, text: f.text, offset: f.offset);
      while (stack.isNotEmpty && stack.last.level >= f.level) {
        stack.removeLast();
      }
      if (stack.isEmpty) {
        roots.add(node);
      } else {
        stack.last.children.add(node);
      }
      stack.add(node);
    }
    return roots;
  }
}

// ─── 内部数据模型 ─────────────────────────────────────

enum _MapKind { innerHeading, subNote }

class _MapNode {
  final String id;
  final _MapKind kind;
  final int level;
  final String? text;
  final Node? node;         // subNote 用
  final Node? ownerNote;    // innerHeading 用 —— null = 主笔记标题；非 null = 子笔记内部标题
  final List<_MapNode> children;

  _MapNode._({
    required this.id,
    required this.kind,
    this.level = 0,
    this.text,
    this.node,
    this.ownerNote,
    List<_MapNode>? children,
  }) : children = children ?? [];

  factory _MapNode.innerHeading({
    required String id,
    required int level,
    required String text,
    required Node? ownerNote,
    required List<_MapNode> children,
  }) =>
      _MapNode._(
        id: id,
        kind: _MapKind.innerHeading,
        level: level,
        text: text,
        ownerNote: ownerNote,
        children: children,
      );

  factory _MapNode.subNote(Node n) =>
      _MapNode._(id: 's_${n.id}', kind: _MapKind.subNote, node: n);
}

class _HeadingFlat {
  final int level;
  final String text;
  final int offset;
  const _HeadingFlat({
    required this.level,
    required this.text,
    required this.offset,
  });
}

class _HeadingTree {
  final int level;
  final String text;
  final int offset;
  final List<_HeadingTree> children;
  _HeadingTree({
    required this.level,
    required this.text,
    required this.offset,
    List<_HeadingTree>? children,
  }) : children = children ?? [];
}