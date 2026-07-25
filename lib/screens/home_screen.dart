import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/location_record.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/status_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/status_selector.dart';
import '../widgets/partner_card.dart';
import '../widgets/location_map.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

/// 主页 - 主仪表盘
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final auth = context.read<AuthProvider>();
    final location = context.read<LocationProvider>();
    final status = context.read<StatusProvider>();
    final chat = context.read<ChatProvider>();

    final myId = auth.userId!;
    final partnerId = auth.profile!.pairedWith;

    // 开始共享位置
    await location.startSharing(myId);

    // 加载伴侣位置
    if (partnerId != null) {
      await location.fetchPartnerLocation(partnerId);
      location.subscribePartnerLocation(partnerId);
    }

    // 加载双方状态
    await status.fetchBothStatuses(myId, partnerId);
    if (partnerId != null) {
      status.subscribePartnerStatus(partnerId);
    }

    // 订阅消息
    chat.subscribeMessages(myId);
    await chat.refreshUnreadCount(myId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = context.watch<LocationProvider>();
    final status = context.watch<StatusProvider>();
    final chat = context.watch<ChatProvider>();

    final partnerId = auth.profile?.pairedWith;

    final screens = [
      _buildHomeTab(auth, location, status, chat, partnerId),
      MapScreen(partnerId: partnerId),
      HistoryScreen(userId: auth.userId!),
      ChatScreen(
        myId: auth.userId!,
        partnerId: partnerId ?? '',
        partnerName: 'TA',
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: BottomNavigationBar(
              currentIndex: _currentTab,
              onTap: (i) => setState(() => _currentTab = i),
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: AppTheme.textSecondary,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页'),
                const BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: '地图'),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.route_rounded),
                  label: '轨迹',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: chat.unreadCount > 0,
                    label: Text(
                      chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.chat_rounded),
                  ),
                  label: '消息',
                ),
                const BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '设置'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(
    AuthProvider auth,
    LocationProvider location,
    StatusProvider status,
    ChatProvider chat,
    String? partnerId,
  ) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部欢迎语
              _buildHeader(auth),
              const SizedBox(height: 20),

              // 双方状态卡片
              _buildCoupleStatus(auth, status, location),
              const SizedBox(height: 20),

              // 快捷状态按钮
              StatusSelector(
                onSelect: (statusValue, label) {
                  context.read<StatusProvider>().postStatus(
                    auth.userId!,
                    statusValue,
                    message: label,
                  );
                },
              ),
              const SizedBox(height: 20),

              // 迷你地图预览
              _buildMiniMap(location, partnerId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 6) greeting = '夜深了 🌙';
    else if (hour < 9) greeting = '早上好 🌅';
    else if (hour < 12) greeting = '上午好 ☀️';
    else if (hour < 14) greeting = '中午好 🌞';
    else if (hour < 18) greeting = '下午好 🌤️';
    else greeting = '晚上好 🌆';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${auth.profile?.displayName ?? '宝贝'} 💕',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        // 头像
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '我',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoupleStatus(
    AuthProvider auth,
    StatusProvider status,
    LocationProvider location,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 我和TA的状态
          Row(
            children: [
              // 我的状态
              Expanded(
                child: _buildPersonStatus(
                  emoji: status.myStatus?.emoji ?? '💬',
                  name: auth.profile?.displayName ?? '我',
                  statusText: status.myStatus?.label ?? '还没有报备',
                  time: status.myStatus != null
                      ? _formatTimeAgo(status.myStatus!.createdAt)
                      : null,
                  isSelf: true,
                ),
              ),

              // 爱心连接
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppTheme.primaryColor, size: 28),
                    if (location.distanceToPartner != null)
                      Text(
                        _formatDistance(location.distanceToPartner!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              // TA的状态
              Expanded(
                child: _buildPersonStatus(
                  emoji: status.partnerStatus?.emoji ?? '💬',
                  name: 'TA',
                  statusText: status.partnerStatus?.label ?? '暂无状态',
                  time: status.partnerStatus != null
                      ? _formatTimeAgo(status.partnerStatus!.createdAt)
                      : null,
                  isSelf: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 分隔线
          Container(height: 1, color: const Color(0xFFF0F0F0)),

          const SizedBox(height: 16),

          // 点击进入聊天
          InkWell(
            onTap: () => setState(() => _currentTab = 3),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                const Text(
                  '给TA发消息 💌',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonStatus({
    required String emoji,
    required String name,
    required String statusText,
    String? time,
    required bool isSelf,
  }) {
    return Column(
      children: [
        // 头像
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelf ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statusText,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (time != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniMap(LocationProvider location, String? partnerId) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // 地图
            SizedBox(
              height: 220,
              child: LocationMap(
                myLocation: location.myLocation != null
                    ? LocationRecord(
                        userId: '',
                        latitude: location.myLocation!.latitude,
                        longitude: location.myLocation!.longitude,
                      )
                    : null,
                partnerLocation: location.partnerLocation,
              ),
            ),

            // 底部信息条
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 位置信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.my_location_rounded, size: 14, color: AppTheme.primaryColor.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              location.myLocation != null
                                  ? '${location.myLocation!.latitude.toStringAsFixed(4)}, ${location.myLocation!.longitude.toStringAsFixed(4)}'
                                  : '定位中...',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        if (location.distanceToPartner != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '相距 ${_formatDistance(location.distanceToPartner!)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 展开按钮
                  IconButton(
                    icon: const Icon(Icons.open_in_full_rounded, color: AppTheme.primaryColor),
                    onPressed: () => setState(() => _currentTab = 1),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
