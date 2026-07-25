import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pairing_screen.dart';

class BaobeiApp extends StatelessWidget {
  const BaobeiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '报备助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

/// 认证网关 - 决定显示登录还是主界面
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().init();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SplashScreen();

    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) return const LoginScreen();

    // 已登录但未配对 -> 配对页
    if (!auth.isPaired) return const PairingScreen();

    // 已登录已配对 -> 主页
    return const HomeScreen();
  }
}
