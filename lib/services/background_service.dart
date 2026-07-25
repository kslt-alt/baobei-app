import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'supabase_service.dart';

/// 后台定位服务 - 用于 App 在后台时持续上报位置
class BackgroundLocationService {
  static const String _channelId = 'baobei_background';
  static const String _channelName = '后台定位服务';
  static const String _channelDesc = '用于在后台上报位置信息给伴侣';

  /// 初始化后台服务
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        isolate: false, // 在主 Isolate 运行，才能访问 Supabase 实例
        notificationChannelId: _channelId,
        initialNotificationTitle: '报备助手',
        initialNotificationContent: '正在后台运行，实时同步位置',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// 启动后台服务
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  /// 停止后台服务
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    await service.invoke('stopService');
  }

  /// 检查服务是否在运行
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 如果是 Android 前台服务，设置通知
  if (service is AndroidServiceInstance) {
    await service.setForegroundNotificationInfo(
      title: '报备助手',
      content: '正在实时同步位置...',
    );
  }

  // 定时上报位置
  service.on('stopService').listen((_) {
    service.stopSelf();
  });

  // 每30秒上报一次位置
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (!(await service.isRunning())) {
      timer.cancel();
      return;
    }

    try {
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: '报备助手',
          content: '位置同步中...',
        );
      }

      final pos = await Geolocator.getCurrentPosition().catchError((_) => null);

      if (pos != null) {
        await SupabaseService.instance.uploadLocation({
          'user_id': SupabaseService.instance.currentUser?.id,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'accuracy': pos.accuracy,
          'altitude': pos.altitude,
          'speed': pos.speed,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // 静默失败
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
