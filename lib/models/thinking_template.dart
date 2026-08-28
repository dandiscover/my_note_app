// lib/models/thinking_template.dart
enum TemplateType {
  think,    // 构思
  write,    // 写作
  fiveW,    // 5W1H
  swot,     // SWOT
  extend,   // 延伸思考
}

class ThinkingTemplate {
  final TemplateType type;
  final String name;
  final String icon;
  final String description;
  final List<String> questions; // 问题列表

  ThinkingTemplate({
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    required this.questions,
  });

  // 预设模板
  static List<ThinkingTemplate> get all => [
    ThinkingTemplate(
      type: TemplateType.think,
      name: '构思模板',
      icon: '🧠',
      description: '问题 · 依据 · 结论',
      questions: [
        '① 我想搞清楚什么？',
        '② 我已经知道什么？',
        '③ 所以，我的结论是？',
      ],
    ),
    ThinkingTemplate(
      type: TemplateType.write,
      name: '写作模板',
      icon: '📝',
      description: '提问 · 动机 · 结构 · 解决',
      questions: [
        '① 读者的问题是什么？',
        '② 我的动机是什么？',
        '③ 文章结构如何？',
        '④ 如何解决问题？',
      ],
    ),
    ThinkingTemplate(
      type: TemplateType.fiveW,
      name: '5W1H',
      icon: '🔍',
      description: '分析问题',
      questions: [
        '① Who（谁）？',
        '② What（什么）？',
        '③ When（何时）？',
        '④ Where（何地）？',
        '⑤ Why（为什么）？',
        '⑥ How（如何）？',
      ],
    ),
    ThinkingTemplate(
      type: TemplateType.swot,
      name: 'SWOT',
      icon: '⚖️',
      description: '决策分析',
      questions: [
        '① Strengths（优势）？',
        '② Weaknesses（劣势）？',
        '③ Opportunities（机会）？',
        '④ Threats（威胁）？',
      ],
    ),
    ThinkingTemplate(
      type: TemplateType.extend,
      name: '延伸思考',
      icon: '💡',
      description: '这让我想到什么',
      questions: [
        '① 这让我想到什么？',
        '② 我的联想/反思：',
      ],
    ),
  ];
}