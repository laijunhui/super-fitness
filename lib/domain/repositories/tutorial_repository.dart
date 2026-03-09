import '../../data/models/tutorial_video.dart';
import '../../data/services/bilibili_api_service.dart';

/// 教程视频仓储接口
abstract class TutorialRepository {
  /// 获取所有教程视频
  Future<List<TutorialVideo>> getAllVideos({GenderFilter gender = GenderFilter.all});

  /// 根据分类获取教程视频
  Future<List<TutorialVideo>> getVideosByCategory(String category, {GenderFilter gender = GenderFilter.all});

  /// 搜索教程视频
  Future<List<TutorialVideo>> searchVideos(String query, {GenderFilter gender = GenderFilter.all});

  /// 获取单个视频
  Future<TutorialVideo?> getVideoById(String id);

  /// 获取相关推荐视频
  Future<List<TutorialVideo>> getRelatedVideos(String videoId);
}
