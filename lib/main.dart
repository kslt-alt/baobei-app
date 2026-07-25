import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/status_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/pairing_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  await NotificationService().initialize();

  // 初始化 Supabase
  await SupabaseService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PairingProvider()),
      ],
      child: const BaobeiApp(),
    ),
  );
}
