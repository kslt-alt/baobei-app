import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/pairing_provider.dart';

/// 配对页面
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('请输入6位配对码'),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final pairing = context.read<PairingProvider>();

    final success = await pairing.pairWithCode(auth.userId!, code);
    if (mounted) {
      if (success) {
        await auth.refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('🎉 配对成功！开始甜蜜报备吧！', isError: false),
        );
      } else if (pairing.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(pairing.error!),
        );
      }
    }
  }

  SnackBar _buildSnackBar(String msg, {bool isError = true}) {
    return SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : AppTheme.primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pairing = context.watch<PairingProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部装饰
            Container(
              padding: const EdgeInsets.only(top: 40, bottom: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    '绑定你的另一半 💕',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '一人创建配对码，另一人输入即可绑定',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab 切换
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '📋 我的配对码'),
                  Tab(text: '🔗 输入配对码'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: 显示我的配对码
                  _buildMyCodeTab(auth),
                  // Tab 2: 输入对方配对码
                  _buildEnterCodeTab(pairing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCodeTab(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // 配对码展示卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE4EC), Color(0xFFFDF2F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '你的配对码',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // 配对码
                GestureDetector(
                  onTap: () {
                    if (auth.pairingCode != null) {
                      Clipboard.setData(ClipboardData(text: auth.pairingCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar('已复制: ${auth.pairingCode}', isError: false),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          auth.pairingCode ?? '------',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.copy_rounded, color: AppTheme.primaryColor, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '点击复制配对码，发给 TA ❤️',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 说明
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStep('1', '复制上面的配对码'),
                _buildDivider(),
                _buildStep('2', '发给你的另一半'),
                _buildDivider(),
                _buildStep('3', 'TA 在 App 中输入你的配对码'),
                _buildDivider(),
                _buildStep('4', '绑定成功，开始甜蜜报备 🎉'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Divider(height: 1),
    );
  }

  Widget _buildEnterCodeTab(PairingProvider pairing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // 输入说明
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '输入 TA 的配对码',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '把 TA 发你的 6 位配对码填在下面',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // 配对码输入
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 10,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '------',
                      hintStyle: TextStyle(letterSpacing: 10, color: AppTheme.textHint),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: pairing.isLoading ? null : _pair,
                    child: pairing.isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('💕 绑定伴侣'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
