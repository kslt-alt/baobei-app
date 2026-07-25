import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

/// 聊天页面 - 精致简洁的消息界面
class ChatScreen extends StatefulWidget {
  final String myId;
  final String partnerId;
  final String partnerName;

  const ChatScreen({
    super.key,
    required this.myId,
    required this.partnerId,
    this.partnerName = 'TA',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _animController;
  bool _isSending = false;
  bool _showEmpty = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.partnerId.isNotEmpty) {
      _loadMessages();
    }
    _animController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    context.read<ChatProvider>().loadMessages(widget.myId, widget.partnerId);
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _isSending = true;
    final chat = context.read<ChatProvider>();
    await chat.sendMessage(widget.myId, widget.partnerId, text);
    _textController.clear();
    _isSending = false;

    // 滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    // 标记为已读
    if (widget.partnerId.isNotEmpty && chat.unreadCount > 0) {
      chat.markAsRead(widget.myId, widget.partnerId);
    }

    final messages = chat.messages;
    _showEmpty = widget.partnerId.isEmpty || messages.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppTheme.accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('给TA发消息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('💌 悄悄话·甜蜜时刻', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            // 消息列表
            Expanded(
              child: _showEmpty ? _buildEmptyChat() : _buildMessageList(chat),
            ),

            // 输入栏
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: FadeTransition(
        opacity: _animController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.favorite_rounded, size: 40, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 16),
            const Text('和TA说点什么吧 💕', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('每一句问候都是爱的信号', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatProvider chat) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      reverse: true,
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final msg = chat.messages[index];
        final isMe = msg.fromUserId == widget.myId;
        final showAvatar = index == 0 || chat.messages[index - 1].fromUserId != msg.fromUserId;

        return _buildMessageBubble(msg, isMe, showAvatar);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showAvatar) SizedBox(height: isMe ? 4 : 2),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && showAvatar)
                Container(
                  width: 28, height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentColor, AppTheme.primaryLight],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('TA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              if (!isMe && !showAvatar) const SizedBox(width: 36),

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: isMe ? null : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              if (isMe && showAvatar)
                Container(
                  width: 28, height: 28,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('我', style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              if (isMe && !showAvatar) const SizedBox(width: 36),
            ],
          ),
          if (showAvatar)
            Padding(
              padding: EdgeInsets.only(top: 2, left: isMe ? 0 : 36, right: isMe ? 36 : 0),
              child: Text(
                _formatTime(msg.createdAt),
                style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: widget.partnerId.isEmpty ? '请先配对后才能聊天哦' : '输入消息...',
                  hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: widget.partnerId.isEmpty ? null : (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: widget.partnerId.isEmpty
                  ? const Color(0xFFE0E0E0)
                  : AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: widget.partnerId.isEmpty ? null : _sendMessage,
                child: Container(
                  width: 48, height: 48,
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
