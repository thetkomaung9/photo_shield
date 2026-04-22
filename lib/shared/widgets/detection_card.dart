import 'package:flutter/material.dart';
import '../models/detection.dart';
import '../../core/theme.dart';

class DetectionCard extends StatelessWidget {
  final Detection detection;
  final VoidCallback onTap;

  const DetectionCard({
    super.key,
    required this.detection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _PlatformIcon(platform: detection.platform),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platformLabel(detection.platform),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detection.foundUrl,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _SimilarityBadge(similarity: detection.similarity),
                        const SizedBox(width: 8),
                        _StatusBadge(status: detection.status),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// 다른 위젯에서도 동일 매핑을 재사용하기 위해 top-level 로 노출.
String platformLabel(String platform) => switch (platform) {
      'naver_blog' => '네이버 블로그',
      'kakao_story' => '카카오스토리',
      'instagram' => '인스타그램',
      'facebook' => '페이스북',
      _ => platform,
    };

class _PlatformVisual {
  final Color background;
  final Color foreground;
  final String label;
  const _PlatformVisual(this.background, this.foreground, this.label);
}

_PlatformVisual _visualFor(String platform) => switch (platform) {
      'naver_blog' =>
        const _PlatformVisual(Color(0xFF03C75A), Colors.white, 'N'),
      'kakao_story' =>
        const _PlatformVisual(Color(0xFFFFE812), Colors.black, 'K'),
      'instagram' =>
        const _PlatformVisual(Color(0xFFE1306C), Colors.white, 'IG'),
      'facebook' =>
        const _PlatformVisual(Color(0xFF1877F2), Colors.white, 'F'),
      _ => const _PlatformVisual(Color(0xFF94A3B8), Colors.white, '?'),
    };

class _PlatformIcon extends StatelessWidget {
  final String platform;
  const _PlatformIcon({required this.platform});

  @override
  Widget build(BuildContext context) {
    final v = _visualFor(platform);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: v.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          v.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: v.label.length > 1 ? 14 : 18,
            color: v.foreground,
          ),
        ),
      ),
    );
  }
}

class _SimilarityBadge extends StatelessWidget {
  final double similarity;
  const _SimilarityBadge({required this.similarity});

  @override
  Widget build(BuildContext context) {
    final pct = (similarity * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '유사도 $pct%',
        style: const TextStyle(
          color: AppTheme.danger,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DetectionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DetectionStatus.unread => AppTheme.warning,
      DetectionStatus.reported => AppTheme.safe,
      DetectionStatus.falsePositive => AppTheme.textSecondary,
      _ => AppTheme.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
