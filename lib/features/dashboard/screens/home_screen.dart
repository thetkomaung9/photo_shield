import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/facebook_api_service.dart';
import '../../../core/services/instagram_api_service.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/detection_card.dart';
import '../../detection/providers/detection_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionsAsync = ref.watch(detectionsProvider);
    final igStatus = ref.watch(instagramConnectionProvider);
    final fbStatus = ref.watch(facebookConnectionProvider);

    final monitoredPlatforms = <bool>[
      igStatus.maybeWhen(data: (s) => s.connected, orElse: () => false),
      fbStatus.maybeWhen(data: (s) => s.connected, orElse: () => false),
      true, // 네이버 (자체 백엔드)
      true, // 카카오스토리 (자체 백엔드)
    ];
    final activeCount = monitoredPlatforms.where((e) => e).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PhotoShield Korea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(detectionsProvider);
          ref.invalidate(instagramConnectionProvider);
          ref.invalidate(facebookConnectionProvider);
          await ref.read(detectionsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBanner(activeCount: activeCount),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '모니터링 플랫폼',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _PlatformGrid(
                igStatus: igStatus,
                fbStatus: fbStatus,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '최근 탐지 결과',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/detections'),
                      child: const Text('전체보기'),
                    ),
                  ],
                ),
              ),
              detectionsAsync.when(
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            '탐지된 결과가 없습니다',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : Column(
                        children: list
                            .take(3)
                            .map(
                              (d) => DetectionCard(
                                detection: d,
                                onTap: () =>
                                    context.go('/detections/${d.detectionId}'),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('탐지 결과를 불러오지 못했습니다.'),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/photos/register'),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('사진 등록'),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final int activeCount;
  const _StatusBanner({required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '모니터링 중',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Text(
                  '안전',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '현재 $activeCount개 플랫폼을 감시하고 있습니다',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '안전',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformGrid extends StatelessWidget {
  final AsyncValue<InstagramConnectionStatus> igStatus;
  final AsyncValue<FacebookConnectionStatus> fbStatus;

  const _PlatformGrid({required this.igStatus, required this.fbStatus});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PlatformCard.fromIg(igStatus),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlatformCard.fromFb(fbStatus),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _PlatformCard(
                  name: '네이버 블로그',
                  color: Color(0xFF03C75A),
                  initial: 'N',
                  status: '정상',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _PlatformCard(
                  name: '카카오스토리',
                  color: Color(0xFFFFE812),
                  initial: 'K',
                  status: '정상',
                  dark: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String name;
  final Color color;
  final String initial;
  final String status;
  final bool dark;
  final Color? statusColor;
  final String? subtitle;

  const _PlatformCard({
    required this.name,
    required this.color,
    required this.initial,
    required this.status,
    this.dark = false,
    this.statusColor,
    this.subtitle,
  });

  /// Instagram 연결 상태에 따라 카드를 구성한다.
  factory _PlatformCard.fromIg(AsyncValue<InstagramConnectionStatus> async) {
    return async.when(
      data: (s) => _PlatformCard(
        name: '인스타그램',
        color: const Color(0xFFE1306C),
        initial: 'IG',
        status: s.connected ? '연결됨' : '데모 모드',
        statusColor: s.connected ? AppTheme.safe : AppTheme.warning,
        subtitle: s.connected ? (s.username ?? '') : null,
      ),
      loading: () => const _PlatformCard(
        name: '인스타그램',
        color: Color(0xFFE1306C),
        initial: 'IG',
        status: '확인 중...',
      ),
      error: (_, __) => const _PlatformCard(
        name: '인스타그램',
        color: Color(0xFFE1306C),
        initial: 'IG',
        status: '오류',
        statusColor: AppTheme.danger,
      ),
    );
  }

  /// Facebook 연결 상태에 따라 카드를 구성한다.
  factory _PlatformCard.fromFb(AsyncValue<FacebookConnectionStatus> async) {
    return async.when(
      data: (s) => _PlatformCard(
        name: '페이스북',
        color: const Color(0xFF1877F2),
        initial: 'F',
        status: s.connected ? '연결됨' : '데모 모드',
        statusColor: s.connected ? AppTheme.safe : AppTheme.warning,
        subtitle: s.connected && s.userId != null ? 'ID: ${s.userId}' : null,
      ),
      loading: () => const _PlatformCard(
        name: '페이스북',
        color: Color(0xFF1877F2),
        initial: 'F',
        status: '확인 중...',
      ),
      error: (_, __) => const _PlatformCard(
        name: '페이스북',
        color: Color(0xFF1877F2),
        initial: 'F',
        status: '오류',
        statusColor: AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = statusColor ?? AppTheme.safe;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: initial.length > 1 ? 12 : 16,
                  color: dark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11, color: dotColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
