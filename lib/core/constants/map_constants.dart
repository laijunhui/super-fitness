/// 地图相关常量配置
class MapConstants {
  // 地图默认配置
  static const double defaultZoom = 16.0; // 默认缩放级别
  static const double minZoom = 3.0; // 最小缩放
  static const double maxZoom = 18.0; // 最大缩放

  // 轨迹配置
  static const int locationInterval = 3000; // GPS采样间隔（毫秒）
  static const double distanceFilter = 5.0; // 距离过滤（米）

  // 轨迹线样式
  static const int trackColorValue = 0xFF6C5CE7; // 轨迹颜色（紫色）
  static const double trackWidth = 8.0; // 轨迹宽度
  static const double miniMapTrackWidth = 3.0; // 缩略图轨迹宽度

  // 缩略图配置
  static const double miniMapZoom = 14.0; // 缩略图默认缩放
  static const int miniMapWidth = 100; // 缩略图宽度
  static const int miniMapHeight = 100; // 缩略图高度
}
