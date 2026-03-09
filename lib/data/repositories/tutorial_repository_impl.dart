import 'package:flutter/foundation.dart';
import '../../domain/repositories/tutorial_repository.dart';
import '../models/tutorial_video.dart';
import '../services/bilibili_api_service.dart';

/// 教程视频仓储实现（使用B站API实时获取数据）
class TutorialRepositoryImpl implements TutorialRepository {
  final BilibiliApiService _apiService;

  TutorialRepositoryImpl({BilibiliApiService? apiService})
      : _apiService = apiService ?? BilibiliApiService();

  @override
  Future<List<TutorialVideo>> getAllVideos({GenderFilter gender = GenderFilter.all}) async {
    try {
      // 获取健身相关热门视频
      final videos = await _apiService.getFitnessVideos(pageSize: 20, gender: gender);
      // 默认归类为全部
      return videos.map((v) => v.toTutorialVideo(VideoCategory.all)).toList();
    } catch (e) {
      debugPrint('获取全部视频失败: $e');
      return [];
    }
  }

  @override
  Future<List<TutorialVideo>> getVideosByCategory(String category, {GenderFilter gender = GenderFilter.all}) async {
    try {
      final videos = await _apiService.getVideosByCategory(
        category: category,
        pageSize: 20,
        gender: gender,
      );
      return videos.map((v) => v.toTutorialVideo(category)).toList();
    } catch (e) {
      debugPrint('获取分类视频失败: $e, category: $category');
      return [];
    }
  }

  @override
  Future<List<TutorialVideo>> searchVideos(String query, {GenderFilter gender = GenderFilter.all}) async {
    try {
      if (query.isEmpty) {
        return getAllVideos(gender: gender);
      }
      final videos = await _apiService.searchVideos(
        keyword: query,
        pageSize: 20,
        gender: gender,
      );
      return videos.map((v) => v.toTutorialVideo(VideoCategory.all)).toList();
    } catch (e) {
      debugPrint('搜索视频失败: $e, query: $query');
      return [];
    }
  }

  @override
  Future<TutorialVideo?> getVideoById(String id) async {
    try {
      // id可能是内部ID或BV号
      // 先尝试作为BV号搜索
      final videos = await _apiService.searchVideos(
        keyword: id,
        pageSize: 1,
      );
      if (videos.isNotEmpty) {
        return videos.first.toTutorialVideo(VideoCategory.all);
      }
      return null;
    } catch (e) {
      debugPrint('获取视频详情失败: $e, id: $id');
      return null;
    }
  }

  @override
  Future<List<TutorialVideo>> getRelatedVideos(String videoId) async {
    try {
      // 获取视频详情，然后获取相关分类的视频
      final video = await getVideoById(videoId);
      if (video == null) return [];

      // 获取同分类的视频作为相关推荐
      final videos = await getVideosByCategory(video.category);
      return videos.where((v) => v.id != videoId).take(4).toList();
    } catch (e) {
      debugPrint('获取相关视频失败: $e, videoId: $videoId');
      return [];
    }
  }
}
