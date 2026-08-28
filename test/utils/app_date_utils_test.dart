// test/utils/app_date_utils_test.dart
// AppDateUtils 单元测试

import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/utils/app_date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('formatShort 应返回简短日期格式', () {
      final date = DateTime(2026, 8, 28, 14, 30);
      final result = AppDateUtils.formatShort(date);
      // 预期: "8/28 14:30"
      expect(result, '8/28 14:30');
    });

    test('formatFull 应返回完整日期时间', () {
      final date = DateTime(2026, 8, 28, 14, 30, 45);
      final result = AppDateUtils.formatFull(date);
      // 预期: "2026-08-28 14:30:45"
      expect(result, '2026-08-28 14:30:45');
    });

    // ✅ 使用 formatDateOnly（方案一）或 formatShort（方案二）
    test('formatDateOnly 应返回纯日期', () {
      final date = DateTime(2026, 8, 28);
      final result = AppDateUtils.formatDateOnly(date);
      expect(result, '2026-08-28');
    });

    test('formatRelative 应返回相对时间', () {
      final now = DateTime.now();

      // 刚刚
      final justNow = now.subtract(Duration(seconds: 10));
      expect(AppDateUtils.formatRelative(justNow), '刚刚');

      // 5分钟前
      final fiveMinAgo = now.subtract(Duration(minutes: 5));
      expect(AppDateUtils.formatRelative(fiveMinAgo), '5分钟前');

      // 2小时前
      final twoHourAgo = now.subtract(Duration(hours: 2));
      expect(AppDateUtils.formatRelative(twoHourAgo), '2小时前');

      // 3天前
      final threeDayAgo = now.subtract(Duration(days: 3));
      expect(AppDateUtils.formatRelative(threeDayAgo), '3天前');

      // 2周前
      final twoWeekAgo = now.subtract(Duration(days: 14));
      expect(AppDateUtils.formatRelative(twoWeekAgo), '2周前');

      // 2月前
      final twoMonthAgo = now.subtract(Duration(days: 60));
      expect(AppDateUtils.formatRelative(twoMonthAgo), '2月前');

      // 1年前
      final oneYearAgo = now.subtract(Duration(days: 365));
      expect(AppDateUtils.formatRelative(oneYearAgo), '1年前');
    });

    // ✅ 新增：测试 isSameDay
    test('isSameDay 应正确判断同一天', () {
      final date1 = DateTime(2026, 8, 28, 10, 0);
      final date2 = DateTime(2026, 8, 28, 23, 59);
      final date3 = DateTime(2026, 8, 29, 0, 0);

      expect(AppDateUtils.isSameDay(date1, date2), true);
      expect(AppDateUtils.isSameDay(date1, date3), false);
    });

    // ✅ 新增：测试 startOfDay
    test('startOfDay 应返回当天开始时间', () {
      final date = DateTime(2026, 8, 28, 14, 30, 45);
      final result = AppDateUtils.startOfDay(date);
      expect(result, DateTime(2026, 8, 28, 0, 0, 0));
    });

    // ✅ 新增：测试 endOfDay
    test('endOfDay 应返回当天结束时间', () {
      final date = DateTime(2026, 8, 28, 14, 30, 45);
      final result = AppDateUtils.endOfDay(date);
      expect(result, DateTime(2026, 8, 28, 23, 59, 59));
    });

    // ✅ 新增：测试 tryParse
    test('tryParse 应正确解析或返回null', () {
      final valid = AppDateUtils.tryParse('2026-08-28T14:30:45.000');
      expect(valid, isNotNull);
      expect(valid!.year, 2026);
      expect(valid.month, 8);
      expect(valid.day, 28);

      final invalid = AppDateUtils.tryParse('invalid-date');
      expect(invalid, isNull);

      final empty = AppDateUtils.tryParse(null);
      expect(empty, isNull);
    });
  });
}