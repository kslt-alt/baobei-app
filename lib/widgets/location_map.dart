import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../models/location_record.dart';

/// 地图组件 - 显示自己和伴侣的位置
class LocationMap extends StatelessWidget {
  final LocationRecord? myLocation;
  final LocationRecord? partnerLocation;
  final List<LocationRecord>? trajectory;

  const LocationMap({
    super.key,
    this.myLocation,
    this.partnerLocation,
    this.trajectory,
  });

  @override
  Widget build(BuildContext context) {
    // 确定地图中心和缩放
    final hasAnyLocation = myLocation != null || partnerLocation != null;

    if (!hasAnyLocation) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: AppTheme.textHint),
              SizedBox(height: 8),
              Text('等待定位...', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    final markers = <Marker>[];
    LatLng? center;

    // 自己的位置标记
    if (myLocation != null) {
      final pos = LatLng(myLocation!.latitude, myLocation!.longitude);
      center ??= pos;
      markers.add(
        Marker(
          point: pos,
          width: 60,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Text('我', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 32),
            ],
          ),
        ),
      );
    }

    // 伴侣的位置标记
    if (partnerLocation != null) {
      final pos = LatLng(partnerLocation!.latitude, partnerLocation!.longitude);
      center ??= pos;
      markers.add(
        Marker(
          point: pos,
          width: 60,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Text('TA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.favorite, color: AppTheme.accentColor, size: 32),
            ],
          ),
        ),
      );
    }

    // 轨迹线
    final polyline = trajectory != null && trajectory!.isNotEmpty
        ? Polyline(
            points: trajectory!.map((t) => LatLng(t.latitude, t.longitude)).toList(),
            color: AppTheme.primaryColor.withValues(alpha: 0.6),
            strokeWidth: 3,
          )
        : null;

    // 如果两人都有位置，以中点为中心
    if (myLocation != null && partnerLocation != null) {
      center = LatLng(
        (myLocation!.latitude + partnerLocation!.latitude) / 2,
        (myLocation!.longitude + partnerLocation!.longitude) / 2,
      );
    }

    return FlutterMap(
      options: MapOptions(
        center: center ?? const LatLng(39.9042, 116.4074), // 默认北京
        zoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // 地图图层 - 使用 OpenStreetMap 免费瓦片
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.baobei.app',
        ),

        // 轨迹线
        if (polyline != null) PolylineLayer(polylines: [polyline]),

        // 标记
        MarkerLayer(markers: markers),
      ],
    );
  }
}
