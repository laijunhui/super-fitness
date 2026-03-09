# 室内运动记录功能规格说明

## 1. 需求概述

调整室内运动页面，简化运动类型选择，新增跟随视频和自由两种记录方式，并实现视频播放自动记录功能。

## 2. 功能需求

### 2.1 室内运动页面调整

- **移除原有运动类型选择**（跑步、骑行、健走、健身）
- **新增两种室内运动类型**：
  - **跟随视频**：通过播放教学视频进行运动
  - **自由**：手动输入运动数据

### 2.2 自由类型输入

- 运动时长（分钟，必填）
- 运动距离（公里，可选）
- 消耗卡路里（kcal，可选）

### 2.3 跟随视频类型输入

- 视频标题（必填）
- 视频链接（必填）
- 视频播放时长（分钟，必填）
- 消耗卡路里（可选，不填时自动估算）

### 2.4 视频播放自动记录

- 视频播放页面停留超过3分钟时，自动新增运动记录
- 运动类型：室内运动（跟随视频）
- 自动计算/估算卡路里消耗
- 记录视频标题和链接作为备注

## 3. 技术方案

### 3.1 数据模型扩展

```dart
// 在 ExerciseModel 中添加新字段
class ExerciseModel {
  // ... 现有字段

  // 新增：室内运动子类型
  IndoorExerciseSubType? indoorSubType;

  // 新增：视频相关信息（跟随视频类型使用）
  String? videoTitle;
  String? videoUrl;
}

// 室内运动子类型枚举
enum IndoorExerciseSubType {
  followVideo,  // 跟随视频
  free,         // 自由
}
```

### 3.2 运动类型枚举调整

在 `app_constants.dart` 中保持 `ExerciseType.gym` 作为室内运动的统一类型，通过 `indoorSubType` 区分具体记录方式。

### 3.3 页面路由

- `/exercise/add` - 新增室内运动记录（包含跟随视频和自由两个tab）
- 跟随视频可从教程视频列表直接进入播放

### 3.4 视频播放自动记录实现

#### 3.4.1 计时器机制

在 `VideoPlayerScreen` 中实现：

```dart
class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Timer? _playbackTimer;
  DateTime? _pageStartTime;

  @override
  void initState() {
    super.initState();
    _pageStartTime = DateTime.now();
    // 3分钟后检查是否需要自动记录
    _playbackTimer = Timer(Duration(minutes: 3), _onPlaybackComplete);
  }

  void _onPlaybackComplete() {
    // 检查用户是否还在当前页面
    if (mounted && _isVideoPlayedSufficiently()) {
      _autoSaveExerciseRecord();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
```

#### 3.4.2 自动保存逻辑

```dart
Future<void> _autoSaveExerciseRecord() async {
  final video = context.read<TutorialProvider>().currentVideo;
  if (video == null) return;

  // 计算卡路里
  final calories = _calculateCalories(video.duration);

  // 添加运动记录
  await context.read<ExerciseProvider>().addExercise(
    type: ExerciseType.gym,
    indoorSubType: IndoorExerciseSubType.followVideo,
    videoTitle: video.title,
    videoUrl: video.videoId,
    duration: video.duration ~/ 60,
    calories: calories,
  );

  // 提示用户
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已自动记录运动：${video.title}')),
    );
  }
}
```

#### 3.4.3 卡路里估算

```dart
double _calculateCalories(int durationSeconds) {
  // 根据视频时长和难度估算
  // 默认使用中等强度 MET 值（约5-6）
  const met = 5.5;
  final weight = bodyMetrics?.weight ?? 70;
  final durationHours = durationSeconds / 3600;
  return met * weight * durationHours;
}
```

### 3.5 UI 调整

#### 3.5.1 运动首页快速开始区域

将原有4种运动类型替换为：
- 室内运动（点击后弹出选择：跟随视频 / 自由）
- 保留原有户外运动类型（跑步、骑行、健走）

#### 3.5.2 新增运动记录页面

- TabView 实现两个 tab：跟随视频、自由
- 跟随视频 Tab：从视频列表选择或手动输入
- 自由 Tab：手动输入时长、距离、卡路里

### 3.6 数据库更新

```sql
-- 运动记录表新增字段
ALTER TABLE exercises ADD COLUMN indoor_sub_type TEXT;
ALTER TABLE exercises ADD COLUMN video_title TEXT;
ALTER TABLE exercises ADD COLUMN video_url TEXT;
```

## 4. 实现任务清单

1. [ ] 扩展 ExerciseModel 添加室内运动子类型字段
2. [ ] 更新数据库迁移脚本
3. [ ] 调整 ExerciseProvider 添加新字段支持
4. [ ] 修改 AddExerciseScreen 支持两种室内运动输入方式
5. [ ] 修改 ExerciseHomeScreen 快速开始区域 UI
6. [ ] 在 VideoPlayerScreen 实现3分钟自动记录功能
7. [ ] 更新 StatisticsProvider 支持室内运动子类型统计
8. [ ] 更新 UI 显示，支持显示跟随视频/自由类型记录

## 5. 边界情况处理

- 用户在3分钟内离开视频页面：不记录
- 用户快速切换多个视频：以最后一个播放超过3分钟的视频为准
- 卡路里为0时：使用估算值
- 无体重数据时：使用默认体重70kg进行估算
