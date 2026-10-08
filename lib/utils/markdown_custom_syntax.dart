// lib/utils/markdown_custom_syntax.dart
// R-1b：<span style='color/background'> 渲染端

import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';

md.ExtensionSet buildMarkdownExtensionSet() {
  return md.ExtensionSet(
    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    [
      _StyledSpanSyntax(),
      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
    ],
  );
}

Map<String, MarkdownElementBuilder> buildMarkdownBuilders() {
  return {
    'styledspan': _StyledSpanBuilder(),
  };
}

class _StyledSpanSyntax extends md.InlineSyntax {
  _StyledSpanSyntax()
      : super(
          r'''<span\s+style\s*=\s*["']([^"']+)["']\s*>(.*?)</span>''',
          caseSensitive: false,
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final style = match.group(1)!;
    final text = match.group(2)!;
    final el = md.Element.text('styledspan', text);
    el.attributes['style'] = style;
    parser.addNode(el);
    return true;
  }
}

class _StyledSpanBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final styleStr = element.attributes['style'] ?? '';
    var base = preferredStyle ?? parentStyle ?? const TextStyle();
    for (final prop in styleStr.split(';')) {
      final p = prop.trim();
      if (p.isEmpty) continue;
      final idx = p.indexOf(':');
      if (idx < 0) continue;
      final k = p.substring(0, idx).trim().toLowerCase();
      final v = p.substring(idx + 1).trim();
      if (k == 'color') {
        final c = _parseColor(v);
        if (c != null) base = base.copyWith(color: c);
      } else if (k == 'background') {
        final c = _parseColor(v);
        if (c != null) base = base.copyWith(backgroundColor: c);
      }
    }
    final span = _inlineToSpan(element.textContent, base);
    return Text.rich(span);
  }
}

InlineSpan _inlineToSpan(String text, TextStyle base) {
  if (text.isEmpty) return TextSpan(text: '', style: base);

  final children = <InlineSpan>[];
  int i = 0;
  final buf = StringBuffer();

  void flush() {
    if (buf.isNotEmpty) {
      children.add(TextSpan(text: buf.toString(), style: base));
      buf.clear();
    }
  }

  while (i < text.length) {
    if (text[i] == '`') {
      final end = text.indexOf('`', i + 1);
      if (end > i) {
        flush();
        children.add(TextSpan(
          text: text.substring(i + 1, end),
          style: base.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.shade100,
          ),
        ));
        i = end + 1;
        continue;
      }
    }
    if (i + 1 < text.length && text[i] == '*' && text[i + 1] == '*') {
      final end = text.indexOf('**', i + 2);
      if (end > i) {
        flush();
        children.add(TextSpan(
          text: text.substring(i + 2, end),
          style: base.copyWith(fontWeight: FontWeight.bold),
        ));
        i = end + 2;
        continue;
      }
    }
    if (text[i] == '*') {
      final end = text.indexOf('*', i + 1);
      if (end > i) {
        flush();
        children.add(TextSpan(
          text: text.substring(i + 1, end),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
        i = end + 1;
        continue;
      }
    }
    buf.write(text[i]);
    i++;
  }
  flush();

  if (children.isEmpty) return TextSpan(text: text, style: base);
  return TextSpan(children: children, style: base);
}

Color? _parseColor(String raw) {
  var s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;

  const named = {
    'red': 0xFFFF0000,
    'teal': 0xFF008080,
    'yellow': 0xFFFFFF00,
    'maroon': 0xFF800000,
    'tan': 0xFFD2B48C,
    'gray': 0xFF808080,
    'grey': 0xFF808080,
    'silver': 0xFFC0C0C0,
    'blue': 0xFF0000FF,
    'green': 0xFF008000,
    'orange': 0xFFFFA500,
    'purple': 0xFF800080,
  };
  if (named.containsKey(s)) return Color(named[s]!);

  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) {
    s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
  }
  if (s.length != 6) return null;
  try {
    return Color(0xFF000000 | int.parse(s, radix: 16));
  } catch (_) {
    return null;
  }
}