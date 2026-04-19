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
                      _platformLabel(detection.platform),
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

  String _platformLabel(String platform) => switch (platform) {
    'naver_blog' => '네이버 블로그',
    'kakao_story' => '카카오스토리',
    _ => platform,
  };
}

class _PlatformIcon extends StatelessWidget {
  final String platform;
  const _PlatformIcon({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: platform == 'naver_blog'
            ? const Color(0xFF03C75A)
            : const Color(0xFFFFE812),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          platform == 'naver_blog' ? 'N' : 'K',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: platform == 'naver_blog' ? Colors.white : Colors.black,
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
        color: AppTheme.danger.withOpacity(0.1),
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
        color: color.withOpacity(0.1),
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
