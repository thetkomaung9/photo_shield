import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: notificationsAsync.when(
        data: (items) => items.isEmpty
            ? const Center(
                child: Text(
                  '알림이 없습니다.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = items[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.isRead
                          ? const Color(0xFFF1F5F9)
                          : AppTheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.notifications,
                        color: n.isRead
                            ? AppTheme.textSecondary
                            : AppTheme.primary,
                      ),
                    ),
                    title: Text(
                      n.message,
                      style: TextStyle(
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(n.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: n.isRead
                        ? null
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () {
                      ref
                          .read(notificationsProvider.notifier)
                          .markRead(n.notificationId);
                      if (n.detectionId != null) {
                        context.go('/detections/${n.detectionId}');
                      }
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('알림을 불러오지 못했습니다.')),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
