// lib/widgets/weread/weread_key_guide_dialog.dart
// 微信读书 Key 引导页——首次导入 / 重填 共用
import 'package:flutter/material.dart';
import '../../services/weread_service.dart';
import '../../services/weread_key_store.dart';

class WereadKeyGuideDialog extends StatefulWidget {
  const WereadKeyGuideDialog({super.key});

  @override
  State<WereadKeyGuideDialog> createState() => _WereadKeyGuideDialogState();
}

class _WereadKeyGuideDialogState extends State<WereadKeyGuideDialog> {
  final _ctrl = TextEditingController();
  final _store = WereadKeyStore();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = _ctrl.text.trim();
    if (v.isEmpty || !v.startsWith('wrk-')) {
      setState(() => _error = 'Key 格式不对（应以 wrk- 开头）');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final probe = WereadService(injectedKey: v);
    try {
      await probe.fetchShelf();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Key 校验失败：$e';
      });
      return;
    }
    await _store.save(v);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('配置微信读书 API Key'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. 打开微信读书 App\n'
              '2. 进入「微信读书 Skill」页\n'
              '3. 点「获取 API Key」复制',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'wrk-xxxxxxxxxxxx',
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '校验中…' : '保存'),
        ),
      ],
    );
  }
}