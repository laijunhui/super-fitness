# 第二阶段功能技术实现方案

**版本**: 1.0
**日期**: 2026-03-08
**状态**: 技术设计

---

## 1. 运动趋势图表

### 1.1 功能需求

- 折线图展示运动数据变化（距离、时长、卡路里）
- 支持7天、30天、90天数据筛选
- 按运动类型筛选查看
- 显示趋势走向（上升/下降/平稳）

### 1.2 技术方案

**使用库**: `fl_chart` ^0.66.2（已集成）

**新增数据模型**:
```dart
// lib/data/models/statistics_model.dart

class TrendData {
  final DateTime date;
  final double value;
  final ExerciseType? type;

  TrendData({
    required this.date,
    required this.value,
    this.type,
  });
}

class ExerciseTrend {
  final List<TrendData> distanceTrend;
  final List<TrendData> durationTrend;
  final List<TrendData> caloriesTrend;
  final TrendDirection distanceDirection;
  final TrendDirection durationDirection;
  final TrendDirection caloriesDirection;

  ExerciseTrend({
    required this.distanceTrend,
    required this.durationTrend,
    required this.caloriesTrend,
    required this.distanceDirection,
    required this.durationDirection,
    required this.caloriesDirection,
  });
}

enum TrendDirection {
  up,    // 上升
  down,  // 下降
  stable // 平稳
}
```

**新增Provider**:
```dart
// lib/presentation/providers/trend_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/statistics_model.dart';
import '../../domain/repositories/exercise_repository.dart';

class TrendProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;

  ExerciseTrend? _trend;
  bool _isLoading = false;
  String? _error;
  FilterPeriod _selectedPeriod = FilterPeriod.week;
  ExerciseType? _selectedType;

  // Getters
  ExerciseTrend? get trend => _trend;
  bool get isLoading => _isLoading;
  FilterPeriod get selectedPeriod => _selectedPeriod;
  ExerciseType? get selectedType => _selectedType;

  /// 加载趋势数据
  Future<void> loadTrend() async {
    _isLoading = true;
    notifyListeners();

    try {
      final exercises = await _exerciseRepository.getExercisesByDateRange(
        _getStartDate(),
        DateTime.now(),
      );

      // 按日期聚合数据
      final distanceData = _aggregateByDate(exercises, (e) => e.distance);
      final durationData = _aggregateByDate(exercises, (e) => e.duration.toDouble());
      final caloriesData = _aggregateByDate(exercises, (e) => e.calories);

      _trend = ExerciseTrend(
        distanceTrend: distanceData,
        durationTrend: durationData,
        caloriesTrend: caloriesData,
        distanceDirection: _calculateDirection(distanceData),
        durationDirection: _calculateDirection(durationData),
        caloriesDirection: _calculateDirection(caloriesData),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case FilterPeriod.week:
        return now.subtract(const Duration(days: 7));
      case FilterPeriod.month:
        return now.subtract(const Duration(days: 30));
      case FilterPeriod.quarter:
        return now.subtract(const Duration(days: 90));
    }
  }

  TrendDirection _calculateDirection(List<TrendData> data) {
    if (data.length < 2) return TrendDirection.stable;

    final recent = data.last.value;
    final previous = data[data.length - 2].value;

    if (previous == 0) return TrendDirection.stable;

    final ratio = recent / previous;
    if (ratio > 1.2) return TrendDirection.up;
    if (ratio < 0.8) return TrendDirection.down;
    return TrendDirection.stable;
  }
}
```

**图表组件**:
```dart
// lib/presentation/widgets/trend_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/statistics_model.dart';

class TrendChart extends StatelessWidget {
  final List<TrendData> data;
  final Color lineColor;
  final String title;
  final String unit;

  const TrendChart({
    super.key,
    required this.data,
    required this.lineColor,
    required this.title,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Text(
                          '${data[index].date.month}/${data[index].date.day}',
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.value);
                  }).toList(),
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  dotData: FlDotData(show: data.length < 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

### 1.3 页面设计

```
┌─────────────────────────────────┐
│  数据趋势                       │
├─────────────────────────────────┤
│  [7天] [30天] [90天]           │  ← 周期选择
├─────────────────────────────────┤
│  📈 距离趋势          ↑ 上升   │  ← 趋势指标卡
│  ─────────────────────────     │
│         折线图                 │
├─────────────────────────────────┤
│  ⏱️ 时长趋势          ↓ 下降   │
│  ─────────────────────────     │
│         折线图                 │
├─────────────────────────────────┤
│  🔥 卡路里趋势      → 平稳    │
│  ─────────────────────────     │
│         折线图                 │
└─────────────────────────────────┘
```

---

## 2. 绿植主题

### 2.1 功能需求

- 新增绿植主题（绿色系新拟态设计）
- 主题切换入口：设置页面
- 主题持久化存储

### 2.2 技术方案

**颜色定义**:
```dart
// lib/core/theme/app_colors.dart 新增

// ============== 绿植主题颜色 ==============
/// 绿植主题 - 背景色
static const Color greenThemeBackground = Color(0xFFE8F5E9);

/// 绿植主题 - 卡片背景
static const Color greenThemeCardBackground = Color(0xFFE8F5E9);

/// 绿植主题 - 阴影亮部
static const Color greenThemeShadowLight = Color(0xFFFFFFFF);

/// 绿植主题 - 阴影暗部
static const Color greenThemeShadowDark = Color(0xFFB8D4BE);

/// 绿植主题 - 主色调（清新绿）
static const Color greenThemePrimary = Color(0xFF4CAF50);

/// 绿植主题 - 次要色
static const Color greenThemeSecondary = Color(0xFF81C784);

/// 绿植主题 - 文字颜色
static const Color greenThemeTextPrimary = Color(0xFF1B5E20);

/// 绿植主题 - 次要文字
static const Color greenThemeTextSecondary = Color(0xFF558B2F);
```

**主题枚举**:
```dart
// lib/core/constants/app_constants.dart 新增

enum AppThemeMode {
  light,
  dark,
  green,  // 绿植主题
}
```

**ThemeProvider扩展**:
```dart
// lib/presentation/providers/theme_provider.dart

class ThemeProvider extends ChangeNotifier {
  // 现有代码...

  AppThemeMode _themeMode = AppThemeMode.light;

  AppThemeMode get themeMode => _themeMode;
  bool get isGreenMode => _themeMode == AppThemeMode.green;

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    // 持久化存储
    _prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  void loadThemeMode() {
    final mode = _prefs.getString('theme_mode');
    if (mode != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == mode,
        orElse: () => AppThemeMode.light,
      );
    }
  }

  // 获取当前主题颜色
  Color get primaryColor {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppColors.lightPrimary;
      case AppThemeMode.dark:
        return AppColors.darkPrimary;
      case AppThemeMode.green:
        return AppColors.greenThemePrimary;
    }
  }

  // ... 其他颜色方法
}
```

**NeumorphicTheme扩展**:
```dart
// lib/core/theme/app_theme.dart

class AppTheme {
  static ThemeData greenTheme() {
    return ThemeData(
      primaryColor: AppColors.greenThemePrimary,
      scaffoldBackgroundColor: AppColors.greenThemeBackground,
      cardColor: AppColors.greenThemeCardBackground,
      // ... 其他配置
    );
  }
}
```

### 2.3 页面设计

设置页面主题选择：
```
┌─────────────────────────────────┐
│  设置                           │
├─────────────────────────────────┤
│                                 │
│  主题模式                       │
│  ┌─────────────────────────┐  │
│  │ ○ 浅色   ● 深色   ○ 绿植 │  │
│  └─────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

---

## 3. 运动目标与提醒

### 3.1 功能需求

- 设置单次运动目标（距离/时长/卡路里）
- 定时提醒用户运动
- 运动目标达成进度显示
- 目标完成提示

### 3.2 技术方案

**数据模型**:
```dart
// lib/data/models/goal_model.dart

class ExerciseGoal {
  final String id;
  final ExerciseType type;
  final GoalType goalType;  // distance, duration, calories
  final double targetValue;
  final DateTime createdAt;
  final bool isCompleted;

  ExerciseGoal({
    required this.id,
    required this.type,
    required this.goalType,
    required this.targetValue,
    required this.createdAt,
    this.isCompleted = false,
  });
}

enum GoalType {
  distance,  // 距离（km）
  duration,  // 时长（分钟）
  calories, // 卡路里（kcal）
}

class Reminder {
  final String id;
  final int hour;      // 小时（0-23）
  final int minute;    // 分钟（0-59）
  final List<int> weekdays;  // 重复日期（1-7，周一至周日）
  final bool isEnabled;
  final String? label;  // 提醒标签

  Reminder({
    required this.id,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.isEnabled = true,
    this.label,
  });
}
```

**Provider**:
```dart
// lib/presentation/providers/goal_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/goal_model.dart';
import '../../domain/repositories/exercise_repository.dart';

class GoalProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;

  ExerciseGoal? _currentGoal;
  List<Reminder> _reminders = [];
  bool _isLoading = false;

  ExerciseGoal? get currentGoal => _currentGoal;
  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;

  /// 获取目标进度（0.0-1.0）
  double get goalProgress {
    if (_currentGoal == null) return 0.0;

    // 从运动记录中获取已完成的数据
    // 计算当前进度并返回
    return _calculateProgress();
  }

  /// 设置运动目标
  Future<void> setGoal(ExerciseGoal goal) async {
    _currentGoal = goal;
    // 持久化存储
    notifyListeners();
  }

  /// 添加提醒
  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    // 持久化存储
    await _scheduleNotification(reminder);
    notifyListeners();
  }

  /// 删除提醒
  Future<void> removeReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    // 持久化存储
    notifyListeners();
  }
}
```

**提醒服务**:
```dart
// lib/core/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/goal_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
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
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    for (final weekday in reminder.weekdays) {
      await _notifications.zonedSchedule(
        reminder.id.hashCode,
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
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static TZDateTime _nextInstanceOfWeekdayTime(
    int weekday,
    int hour,
    int minute,
  ) {
    // 计算下一个提醒时间
  }
}
```

### 3.3 页面设计

**运动目标页面**:
```
┌─────────────────────────────────┐
│  运动目标              [设置]  │
├─────────────────────────────────┤
│                                 │
│  当前目标                       │
│  ┌─────────────────────────┐   │
│  │ 🏃 跑步 - 距离           │   │
│  │ 目标: 5.0 km            │   │
│  │ ████████░░░░  80%       │   │
│  └─────────────────────────┘   │
│                                 │
│  [选择运动类型]                │
│  [目标类型: 距离/时长/卡路里]   │
│  [目标值: _____]               │
│                                 │
│  [保存目标]                    │
│                                 │
└─────────────────────────────────┘
```

**提醒设置页面**:
```
┌─────────────────────────────────┐
│  运动提醒              [+添加]  │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🔔 每天早上 8:00         │   │
│  │    开启中              ○ │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🔔 每周三 19:00          │   │
│  │    开启中              ○ │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

---

## 4. 运动成就系统

### 4.1 功能需求

- 运动成就徽章（连续打卡、里程碑）
- 成就解锁条件判定
- 成就展示页面
- 成就解锁通知

### 4.2 技术方案

**成就模型**:
```dart
// lib/data/models/achievement_model.dart

enum AchievementType {
  // 连续打卡类
  consecutiveDays3,   // 连续3天
  consecutiveDays7,   // 连续7天
  consecutiveDays30,  // 连续30天

  // 里程类
  totalDistance10,   // 总里程10km
  totalDistance50,   // 总里程50km
  totalDistance100,  // 总里程100km
  totalDistance500,  // 总里程500km

  // 次数类
  exerciseCount10,    // 运动10次
  exerciseCount50,    // 运动50次
  exerciseCount100,   // 运动100次

  // 时长类
  totalDuration10h,  // 累计10小时
  totalDuration50h,  // 累计50小时

  // 运动类型专属
  running10km,       // 单次跑步10km
  cycling30km,       // 单次骑行30km
}

class Achievement {
  final AchievementType type;
  final String name;
  final String description;
  final String icon;
  final int requiredValue;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  Achievement({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredValue,
    this.unlockedAt,
  });
}

class UserAchievements {
  final Map<AchievementType, DateTime> unlockedAchievements;
  final int totalPoints;

  UserAchievements({
    required this.unlockedAchievements,
    required this.totalPoints,
  });
}
```

**成就配置**:
```dart
// lib/core/constants/achievements.dart

class AchievementConfig {
  static const List<Achievement> all = [
    // 连续打卡
    Achievement(
      type: AchievementType.consecutiveDays3,
      name: '初露头角',
      description: '连续运动3天',
      icon: '🌱',
      requiredValue: 3,
    ),
    Achievement(
      type: AchievementType.consecutiveDays7,
      name: '持之以恒',
      description: '连续运动7天',
      icon: '🌿',
      requiredValue: 7,
    ),
    Achievement(
      type: AchievementType.consecutiveDays30,
      name: '运动达人',
      description: '连续运动30天',
      icon: '🌳',
      requiredValue: 30,
    ),

    // 里程类
    Achievement(
      type: AchievementType.totalDistance10,
      name: '初出茅庐',
      description: '累计跑步10公里',
      icon: '🏃',
      requiredValue: 10,
    ),
    Achievement(
      type: AchievementType.totalDistance50,
      name: '渐入佳境',
      description: '累计跑步50公里',
      icon: '🏅',
      requiredValue: 50,
    ),
    // ... 更多成就
  ];
}
```

**成就Provider**:
```dart
// lib/presentation/providers/achievement_provider.dart

import 'package:flutter/foundation.dart';
import '../../core/constants/achievements.dart';
import '../../domain/repositories/exercise_repository.dart';

class AchievementProvider extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;

  List<Achievement> _achievements = [];
  bool _isLoading = false;
  Achievement? _newlyUnlocked;

  List<Achievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  Achievement? get newlyUnlocked => _newlyUnlocked;

  /// 加载成就数据
  Future<void> loadAchievements() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 从存储中加载已解锁成就
      final unlockedTypes = await _loadUnlockedAchievements();

      // 初始化所有成就
      _achievements = AchievementConfig.all.map((base) {
        final unlockedAt = unlockedTypes[base.type];
        return Achievement(
          type: base.type,
          name: base.name,
          description: base.description,
          icon: base.icon,
          requiredValue: base.requiredValue,
          unlockedAt: unlockedAt,
        );
      }).toList();

      // 检查新成就
      await _checkAndUnlockNewAchievements();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 检查并解锁新成就
  Future<void> _checkAndUnlockNewAchievements() async {
    final exercises = await _exerciseRepository.getAllExercises();

    for (final achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.consecutiveDays3:
        case AchievementType.consecutiveDays7:
        case AchievementType.consecutiveDays30:
          shouldUnlock = _checkConsecutiveDays(
            exercises,
            achievement.requiredValue,
          );
          break;

        case AchievementType.totalDistance10:
        case AchievementType.totalDistance50:
        case AchievementType.totalDistance100:
          shouldUnlock = _checkTotalDistance(
            exercises,
            achievement.requiredValue,
          );
          break;

        // ... 其他类型检查
      }

      if (shouldUnlock) {
        await _unlockAchievement(achievement.type);
      }
    }
  }

  bool _checkConsecutiveDays(List exercises, int days) {
    // 计算连续运动天数
  }

  bool _checkTotalDistance(List exercises, int distance) {
    // 计算总里程
  }

  Future<void> _unlockAchievement(AchievementType type) async {
    // 解锁成就并存储
    _newlyUnlocked = _achievements.firstWhere((a) => a.type == type);
    notifyListeners();
  }

  /// 清除新成就提示
  void clearNewlyUnlocked() {
    _newlyUnlocked = null;
    notifyListeners();
  }
}
```

**成就展示页面**:
```dart
// lib/presentation/screens/achievements/achievements_screen.dart

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: provider.achievements.length,
        itemBuilder: (context, index) {
          final achievement = provider.achievements[index];
          return _buildAchievementCard(achievement);
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.amber.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: isUnlocked
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.icon,
            style: TextStyle(
              fontSize: 32,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black87 : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 10,
              color: isUnlocked ? Colors.black54 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

### 4.3 成就列表设计

```
┌─────────────────────────────────┐
│  成就                     🏆 12  │
├─────────────────────────────────┤
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐      │
│  │ 🌱  │ │ 🌿  │ │ 🌳  │      │  ← 连续打卡
│  │初露 │ │持之 │ │达人 │      │
│  │头角 │ │以恒 │ │     │      │
│  └─────┘ └─────┘ └─────┘      │
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐      │
│  │ 🏃  │ │ 🏅 │ │ ⭐  │      │  ← 里程成就
│  │10km │ │50km │ │100km│      │
│  │ ✓  │ │ ✓  │ │     │      │
│  └─────┘ └─────┘ └─────┘      │
│                                 │
│  ┌─────┐ ┌─────┐              │
│  │ 🔥  │ │ 💪 │              │  ← 其他成就
│  │10次 │ │100次│              │
│  │ ✓  │ │     │              │
│  └─────┘ └─────┘              │
│                                 │
└─────────────────────────────────┘
```

### 4.4 解锁通知

```dart
// 成就解锁时显示弹窗
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Row(
      children: [
        Text(achievement.icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 8),
        const Text('成就解锁!'),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          achievement.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(achievement.description),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('太棒了!'),
      ),
    ],
  ),
);
```

---

## 5. 依赖更新

```yaml
# pubspec.yaml 新增依赖

dependencies:
  # 现有依赖...

  # 新增：本地通知
  flutter_local_notifications: ^17.0.0

  # 新增：本地存储（用于设置和成就）
  shared_preferences: ^2.2.2

  # 新增：时区计算（用于定时提醒）
  timezone: ^0.9.2
```

---

## 6. 实现计划

### 第一周：运动趋势图表
1. 创建数据模型
2. 实现TrendProvider
3. 创建TrendChart组件
4. 集成到统计页面

### 第二周：绿植主题
1. 添加绿植主题颜色
2. 扩展ThemeProvider
3. 更新设置页面主题选择
4. 测试主题切换

### 第三周：运动目标与提醒
1. 创建目标/提醒数据模型
2. 实现GoalProvider
3. 集成本地通知
4. 目标设置和提醒页面

### 第四周：运动成就系统
1. 创建成就数据模型和配置
2. 实现AchievementProvider
3. 创建成就展示页面
4. 成就解锁通知

---

*文档版本：v1.0*
*创建日期：2026-03-08*
