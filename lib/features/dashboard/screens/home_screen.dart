import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/mock_data.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/photoshield_logo.dart';

/// 메인 대시보드 화면 — 데모 목업과 동일한 레이아웃.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = MockData.currentUser;
    final lastScan = MockData.lastScanAt;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        toolbarHeight: 64,
        title: const PhotoShieldAppBarTitle(),
        actions: [
          IconButton(
            tooltip: '알림',
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 26),
            onPressed: () => context.go('/records'),
          ),
          IconButton(
            tooltip: '설정',
            icon:
                const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
            onPressed: () => context.go('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            '안녕하세요, ${user.name}님',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          const _SafetyRing(),
          const SizedBox(height: 24),
          _RecentScanCard(lastScan: lastScan),
          const SizedBox(height: 28),
          const Text(
            '활동 기록',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const _PlatformRow(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SafetyRing extends StatelessWidget {
  const _SafetyRing();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppTheme.safe, width: 14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.safe.withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '안전함',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.safe,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '내 사진은 모든 플랫폼에서\n안전하게 보호되고 있습니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final DateTime lastScan;
  const _RecentScanCard({required this.lastScan});

  String _format(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '최근 검사: ${_format(lastScan)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow();

  @override
  Widget build(BuildContext context) {
    final items = MockData.platforms;
    return Row(
      children: List.generate(items.length, (i) {
        final p = items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i == items.length - 1 ? 0 : 10,
            ),
            child: _PlatformCard(platform: p),
          ),
        );
      }),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final PlatformStatus platform;
  const _PlatformCard({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _PlatformIcon(id: platform.id),
          const SizedBox(height: 10),
          Text(
            platform.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Text(
              platform.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: platform.isSafe
                    ? AppTheme.safe
                    : AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformIcon extends StatelessWidget {
  final String id;
  const _PlatformIcon({required this.id});

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'instagram':
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFEDA77),
                Color(0xFFF58529),
                Color(0xFFDD2A7B),
                Color(0xFF8134AF),
                Color(0xFF515BD4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.camera_alt_rounded,
              color: Colors.white, size: 26),
        );
      case 'kakao_story':
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.kakaoYellow,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.chat_bubble_rounded,
              color: Color(0xFF3C1E1E), size: 24),
        );
      case 'naver':
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.naverGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      default:
        return const Icon(Icons.public, size: 44);
    }
  }
}
