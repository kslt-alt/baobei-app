import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/location_record.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';

/// 全屏地图页面 - 带精致动画
class MapScreen extends StatefulWidget {
  final String? partnerId;

  const MapScreen({super.key, this.partnerId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _mapFadeIn;
  late Animation<Offset> _infoSlideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _mapFadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _infoSlideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _mapFadeIn,
          child: Column(
            children: [
              // 地图主体
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      _buildMap(location),
                      // 顶部装饰栏
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.my_location, size: 14, color: AppTheme.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      location.myLocation != null
                                          ? '${location.myLocation!.latitude.toStringAsFixed(4)}, ${location.myLocation!.longitude.toStringAsFixed(4)}'
                                          : '定位中',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: location.isSharing
                                      ? Colors.green.withOpacity(0.9)
                                      : Colors.grey.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6, height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      location.isSharing ? '共享中' : '已暂停',
                                      style: const TextStyle(fontSize: 11, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 底部信息 - 滑入动画
              SlideTransition(
                position: _infoSlideUp,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 距离卡片
                      if (location.distanceToPartner != null)
                        _buildDistanceCard(location),
                      const SizedBox(height: 12),
                      // 操作按钮
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.route_rounded,
                              label: '查看轨迹',
                              onTap: () {
                                // 切换到轨迹tab
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.refresh_rounded,
                              label: '刷新位置',
                              onTap: () {
                                if (widget.partnerId != null) {
                                  location.fetchPartnerLocation(widget.partnerId!);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(LocationProvider location) {
    final markers = <Marker>[];

    if (location.myLocation != null) {
      markers.add(Marker(
        point: LatLng(location.myLocation!.latitude, location.myLocation!.longitude),
        width: 80, height: 80,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📍', style: TextStyle(fontSize: 16)),
            Icon(Icons.location_on, color: AppTheme.primaryColor, size: 36),
          ],
        ),
      ));
    }

    if (location.partnerLocation != null) {
      markers.add(Marker(
        point: LatLng(location.partnerLocation!.latitude, location.partnerLocation!.longitude),
        width: 80, height: 80,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💕', style: TextStyle(fontSize: 16)),
            Icon(Icons.favorite, color: AppTheme.accentColor, size: 36),
          ],
        ),
      ));
    }

    final center = _calculateCenter(location);

    return FlutterMap(
      options: MapOptions(
        center: center,
        zoom: 13,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.baobei.app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  LatLng _calculateCenter(LocationProvider location) {
    if (location.myLocation != null && location.partnerLocation != null) {
      return LatLng(
        (location.myLocation!.latitude + location.partnerLocation!.latitude) / 2,
        (location.myLocation!.longitude + location.partnerLocation!.longitude) / 2,
      );
    }
    if (location.myLocation != null) {
      return LatLng(location.myLocation!.latitude, location.myLocation!.longitude);
    }
    if (location.partnerLocation != null) {
      return LatLng(location.partnerLocation!.latitude, location.partnerLocation!.longitude);
    }
    return const LatLng(39.9042, 116.4074); // 默认北京
  }

  Widget _buildDistanceCard(LocationProvider location) {
    final dist = location.distanceToPartner!;
    final distText = dist < 1000
        ? '${dist.round()} 米'
        : '${(dist / 1000).toStringAsFixed(1)} 公里';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.straighten_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('距离伴侣', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: distText,
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: location.partnerLocation != null
                            ? ' · 更新于 ${_formatTime(location.partnerLocation!.createdAt)}'
                            : '',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
