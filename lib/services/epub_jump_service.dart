// lib/services/epub_jump_service.dart
import '../models/book_note.dart';
import 'reader_jump_service.dart';

class EpubJumpService implements ReaderJumpService {
  // 延迟取值：实际执行时取最新 _mainController，不在 initState 绑定 null。
  final Future<dynamic> Function(String js) runJs;
  EpubJumpService({required this.runJs});

  @override
  Future<void> jumpToText(String text) async {
    final safe = Uri.encodeComponent(text);
    await runJs(_jsFindAndScroll(safe));
  }

  @override
  Future<void> jumpToScroll(int top) async {
    final js = '(function(){var top=$top;var max=Math.max(0,document.body.scrollHeight-window.innerHeight);top=Math.max(0,Math.min(top,max));window.scrollTo({top:top,behavior:"smooth"});})();';
    await runJs(js);
  }

  @override
  Future<void> jumpToNote(BookNote note) async {
    final loc = note.location ?? '';
    final parsed = _parseLocation(loc);
    if (parsed.top > 0) {
      await jumpToScroll(parsed.top);
    } else {
      await jumpToText(note.selectedText);
    }
  }

  // location 格式：type|page:N|top:M，type 预留 pdf/txt
  // 例：epub|page:3|top:500；旧格式 page:N 回退 top=0。
  _JumpLoc _parseLocation(String loc) {
    final m = RegExp(r'^(epub|pdf|txt)\|page:(\d+)\|top:(\d+)$').firstMatch(loc);
    if (m != null) {
      return _JumpLoc(m.group(1)!, int.parse(m.group(2)!), int.parse(m.group(3)!));
    }
    final old = RegExp(r'^page:(\d+)$').firstMatch(loc);
    if (old != null) {
      return _JumpLoc('epub', int.parse(old.group(1)!), 0);
    }
    return _JumpLoc('epub', 0, 0);
  }

  String _jsFindAndScroll(String encoded) {
    return '''
(function(){
  var text = decodeURIComponent('$encoded');
  var target = null;
  var nodes = document.querySelectorAll('a[data-id]');
  for (var i=0;i<nodes.length;i++){
    if (nodes[i].textContent.indexOf(text) !== -1) { target = nodes[i]; break; }
  }
  if (!target) {
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) {
      if (walker.currentNode.data.indexOf(text) !== -1) { target = walker.currentNode.parentElement; break; }
    }
  }
  if (!target) { console.log('DEBUG jump 失锚: ' + text); return; }
  target.scrollIntoView({behavior: 'smooth', block: 'center'});
  target.classList.add('flash-target');
  setTimeout(function(){ target.classList.remove('flash-target'); }, 2000);
})();
''';
  }
}

class _JumpLoc {
  final String type;
  final int page;
  final int top;
  _JumpLoc(this.type, this.page, this.top);
}