/// 模块：时间格式化（presentation/utils）
/// 作用：把彩云接口的时间字符串格式化成"今天/明天/周一"、"18:00"、"9月26日"。
/// 依赖：纯 Dart。
library;

class TimeFormatter {
  const TimeFormatter._();

  /// 兼容 `2024-09-26T18:00+08:00` 与 `2024-09-26` 两种格式。
  ///
  /// 先去掉末尾时区偏移，再交给 [DateTime.tryParse]；
  /// 这样不会把日期字符串误截断，也不会引入 UTC 换算偏差。
  static DateTime? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim().replaceFirst(RegExp(r'([+-]\d{2}:\d{2})$'), '');
    return DateTime.tryParse(raw);
  }

  /// 今天 / 明天 / 昨天 / 周几。
  static String weatherDayLabel(String? value) {
    final date = tryParse(value);
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == -1) return '昨天';
    return _weekdayLabel(date.weekday);
  }

  /// 18:00。
  static String hourLabel(String? value) {
    final date = tryParse(value);
    if (date == null) return '';
    return '${_two(date.hour)}:${_two(date.minute)}';
  }

  /// 9月26日。
  static String dayMonthLabel(String? value) {
    final date = tryParse(value);
    if (date == null) return '';
    return '${date.month}月${date.day}日';
  }

  /// 当前时间 H:mm。
  static String nowLabel() {
    final now = DateTime.now();
    return '${now.hour}:${_two(now.minute)}';
  }

  static String _two(int value) => value < 10 ? '0$value' : '$value';

  static String _weekdayLabel(int weekday) {
    const labels = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    if (weekday < 1 || weekday > 7) return '';
    return labels[weekday - 1];
  }
}
