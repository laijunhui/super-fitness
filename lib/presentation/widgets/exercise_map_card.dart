import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../../core/constants/map_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise_model.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;

/// 运动列表地图缩略图卡片
class ExerciseMapCard extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isDark;
  final VoidCallback? onTap;

  // API Key
  static final AMapApiKey _apiKey = AMapApiKey(
    androidKey: '485cea207a05dd129e9ac8451dea727b',
    iosKey: 'b5f5ab10966cbf714bfd05ebac9e3816',
  );

  const ExerciseMapCard({
    super.key,
    required this.exercise,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gpsPoints = exercise.gpsPoints;
    final hasTrack = gpsPoints != null && gpsPoints.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 地图缩略图
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                height: 100,
                child: hasTrack
                    ? _buildMiniMap(gpsPoints)
                    : _buildPlaceholder(),
              ),
            ),

            // 信息区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Text(exercise.type.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          exercise.type.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 日期
                    Text(
                      app_date_utils.DateUtils.formatDate(exercise.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 统计
                    Row(
                      children: [
                        _buildStatChip('${exercise.distance.toStringAsFixed(1)} km', isDark),
                        const SizedBox(width: 8),
                        _buildStatChip('${exercise.duration}分钟', isDark),
                        const SizedBox(width: 8),
                        _buildStatChip('${exercise.calories.toInt()} kcal', isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMap(List<GPSPoint> gpsPoints) {
    final trackPoints = gpsPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return AMapWidget(
      apiKey: _apiKey,
      initialCameraPosition: CameraPosition(
        target: trackPoints.first,
        zoom: MapConstants.miniMapZoom,
      ),
      zoomGesturesEnabled: false,
      scrollGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      scaleEnabled: false,
      compassEnabled: false,
      touchPoiEnabled: false,
      polylines: Set<Polyline>.of([
        Polyline(
          points: trackPoints,
          color: Color(MapConstants.trackColorValue),
          width: MapConstants.miniMapTrackWidth,
        ),
      ]),
      markers: Set<Marker>.of([
        Marker(
          position: trackPoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        if (trackPoints.length > 1)
          Marker(
            position: trackPoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
      ]),
      myLocationStyleOptions: MyLocationStyleOptions(
        false,
        circleFillColor: Colors.transparent,
        circleStrokeColor: Colors.transparent,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Icon(Icons.map_outlined, color: Colors.grey[400]),
    );
  }

  Widget _buildStatChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ),
    );
  }
}
