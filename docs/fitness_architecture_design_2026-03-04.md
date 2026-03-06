# 健身记录应用 - Flutter移动端技术架构设计文档

**版本**: 1.0
**日期**: 2026-03-04
**状态**: 第一阶段基础功能架构设计

---

## 1. 项目目录结构

采用 Clean Architecture 架构 + Feature-Based（功能模块化）组织方式，确保代码高内聚、低耦合、易测试。

```
super_fitness/
├── lib/
│   ├── main.dart                     # 应用入口
│   ├── app.dart                      # App根组件（主题、路由配置）
│   │
│   ├── core/                         # 核心层 - 通用工具与配置
│   │   ├── constants/
│   │   │   ├── app_constants.dart    # 应用常量（运动类型枚举、默认数值）
│   │   │   └── db_constants.dart     # 数据库常量（表名、版本）
│   │   ├── theme/
│   │   │   ├── app_theme.dart        # 主题配置（浅色/深色）
│   │   │   ├── neumorphic_theme.dart # 新拟态样式定义
│   │   │   └── app_colors.dart       # 颜色系统
│   │   ├── utils/
│   │   │   ├── date_utils.dart       # 日期工具函数
│   │   │   ├── distance_utils.dart   # 距离计算工具
│   │   │   └── calorie_utils.dart    # 卡路里计算工具
│   │   ├── widgets/
│   │   │   ├── neumorphic_container.dart  # 新拟态容器组件
│   │   │   ├── neumorphic_button.dart     # 新拟态按钮组件
│   │   │   ├── stat_card.dart              # 统计卡片组件
│   │   │   └── exercise_type_icon.dart     # 运动类型图标
│   │   └── di/
│   │       └── injection.dart        # 依赖注入配置
│   │
│   ├── data/                         # 数据层
│   │   ├── database/
│   │   │   ├── database_helper.dart  # SQLite数据库助手
│   │   │   └── tables/
│   │   │       ├── exercise_table.dart     # 运动记录表
│   │   │       └── body_metrics_table.dart # 身体指标表
│   │   ├── repositories/
│   │   │   ├── exercise_repository_impl.dart
│   │   │   └── body_metrics_repository_impl.dart
│   │   └── models/
│   │       ├── exercise_model.dart   # 运动记录数据模型
│   │       └── body_metrics_model.dart # 身体指标数据模型
│   │
│   ├── domain/                       # 领域层
│   │   ├── entities/
│   │   │   ├── exercise_entity.dart   # 运动记录实体
│   │   │   └── body_metrics_entity.dart # 身体指标实体
│   │   ├── repositories/
│   │   │   ├── exercise_repository.dart      # 运动仓储接口
│   │   │   └── body_metrics_repository.dart  # 身体指标仓储接口
│   │   └── usecases/
│   │       ├── exercise/
│   │       │   ├── get_exercises_usecase.dart
│   │       │   ├── add_exercise_usecase.dart
│   │       │   └── delete_exercise_usecase.dart
│   │       ├── statistics/
│   │       │   ├── get_today_stats_usecase.dart
│   │       │   ├── get_week_stats_usecase.dart
│   │       │   └── get_month_stats_usecase.dart
│   │       └── body_metrics/
│   │           ├── save_body_metrics_usecase.dart
│   │           ├── calculate_bmi_usecase.dart
│   │           └── calculate_bmr_usecase.dart
│   │
│   ├── presentation/                 # 展示层
│   │   ├── providers/                # 状态管理（Provider）
│   │   │   ├── exercise_provider.dart
│   │   │   ├── statistics_provider.dart
│   │   │   ├── body_metrics_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── screens/
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart       # 首页（统计概览）
│   │   │   ├── exercise/
│   │   │   │   ├── exercise_list_screen.dart  # 运动记录列表
│   │   │   │   ├── exercise_detail_screen.dart # 运动详情
│   │   │   │   ├── add_exercise_screen.dart    # 添加运动记录
│   │   │   │   └── active_workout_screen.dart  # 实时运动记录（GPS）
│   │   │   ├── statistics/
│   │   │   │   └── statistics_screen.dart     # 数据统计页面
│   │   │   ├── body/
│   │   │   │   ├── body_metrics_screen.dart   # 身体指标页面
│   │   │   │   └── body_input_screen.dart      # 身体数据录入
│   │   │   └── settings/
│   │   │       └── settings_screen.dart       # 设置页面（主题切换）
│   │   └── widgets/
│   │       ├── exercise_list_item.dart
│   │       ├── stat_summary_card.dart
│   │       ├── bmi_indicator.dart
│   │       └── week_chart.dart
│   │
│   └── router/
│       └── app_router.dart           # 路由配置（GoRouter）
│
├── test/                             # 测试目录
├── android/                          # Android平台配置
├── ios/                              # iOS平台配置
├── pubspec.yaml                      # 依赖配置
└── README.md
```

---

## 2. 技术选型

### 2.1 核心依赖库

| 类别 | 库名称 | 版本 | 用途说明 |
|------|--------|------|----------|
| **状态管理** | provider | ^6.1.1 | 轻量级状态管理，适合中小型应用 |
| **本地存储** | sqflite | ^2.3.2 | SQLite数据库，本地数据持久化 |
| **路径获取** | path_provider | ^2.1.2 | 获取应用文档目录路径 |
| **GPS定位** | geolocator | ^11.0.0 | 获取GPS位置信息 |
| **地图显示** | google_maps_flutter | ^2.5.3 | 显示运动轨迹地图 |
| **路由管理** | go_router | ^13.2.0 | 声明式路由，深度链接支持 |
| **日期处理** | intl | ^0.19.0 | 日期格式化和本地化 |
| **UUID生成** | uuid | ^4.3.3 | 生成唯一记录ID |
| **权限处理** | permission_handler | ^11.3.0 | 处理位置权限请求 |
| **图表展示** | fl_chart | ^0.66.2 | 绘制统计图表（周/月数据） |
| **路径计算** | latlong2 | ^0.9.0 | GPS坐标距离计算 |

### 2.2 状态管理方案

**选用方案**: Provider + ChangeNotifier

**选择理由**:
- 轻量级，学习曲线平缓
- 性能优秀，重建机制高效
- 适合本应用规模（中小型）
- 与Flutter生态系统深度集成

**状态结构设计**:
```
- ExerciseProvider: 管理运动记录列表、当前运动状态
- StatisticsProvider: 管理统计数据、筛选条件
- BodyMetricsProvider: 管理身体指标数据
- ThemeProvider: 管理主题模式（浅色/深色）
```

### 2.3 存储方案

**选用方案**: SQLite (sqflite)

**数据库设计**:
- 数据库名: `super_fitness.db`
- 版本: 1
- 表结构:
  - `exercises`: 运动记录表
  - `body_metrics`: 身体指标表
  - `user_settings`: 用户设置表（主题偏好等）

---

## 3. 数据模型设计

### 3.1 运动记录模型

```dart
// ExerciseEntity - 领域实体
class ExerciseEntity {
  final String id;
  final ExerciseType type;        // 运动类型
  final double distance;          // 距离（公里）
  final int duration;             // 时长（分钟）
  final double calories;          // 卡路里（千卡）
  final List<GPSPoint>? gpsPoints; // GPS轨迹点列表
  final DateTime createdAt;       // 创建时间
  final String? notes;            // 备注
}

// ExerciseType 枚举
enum ExerciseType {
  running,   // 跑步
  cycling,   // 骑行
  walking,   // 健走
  gym        // 健身
}

// GPS点模型
class GPSPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude;     // 海拔
  final double? speed;        // 速度（m/s）
}
```

### 3.2 身体指标模型

```dart
// BodyMetricsEntity - 领域实体
class BodyMetricsEntity {
  final String id;
  final double height;        // 身高（厘米）
  final double weight;        // 体重（公斤）
  final double? waist;         // 腰围（厘米）
  final int age;              // 年龄
  final Gender gender;        // 性别
  final double? bmi;          // 计算出的BMI
  final double? bmr;          // 计算出的基础代谢
  final DateTime createdAt;   // 记录时间
}

// Gender 枚举
enum Gender {
  male,
  female
}
```

### 3.3 统计模型

```dart
// DailyStats - 每日统计
class DailyStats {
  final DateTime date;
  final int exerciseCount;   // 运动次数
  final int totalDuration;    // 总时长（分钟）
  final double totalCalories; // 总卡路里
  final double totalDistance; // 总距离
}

// FilterPeriod 枚举
enum FilterPeriod {
  week,   // 7天
  month   // 30天
}
```

### 3.4 数据库表结构

**exercises 表**:
```sql
CREATE TABLE exercises (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  distance REAL NOT NULL,
  duration INTEGER NOT NULL,
  calories REAL NOT NULL,
  gps_points TEXT,           -- JSON序列化的GPS点列表
  created_at TEXT NOT NULL,
  notes TEXT
);
```

**body_metrics 表**:
```sql
CREATE TABLE body_metrics (
  id TEXT PRIMARY KEY,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  waist REAL,
  age INTEGER NOT NULL,
  gender TEXT NOT NULL,
  bmi REAL,
  bmr REAL,
  created_at TEXT NOT NULL
);
```

---

## 4. 核心模块设计

### 4.1 运动记录模块

**模块职责**:
- 创建新的运动记录
- 查看运动历史列表
- 查看单次运动详情
- 实时GPS轨迹记录（跑步/骑行/健走）
- 删除运动记录

**核心类设计**:

```
ExerciseRepository (接口)
    ↓
ExerciseRepositoryImpl (实现)
    ↓
ExerciseProvider (状态管理)
    ↓
ExerciseListScreen / AddExerciseScreen / ExerciseDetailScreen
```

**业务流程**:
1. 用户选择运动类型
2. 若是跑步/骑行/健走 → 启动GPS追踪
3. 用户结束运动 → 自动计算距离、时长、卡路里
4. 保存记录 → 更新统计缓存

### 4.2 数据统计模块

**模块职责**:
- 首页统计卡片展示
- 7天数据筛选
- 30天数据筛选
- 统计图表展示

**核心类设计**:

```
StatisticsRepository (接口)
    ↓
StatisticsRepositoryImpl (实现)
    ↓
StatisticsProvider (状态管理)
    ↓
HomeScreen / StatisticsScreen
```

**统计计算逻辑**:
- 今日统计: 查询created_at = 今日的记录聚合
- 本周统计: 查询created_at在当前周内的记录
- 本月统计: 查询created_at在当前月内的记录

### 4.3 身体指标模块

**模块职责**:
- 身体数据录入（身高、体重、腰围、年龄、性别）
- BMI自动计算
- 基础代谢率（BMR）自动计算
- 历史身体数据查看

**核心类设计**:

```
BodyMetricsRepository (接口)
    ↓
BodyMetricsRepositoryImpl (实现)
    ↓
BodyMetricsProvider (状态管理)
    ↓
CalculateBMIUseCase / CalculateBMRUseCase
    ↓
BodyMetricsScreen / BodyInputScreen
```

### 4.4 主题模块

**模块职责**:
- 浅色主题管理
- 深色主题管理
- 主题切换持久化
- 新拟态样式统一

**新拟态设计规范**:

| 属性 | 浅色模式 | 深色模式 |
|------|----------|----------|
| 背景色 | #E8EDF2 | #2D3436 |
| 阴影亮部 | #FFFFFF | #3D4749 |
| 阴影暗部 | #C5CBD0 | #1B2122 |
| 主色调 | #6C5CE7 | #A29BFE |
| 文字色 | #2D3436 | #FFFFFF |

**新拟态组件**:
- NeumorphicContainer: 凹陷/凸起容器
- NeumorphicButton: 按钮组件
- NeumorphicTextField: 文本输入框
- NeumorphicSwitch: 开关组件

---

## 5. 页面路由设计

### 5.1 路由结构

```
/                          → HomeScreen (首页/统计)
/exercise                  → ExerciseListScreen (运动记录列表)
/exercise/:id              → ExerciseDetailScreen (运动详情)
/exercise/add              → AddExerciseScreen (添加运动)
/exercise/active           → ActiveWorkoutScreen (实时运动追踪)
/statistics                → StatisticsScreen (数据统计)
/body                      → BodyMetricsScreen (身体指标)
/body/input                → BodyInputScreen (身体数据录入)
/settings                  → SettingsScreen (设置)
```

### 5.2 GoRouter 配置

```dart
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 首页（统计）
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // 运动记录列表
    GoRoute(
      path: '/exercise',
      builder: (context, state) => const ExerciseListScreen(),
    ),
    // 运动详情
    GoRoute(
      path: '/exercise/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ExerciseDetailScreen(exerciseId: id);
      },
    ),
    // 添加运动
    GoRoute(
      path: '/exercise/add',
      builder: (context, state) {
        final type = state.extra as ExerciseType?;
        return AddExerciseScreen(initialType: type);
      },
    ),
    // 实时运动追踪
    GoRoute(
      path: '/exercise/active',
      builder: (context, state) {
        final type = state.extra as ExerciseType;
        return ActiveWorkoutScreen(exerciseType: type);
      },
    ),
    // 数据统计
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    // 身体指标
    GoRoute(
      path: '/body',
      builder: (context, state) => const BodyMetricsScreen(),
    ),
    // 身体数据录入
    GoRoute(
      path: '/body/input',
      builder: (context, state) => const BodyInputScreen(),
    ),
    // 设置
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
```

### 5.3 底部导航

应用采用底部导航栏，包含4个主Tab:
1. **首页** - 统计概览 (`/`)
2. **运动** - 运动记录 (`/exercise`)
3. **身体** - 身体指标 (`/body`)
4. **我的** - 设置 (`/settings`)

---

## 6. 核心算法实现

### 6.1 BMI 计算算法

**公式**:
```
BMI = 体重(kg) / 身高(m)²
```

**实现代码**:
```dart
/// 计算BMI
/// [weight] 体重（公斤）
/// [height] 身高（厘米）
/// 返回BMI值，保留1位小数
double calculateBMI(double weight, double heightCm) {
  if (weight <= 0 || heightCm <= 0) return 0;

  final heightM = heightCm / 100; // 厘米转米
  final bmi = weight / (heightM * heightM);

  return double.parse(bmi.toStringAsFixed(1));
}

/// BMI分类
String getBMICategory(double bmi) {
  if (bmi <= 0) return '未知';
  if (bmi < 18.5) return '偏瘦';
  if (bmi < 24) return '正常';
  if (bmi < 28) return '偏胖';
  if (bmi < 30) return '肥胖';
  return '重度肥胖';
}
```

### 6.2 基础代谢率（BMR）计算算法

**Mifflin-St Jeor 公式**:
```
男性: BMR = 10 × 体重(kg) + 6.25 × 身高(cm) - 5 × 年龄 + 5
女性: BMR = 10 × 体重(kg) + 6.25 × 身高(cm) - 5 × 年龄 - 161
```

**实现代码**:
```dart
import '../entities/body_metrics_entity.dart';

/// 计算基础代谢率（BMR）
/// 使用Mifflin-St Jeor公式
/// [weight] 体重（公斤）
/// [height] 身高（厘米）
/// [age] 年龄
/// [gender] 性别
/// 返回基础代谢率（千卡/天），保留整数
double calculateBMR({
  required double weight,
  required double height,
  required int age,
  required Gender gender,
}) {
  if (weight <= 0 || height <= 0 || age <= 0) return 0;

  // 基础公式: 10 × 体重 + 6.25 × 身高 - 5 × 年龄
  double bmr = 10 * weight + 6.25 * height - 5 * age;

  // 根据性别调整
  switch (gender) {
    case Gender.male:
      bmr += 5;   // 男性 +5
      break;
    case Gender.female:
      bmr -= 161; // 女性 -161
      break;
  }

  return bmr.roundToDouble();
}

/// 计算日均总代谢（TDEE）
/// 考虑活动系数
double calculateTDEE(double bmr, ActivityLevel activityLevel) {
  const activityMultipliers = {
    ActivityLevel.sedentary: 1.2,      // 久坐
    ActivityLevel.light: 1.375,        // 轻度活动
    ActivityLevel.moderate: 1.55,      // 中度活动
    ActivityLevel.active: 1.725,       // 活跃
    ActivityLevel.veryActive: 1.9,     // 非常活跃
  };

  return bmr * (activityMultipliers[activityLevel] ?? 1.2);
}
```

### 6.3 卡路里消耗估算算法

**运动类型卡路里计算**:
```dart
/// 估算运动消耗卡路里
/// 使用MET（代谢当量）值估算
/// [exerciseType] 运动类型
/// [duration] 运动时长（分钟）
/// [weight] 体重（公斤）
/// 返回估算消耗卡路里（千卡）
double estimateCalories({
  required ExerciseType exerciseType,
  required int duration,
  required double weight,
}) {
  // MET值（代谢当量）
  const metValues = {
    ExerciseType.running: 9.8,    // 跑步（8km/h）
    ExerciseType.cycling: 7.5,    // 骑行（15km/h）
    ExerciseType.walking: 3.8,     // 健走（5km/h）
    ExerciseType.gym: 6.0,         // 健身（综合）
  };

  final met = metValues[exerciseType] ?? 5.0;

  // 卡路里 = MET × 体重(kg) × 时长(小时)
  final hours = duration / 60;
  final calories = met * weight * hours;

  return double.parse(calories.toStringAsFixed(1));
}
```

### 6.4 GPS距离计算算法

**使用 Haversine 公式计算两点间距离**:
```dart
import 'package:latlong2/latlong.dart';

/// 计算GPS轨迹总距离
/// [points] GPS点列表
/// 返回总距离（公里）
double calculateTotalDistance(List<GPSPoint> points) {
  if (points.length < 2) return 0;

  double totalDistance = 0;
  const distance = Distance();

  for (int i = 0; i < points.length - 1; i++) {
    final from = LatLng(points[i].latitude, points[i].longitude);
    final to = LatLng(points[i + 1].latitude, points[i + 1].longitude);

    // 计算两点间距离（米），转为公里
    totalDistance += distance.as(LengthUnit.Meter, from, to);
  }

  return totalDistance / 1000; // 米转公里
}
```

---

## 7. 依赖注入配置

使用 Provider 进行依赖注入:

```dart
// lib/core/di/injection.dart

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../data/database/database_helper.dart';
import '../../data/repositories/exercise_repository_impl.dart';
import '../../data/repositories/body_metrics_repository_impl.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/repositories/body_metrics_repository.dart';
import '../../domain/usecases/exercise/*';
import '../../domain/usecases/statistics/*';
import '../../domain/usecases/body_metrics/*';
import '../../presentation/providers/exercise_provider.dart';
import '../../presentation/providers/statistics_provider.dart';
import '../../presentation/providers/body_metrics_provider.dart';
import '../../presentation/providers/theme_provider.dart';

List<SingleChildWidget> getProviders() {
  return [
    // 数据库
    Provider<DatabaseHelper>(
      create: (_) => DatabaseHelper(),
    ),

    // 仓储接口
    Provider<ExerciseRepository>(
      create: (context) => ExerciseRepositoryImpl(
        databaseHelper: context.read<DatabaseHelper>(),
      ),
    ),
    Provider<BodyMetricsRepository>(
      create: (context) => BodyMetricsRepositoryImpl(
        databaseHelper: context.read<DatabaseHelper>(),
      ),
    ),

    // Use Cases
    Provider(create: (_) => GetExercisesUseCase(context.read())),
    Provider(create: (_) => AddExerciseUseCase(context.read())),
    Provider(create: (_) => DeleteExerciseUseCase(context.read())),
    Provider(create: (_) => GetTodayStatsUseCase(context.read())),
    Provider(create: (_) => GetWeekStatsUseCase(context.read())),
    Provider(create: (_) => GetMonthStatsUseCase(context.read())),
    Provider(create: (_) => SaveBodyMetricsUseCase(context.read())),
    Provider(create: (_) => CalculateBMIUseCase()),
    Provider(create: (_) => CalculateBMRUseCase()),

    // Providers (状态管理)
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
    ),
    ChangeNotifierProvider<ExerciseProvider>(
      create: (context) => ExerciseProvider(
        getExercisesUseCase: context.read(),
        addExerciseUseCase: context.read(),
        deleteExerciseUseCase: context.read(),
        exerciseRepository: context.read(),
      ),
    ),
    ChangeNotifierProvider<StatisticsProvider>(
      create: (context) => StatisticsProvider(
        getTodayStatsUseCase: context.read(),
        getWeekStatsUseCase: context.read(),
        getMonthStatsUseCase: context.read(),
        exerciseRepository: context.read(),
      ),
    ),
    ChangeNotifierProvider<BodyMetricsProvider>(
      create: (context) => BodyMetricsProvider(
        saveBodyMetricsUseCase: context.read(),
        calculateBMIUseCase: context.read(),
        calculateBMRUseCase: context.read(),
        bodyMetricsRepository: context.read(),
      ),
    ),
  ];
}
```

---

## 8. 总结

本技术架构设计文档为健身记录应用第一阶段基础功能提供了完整的解决方案:

1. **架构设计**: 采用 Clean Architecture + Feature-Based 结构，层间职责清晰
2. **技术选型**: Provider状态管理 + SQLite本地存储 + GoRouter路由
3. **数据模型**: 运动记录、身体指标、统计数据三大核心模型
4. **核心模块**: 运动记录、数据统计、身体指标、主题管理四大模块
5. **路由设计**: 9个页面路由，底部导航4个主Tab
6. **核心算法**: BMI计算、BMR计算(Mifflin-St Jeor)、卡路里估算、GPS距离计算

后续扩展方向:
- 添加云端同步功能（预留后端API接口）
- 添加运动计划功能
- 添加社区分享功能
- 支持Apple Watch/小米手环等可穿戴设备
