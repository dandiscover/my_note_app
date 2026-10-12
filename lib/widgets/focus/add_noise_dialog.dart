// lib/widgets/focus/add_noise_dialog.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/white_noise_service.dart';

class AddNoiseDialog extends StatefulWidget {
  const AddNoiseDialog({super.key});

  @override
  State<AddNoiseDialog> createState() => _AddNoiseDialogState();
}

class _AddNoiseDialogState extends State<AddNoiseDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _addFromUrl() async {
    if (_nameCtrl.text.trim().isEmpty || _urlCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final path = await WhiteNoiseService()
          .addFromUrl(_nameCtrl.text.trim(), _urlCtrl.text.trim());
      if (!mounted) return;
      Navigator.pop(context, {
        'name': _nameCtrl.text.trim(),
        'path': path,
        'type': 'url',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFromFile() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg'],
    );
    if (f == null) return;
    final name = _nameCtrl.text.trim().isEmpty
        ? f.name.replaceAll(RegExp(r'\.[^.]+$'), '')
        : _nameCtrl.text.trim();
    setState(() => _busy = true);
    try {
      final path = await WhiteNoiseService().addFromFile(name, f.path!);
      if (!mounted) return;
      Navigator.pop(context, {
        'name': name,
        'path': path,
        'type': 'file',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加音源'),
      content: SizedBox(
        width: 400,
        height: 240,
        child: Column(
          children: [
            TabBar(
              controller: _tab,
              tabs: const [Tab(text: '从链接'), Tab(text: '从文件')],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [_tab1Url(), _tab2File()],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _tab1Url() {
    return Column(
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: '名称', isDense: true),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlCtrl,
          decoration: const InputDecoration(labelText: 'URL', isDense: true),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy ? null : _addFromUrl,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('下载'),
        ),
      ],
    );
  }

  Widget _tab2File() {
    return Column(
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
              labelText: '名称（可空）', isDense: true),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy ? null : _addFromFile,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('选择文件'),
        ),
      ],
    );
  }
}