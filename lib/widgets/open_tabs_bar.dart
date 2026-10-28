// lib/widgets/open_tabs_bar.dart
// 笔记标签条 —— 已开笔记切换
// v2.1：动态吸顶 + 边界回退（方案 C）
//   - 标签少：+ 紧跟最后一个标签，返回在最右，中间留白
//   - 标签多：+ 吸顶（在 onBack 左侧）
//   - 宽度测量考虑 textScaler
import 'package:flutter/material.dart';
import '../services/open_tabs_manager.dart';

class OpenTabsBar extends StatefulWidget {
  final VoidCallback? onTabTap;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;

  const OpenTabsBar({super.key, this.onTabTap, this.onBack, this.onAdd});

  @override
  State<OpenTabsBar> createState() => _OpenTabsBarState();
}

class _OpenTabsBarState extends State<OpenTabsBar> {
  final ScrollController _scrollCtrl = ScrollController();

  static const double _tabH = 12.0;
  static const double _tabGap = 6.0;
  static const double _closeIconW = 14.0;
  static const double _plusBtnW = 48.0;
  static const double _backBtnW = 48.0;
  static const double _tabMaxTextW = 160.0;

  static const TextStyle _tabTextStyle = TextStyle(fontSize: 13);

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  double _measureTabsWidth(List<OpenTab> tabs, TextScaler scaler, TextDirection dir) {
    double total = 0;
    for (final t in tabs) {
      final tp = TextPainter(
        text: TextSpan(text: t.title, style: _tabTextStyle),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final textW = tp.width > _tabMaxTextW ? _tabMaxTextW : tp.width;
      tp.dispose();
      total += _tabH * 2 + textW + _tabGap + _closeIconW;
    }
    return total;
  }

  Widget _buildTab(OpenTab tab, bool isActive) {
    return GestureDetector(
      onTap: () {
        widget.onTabTap?.call();
        OpenTabsManager.instance.activate(tab.noteId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: _tabH),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : null,
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _tabMaxTextW),
              child: Text(
                tab.title,
                style: _tabTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: _tabGap),
            InkWell(
              onTap: () => OpenTabsManager.instance.close(tab.noteId),
              child: const Icon(Icons.close, size: _closeIconW),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlus() {
    if (widget.onAdd == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: const Icon(Icons.add, size: 20),
        tooltip: '新建笔记',
        onPressed: widget.onAdd,
      ),
    );
  }

  Widget _buildBack() {
    if (widget.onBack == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        tooltip: '返回智库',
        onPressed: widget.onBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OpenTab>>(
      valueListenable: OpenTabsManager.tabs,
      builder: (context, tabs, _) {
        if (tabs.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          bottom: false,
          child: Container(
            height: 40,
            color: Colors.grey.shade100,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final scaler = MediaQuery.textScalerOf(ctx);
                final dir = Directionality.of(ctx);
                final contentW = _measureTabsWidth(tabs, scaler, dir);
                final plusW = widget.onAdd != null ? _plusBtnW : 0.0;
                final backW = widget.onBack != null ? _backBtnW : 0.0;
                final available = constraints.maxWidth - plusW - backW;

                final fitsInline = contentW <= available;

                if (fitsInline) {
                  // 分支 1：不溢出 —— 标签组 + [+][Spacer][←]
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(0);
                  }
                  return Row(
                    children: [
                      SizedBox(
                        width: contentW,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tabs.length,
                          itemBuilder: (ctx, i) {
                            final tab = tabs[i];
                            return ValueListenableBuilder<String?>(
                              valueListenable: OpenTabsManager.activeTabId,
                              builder: (ctx, activeId, _) {
                                return _buildTab(tab, activeId == tab.noteId);
                              },
                            );
                          },
                        ),
                      ),
                      _buildPlus(),
                      const Spacer(),
                      _buildBack(),
                    ],
                  );
                }

                // 分支 2：溢出 —— Expanded + 吸顶
                return Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollCtrl,
                        itemCount: tabs.length,
                        itemBuilder: (ctx, i) {
                          final tab = tabs[i];
                          return ValueListenableBuilder<String?>(
                            valueListenable: OpenTabsManager.activeTabId,
                            builder: (ctx, activeId, _) {
                              return _buildTab(tab, activeId == tab.noteId);
                            },
                          );
                        },
                      ),
                    ),
                    _buildPlus(),
                    _buildBack(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}