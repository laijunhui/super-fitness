# 健身教程视频模块实现计划

## 1. 需求概述

新增一个「健身教程视频」功能模块，支持：
- 视频分类浏览（瑜伽、HIIT、力量训练、拉伸等）
- 视频搜索
- 视频播放

## 2. 视频来源方案

### 推荐方案：本地视频 + 分类标签

**原因：**
- 国内外网络环境复杂，YouTube国内访问受限
- B站API存在法律风险，不推荐
- 本地方案无网络依赖，用户体验稳定

**实现方式：**
- 使用 `chewie` + `video_player` 播放视频
- 视频数据存储在本地（JSON配置或SQLite）
- 通过分类标签实现"搜索/筛选"功能

## 3. 技术方案

### 3.1 依赖库

```yaml
dependencies:
  video_player: ^2.9.2
  chewie: ^1.10.0
```

### 3.2 数据模型

```dart
// lib/data/models/tutorial_video.dart
class TutorialVideo {
  String id;
  String title;
  String description;
  String category; // 分类：yoga, hiit, strength, stretching
  String thumbnailUrl;
  String videoUrl;
  int duration; // 秒
  String difficulty; // beginner, intermediate, advanced
}
```

### 3.3 页面结构

```
/tutorials                 # 教程列表页（首页）
  ├── 分类筛选栏
  ├── 搜索框
  └── 视频卡片列表
      └── 点击跳转

/tutorials/:id            # 视频播放页
  ├── 视频播放器 (Chewie)
  ├── 视频标题/简介
  └── 相关推荐
```

### 3.4 Provider

```dart
// lib/presentation/providers/tutorial_provider.dart
class TutorialProvider extends ChangeNotifier {
  List<TutorialVideo> videos;
  List<TutorialVideo> filteredVideos;
  String selectedCategory;
  String searchQuery;

  void setCategory(String category);
  void search(String query);
  Future<void> loadVideos();
}
```

## 4. 关键文件

| 文件 | 说明 |
|------|------|
| `lib/data/models/tutorial_video.dart` | 视频数据模型 |
| `lib/data/repositories/tutorial_repository.dart` | 视频数据仓库 |
| `lib/presentation/providers/tutorial_provider.dart` | 视频状态管理 |
| `lib/presentation/screens/tutorials/tutorials_screen.dart` | 教程列表页 |
| `lib/presentation/screens/tutorials/video_player_screen.dart` | 视频播放页 |
| `lib/router/app_router.dart` | 添加新路由 |
| `lib/core/di/injection.dart` | 注册Provider |

## 5. 视频内容来源

### 方案A：示例视频URL（开发测试用）

使用公开可访问的视频URL（如Pexels、Pixabay的免费健身视频）

### 方案B：Asset本地视频

将视频放入 `assets/videos/` 目录，打包到APP中

### 方案C：用户自行添加视频URL

允许用户输入视频URL进行播放

## 6. 验收标准

- [ ] 教程列表页正确显示视频卡片
- [ ] 分类筛选功能正常
- [ ] 搜索功能正常
- [ ] 视频播放正常（播放/暂停/进度条）
- [ ] 路由跳转正常

## 7. 实施步骤

1. 创建视频数据模型 `TutorialVideo`
2. 创建视频仓库（示例数据）
3. 创建 `TutorialProvider`
4. 创建教程列表页 `TutorialsScreen`
5. 创建视频播放页 `VideoPlayerScreen`
6. 配置路由和DI

---

*文档版本：v1.0*
*创建日期：2026-03-09*
