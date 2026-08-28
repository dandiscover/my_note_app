import 'package:flutter/material.dart';

class ImportDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('⚠️ 导入确认'),
      content: Text(
        '导入将**覆盖**当前所有数据（笔记、任务、卡片、宠物等），此操作不可撤销。\n\n'
        '请确认您已备份当前数据，或确定要覆盖？',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('确认覆盖'),
        ),
      ],
    );
  }
}