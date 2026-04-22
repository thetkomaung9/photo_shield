import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../shared/models/photo.dart';
import '../../../shared/widgets/photoshield_logo.dart';
import '../providers/photo_provider.dart';

/// "보호" 탭 — 등록된 내 사진 그리드와 추가 등록 CTA.
class PhotoListScreen extends ConsumerWidget {
  const PhotoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(photosProvider);

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
        data: (photos) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '보호 중인 사진',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '총 ${photos.length}장의 사진을 AI가 모니터링합니다.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: photos.isEmpty
                    ? const _EmptyState()
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: photos.length,
                        itemBuilder: (_, i) => _PhotoTile(photo: photos[i]),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/photos/register'),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text(
                    '사진 등록',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.shield_outlined, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 12),
          Text(
            '아직 등록된 사진이 없습니다.\n사진을 등록하고 모니터링을 시작해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Photo photo;
  const _PhotoTile({required this.photo});

  bool get _isLocal {
    final t = photo.thumbnailUrl;
    if (t == null) return false;
    return !(t.startsWith('http://') || t.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: photo.thumbnailUrl == null
                  ? Container(color: Colors.grey.shade200)
                  : _isLocal
                      ? Image.file(File(photo.thumbnailUrl!),
                          fit: BoxFit.cover)
                      : Image.network(photo.thumbnailUrl!,
                          fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: photo.status == 'monitoring'
                        ? AppTheme.safe
                        : AppTheme.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    photo.status == 'monitoring' ? '모니터링 중' : '학습 중',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
