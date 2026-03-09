# 常练习的运动 - 技术实现方案

## 1. 现有代码结构分析

### 1.1 相关文件

| 文件路径 | 说明 |
|---------|------|
| `lib/presentation/screens/exercise/exercise_home_screen.dart` | 运动首页 |
| `lib/presentation/providers/tutorial_provider.dart` | 教程视频状态管理 |
| `lib/data/models/tutorial_video.dart` | 教程视频数据模型 |
| `lib/router/app_router.dart` | 路由配置 |

### 1.2 TutorialProvider 现有接口

```dart
class TutorialProvider extends ChangeNotifier {
  List<TutorialVideo> videos;           // 所有视频列表
  List<TutorialVideo> filteredVideos;   // 筛选后的视频
  String selectedCategory;              // 当前选中的分类
  bool isLoading;                       // 加载状态

  Future<void> loadVideos();             // 加载视频
  void setCategory(String category);    // 设置分类
  void search(String query);            // 搜索
}
```

### 1.3 TutorialVideo 数据模型

```dart
class TutorialVideo {
  String id;
  String title;
  String description;
  String category;
  String videoId;
  int duration;
  VideoDifficulty difficulty;

  // 已有方法
  String get durationFormatted;      // 时长格式化
  String get difficultyText;         // 难度文本
  String get thumbnailUrlResolved;   // 封面图URL（根据视频来源自动选择B站封面或YouTube缩略图）
}
```

## 2. 技术方案

### 2.1 数据获取

在 `exercise_home_screen.dart` 中通过 `TutorialProvider` 获取视频数据：

```dart
// 初始化时加载视频
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<TutorialProvider>().loadVideos();
  });
}

// 获取推荐视频（取前3条）
final videos = tutorialProvider.videos.take(3).toList();
```

### 2.2 UI组件设计

新增 `_buildUsuallyExercised` 方法，构建「常练习的运动」模块：

```dart
Widget _buildUsuallyExercised(BuildContext context, bool isDark) {
  final tutorialProvider = context.watch<TutorialProvider>();
  final videos = tutorialProvider.videos.take(3).toList();

  return Column(
    children: [
      // 标题行
      _buildHeader(context, isDark),
      // 视频列表
      ...videos.map((video) => _buildVideoItem(context, video, isDark)),
    ],
  );
}
```

### 2.3 视频卡片组件

```dart
Widget _buildVideoItem(BuildContext context, TutorialVideo video, bool isDark) {
  return NeumorphicContainer(
    child: Row(
      children: [
        // 封面 + 时长
        _buildThumbnail(video),
        // 标题 + 难度
        _buildInfo(video),
        // 播放按钮
        _buildPlayButton(context, video),
      ],
    ),
  );
}
```

### 2.4 路由跳转

| 操作 | 路由 | 参数 |
|------|------|------|
| 查看全部 | `/tutorials` | - |
| 播放视频 | `/tutorials/:id` | video.id |

```dart
// 跳转到教程列表
context.go('/tutorials');

// 跳转到视频播放页
context.push('/tutorials/${video.id}');
```

## 3. 实现步骤

### Step 1: 添加依赖导入

文件：`lib/presentation/screens/exercise/exercise_home_screen.dart`

```dart
import '../../../data/models/tutorial_video.dart';
import '../../providers/tutorial_provider.dart';
```

### Step 2: 初始化加载视频

在 `initState` 中添加视频加载：

```dart
context.read<TutorialProvider>().loadVideos();
```

### Step 3: 添加模块入口

在 `_buildQuickStart` 和 `_buildRecentRecords` 之间添加：

```dart
_buildUsuallyExercised(context, isDark),
```

### Step 4: 实现 UI 组件

实现 `_buildUsuallyExercised` 和 `_buildVideoItem` 方法。

### Step 5: 修改运动类型名称

文件：`lib/core/constants/app_constants.dart`

```dart
case ExerciseType.gym:
  return '室内运动';
```

## 4. 关键代码示例

### 4.1 视频卡片布局

```dart
Widget _buildVideoItem(BuildContext context, TutorialVideo video, bool isDark) {
  final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: NeumorphicContainer(
      isDark: isDark,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 封面
          _buildThumbnail(video, primaryColor),
          const SizedBox(width: 12),
          // 信息
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/tutorials/${video.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, maxLines: 1),
                  const SizedBox(height: 4),
                  _buildDifficultyTag(video, primaryColor),
                ],
              ),
            ),
          ),
          // 播放按钮
          GestureDetector(
            onTap: () => context.push('/tutorials/${video.id}'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 4.2 封面缩略图

```dart
Widget _buildThumbnail(TutorialVideo video, Color primaryColor) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          video.thumbnailUrlResolved,
          width: 80,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 80,
            height: 50,
            color: primaryColor.withOpacity(0.2),
            child: Icon(Icons.play_circle_outline),
          ),
        ),
      ),
      Positioned(
        right: 2,
        bottom: 2,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            video.durationFormatted,
            style: TextStyle(color: Colors.white, fontSize: 9),
          ),
        ),
      ),
    ],
  );
}
```

## 5. 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 修改 | `lib/presentation/screens/exercise/exercise_home_screen.dart` | 添加模块UI |
| 修改 | `lib/core/constants/app_constants.dart` | 修改类型名称 |
| 无需修改 | `lib/presentation/providers/tutorial_provider.dart` | 复用现有接口 |
| 无需修改 | `lib/data/models/tutorial_video.dart` | 复用现有模型 |

## 6. 验收测试

1. **功能测试**
   - [x] 运动页面显示「常练习的运动」模块
   - [x] 显示 TOP 3 视频
   - [x] 点击视频卡片跳转播放页
   - [x] 点击播放按钮跳转播放页
   - [x] 点击「查看全部」跳转教程列表

2. **视觉测试**
   - [x] 封面缩略图正常显示
   - [ ] 时长标签正确显示
   - [ ] 难度标签正确显示
   - [ ] 播放按钮样式正确

3. **回归测试**
   - [ ] 原有运动类型名称已更新
   - [ ] 其他页面功能正常

---

*文档版本：v1.0*
*创建日期：2026-03-09*
