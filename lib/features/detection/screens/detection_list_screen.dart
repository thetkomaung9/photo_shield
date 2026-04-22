import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../shared/models/detection.dart';
import '../../../shared/widgets/photoshield_logo.dart';
import '../providers/detection_provider.dart';

/// 감시(탐지) 화면 — 가장 최근 위험 감지 사례를 목업과 동일한 빨간 알림 카드로
/// 강조 표시하고, 그 아래에 이전 탐지 기록을 나열한다.
class DetectionListScreen extends ConsumerWidget {
  const DetectionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detectionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        toolbarHeight: 64,
        title: const PhotoShieldAppBarTitle(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_horiz, color: Colors.white),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('탐지된 결과가 없습니다.'));
          }
          final latest = list.first;
          final rest = list.length > 1 ? list.sublist(1) : <Detection>[];
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(detectionsProvider);
              await ref.read(detectionsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _AlertBanner(detection: latest),
                const SizedBox(height: 24),
                if (rest.isNotEmpty) ...[
                  const Text(
                    '이전 탐지 기록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...rest.map((d) => _PastDetectionCard(detection: d)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final Detection detection;
  const _AlertBanner({required this.detection});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: const BoxDecoration(
              color: AppTheme.danger,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Text(
              '위험 감지!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              '무단 도용 의심 사례가 발견되었습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: _LabeledPhoto(
                    label: '내 원본 사진',
                    labelColor: AppTheme.textPrimary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.double_arrow,
                        color: Colors.white, size: 20),
                  ),
                ),
                Expanded(
                  child: _LabeledPhoto(
                    label: '가짜 인스타 프로필',
                    labelColor: AppTheme.danger,
                    profile: detection,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => context.go(
                  '/detections/${detection.detectionId}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('상세 보기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledPhoto extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Detection? profile;
  const _LabeledPhoto({
    required this.label,
    required this.labelColor,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(
                  profile?.screenshotUrl ??
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
                ),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
            ),
            child: profile != null
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '도용 진행중',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _PastDetectionCard extends StatelessWidget {
  final Detection detection;
  const _PastDetectionCard({required this.detection});

  String _platformLabel() => switch (detection.platform) {
        'instagram' => '인스타그램',
        'facebook' => '페이스북',
        'naver_blog' => '네이버 블로그',
        'kakao_story' => '카카오스토리',
        _ => detection.platform,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/detections/${detection.detectionId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _platformLabel(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '유사도 ${(detection.similarity * 100).toStringAsFixed(1)}% · ${detection.status.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
