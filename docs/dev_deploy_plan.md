# 健身记录应用 - 开发与部署计划

**版本**: 1.0
**日期**: 2026-03-04
**文档类型**: 开发部署指南

---

## 1. 开发阶段规划

### 1.1 阶段划分概述

| 阶段 | 周期 | 目标 | 交付物 |
|------|------|------|--------|
| 阶段一：项目初始化 | 第1天 | 环境搭建 + 项目基础架构 | Flutter 项目 + 依赖配置 |
| 阶段二：核心层开发 | 第2-3天 | 核心工具与组件 | 主题系统、新拟态组件、工具函数 |
| 阶段三：数据层开发 | 第4-5天 | 本地存储实现 | SQLite 数据库 + Repository |
| 阶段四：业务层开发 | 第6-9天 | 核心业务逻辑 | Provider 状态管理 + UseCase |
| 阶段五：UI层开发 | 第10-15天 | 页面开发 | 9个页面 + 路由配置 |
| 阶段六：集成测试 | 第16-18天 | 功能集成测试 | 可运行App + 测试报告 |
| 阶段七：打包发布 | 第19-20天 | APK/iOS打包 | 可安装的App文件 |

---

## 2. 阶段一：项目初始化（第1天）

### 2.1 开发任务

| 任务ID | 任务名称 | 预计工时 | 依赖 |
|--------|----------|----------|------|
| T1.1 | 创建Flutter项目 | 0.5h | - |
| T1.2 | 配置 pubspec.yaml 依赖 | 0.5h | T1.1 |
| T1.3 | 配置 iOS/Android 权限 | 1h | T1.1 |
| T1.4 | 验证项目编译 | 1h | T1.2, T1.3 |

### 2.2 依赖配置 (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 状态管理
  provider: ^6.1.1

  # 本地存储
  sqflite: ^2.3.2
  path_provider: ^2.1.2

  # GPS定位
  geolocator: ^11.0.0
  latlong2: ^0.9.0
  google_maps_flutter: ^2.5.3

  # 路由管理
  go_router: ^13.2.0

  # 工具库
  intl: ^0.19.0
  uuid: ^4.3.3
  permission_handler: ^11.3.0

  # 图表
  fl_chart: ^0.66.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### 2.3 iOS 权限配置 (ios/Runner/Info.plist)

```xml
<!-- 位置权限 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要获取位置信息以记录运动轨迹</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要获取位置信息以记录运动轨迹</string>

<!-- 运动与健康 -->
<key>NSMotionUsageDescription</key>
<string>需要访问运动数据以记录健身活动</string>
```

### 2.4 Android 权限配置 (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

---

## 3. 阶段二：核心层开发（第2-3天）

### 3.1 任务拆解

| 任务ID | 任务名称 | 预计工时 | 依赖 |
|--------|----------|----------|------|
| T2.1 | 运动类型枚举定义 | 0.5h | T1.1 |
| T2.2 | 数据库常量定义 | 0.5h | T2.1 |
| T2.3 | 新拟态主题系统 | 2h | T1.1 |
| T2.4 | 新拟态组件库 | 2h | T2.3 |
| T2.5 | 工具函数（日期/距离/卡路里） | 1.5h | T2.1 |
| T2.6 | 核心层单元测试 | 1h | T2.5 |

### 3.2 交付产物

```
lib/core/
├── constants/
│   ├── app_constants.dart    # ExerciseType, ActivityLevel 枚举
│   └── db_constants.dart     # 数据库表名、版本
├── theme/
│   ├── app_theme.dart        # ThemeData 配置
│   ├── app_colors.dart       # 颜色定义
│   └── app_text_styles.dart  # 文字样式
├── utils/
│   ├── date_utils.dart       # 日期工具
│   ├── distance_utils.dart   # Haversine 距离计算
│   └── calorie_utils.dart    # 卡路里计算
└── widgets/
    ├── neumorphic_container.dart
    ├── neumorphic_button.dart
    ├── stat_card.dart
    └── exercise_type_icon.dart
```

### 3.3 验证标准

- [ ] 浅色/深色主题可切换
- [ ] 新拟态组件正常显示（凸起/凹陷效果）
- [ ] 工具函数单元测试通过

---

## 4. 阶段三：数据层开发（第4-5天）

### 4.1 任务拆解

| 任务ID | 任务名称 | 预计工时 | 依赖 |
|--------|----------|----------|------|
| T3.1 | 数据模型定义 | 1h | T2.1 |
| T3.2 | 数据库表结构实现 | 1.5h | T3.1 |
| T3.3 | DatabaseHelper 实现 | 1.5h | T3.2 |
| T3.4 | Repository 接口定义 | 1h | T3.1 |
| T3.5 | Repository 实现 | 2h | T3.4, T3.3 |
| T3.6 | 数据层集成测试 | 1h | T3.5 |

### 4.2 交付产物

```
lib/data/
├── database/
│   ├── database_helper.dart   # SQLite 数据库助手
│   └── tables/
│       ├── exercise_table.dart
│       └── body_metrics_table.dart
├── models/
│   ├── exercise_model.dart
│   └── body_metrics_model.dart
└── repositories/
    ├── exercise_repository_impl.dart
    └── body_metrics_repository_impl.dart
```

### 4.3 验证标准

- [ ] SQLite 数据库创建成功
- [ ] 运动记录 CRUD 操作正常
- [ ] 身体指标 CRUD 操作正常
- [ ] 数据持久化验证（重启App数据保留）

---

## 5. 阶段四：业务层开发（第6-9天）

### 5.1 任务拆解

| 任务ID | 任务名称 | 预计工时 | 依赖 |
|--------|----------|----------|------|
| T4.1 | UseCase - 运动记录 | 2h | T3.5 |
| T4.2 | UseCase - 统计数据 | 1.5h | T3.5 |
| T4.3 | UseCase - 身体指标 | 1.5h | T3.5 |
| T4.4 | Provider - ThemeProvider | 0.5h | T2.3 |
| T4.5 | Provider - ExerciseProvider | 2h | T4.1 |
| T4.6 | Provider - StatisticsProvider | 1.5h | T4.2 |
| T4.7 | Provider - BodyMetricsProvider | 1.5h | T4.3 |
| T4.8 | 依赖注入配置 | 1h | T4.4-T4.7 |
| T4.9 | 业务层单元测试 | 2h | T4.8 |

### 5.2 交付产物

```
lib/domain/
├── entities/
│   ├── exercise_entity.dart
│   └── body_metrics_entity.dart
├── repositories/
│   ├── exercise_repository.dart (接口)
│   └── body_metrics_repository.dart (接口)
└── usecases/
    ├── exercise/
    │   ├── get_exercises_usecase.dart
    │   ├── add_exercise_usecase.dart
    │   └── delete_exercise_usecase.dart
    ├── statistics/
    │   ├── get_today_stats_usecase.dart
    │   ├── get_week_stats_usecase.dart
    │   └── get_month_stats_usecase.dart
    └── body_metrics/
        ├── save_body_metrics_usecase.dart
        ├── calculate_bmi_usecase.dart
        └── calculate_bmr_usecase.dart

lib/presentation/providers/
├── theme_provider.dart
├── exercise_provider.dart
├── statistics_provider.dart
└── body_metrics_provider.dart

lib/core/di/
└── injection.dart
```

### 5.3 验证标准

- [ ] BMI 计算正确（测试用例：170cm/70kg → 24.2）
- [ ] BMR 计算正确（测试用例：男性 30岁 70kg 170cm → 1629）
- [ ] 运动记录查询返回正确数据
- [ ] 统计数据聚合正确

---

## 6. 阶段五：UI层开发（第10-15天）

### 6.1 任务拆解

| 任务ID | 任务名称 | 预计工时 | 依赖 |
|--------|----------|----------|------|
| T5.1 | 路由配置 (GoRouter) | 1h | T4.8 |
| T5.2 | 底部导航组件 | 1h | T5.1 |
| T5.3 | 首页 (HomeScreen) | 2h | T5.2 |
| T5.4 | 运动列表页 | 1.5h | T5.2 |
| T5.5 | 运动详情页 | 1.5h | T5.2 |
| T5.6 | 添加运动页 | 2h | T5.2 |
| T5.7 | 实时运动页 (GPS) | 3h | T5.2 |
| T5.8 | 统计页 | 2h | T5.2 |
| T5.9 | 身体指标页 | 1.5h | T5.2 |
| T5.10 | 身体数据录入页 | 1.5h | T5.2 |
| T5.11 | 设置页 (主题切换) | 1h | T5.2 |
| T5.12 | UI集成测试 | 2h | T5.3-T5.11 |

### 6.2 页面与路由映射

| 路由 | 页面 | 功能 |
|------|------|------|
| `/` | HomeScreen | 今日统计、本周概览、快速开始运动 |
| `/exercise` | ExerciseListScreen | 运动历史列表 |
| `/exercise/:id` | ExerciseDetailScreen | 单次运动详情 |
| `/exercise/add` | AddExerciseScreen | 手动添加运动 |
| `/exercise/active` | ActiveWorkoutScreen | GPS实时追踪 |
| `/statistics` | StatisticsScreen | 7天/30天数据筛选 + 图表 |
| `/body` | BodyMetricsScreen | 身体指标展示 |
| `/body/input` | BodyInputScreen | 身体数据录入 |
| `/settings` | SettingsScreen | 主题切换 |

### 6.3 验证标准

- [ ] 所有页面可正常导航
- [ ] 主题切换实时生效
- [ ] 运动记录可正常添加/查看/删除
- [ ] 统计数据正确展示
- [ ] 身体指标计算正确显示

---

## 7. 本地验证流程

### 7.1 环境准备

#### 7.1.1 Flutter 环境检查

```bash
# 检查 Flutter 版本
flutter --version

# 检查 Dart 版本
dart --version

# 检查 Flutter 医生诊断
flutter doctor

# 验证 Android SDK
flutter doctor -v | grep -A 5 "Android"
```

#### 7.1.2 iOS 模拟器检查

```bash
# 列出可用模拟器
xcrun simctl list devices available

# 启动指定模拟器（后台运行）
open -a Simulator
```

#### 7.1.3 Android 模拟器检查

```bash
# 列出可用 Android 设备
flutter devices

# 启动 Android 模拟器
emulator -list-avds
emulator -avd <avd_name> &
```

### 7.2 依赖安装

```bash
# 进入项目目录
cd super_fitness

# 获取依赖
flutter pub get

# 更新依赖（如有更新）
flutter pub upgrade
```

### 7.3 本地调试流程

#### 7.3.1 启动调试（Android）

```bash
# 方式一：连接真机调试
# 1. 手机开启开发者选项 -> USB调试
# 2. 连接电脑
# 3. 运行
flutter run

# 方式二：Android 模拟器
flutter run -d <device_id>

# 方式三：指定 Android Studio 模拟器
flutter run -d "Android_SDK_built_for_x86"
```

#### 7.3.2 启动调试（iOS）

```bash
# 方式一：iOS 模拟器
flutter run -d "iPhone 16 Pro"

# 方式二：指定设备
flutter devices  # 查看设备ID
flutter run -d <device_id>
```

#### 7.3.3 热重载调试

```bash
# 在调试模式下，按 'r' 键进行热重载
# 或在 VSCode/Android Studio 中点击热重载按钮
```

### 7.4 测试验证清单

| 编号 | 测试项 | 验证方法 | 预期结果 |
|------|--------|----------|----------|
| V1 | 首次启动 | 运行App | 显示首页，无崩溃 |
| V2 | 主题切换 | 设置 → 切换主题 | 界面颜色变化 |
| V3 | 添加运动 | 首页 → 添加运动 | 记录成功保存 |
| V4 | 查看列表 | 运动 → 查看列表 | 显示历史记录 |
| V5 | 数据筛选 | 统计 → 7天/30天 | 数据显示正确 |
| V6 | 身体指标 | 身体 → 查看BMI/BMR | 计算值正确 |
| V7 | 数据持久化 | 重启App | 数据仍然存在 |

---

## 8. 打包与发布

### 8.1 Android APK 打包

#### 8.1.1 调试 APK（开发测试用）

```bash
# 生成调试 APK
flutter build apk --debug

# 输出位置
# build/app/outputs/flutter-apk/app-debug.apk
```

#### 8.1.2 发布版 APK（正式发布）

```bash
# 1. 创建密钥库（如没有）
keytool -genkey -v -keystore super_fitness.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fitness

# 2. 配置签名（android/app/build.gradle）
android {
    signingConfigs {
        release {
            storeFile file("super_fitness.jks")
            storePassword "your_password"
            keyAlias "fitness"
            keyPassword "your_password"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}

# 3. 构建发布版 APK
flutter build apk --release

# 输出位置
# build/app/outputs/flutter-apk/app-release.apk
```

### 8.2 iOS 打包

#### 8.2.1 iOS 模拟器构建

```bash
# 为模拟器构建
flutter build ios --simulator --no-codesign

# 输出位置
# build/ios/iphonesimulator/Runner.app
```

#### 8.2.2 iOS 真机发布

```bash
# 1. 配置 App Store Connect（需要 Apple 开发者账号）
# 2. 创建 App ID 和描述文件
# 3. 更新 iOS 版本号（ios/Runner/Info.plist）

# 4. 构建发布版
flutter build ipa --release

# 输出位置
# build/ios/ipa/Runner.ipa
```

#### 8.2.3 iOS 手动打包（Xcode）

```bash
# 1. 打开 iOS 项目
open ios/Runner.xcworkspace

# 2. 在 Xcode 中：
#    - 选择目标设备 → Generic iOS Device
#    - Product → Archive
#    - 打包完成后在 Organizer 中导出
```

### 8.3 打包验证

| 平台 | 验证项 | 检查方法 |
|------|--------|----------|
| Android | APK 可安装 | `adb install app-release.apk` |
| Android | 签名验证 | `jarsigner -verify app-release.apk` |
| iOS | IPA 可安装 | Xcode → Devices → Install |
| iOS | 包大小 | 检查文件大小 < 200MB |

### 8.4 发布分发

| 渠道 | 方式 | 说明 |
|------|------|------|
| **Android** | 直接安装 | APK 文件分享安装 |
| **Android** | Google Play | 需要开发者账号，上传AAB/APK |
| **Android** | 第三方商店 | 华为、应用宝等 |
| **iOS** | TestFlight | 测试分发，最多10000名测试员 |
| **iOS** | App Store | 正式发布，需要审核 |

---

## 9. 开发里程碑检查点

| 检查点 | 完成条件 | 预计时间 |
|--------|----------|----------|
| M1 - 项目初始化 | Flutter 项目可编译运行 | 第1天 |
| M2 - 核心层完成 | 主题+组件+工具完成 | 第3天 |
| M3 - 数据层完成 | SQLite CRUD 完成 | 第5天 |
| M4 - 业务层完成 | Provider 状态管理完成 | 第9天 |
| M5 - UI层完成 | 所有页面开发完成 | 第15天 |
| M6 - 功能集成 | 所有功能联调通过 | 第18天 |
| M7 - 发布就绪 | APK/IPA 构建成功 | 第20天 |

---

## 10. 附录：常用命令速查

```bash
# 项目相关
flutter create super_fitness          # 创建项目
flutter pub get                       # 安装依赖
flutter analyze                       # 代码分析
flutter test                          # 运行测试

# 调试相关
flutter run                           # 运行App
flutter run -d <device>               # 指定设备运行
flutter attach                        # 附加到运行中的进程

# 构建相关
flutter build apk --debug              # 调试APK
flutter build apk --release           # 发布APK
flutter build ios --simulator         # iOS模拟器构建
flutter build ipa --release           # iOS发布构建

# 清理相关
flutter clean                         # 清理构建缓存
rm -rf ~/.pub-cache/hosted/*         # 清理依赖缓存
```

---

*文档版本：v1.0*
*创建日期：2026-03-04*
