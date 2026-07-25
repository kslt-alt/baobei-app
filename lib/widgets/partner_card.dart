import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/location_record.dart';
import '../models/status_record.dart';

/// 伴侣信息卡片 - 显示对方状态、位置、电量
class PartnerCard extends StatelessWidget {
  final String name;
  final StatusRecord? status;
  final LocationRecord? location;
  final double? distance;
  final int? batteryLevel;
  final bool? isCharging;

  const PartnerCard({
    super.key,
    this.name = 'TA',
    this.status,
    this.location,
    this.distance,
    this.batteryLevel,
    this.isCharging,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头像 + 状态
          Row(
            children: [
              // 头像
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentColor, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    status?.emoji ?? '💕',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status?.label ?? '暂无状态',
                      style: TextStyle(
                        fontSize: 13,
                        color: status != null ? AppTheme.primaryColor : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              // 电量
              if (batteryLevel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: batteryLevel! > 20
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCharging == true
                            ? Icons.battery_charging_full
                            : batteryLevel! > 60
                                ? Icons.battery_full
                                : batteryLevel! > 20
                                    ? Icons.battery_std
                                    : Icons.battery_alert,
                        size: 16,
                        color: batteryLevel! > 20
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$batteryLevel%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: batteryLevel! > 20
                              ? Colors.green[700]
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // 距离信息
          if (distance != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.straighten_rounded, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '相距 ${_formatDistance(distance!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(
                    location != null ? _formatTimeAgo(location!.createdAt) : '',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} 米';
    return '${(meters / 1000).toStringAsFixed(1)} 公里';
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '刚刚更新';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}
