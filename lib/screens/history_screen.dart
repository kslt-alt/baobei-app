import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/trajectory_view.dart';

/// 历史轨迹页面 - 日期选择和轨迹回放
class HistoryScreen extends StatefulWidget {
  final String userId;

  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  bool _showSelf = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadData();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadData() {
    final location = context.read<LocationProvider>();
    final auth = context.read<AuthProvider>();
    final partnerId = auth.profile?.pairedWith;

    location.fetchHistory(widget.userId, date: _selectedDate);
    if (_showSelf && partnerId != null) {
      location.fetchHistory(partnerId, date: _selectedDate);
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // 顶部
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    // 标题
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.route_rounded, color: AppTheme.primaryColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('历史轨迹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('查看一天的足迹路线', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 日期选择
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            color: AppTheme.textSecondary,
                            onPressed: () => _changeDate(-1),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppTheme.primaryColor,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                  _loadData();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('M月d日 EEEE', 'zh_CN').format(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedDate.isToday() ? ' · 今天' : '',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: AppTheme.textSecondary,
                            onPressed: () => _changeDate(1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 切换按钮：自己/对方
                    Row(
                      children: [
                        _buildToggleChip('我的轨迹', true, () => setState(() => _showSelf = true)),
                        const SizedBox(width: 8),
                        if (auth.profile?.pairedWith != null)
                          _buildToggleChip('TA的轨迹', false, () => setState(() => _showSelf = false)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 轨迹内容
              Expanded(
                child: location.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      )
                    : location.history.isEmpty
                        ? _buildEmptyState()
                        : TrajectoryView(
                            records: location.history,
                            myId: widget.userId,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: isActive
              ? [BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.route_outlined, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text('今天还没有活动轨迹', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            '开启位置共享后，足迹会在这里显示 🗺️',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

extension _DateExt on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
