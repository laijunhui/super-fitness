import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import '../../core/constants/map_constants.dart';
import '../../data/models/exercise_model.dart';

/// 运动详情页地图组件
class ExerciseMapDetail extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isDark;

  // API Key
  static final AMapApiKey _apiKey = AMapApiKey(
    androidKey: '485cea207a05dd129e9ac8451dea727b',
    iosKey: 'b5f5ab10966cbf714bfd05ebac9e3816',
  );

  const ExerciseMapDetail({
    super.key,
    required this.exercise,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final gpsPoints = exercise.gpsPoints;
    if (gpsPoints == null || gpsPoints.isEmpty) {
      return _buildNoDataPlaceholder();
    }

    final trackPoints = gpsPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

    // 计算起点和终点
    final startPoint = trackPoints.first;
    final endPoint = trackPoints.last;

    return Column(
      children: [
        // 地图区域
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AMapWidget(
              apiKey: _apiKey,
              initialCameraPosition: CameraPosition(
                target: startPoint,
                zoom: 15,
              ),
              touchPoiEnabled: false,
              polylines: Set<Polyline>.of([
                Polyline(
                  points: trackPoints,
                  color: Color(MapConstants.trackColorValue),
                  width: MapConstants.trackWidth,
                ),
              ]),
              markers: Set<Marker>.of([
                // 起点标记
                Marker(
                  position: startPoint,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
                // 终点标记
                if (trackPoints.length > 1)
                  Marker(
                    position: endPoint,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
              ]),
              myLocationStyleOptions: MyLocationStyleOptions(
                false,
                circleFillColor: Colors.transparent,
                circleStrokeColor: Colors.transparent,
              ),
            ),
          ),
        ),

        // 轨迹统计信息
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatRow(
                '起点',
                '${startPoint.latitude.toStringAsFixed(4)}, ${startPoint.longitude.toStringAsFixed(4)}',
              ),
              _buildStatRow(
                '终点',
                '${endPoint.latitude.toStringAsFixed(4)}, ${endPoint.longitude.toStringAsFixed(4)}',
              ),
              _buildStatRow('轨迹点数', '${gpsPoints.length}'),
              _buildStatRow('总距离', '${exercise.distance.toStringAsFixed(2)} km'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '无轨迹数据',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
