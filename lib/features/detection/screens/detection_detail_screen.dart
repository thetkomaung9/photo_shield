import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme.dart';
import '../../../shared/models/detection.dart';
import '../../../shared/widgets/photoshield_logo.dart';
import '../providers/detection_provider.dart';

/// 탐지 상세 — 위험 알림 목업과 동일한 비교 카드 + 신고하기 진입점.
class DetectionDetailScreen extends ConsumerWidget {
  final String id;
  const DetectionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detectionDetailProvider(id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        toolbarHeight: 64,
        title: const PhotoShieldAppBarTitle(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/monitor'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('${context.tr('errorPrefix')}: $e')),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _DetailHero(detection: d),
            const SizedBox(height: 24),
            _InfoTile(
                label: context.tr('platform'),
                value: _platformLabel(context, d.platform)),
            _InfoTile(
              label: context.tr('similarity'),
              value: '${(d.similarity * 100).toStringAsFixed(1)}%',
              valueColor: AppTheme.danger,
            ),
            _InfoTile(label: context.tr('foundUrl'), value: d.foundUrl),
            _InfoTile(
              label: context.tr('detectedAt'),
              value: d.detectedAt.toString().split('.').first,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flag_rounded),
                label: Text(context.tr('report')),
                onPressed: () =>
                    context.go('/detections/${d.detectionId}/report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _platformLabel(BuildContext context, String p) =>
      AppLocale.platform(context, p);
}

class _DetailHero extends StatelessWidget {
  final Detection detection;
  const _DetailHero({required this.detection});

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
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              color: AppTheme.danger,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Text(
              context.tr('dangerDetected'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        context.tr('myOriginalPhoto'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 6),
                      _ThumbnailBox(
                        url:
                            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.double_arrow,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        context.tr('fakeInstagramProfile'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.danger,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ThumbnailBox(
                        url: detection.screenshotUrl ??
                            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
                        badge: context.tr('infringementInProgress'),
                      ),
                    ],
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

class _ThumbnailBox extends StatelessWidget {
  final String url;
  final String? badge;
  const _ThumbnailBox({required this.url, this.badge});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
            onError: (_, __) {},
          ),
        ),
        child: badge != null
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
