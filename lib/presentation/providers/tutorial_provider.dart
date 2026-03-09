import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/video_history_service.dart';
import '../../data/models/tutorial_video.dart';
import '../../data/services/bilibili_api_service.dart';
import '../../data/services/video_cache_service.dart';
import '../../domain/repositories/tutorial_repository.dart';

/// 教程视频状态管理
class TutorialProvider extends ChangeNotifier {
  final TutorialRepository _repository;
  VideoHistoryService? _historyService;
  VideoCacheService? _cacheService;
  bool _historyReady = false;
  bool _hasUserClearedHistory = false; // 用户是否主动清空过历史

  List<TutorialVideo> _videos = [];
  List<TutorialVideo> _filteredVideos = [];
  String _selectedCategory = VideoCategory.all;
  String _searchQuery = '';
  GenderFilter _genderFilter = GenderFilter.all;
  bool _isLoading = false;
  TutorialVideo? _currentVideo;
  List<TutorialVideo> _relatedVideos = [];

  TutorialProvider({
    required TutorialRepository repository,
  }) : _repository = repository {
    _initServices();
    _loadLocalVideos();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _historyService = VideoHistoryService(prefs);
    _cacheService = VideoCacheService(prefs);
    _historyReady = true;
  }

  /// 加载本地预设视频（不请求API）
  void _loadLocalVideos() {
    _videos = _defaultVideos;
    _filteredVideos = _videos;
  }

  /// 预设视频列表（本地存储，不请求B站API）
  static final List<TutorialVideo> _defaultVideos = [
    TutorialVideo(
      id: 'BV1GJ411x7h7',
      title: '帕梅拉 - 10分钟全身燃脂',
      description: '高效燃脂训练，全程站立无需器械',
      category: VideoCategory.fatLoss,
      thumbnailUrl: 'https://i2.hdslb.com/bfs/archive/3c6e9deb4c9a20c4df4e8f6b7b0e7f0c.jpg',
      videoId: 'BV1GJ411x7h7',
      duration: 600,
      difficulty: VideoDifficulty.intermediate,
      source: VideoSource.bilibili,
      viewCount: 5000000,
      publishDate: DateTime(2023, 1, 15),
      author: '帕梅拉PamelaReif',
    ),
    TutorialVideo(
      id: 'BV1xV411R7o5',
      title: '20分钟 HIIT 燃脂挑战',
      description: '高强度间歇训练，快速燃脂',
      category: VideoCategory.fatLoss,
      thumbnailUrl: 'https://i1.hdslb.com/bfs/archive/5c2c4e9deb4c9a20c4df4e8f6b7b0e7f1c.jpg',
      videoId: 'BV1xV411R7o5',
      duration: 1200,
      difficulty: VideoDifficulty.advanced,
      source: VideoSource.bilibili,
      viewCount: 3000000,
      publishDate: DateTime(2023, 2, 20),
      author: '健身UP主',
    ),
    TutorialVideo(
      id: 'BV1xV411R7o6',
      title: '瑜伽基础入门 - 柔韧性训练',
      description: '适合初学者的瑜伽课程',
      category: VideoCategory.yoga,
      thumbnailUrl: 'https://i1.hdslb.com/bfs/archive/6c3c5e9deb4c9a20c4df4e8f6b7b0e7f2c.jpg',
      videoId: 'BV1xV411R7o6',
      duration: 1800,
      difficulty: VideoDifficulty.beginner,
      source: VideoSource.bilibili,
      viewCount: 2000000,
      publishDate: DateTime(2023, 3, 10),
      author: '瑜伽老师',
    ),
    TutorialVideo(
      id: 'BV1xV411R7o7',
      title: '核心力量训练 - 腹肌马甲线',
      description: '针对核心肌群的专项训练',
      category: VideoCategory.strength,
      thumbnailUrl: 'https://i1.hdslb.com/bfs/archive/7c4c6e9deb4c9a20c4df4e8f6b7b0e7f3c.jpg',
      videoId: 'BV1xV411R7o7',
      duration: 900,
      difficulty: VideoDifficulty.intermediate,
      source: VideoSource.bilibili,
      viewCount: 4000000,
      publishDate: DateTime(2023, 4, 5),
      author: '力量训练',
    ),
    TutorialVideo(
      id: 'BV1xV411R7o8',
      title: '运动后拉伸放松教程',
      description: '运动后必做的拉伸放松动作',
      category: VideoCategory.stretching,
      thumbnailUrl: 'https://i1.hdslb.com/bfs/archive/8c5c7e9deb4c9a20c4df4e8f6b7b0e7f4c.jpg',
      videoId: 'BV1xV411R7o8',
      duration: 600,
      difficulty: VideoDifficulty.beginner,
      source: VideoSource.bilibili,
      viewCount: 1500000,
      publishDate: DateTime(2023, 5, 1),
      author: '康复训练',
    ),
  ];

  /// 确保历史服务已初始化
  Future<void> _ensureHistoryReady() async {
    while (!_historyReady) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // Getters
  List<TutorialVideo> get videos => _videos;
  List<TutorialVideo> get filteredVideos => _filteredVideos;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  GenderFilter get genderFilter => _genderFilter;
  bool get isLoading => _isLoading;
  TutorialVideo? get currentVideo => _currentVideo;
  List<TutorialVideo> get relatedVideos => _relatedVideos;

  /// 加载所有视频
  Future<void> loadVideos() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 先尝试从缓存获取
      final cachedVideos = _cacheService?.getCachedVideos(
        category: _selectedCategory,
        gender: _genderFilter.name,
      );

      if (cachedVideos != null && cachedVideos.isNotEmpty) {
        _videos = cachedVideos;
        _applyFilters();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 缓存不存在或过期，从API获取
      if (_selectedCategory == VideoCategory.all) {
        _videos = await _repository.getAllVideos(gender: _genderFilter);
      } else {
        _videos = await _repository.getVideosByCategory(_selectedCategory, gender: _genderFilter);
      }

      // 缓存结果
      await _cacheService?.cacheVideos(
        _videos,
        category: _selectedCategory,
        gender: _genderFilter.name,
      );

      _applyFilters();
    } catch (e) {
      // API失败时，尝试使用缓存（即使过期）
      final cachedVideos = _cacheService?.getCachedVideos(
        category: _selectedCategory,
        gender: _genderFilter.name,
      );
      if (cachedVideos != null && cachedVideos.isNotEmpty) {
        _videos = cachedVideos;
        _applyFilters();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置分类筛选 - 重新从API获取数据
  void setCategory(String category) {
    _selectedCategory = category;
    loadVideos();
  }

  /// 设置性别筛选 - 重新从API获取数据
  void setGenderFilter(GenderFilter gender) {
    _genderFilter = gender;
    loadVideos();
  }

  /// 搜索视频 - 实时从API获取
  Future<void> search(String query) async {
    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      // 先尝试从缓存获取
      final cachedVideos = _cacheService?.getCachedVideos(
        searchQuery: query,
        gender: _genderFilter.name,
      );

      if (cachedVideos != null && cachedVideos.isNotEmpty) {
        _videos = cachedVideos;
        _filteredVideos = _videos;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 缓存不存在或过期，从API获取
      _videos = await _repository.searchVideos(query, gender: _genderFilter);
      _filteredVideos = _videos;

      // 缓存结果
      await _cacheService?.cacheVideos(
        _videos,
        searchQuery: query,
        gender: _genderFilter.name,
      );
    } catch (e) {
      // API失败时，尝试使用缓存（即使过期）
      final cachedVideos = _cacheService?.getCachedVideos(
        searchQuery: query,
        gender: _genderFilter.name,
      );
      if (cachedVideos != null && cachedVideos.isNotEmpty) {
        _videos = cachedVideos;
        _filteredVideos = _videos;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清除搜索 - 重新加载所有视频
  void clearSearch() {
    _searchQuery = '';
    loadVideos();
    notifyListeners();
  }

  /// 加载视频详情和相关推荐
  /// 优先从缓存中查找，如果找不到再请求API
  Future<void> loadVideoDetail(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 确保历史服务已初始化
      await _ensureHistoryReady();

      // 先从当前视频列表缓存中查找
      for (final v in _videos) {
        if (v.videoId == id || v.id == id) {
          _currentVideo = v;
          break;
        }
      }

      // 如果缓存没找到，再请求API
      if (_currentVideo == null) {
        _currentVideo = await _repository.getVideoById(id);
      }

      // 记录播放历史
      if (_currentVideo != null) {
        await _historyService!.recordPlay(
          _currentVideo!.videoId,
          title: _currentVideo!.title,
          thumbnailUrl: _currentVideo!.thumbnailUrl,
          source: _currentVideo!.source.name,
        );
        // 重置清空历史标志
        _resetClearedHistoryFlag();
        // 加载相关推荐 - 使用本地播放历史
        _loadRelatedFromHistory(_currentVideo!.videoId);
      }
    } catch (e) {
      debugPrint('加载视频详情错误: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从本地播放历史加载相关推荐
  void _loadRelatedFromHistory(String currentVideoId) {
    // 获取用户常播放的视频ID列表
    final frequentIds = _historyService!.getFrequentlyPlayedIds(
      excludeId: currentVideoId,
      limit: 4,
    );

    if (frequentIds.isNotEmpty) {
      // 从视频列表缓存中查找匹配的视频
      _relatedVideos = _videos
          .where((v) => frequentIds.contains(v.videoId))
          .take(4)
          .toList();

      // 如果缓存的视频不够，从全部视频中补充
      if (_relatedVideos.length < 4) {
        final remainingIds = frequentIds
            .where((id) => !_relatedVideos.any((v) => v.videoId == id))
            .toList();

        for (final id in remainingIds) {
          // 从已加载的视频中查找
          final video = _videos.where((v) => v.videoId == id).firstOrNull;
          if (video != null && _relatedVideos.length < 4) {
            _relatedVideos.add(video);
          }
        }
      }
    } else {
      // 如果没有播放历史，返回空列表
      _relatedVideos = [];
    }
  }

  /// 清除当前视频
  void clearCurrentVideo() {
    _currentVideo = null;
    _relatedVideos = [];
    notifyListeners();
  }

  /// 获取本地常播放的视频（从播放历史中获取）
  /// 如果没有播放历史，返回空列表
  Future<List<TutorialVideo>> getFrequentlyPlayedVideos({int limit = 3}) async {
    await _ensureHistoryReady();

    if (_historyService == null) {
      return [];
    }

    // 如果用户主动清空过历史，返回空列表
    if (_hasUserClearedHistory) {
      return [];
    }

    // 从播放历史中获取记录
    final records = _historyService!.getAllRecordsWithInfo();

    if (records.isEmpty) {
      return [];
    }

    // 限制数量并转换为 TutorialVideo
    final videos = <TutorialVideo>[];
    for (final record in records.take(limit)) {
      // 尝试从视频缓存中查找完整信息
      TutorialVideo? video = _videos.where((v) => v.videoId == record.videoId).firstOrNull;

      if (video == null) {
        // 如果缓存中没有，使用历史记录中的信息创建视频对象
        video = TutorialVideo(
          id: record.videoId,
          title: record.title ?? '未知视频',
          description: '',
          category: VideoCategory.all,
          thumbnailUrl: record.thumbnailUrl ?? '',
          videoId: record.videoId,
          duration: 0,
          difficulty: VideoDifficulty.intermediate,
          source: _parseVideoSource(record.source),
          viewCount: 0,
          publishDate: DateTime.now(),
          author: '',
        );
      }

      videos.add(video);
    }

    // 按播放次数排序（已在 getAllRecordsWithInfo 中按播放次数降序）
    return videos;
  }

  /// 解析视频来源
  VideoSource _parseVideoSource(String? source) {
    switch (source) {
      case 'bilibili':
        return VideoSource.bilibili;
      case 'youtube':
        return VideoSource.youtube;
      case 'local':
        return VideoSource.local;
      default:
        return VideoSource.bilibili;
    }
  }

  /// 清空所有播放历史
  Future<void> clearVideoHistory() async {
    await _historyService?.clearHistory();
    _hasUserClearedHistory = true;
    notifyListeners();
  }

  /// 重置清空历史标志（当用户播放新视频时）
  void _resetClearedHistoryFlag() {
    _hasUserClearedHistory = false;
  }

  /// 清除视频缓存
  Future<void> clearVideoCache() async {
    await _cacheService?.clearAllCache();
    notifyListeners();
  }

  /// 应用筛选条件
  void _applyFilters() {
    var result = List<TutorialVideo>.from(_videos);

    // 按分类筛选
    if (_selectedCategory != VideoCategory.all) {
      result = result.where((v) => v.category == _selectedCategory).toList();
    }

    // 按关键词搜索
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      result = result.where((v) {
        return v.title.toLowerCase().contains(lowerQuery) ||
            v.description.toLowerCase().contains(lowerQuery) ||
            v.category.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    _filteredVideos = result;
  }
}
