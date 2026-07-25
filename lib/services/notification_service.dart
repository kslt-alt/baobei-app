import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

/// 本地通知服务
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 初始化通知
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(initSettings);
  }

  /// 显示通知
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'baobei_channel',
      '报备提醒',
      channelDescription: '接收来自伴侣的状态更新和消息提醒',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notifications.show(id, title, body, details);
  }
}
