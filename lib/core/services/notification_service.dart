import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../data/models/goal_model.dart';

/// 通知服务
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 初始化通知服务
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  /// 请求通知权限
  static Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iOS = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool? granted = false;

    if (android != null) {
      granted = await android.requestNotificationsPermission();
    }

    if (iOS != null) {
      granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return granted ?? false;
  }

  /// 安排定时提醒
  static Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isEnabled) return;

    // 为每个星期几创建重复提醒
    for (final weekday in reminder.weekdays) {
      await _notifications.zonedSchedule(
        '${reminder.id}_$weekday'.hashCode,
        '运动提醒',
        reminder.label ?? '该运动了！来记录一下今天的运动吧',
        _nextInstanceOfWeekdayTime(weekday, reminder.hour, reminder.minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'exercise_reminder',
            '运动提醒',
            channelDescription: '定时提醒用户运动',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// 计算下一个指定星期几的时间
  static tz.TZDateTime _nextInstanceOfWeekdayTime(
    int weekday,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 调整到下一个指定的星期几
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 如果时间已经过了今天，调整到下一周
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// 取消提醒
  static Future<void> cancelReminder(String reminderId) async {
    // 取消所有与该提醒相关的通知（每个星期几一个）
    for (int i = 1; i <= 7; i++) {
      await _notifications.cancel('${reminderId}_$i'.hashCode);
    }
  }

  /// 取消所有提醒
  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  /// 显示即时通知
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      '通用通知',
      channelDescription: '通用通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }
}
