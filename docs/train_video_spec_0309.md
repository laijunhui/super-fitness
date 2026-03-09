# 健身教程视频模块实现计划

## 1. 需求概述

新增一个「健身教程视频」功能模块，支持：
- 视频分类浏览（瑜伽、力量、拉伸、减脂等）
- 视频搜索
- 视频播放
- 性别筛选（男/女）
- 最近3年热门视频筛选

## 2. 视频来源调研

### 2.1 B站（哔哩哔哩）

**最终采用方案**

- 使用 B站官方搜索 API 实时获取健身视频
- API 端点：`https://api.bilibili.com/x/web-interface/search/type`
- 支持分类搜索、关键词搜索、性别筛选、时间排序
- 无需科学上网，国内访问稳定
- 海量免费健身内容（帕梅拉、周六野、瑜伽、HIIT等）

### 2.2 YouTube

**备选方案**（已搁置）

- 原计划使用 YouTube 健身视频
- 国内访问需要科学上网
- 用户体验不佳

## 3. 技术方案

### 3.1 API 设计

```dart
// 搜索参数
- keyword: 搜索关键词
- page: 页码
- page_size: 每页数量
- order: 排序方式 (click/pubdate/mix)
- sex: 性别筛选 (0:全部, 1:男, 2:女)
```

### 3.2 分类关键词映射

| 分类 | 搜索关键词 |
|------|-----------|
| 全部 | 健身, 减脂, HIIT, 瑜伽, 帕梅拉, 周六野, 燃脂, 拉伸 |
| 瑜伽 | 瑜伽课程 瑜伽跟练 瑜伽教学 |
| 力量 | 力量 腹肌 核心 |
| 拉伸 | 拉伸 放松 肩颈 |
| 减脂 | 减脂 燃脂 有氧 |

### 3.3 依赖库

```yaml
dependencies:
  provider: ^6.1.2
  go_router: ^14.6.2
  http: ^1.2.2
  cached_network_image: ^3.4.1
  youtube_player_flutter: ^9.1.1
  webview_flutter: ^4.10.0
  url_launcher: ^6.3.1
```

### 3.4 数据模型

```dart
// lib/data/models/tutorial_video.dart
class TutorialVideo {
  String id;           // 视频唯一标识（B站BV号）
  String title;        // 视频标题
  String description;   // 视频简介
  String category;     // 分类：yoga, strength, stretching, fatLoss
  String thumbnailUrl; // 封面图URL
  String videoId;      // B站BV号
  int duration;        // 时长（秒）
  VideoDifficulty difficulty; // beginner/intermediate/advanced
  VideoSource source;  // bilibili/youtube/local
  int viewCount;       // 播放量
  DateTime publishDate; // 发布时间
  String author;       // UP主
}

enum VideoSource { youtube, bilibili, local }
enum VideoDifficulty { beginner, intermediate, advanced }
```

### 3.5 API 服务

```dart
// lib/data/services/bilibili_api_service.dart
class BilibiliApiService {
  // 搜索视频
  Future<List<BilibiliVideoItem>> searchVideos({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    SearchOrder order = SearchOrder.click,
    GenderFilter gender = GenderFilter.all,
  });

  // 根据分类获取视频
  Future<List<BilibiliVideoItem>> getVideosByCategory({
    required String category,
    GenderFilter gender = GenderFilter.all,
  });

  // 并发获取健身视频（多个关键词）
  Future<List<BilibiliVideoItem>> getFitnessVideos({
    GenderFilter gender = GenderFilter.all,
  });
}
```

### 3.6 稳定性保障

- **重试机制**：请求失败时最多重试3次
- **递增延迟**：每次重试延迟800ms，412错误延迟更长
- **请求头优化**：模拟真实浏览器请求头
- **并发优化**：多个关键词并发搜索，减少等待时间

### 3.7 缓存策略

由于B站API请求频率限制容易触发限流，增加本地缓存机制：

**缓存服务**：`lib/data/services/video_cache_service.dart`

**缓存策略**：
- 基于查询条件（分类+搜索关键词+性别筛选）生成唯一缓存键
- 缓存有效期：**3天**
- 查询时优先检查缓存，缓存有效则直接返回
- 缓存不存在或过期时才请求API
- API请求失败时，使用过期缓存兜底

**缓存流程**：
```
1. 检查缓存是否存在且在有效期内（3天）
   → 是：直接返回缓存数据
   → 否：继续步骤2

2. 请求API获取新数据
   → 成功：缓存结果并返回
   → 失败：继续步骤3

3. API失败时，使用过期缓存兜底
   → 有过期缓存：返回过期缓存数据
   → 无缓存：返回空列表
```

**关键方法**：
```dart
class VideoCacheService {
  // 获取缓存（自动判断是否过期）
  List<TutorialVideo>? getCachedVideos({
    String? category,
    String? searchQuery,
    String? gender,
  });

  // 缓存视频列表
  Future<void> cacheVideos(
    List<TutorialVideo> videos, {
    String? category,
    String? searchQuery,
    String? gender,
  });

  // 清除所有缓存
  Future<void> clearAllCache();
}
```

### 3.8 页面结构

```
/tutorials                 # 教程列表页
  ├── 性别筛选栏 (全部/男/女)
  ├── 分类筛选栏 (全部/瑜伽/力量/拉伸/减脂)
  ├── 搜索功能
  └── 视频卡片列表

/tutorials/:id            # 视频播放页
  ├── B站嵌入式播放器 / WebView
  ├── 视频标题/简介
  └── 相关推荐
```

### 3.9 Provider

```dart
// lib/presentation/providers/tutorial_provider.dart
class TutorialProvider extends ChangeNotifier {
  List<TutorialVideo> videos;           // 视频列表
  List<TutorialVideo> filteredVideos;  // 筛选后视频
  String selectedCategory;             // 当前分类
  String searchQuery;                  // 搜索关键词
  GenderFilter genderFilter;          // 性别筛选
  TutorialVideo? currentVideo;        // 当前播放视频
  List<TutorialVideo> relatedVideos;  // 相关推荐

  void setCategory(String category);
  void setGenderFilter(GenderFilter gender);
  void search(String query);
  Future<void> loadVideos();
  Future<void> loadVideoDetail(String id);
}
```

## 5. 关键文件

| 文件 | 说明 |
|------|------|
| `lib/data/services/bilibili_api_service.dart` | B站API服务 |
| `lib/data/services/video_cache_service.dart` | 视频缓存服务（3天有效期） |
| `lib/data/models/tutorial_video.dart` | 视频数据模型 |
| `lib/data/repositories/tutorial_repository.dart` | 视频数据仓库接口 |
| `lib/data/repositories/tutorial_repository_impl.dart` | 视频数据仓库实现 |
| `lib/presentation/providers/tutorial_provider.dart` | 视频状态管理（含缓存逻辑） |
| `lib/presentation/screens/tutorials/tutorials_screen.dart` | 教程列表页 |
| `lib/presentation/screens/tutorials/video_player_screen.dart` | 视频播放页 |
| `lib/presentation/screens/tutorials/bilibili_player.dart` | B站播放器 |

## 6. 产品原型

### 5.1 教程列表页

```
┌─────────────────────────────────┐
│  健身教程              🔍       │
├─────────────────────────────────┤
│  性别: [全部] [男] [女]        │ ← 性别筛选
├─────────────────────────────────┤
│  [全部] [瑜伽] [力量] [拉伸]   │ ← 分类筛选
│  [减脂]                         │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │ ┌─────┐  帕梅拉10分钟  │   │
│  │ │封面 │  瑜伽放松课程   │   │ ← 视频卡片
│  │ └─────┘  🔥 12.5万    │   │
│  │        初级 · 10分钟    │   │
│  └─────────────────────────┘   │
│  ...                          │
└─────────────────────────────────┘
```

### 5.2 视频播放页

```
┌─────────────────────────────────┐
│  ←  健身教程                    │
├─────────────────────────────────┤
│                                 │
│     ┌───────────────────┐      │
│     │   B站WebView播放器│      │
│     └───────────────────┘      │
│                                 │
│   帕梅拉10分钟全身瑜伽          │ ← 标题
│   🔥 12.5万播放  初级          │
│                                 │
│   课程简介                     │
│   这是一套适合初学者的全身瑜伽  │
│                                 │
│   ─────────────────────────    │
│   相关推荐                      │
│   ┌────┐ ┌────┐ ┌────┐       │
│   │视频1│ │视频2│ │视频3│      │
│   └────┘ └────┘ └────┘       │
└─────────────────────────────────┘
```

## 7. 验收标准

- [x] 底部导航栏显示教程Tab
- [x] 教程列表页正确显示视频卡片
- [x] 分类筛选功能正常
- [x] 性别筛选功能正常
- [x] 搜索功能正常
- [x] B站视频播放正常（WebView方式）
- [x] 路由跳转正常
- [x] API稳定性优化（重试机制）
- [x] 并发搜索优化
- [x] 视频结果缓存（3天有效期）
- [x] API限流时使用缓存兜底

## 8. 实施步骤

1. ~~添加首页教程入口卡片~~ ✅
2. ~~添加底部导航栏教程Tab~~ ✅
3. ~~添加运动页面常练习模块~~ ✅
4. ~~修改"健身"为"室内运动"~~ ✅
5. ~~创建视频数据模型~~ ✅
6. ~~实现B站API服务~~ ✅
7. ~~创建视频仓库~~ ✅
8. ~~创建TutorialProvider~~ ✅
9. ~~创建教程列表页~~ ✅
10. ~~创建视频播放页~~ ✅
11. ~~配置路由和DI~~ ✅

---

*文档版本：v3.0*
*创建日期：2026-03-09*
*更新日期：2026-03-09*
*更新说明：新增视频缓存策略（3天有效期），解决API限流问题*
