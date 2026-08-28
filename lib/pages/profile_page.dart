import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:developer';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;
import '../services/settings_service.dart';
import '../models/user_settings.dart';
import '../services/keyboard_shortcut_manager.dart';
import '../models/keyboard_shortcut.dart';
import '../database_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final SettingsService _settings = SettingsService();
  final KeyboardShortcutManager _shortcutManager = KeyboardShortcutManager();
  final DatabaseService db = DatabaseService();
  UserSettings? _settingsData;
  bool _isLoading = true;
  List<KeyboardShortcut> _shortcuts = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _settings.load();
      await _shortcutManager.load();
      setState(() {
        _settingsData = settings;
        _shortcuts = _shortcutManager.all;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载设置失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_settingsData == null) return;
    await _settings.save(_settingsData!);
  }

  // ============================================================
  // 文件操作辅助
  // ============================================================

  void _downloadFile(String content, String fileName, String mimeType) {
    final blob = html.Blob([content], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _saveFileDesktop(String content, String fileName) async {
    final String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '保存文件',
      fileName: fileName,
    );
    if (outputFile != null) {
      final file = io.File(outputFile);
      await file.writeAsString(content);
    }
  }

  Future<String?> _pickFileDesktop() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return null;
    final fileBytes = result.files.first.bytes;
    return utf8.decode(fileBytes!);
  }

  Future<String?> _pickFileWeb() async {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();
    await input.onChange.first;
    if (input.files!.isEmpty) return null;
    final file = input.files!.first;
    // 使用 FileReader 替代 file.text() 避免类型问题
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    return reader.result as String?;
  }

  // ============================================================
  // 导出 / 导入
  // ============================================================

  Future<void> _exportJson() async {
    try {
      final jsonData = await db.exportAllData();
      final fileName = 'cloudbrain_backup_${DateTime.now().toIso8601String()}.json';
      if (kIsWeb) {
        _downloadFile(jsonData, fileName, 'application/json');
      } else {
        await _saveFileDesktop(jsonData, fileName);
      }
      _showSnackBar('✅ 导出成功');
    } catch (e) {
      _showSnackBar('❌ 导出失败：$e');
    }
  }

  Future<void> _importJson() async {
    try {
      String? jsonString;
      if (kIsWeb) {
        jsonString = await _pickFileWeb();
      } else {
        jsonString = await _pickFileDesktop();
      }
      if (jsonString == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ 导入确认'),
          content: const Text(
            '导入将**覆盖**当前所有数据（笔记、节点、图书、卡片、宠物、复习卡、快捷键、任务、子任务、用户设置）。\n\n'
            '此操作不可撤销，请确认已备份当前数据。',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('确认覆盖'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导入数据，请稍候...'),
              ],
            ),
          ),
        );

        await db.importAllData(jsonString);
        if (mounted) Navigator.pop(context);
        _showSnackBar('✅ 导入成功！请重启应用（或刷新页面）以生效。');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('❌ 导入失败：$e');
    }
  }

  Future<void> _exportMarkdown() async {
    try {
      final markdown = await db.exportNotesAsMarkdown();
      final fileName = 'cloudbrain_notes_${DateTime.now().toIso8601String()}.md';
      if (kIsWeb) {
        _downloadFile(markdown, fileName, 'text/markdown');
      } else {
        await _saveFileDesktop(markdown, fileName);
      }
      _showSnackBar('✅ Markdown 导出成功');
    } catch (e) {
      _showSnackBar('❌ 导出失败：$e');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('👤 我的'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('👤 我的'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: '资料'),
            Tab(icon: Icon(Icons.settings), text: '设置'),
            Tab(icon: Icon(Icons.keyboard), text: '快捷键'),
            Tab(icon: Icon(Icons.storage), text: '数据'),
            Tab(icon: Icon(Icons.share), text: '社交'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildSettingsTab(),
          _buildShortcutTab(),
          _buildDataTab(),
          _buildSocialTab(),
        ],
      ),
    );
  }

  // ============================================================
  // Tab 1：个人资料
  // ============================================================

  Widget _buildProfileTab() {
    final settings = _settingsData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('头像选择功能开发中...')),
              );
            },
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: settings.avatarUrl.isNotEmpty
                  ? null
                  : Text(
                      settings.nickname.substring(0, 1),
                      style: const TextStyle(fontSize: 32, color: Colors.blue),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '昵称',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '输入昵称',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  controller: TextEditingController(text: settings.nickname)
                    ..addListener(() {
                      setState(() {
                        _settingsData!.nickname = _settingsData!.nickname;
                      });
                    }),
                  onChanged: (value) {
                    _settingsData!.nickname = value;
                    _saveSettings();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '简介',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '一句话介绍自己',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  controller: TextEditingController(text: settings.bio)
                    ..addListener(() {
                      setState(() {
                        _settingsData!.bio = _settingsData!.bio;
                      });
                    }),
                  onChanged: (value) {
                    _settingsData!.bio = value;
                    _saveSettings();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📊 已积累 ${0} 条笔记，${0} 个标签',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Tab 2：设置（完整保留）
  // ============================================================

  Widget _buildSettingsTab() {
    final settings = _settingsData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingSection(
            title: '🎨 外观',
            children: [
              ListTile(
                title: const Text('主题模式'),
                subtitle: const Text('切换亮色/暗色/跟随系统'),
                trailing: DropdownButton<ThemeModePreference>(
                  value: settings.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeModePreference.light,
                      child: Text('亮色'),
                    ),
                    DropdownMenuItem(
                      value: ThemeModePreference.dark,
                      child: Text('暗色'),
                    ),
                    DropdownMenuItem(
                      value: ThemeModePreference.system,
                      child: Text('跟随系统'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _settingsData!.themeMode = value;
                      });
                      await _saveSettings();
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(),

          _buildSettingSection(
            title: '✍️ 编辑器',
            children: [
              SwitchListTile(
                title: const Text('默认使用 Markdown'),
                subtitle: const Text('新笔记默认开启 Markdown 模式'),
                value: settings.defaultMarkdown,
                onChanged: (value) async {
                  setState(() {
                    _settingsData!.defaultMarkdown = value;
                  });
                  await _saveSettings();
                },
              ),
            ],
          ),
          const Divider(),

          _buildSettingSection(
            title: '🧠 复习设置',
            children: [
              ListTile(
                title: const Text('每日提醒时间'),
                subtitle: const Text('设置每日复习提醒的时间'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: settings.reviewReminderHour,
                      underline: const SizedBox.shrink(),
                      items: List.generate(24, (i) => i).map((h) {
                        return DropdownMenuItem(
                          value: h,
                          child: Text('${h.toString().padLeft(2, '0')}:${settings.reviewReminderMinute.toString().padLeft(2, '0')}'),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() {
                            _settingsData!.reviewReminderHour = value;
                          });
                          await _saveSettings();
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    DropdownButton<int>(
                      value: settings.reviewReminderMinute,
                      underline: const SizedBox.shrink(),
                      items: [0, 15, 30, 45].map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m.toString().padLeft(2, '0')),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() {
                            _settingsData!.reviewReminderMinute = value;
                          });
                          await _saveSettings();
                        }
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('每日复习上限'),
                subtitle: const Text('每天最多复习的卡片数'),
                trailing: DropdownButton<int>(
                  value: settings.dailyReviewLimit,
                  underline: const SizedBox.shrink(),
                  items: [5, 10, 15, 20, 30, 50].map((limit) {
                    return DropdownMenuItem(
                      value: limit,
                      child: Text('$limit 张'),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _settingsData!.dailyReviewLimit = value;
                      });
                      await _saveSettings();
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('间隔因子'),
                subtitle: const Text('SM-2 算法参数 (1.0-3.0)'),
                trailing: SizedBox(
                  width: 80,
                  child: Slider(
                    value: settings.reviewFactor,
                    min: 1.0,
                    max: 3.0,
                    divisions: 10,
                    label: settings.reviewFactor.toStringAsFixed(1),
                    onChanged: (value) async {
                      setState(() {
                        _settingsData!.reviewFactor = value;
                      });
                      await _saveSettings();
                    },
                  ),
                ),
              ),
            ],
          ),
          const Divider(),

          _buildSettingSection(
            title: '📊 热力图设置',
            children: [
              ListTile(
                title: const Text('统计模式'),
                subtitle: const Text('选择热力图的统计维度'),
                trailing: DropdownButton<HeatmapStatMode>(
                  value: settings.heatmapStatMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: HeatmapStatMode.count,
                      child: Text('📝 按笔记数'),
                    ),
                    DropdownMenuItem(
                      value: HeatmapStatMode.words,
                      child: Text('📄 按总字数'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _settingsData!.heatmapStatMode = value;
                      });
                      await _saveSettings();
                    }
                  },
                ),
              ),
              ListTile(
                title: Text(
                  settings.heatmapStatMode == HeatmapStatMode.words
                      ? '高产字数阈值'
                      : '高产条数阈值',
                ),
                subtitle: Text(
                  settings.heatmapStatMode == HeatmapStatMode.words
                      ? '每日 ≥ ${settings.heatmapWordHighThreshold} 字显示金色'
                      : '每日 ≥ ${settings.heatmapHighThreshold} 条显示金色',
                ),
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: (settings.heatmapStatMode == HeatmapStatMode.words
                        ? settings.heatmapWordHighThreshold
                        : settings.heatmapHighThreshold).toDouble(),
                    min: settings.heatmapStatMode == HeatmapStatMode.words ? 50 : 1,
                    max: settings.heatmapStatMode == HeatmapStatMode.words ? 5000 : 20,
                    divisions: settings.heatmapStatMode == HeatmapStatMode.words ? 50 : 19,
                    label: settings.heatmapStatMode == HeatmapStatMode.words
                        ? '${settings.heatmapWordHighThreshold} 字'
                        : '${settings.heatmapHighThreshold} 条',
                    onChanged: (value) async {
                      setState(() {
                        if (settings.heatmapStatMode == HeatmapStatMode.words) {
                          _settingsData!.heatmapWordHighThreshold = value.round();
                        } else {
                          _settingsData!.heatmapHighThreshold = value.round();
                        }
                      });
                      await _saveSettings();
                    },
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  settings.heatmapStatMode == HeatmapStatMode.words
                      ? '爆发字数阈值'
                      : '爆发条数阈值',
                ),
                subtitle: Text(
                  settings.heatmapStatMode == HeatmapStatMode.words
                      ? '每日 ≥ ${settings.heatmapWordBurstThreshold} 字显示红色'
                      : '每日 ≥ ${settings.heatmapBurstThreshold} 条显示红色',
                ),
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: (settings.heatmapStatMode == HeatmapStatMode.words
                        ? settings.heatmapWordBurstThreshold
                        : settings.heatmapBurstThreshold).toDouble(),
                    min: settings.heatmapStatMode == HeatmapStatMode.words ? 100 : 2,
                    max: settings.heatmapStatMode == HeatmapStatMode.words ? 10000 : 30,
                    divisions: settings.heatmapStatMode == HeatmapStatMode.words ? 50 : 28,
                    label: settings.heatmapStatMode == HeatmapStatMode.words
                        ? '${settings.heatmapWordBurstThreshold} 字'
                        : '${settings.heatmapBurstThreshold} 条',
                    onChanged: (value) async {
                      setState(() {
                        if (settings.heatmapStatMode == HeatmapStatMode.words) {
                          _settingsData!.heatmapWordBurstThreshold = value.round();
                        } else {
                          _settingsData!.heatmapBurstThreshold = value.round();
                        }
                      });
                      await _saveSettings();
                    },
                  ),
                ),
              ),
              ListTile(
                title: const Text('颜色方案'),
                subtitle: const Text('选择热力图的颜色主题'),
                trailing: DropdownButton<HeatmapColorScheme>(
                  value: settings.heatmapColorScheme,
                  underline: const SizedBox.shrink(),
                  items: HeatmapColorScheme.values.map((scheme) {
                    return DropdownMenuItem(
                      value: scheme,
                      child: Text(settings.getColorSchemeName(scheme)),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _settingsData!.heatmapColorScheme = value;
                        if (value != HeatmapColorScheme.custom) {
                          final colors = settings.getHeatmapColors();
                          _settingsData!.heatmapColorLow = _colorToHex(colors[0]);
                          _settingsData!.heatmapColorMid = _colorToHex(colors[1]);
                          _settingsData!.heatmapColorHigh = _colorToHex(colors[2]);
                          _settingsData!.heatmapColorBurst = _colorToHex(colors[3]);
                        }
                      });
                      await _saveSettings();
                    }
                  },
                ),
              ),
              if (settings.heatmapColorScheme == HeatmapColorScheme.custom) ...[
                _buildColorPickerTile(
                  title: '低产颜色',
                  color: settings.heatmapColorLow,
                  onColorSelected: (hex) async {
                    setState(() {
                      _settingsData!.heatmapColorLow = hex;
                    });
                    await _saveSettings();
                  },
                ),
                _buildColorPickerTile(
                  title: '中产颜色',
                  color: settings.heatmapColorMid,
                  onColorSelected: (hex) async {
                    setState(() {
                      _settingsData!.heatmapColorMid = hex;
                    });
                    await _saveSettings();
                  },
                ),
                _buildColorPickerTile(
                  title: '高产颜色',
                  color: settings.heatmapColorHigh,
                  onColorSelected: (hex) async {
                    setState(() {
                      _settingsData!.heatmapColorHigh = hex;
                    });
                    await _saveSettings();
                  },
                ),
                _buildColorPickerTile(
                  title: '爆发颜色',
                  color: settings.heatmapColorBurst,
                  onColorSelected: (hex) async {
                    setState(() {
                      _settingsData!.heatmapColorBurst = hex;
                    });
                    await _saveSettings();
                  },
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '颜色预览',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildColorPreview(settings.heatmapColorLow, '低'),
                        _buildColorPreview(settings.heatmapColorMid, '中'),
                        _buildColorPreview(settings.heatmapColorHigh, '高'),
                        _buildColorPreview(settings.heatmapColorBurst, '爆发'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '当前模式: ${settings.statModeLabel}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),

          _buildSettingSection(
            title: '🐾 宠物',
            children: [
              SwitchListTile(
                title: const Text('显示宠物'),
                subtitle: const Text('在应用界面显示桌面宠物'),
                value: settings.showPet,
                onChanged: (value) async {
                  setState(() {
                    _settingsData!.showPet = value;
                  });
                  await _saveSettings();
                },
              ),
              ListTile(
                title: const Text('宠物皮肤'),
                subtitle: const Text('选择宠物的外观'),
                trailing: DropdownButton<String>(
                  value: settings.petSkin,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('🐱 默认小猫')),
                    DropdownMenuItem(value: 'robot', child: Text('🤖 机器人')),
                    DropdownMenuItem(value: 'dragon', child: Text('🐉 小龙')),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _settingsData!.petSkin = value;
                      });
                      await _saveSettings();
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('宠物名字'),
                subtitle: const Text('给你的宠物起个名字'),
                trailing: SizedBox(
                  width: 120,
                  child: TextField(
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '输入名字',
                    ),
                    controller: TextEditingController(text: settings.petName)
                      ..addListener(() {
                        setState(() {
                          _settingsData!.petName = _settingsData!.petName;
                        });
                      }),
                    onChanged: (value) async {
                      _settingsData!.petName = value;
                      await _saveSettings();
                    },
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('专注模式显示'),
                subtitle: const Text('专注时宠物出现在界面'),
                value: settings.petInFocusMode,
                onChanged: (value) async {
                  setState(() {
                    _settingsData!.petInFocusMode = value;
                  });
                  await _saveSettings();
                },
              ),
            ],
          ),
          const Divider(),

          _buildSettingSection(
            title: '🔌 插件（开发中）',
            children: [
              const ListTile(
                title: Text('插件管理'),
                subtitle: Text('暂无可用插件'),
                trailing: Text('即将上线', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================
  // Tab 3：快捷键
  // ============================================================

  Widget _buildShortcutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '点击快捷键可自定义修改，冲突时会提示',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._shortcuts.map((shortcut) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              title: Text(
                shortcut.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                shortcut.description,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  shortcut.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              onTap: () => _showShortcutEditor(shortcut),
            ),
          )).toList(),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () async {
                await _shortcutManager.reset();
                setState(() {
                  _shortcuts = _shortcutManager.all;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 已重置为默认快捷键'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text('🔄 重置为默认'),
            ),
          ),
        ],
      ),
    );
  }

  void _showShortcutEditor(KeyboardShortcut shortcut) async {
    final current = shortcut.displayName;
    final controller = TextEditingController(text: current);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修改 "${shortcut.name}" 快捷键'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('输入新的快捷键组合，例如：'),
            const SizedBox(height: 4),
            const Text(
              'Ctrl+S, Ctrl+Shift+Z, Alt+E',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ctrl+S',
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != current) {
      try {
        final newShortcut = KeyboardShortcut.fromDisplayName(result);
        if (newShortcut == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 无效的快捷键格式'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        await _shortcutManager.update(shortcut.id, newShortcut);
        await _shortcutManager.load();
        setState(() {
          _shortcuts = _shortcutManager.all;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 已更新 "${shortcut.name}" 快捷键'),
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ============================================================
  // Tab 4：数据管理
  // ============================================================

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDataCard(
            icon: Icons.upload_file,
            title: '📤 导出 JSON 备份',
            subtitle: '导出全部数据（笔记、节点、图书、卡片、宠物、复习卡、快捷键、任务、设置）',
            buttonText: '导出',
            color: Colors.blue,
            onTap: _exportJson,
          ),
          const SizedBox(height: 12),
          _buildDataCard(
            icon: Icons.download,
            title: '📥 导入 JSON 恢复',
            subtitle: '从备份文件恢复数据（⚠️ 覆盖当前所有数据）',
            buttonText: '导入',
            color: Colors.green,
            onTap: _importJson,
          ),
          const SizedBox(height: 12),
          _buildDataCard(
            icon: Icons.text_snippet,
            title: '📄 导出 Markdown',
            subtitle: '将所有笔记导出为单个 Markdown 文件',
            buttonText: '导出',
            color: Colors.orange,
            onTap: _exportMarkdown,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '数据存储在本地，导出备份可防止数据丢失。导入将覆盖所有现有数据，请谨慎操作。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            foregroundColor: color,
          ),
          child: Text(buttonText),
        ),
      ),
    );
  }

  // ============================================================
  // Tab 5：社交
  // ============================================================

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.people_outline, size: 48, color: Colors.blue),
                const SizedBox(height: 12),
                const Text(
                  '🌐 社交功能开发中',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '分享知识库、关联账号、社区互动',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  '即将上线',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSocialCard(
            icon: Icons.share,
            title: '分享知识库',
            subtitle: '生成公开链接分享你的知识',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享功能开发中...')),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSocialCard(
            icon: Icons.link,
            title: '关联账号',
            subtitle: '绑定社交账号同步数据',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('关联功能开发中...')),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSocialCard(
            icon: Icons.groups,
            title: '社区',
            subtitle: '查看他人的公开知识库',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('社区功能开发中...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 16),
        onTap: onTap,
      ),
    );
  }



  Widget _buildColorPickerTile({
    required String title,
    required String color,
    required Function(String) onColorSelected,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: GestureDetector(
        onTap: () => _showColorPicker(context, color, onColorSelected),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hexToColor(color),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview(String hex, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context, String currentColor, Function(String) onSelected) async {
    final colors = [
      '#E8F5E9', '#C8E6C9', '#81C784', '#4CAF50', '#2E7D32',
      '#E3F2FD', '#90CAF9', '#42A5F5', '#1565C0',
      '#FFF3E0', '#FFB74D', '#FFA726', '#EF6C00',
      '#FCE4EC', '#F48FB1', '#EC407A', '#AD1457',
      '#E8EAF6', '#9FA8DA', '#5C6BC0', '#283593',
      '#FFF8E1', '#FFD54F', '#FFC107', '#FF6F00',
      '#FBE9E7', '#FF8A65', '#FF5722', '#BF360C',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择颜色',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((hex) {
                    final isSelected = hex == currentColor;
                    return GestureDetector(
                      onTap: () {
                        onSelected(hex);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(hex),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7 || hex.length == 9) {
      buffer.write(hex.replaceFirst('#', ''));
    } else {
      return Colors.grey.shade300;
    }
    return Color(int.parse(buffer.toString(), radix: 16) + (hex.length == 7 ? 0xFF000000 : 0));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}