import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/tutorial_video.dart';

/// 视频缓存服务
class VideoCacheService {
  static const String _cacheKey = 'tutorial_videos_cache';
  static const Duration _cacheDuration = Duration(days: 3);

  final SharedPreferences _prefs;

  VideoCacheService(this._prefs);

  /// 获取缓存键（根据查询条件生成唯一键）
  String _getCacheKey({
    String? category,
    String? searchQuery,
    String? gender,
  }) {
    return '${_cacheKey}_${category ?? 'all'}_${searchQuery ?? ''}_${gender ?? 'all'}';
  }

  /// 检查缓存是否有效
  bool _isCacheValid(String key) {
    final cacheTimeStr = _prefs.getString('${key}_time');
    if (cacheTimeStr == null) return false;

    final cacheTime = DateTime.tryParse(cacheTimeStr);
    if (cacheTime == null) return false;

    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  /// 获取缓存的视频列表
  List<TutorialVideo>? getCachedVideos({
    String? category,
    String? searchQuery,
    String? gender,
  }) {
    final key = _getCacheKey(
      category: category,
      searchQuery: searchQuery,
      gender: gender,
    );

    if (!_isCacheValid(key)) {
      return null;
    }

    final cachedData = _prefs.getString(key);
    if (cachedData == null) return null;

    try {
      final List<dynamic> jsonList = json.decode(cachedData);
      return jsonList.map((e) => _videoFromJson(e)).toList();
    } catch (e) {
      return null;
    }
  }

  /// 缓存视频列表
  Future<void> cacheVideos(
    List<TutorialVideo> videos, {
    String? category,
    String? searchQuery,
    String? gender,
  }) async {
    final key = _getCacheKey(
      category: category,
      searchQuery: searchQuery,
      gender: gender,
    );

    final jsonList = videos.map((e) => _videoToJson(e)).toList();
    await _prefs.setString(key, json.encode(jsonList));
    await _prefs.setString('${key}_time', DateTime.now().toIso8601String());
  }

  /// 清除所有视频缓存
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cacheKey)) {
        await _prefs.remove(key);
      }
    }
  }

  /// 将 TutorialVideo 转换为 JSON
  Map<String, dynamic> _videoToJson(TutorialVideo video) {
    return {
      'id': video.id,
      'title': video.title,
      'description': video.description,
      'category': video.category,
      'thumbnailUrl': video.thumbnailUrl,
      'videoId': video.videoId,
      'duration': video.duration,
      'difficulty': video.difficulty.name,
      'source': video.source.name,
      'viewCount': video.viewCount,
      'publishDate': video.publishDate.toIso8601String(),
      'author': video.author,
    };
  }

  /// 从 JSON 创建 TutorialVideo
  TutorialVideo _videoFromJson(Map<String, dynamic> json) {
    return TutorialVideo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      thumbnailUrl: json['thumbnailUrl'],
      videoId: json['videoId'],
      duration: json['duration'],
      difficulty: VideoDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => VideoDifficulty.beginner,
      ),
      source: VideoSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => VideoSource.bilibili,
      ),
      viewCount: json['viewCount'] ?? 0,
      publishDate: DateTime.parse(json['publishDate']),
      author: json['author'] ?? '',
    );
  }
}
