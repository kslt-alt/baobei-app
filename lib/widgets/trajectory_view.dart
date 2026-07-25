import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.route_outlined, size: 48, color: AppTheme.textHint),
              const SizedBox(height: 8),
              Text('暂无轨迹数据', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    final points = widget.records
        .map((r) => LatLng(r.latitude, r.longitude))
        .toList();

    final startTime = widget.records.first.createdAt;
    final endTime = widget.records.last.createdAt;
    final totalDuration = endTime.difference(startTime);

    double totalDistance = 0;
    for (int i = 1; i < widget.records.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        widget.records[i - 1].latitude,
        widget.records[i - 1].longitude,
        widget.records[i].latitude,
        widget.records[i].longitude,
      );
    }

    final currentPoint = _playbackIndex < points.length
        ? points[_playbackIndex]
        : points.last;

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              center: currentPoint,
              zoom: 15,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.baobei.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 4,
                  ),
                  if (_playbackIndex > 0)
                    Polyline(
                      points: points.sublist(0, _playbackIndex + 1),
                      color: AppTheme.primaryColor,
                      strokeWidth: 4,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPoint,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.circle,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                  Marker(
                    point: points.first,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.trip_origin,
                        color: Colors.green, size: 24),
                  ),
                  Marker(
                    point: points.last,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.flag_rounded,
                        color: Colors.red, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('距离', _formatDistance(totalDistance)),
                  _buildStat('时长', _formatDuration(totalDuration)),
                  _buildStat('点数', '${widget.records.length}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _formatTime(startTime),
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primaryColor,
                        inactiveTrackColor:
                            AppTheme.primaryColor.withOpacity(0.2),
                        thumbColor: AppTheme.primaryColor,
                        overlayColor:
                            AppTheme.primaryColor.withOpacity(0.1),
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _playbackIndex.toDouble(),
                        min: 0,
                        max: points.length > 1
                            ? (points.length - 1).toDouble()
                            : 1,
                        onChanged: (v) =>
                            setState(() => _playbackIndex = v.round()),
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(endTime),
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
    return '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';
  }
}
