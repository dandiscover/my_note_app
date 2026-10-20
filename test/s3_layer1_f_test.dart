@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/utils/app_date_utils.dart';

void main() {
  group('L1-8 日期解析（AppDateUtils.tryParse）', () {
    test('null 输入 → null', () {
      expect(AppDateUtils.tryParse(null), isNull);
    });

    test('空串 → null', () {
      expect(AppDateUtils.tryParse(''), isNull);
    });

    test('非法格式 → null', () {
      expect(AppDateUtils.tryParse('not a date'), isNull);
      expect(AppDateUtils.tryParse('invalid-date-str'), isNull);
      expect(AppDateUtils.tryParse('abc-123'), isNull);
      expect(AppDateUtils.tryParse('   '), isNull,
          reason: '仅空格不触发 isEmpty，走 DateTime.parse 抛异常 → null');
    });

    test('无 Z 后缀 → isUtc==false，字段值与入参一致', () {
      final dt = AppDateUtils.tryParse('2026-10-19T12:34:56.789');
      expect(dt, isNotNull);
      expect(dt!.isUtc, isFalse, reason: 'Dart DateTime.parse 对无 Z 后缀返回本地 DateTime');
      expect(dt.year, 2026);
      expect(dt.month, 10);
      expect(dt.day, 19);
      expect(dt.hour, 12);
      expect(dt.minute, 34);
      expect(dt.second, 56);
      expect(dt.millisecond, 789);
    });

    test('带 Z 后缀 → isUtc==true，字段值按 UTC 保留', () {
      final dt = AppDateUtils.tryParse('2026-10-19T12:34:56.789Z');
      expect(dt, isNotNull);
      expect(dt!.isUtc, isTrue, reason: 'Dart DateTime.parse 对 Z 后缀返回 UTC DateTime');
      expect(dt.year, 2026);
      expect(dt.month, 10);
      expect(dt.day, 19);
      expect(dt.hour, 12);
      expect(dt.minute, 34);
    });

    test('带时区偏移 +08:00 → isUtc==true，转 UTC 后 hour=4', () {
      final dt = AppDateUtils.tryParse('2026-10-19T12:34:56+08:00');
      expect(dt, isNotNull);
      expect(dt!.isUtc, isTrue, reason: 'Dart DateTime.parse 对带时区偏移返回 UTC DateTime');
      expect(dt.hour, 4, reason: '12:34 +08:00 = 04:34 UTC');
      expect(dt.minute, 34);
    });

    test('仅日期（无时分秒）→ 解析成功，时分秒为 0，isUtc==false', () {
      final dt = AppDateUtils.tryParse('2026-10-19');
      expect(dt, isNotNull);
      expect(dt!.isUtc, isFalse);
      expect(dt.year, 2026);
      expect(dt.month, 10);
      expect(dt.day, 19);
      expect(dt.hour, 0);
      expect(dt.minute, 0);
      expect(dt.second, 0);
    });
  });
}