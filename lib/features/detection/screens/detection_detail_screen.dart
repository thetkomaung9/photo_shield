import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/detection_provider.dart';

class DetectionDetailScreen extends ConsumerWidget {
  final String id;
  const DetectionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionAsync = ref.watch(detectionDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('탐지 결과 상세')),
      body: detectionAsync.when(
        data: (d) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사진 비교
              Row(
                children: [
                  Expanded(
                    child: _PhotoBox(
                      label: '내 원본 사진',
                      url: null, // TODO: original photo thumbnail
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoBox(label: '도용 의심 사진', url: d.screenshotUrl),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 유사도
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI 유사도 분석',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${(d.similarity * 100).toStringAsFixed(1)}% 일치',
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 정보
              _InfoRow(
                label: '플랫폼',
                value: d.platform == 'naver_blog' ? '네이버 블로그' : '카카오스토리',
              ),
              _InfoRow(label: '탐지 시각', value: d.detectedAt.toString()),
              const SizedBox(height: 8),
              const Text(
                '발견 URL',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(d.foundUrl)),
                child: Text(
                  d.foundUrl,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: '신고하기',
                onPressed: () => context.go('/detections/$id/report'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // TODO: PATCH status = false_positive
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('오탐지 신고'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('정보를 불러오지 못했습니다.')),
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  final String label;
  final String? url;
  const _PhotoBox({required this.label, this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: url != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: AppTheme.textSecondary,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
