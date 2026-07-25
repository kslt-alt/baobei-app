import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';

/// 快捷状态选择器 - 圆形图标网格布局
class StatusSelector extends StatelessWidget {
  final void Function(String statusValue, String label) onSelect;

  const StatusSelector({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                '现在在做什么？',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 状态网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: AppConstants.predefinedStatuses.length,
            itemBuilder: (context, index) {
              final s = AppConstants.predefinedStatuses[index];
              final emoji = s['emoji']!;
              final label = s['label']!;
              final value = s['value']!;

              return _StatusButton(
                emoji: emoji,
                label: label,
                onTap: () => onSelect(value, label),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _StatusButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE4EC), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
