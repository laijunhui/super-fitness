import 'package:intl/intl.dart';

/// 日期工具函数
class DateUtils {
  DateUtils._();

  /// 日期格式化 - 年-月-日
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 日期格式化 - 月-日
  static String formatDateShort(DateTime date) {
    return DateFormat('MM-dd').format(date);
  }

  /// 时间格式化 - 时:分
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// 时间格式化 - 时:分:秒
  static String formatTimeWithSeconds(DateTime date) {
    return DateFormat('HH:mm:ss').format(date);
  }

  /// 日期时间格式化
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// 获取今天开始时间
  static DateTime getTodayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 获取今天结束时间
  static DateTime getTodayEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// 获取本周开始时间（周一）
  static DateTime getWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return DateTime(now.year, now.month, now.day - weekday + 1);
  }

  /// 获取本周结束时间（周日）
  static DateTime getWeekEnd() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return DateTime(now.year, now.month, now.day + (7 - weekday), 23, 59, 59);
  }

  /// 获取本月开始时间
  static DateTime getMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// 获取本月结束时间
  static DateTime getMonthEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// 获取N天前的时间
  static DateTime getDaysAgo(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - days);
  }

  /// 判断是否是同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 获取星期几名称
  static String getWeekdayName(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }

  /// 获取相对时间描述
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks周前';
    } else {
      return formatDateShort(date);
    }
  }

  /// 格式化时长（分钟）
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}分钟';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}小时';
    }
    return '${hours}小时${mins}分钟';
  }

  /// 格式化计时器显示（时:分:秒）
  static String formatTimer(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }
}
