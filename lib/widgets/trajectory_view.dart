import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../models/location_record.dart';

/// 轨迹回放视图 - 在地图上绘制历史路径
class TrajectoryView extends StatefulWidget {
  final List<LocationRecord> records;
  final String? myId;

  const TrajectoryView({
    super.key,
    required this.records,
    this.myId,
  });

  @override
  State<TrajectoryView> createState() => _TrajectoryViewState();
}

class _TrajectoryViewState extends State<TrajectoryView> {
  int _playbackIndex = 0;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.route_outlined, size: 48, color: AppTheme.textHint),
              SizedBox(height: 8),
              Text('暂无轨迹数据', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        );
      }
    }

    final points = widget.records.map((r) => LatLng(r.latitude, r.longitude)).toList();
    final startTime = widget.records.first.createdAt;
    final endTime = widget.records.last.createdAt;
    final totalDuration = endTime.difference(startTime);

    // 计算总距离
    double totalDistance = 0;
    for (int i = 1; i < widget.records.length; i++) {
      final p1 = LatLng(widget.records[i - 1].latitude, widget.records[i - 1].longitude);
      final p2 = LatLng(widget.records[i].latitude, widget.records[i].longitude);
      totalDistance += p1.distanceTo(p2);
    }

    // 当前播放到的点
    final currentPoint = _playbackIndex < points.length ? points[_playbackIndex] : points.last;

    return Column(
      children: [
        // 地图
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              center: currentPoint,
              zoom: 15,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.baobei.app',
              ),
              // 轨迹线 - 完整的灰线 + 已走过的粉线
              PolylineLayer(
                polylines: [
                  // 完整轨迹（灰色）
                  Polyline(
                    points: points,
                    color: Colors.grey.withValues(alpha: 0.3),
                    strokeWidth: 4,
                  ),
                  // 已走过的轨迹
                  if (_playbackIndex > 0)
                    Polyline(
                      points: points.sublist(0, _playbackIndex + 1),
                      color: AppTheme.primaryColor,
                      strokeWidth: 4,
                    ),
                ],
              ),
              // 当前点标记
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPoint,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.circle,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                  // 起点
                  Marker(
                    point: points.first,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.trip_origin, color: Colors.green, size: 24),
                  ),
                  // 终点
                  Marker(
                    point: points.last,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.flag_rounded, color: Colors.red, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 底部信息栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 统计信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('距离', _formatDistance(totalDistance)),
                  _buildStat('时长', _formatDuration(totalDuration)),
                  _buildStat('点数', '${widget.records.length}'),
                ],
              ),
              const SizedBox(height: 12),

              // 时间进度条
              Row(
                children: [
                  Text(
                    _formatTime(startTime),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primaryColor,
                        inactiveTrackColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        thumbColor: AppTheme.primaryColor,
                        overlayColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _playbackIndex.toDouble(),
                        min: 0,
                        max: points.length > 1 ? (points.length - 1).toDouble() : 1,
                        onChanged: (v) => setState(() => _playbackIndex = v.round()),
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(endTime),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
