import 'dart:math' as math;
import 'package:amap_flutter_base/amap_flutter_base.dart';

/// 轨迹处理工具类
class TrackUtils {
  TrackUtils._();

  /// 平滑轨迹（移除漂移点）
  ///
  /// [points] 原始轨迹点列表
  /// [threshold] 距离阈值（米），默认10米
  ///
  /// 返回平滑后的轨迹点列表
  static List<LatLng> smoothTrack(List<LatLng> points, {double threshold = 10}) {
    if (points.length < 3) return points;

    final smoothed = <LatLng>[points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prev = smoothed.last;
      final curr = points[i];

      // 计算与前一点的距离
      final distance = calculateDistance(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      // 如果距离超过阈值，保留该点
      if (distance > threshold) {
        smoothed.add(curr);
      }
    }

    // 保留最后一个点
    smoothed.add(points.last);

    return smoothed;
  }

  /// 计算轨迹边界
  static LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// 计算轨迹总距离（公里）
  static double calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0;

    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    return total / 1000;
  }

  /// 使用Haversine公式计算两点间距离
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // 地球半径（米）

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// 生成轨迹分段（按点数）
  static List<TrackSegment> splitIntoSegments(
    List<LatLng> points, {
    int maxPointsPerSegment = 100,
  }) {
    final segments = <TrackSegment>[];

    for (int i = 0; i < points.length; i += maxPointsPerSegment) {
      final end = (i + maxPointsPerSegment > points.length)
          ? points.length
          : i + maxPointsPerSegment;

      final segmentPoints = points.sublist(i, end);

      segments.add(TrackSegment(points: segmentPoints));
    }

    return segments;
  }

  /// 度转弧度
  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

/// 轨迹段
class TrackSegment {
  final List<LatLng> points;

  TrackSegment({required this.points});

  double get distance => TrackUtils.calculateTotalDistance(points);

  int get pointCount => points.length;
}
