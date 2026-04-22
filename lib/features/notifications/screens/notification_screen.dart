import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../shared/models/notification_item.dart';
import '../../../shared/widgets/photoshield_logo.dart';
import '../providers/notification_provider.dart';

/// "기록" 탭 — 알림/탐지 활동 기록.
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        toolbarHeight: 64,
        title: const PhotoShieldAppBarTitle(),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러: $e')),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
            await ref.read(notificationsProvider.future);
          },
          child: items.isEmpty
              ? const _Empty()
              : ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _NotificationCard(
                    item: items[i],
                    onTap: () {
                      ref
                          .read(notificationsProvider.notifier)
                          .markRead(items[i].notificationId);
                      final did = items[i].detectionId;
                      if (did != null && did.isNotEmpty) {
                        context.go('/detections/$did');
                      }
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Icon(Icons.notifications_off_outlined,
              size: 64, color: AppTheme.textSecondary),
        ),
        SizedBox(height: 12),
        Center(
          child: Text(
            '아직 활동 기록이 없습니다.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _NotificationCard({required this.item, required this.onTap});

  Color _color() {
    switch (item.type) {
      case 'danger':
        return AppTheme.danger;
      case 'safe':
        return AppTheme.safe;
      default:
        return AppTheme.primary;
    }
  }

  IconData _icon() {
    switch (item.type) {
      case 'danger':
        return Icons.warning_amber_rounded;
      case 'safe':
        return Icons.verified_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _time() {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? Colors.grey.shade200
                : c.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(), color: c, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          item.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _time(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
