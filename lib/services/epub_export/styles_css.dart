// lib/services/epub_export/styles_css.dart
// EPUB 导出 — 基础排版样式（内联字符串常量）
// 依据：第五轮方案 v6 §5.4

const String kEpubStylesCss = '''
body {
  font-family: -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif;
  line-height: 1.8;
  margin: 1em;
  color: #333;
}
h1, h2, h3, h4, h5, h6 {
  line-height: 1.4;
  margin-top: 1.5em;
  margin-bottom: 0.6em;
}
h1.chapter-title {
  font-size: 1.6em;
  text-align: center;
  margin-top: 2em;
  margin-bottom: 1.5em;
  border-bottom: 1px solid #ccc;
  padding-bottom: 0.5em;
}
p { margin: 0.8em 0; text-indent: 0; }
ul, ol { padding-left: 1.6em; margin: 0.8em 0; }
blockquote {
  margin: 1em 1.5em;
  padding-left: 1em;
  border-left: 3px solid #ccc;
  color: #666;
}
pre, code {
  font-family: "SF Mono", Consolas, monospace;
  background: #f5f5f5;
  border-radius: 4px;
}
pre { padding: 0.8em; overflow-x: auto; }
table { border-collapse: collapse; margin: 1em 0; }
th, td { border: 1px solid #ccc; padding: 0.4em 0.8em; }
img { max-width: 100%; height: auto; }
hr { border: none; border-top: 1px solid #ccc; margin: 1.5em 0; }
''';