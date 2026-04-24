import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/photoshield_logo.dart';
import '../providers/liveness_provider.dart';
import '../providers/photo_provider.dart';

/// 사진 등록 화면 — 목업과 동일한 점선 업로드 박스 + 단일 네이비 CTA.
class PhotoRegisterScreen extends ConsumerStatefulWidget {
  const PhotoRegisterScreen({super.key});

  @override
  ConsumerState<PhotoRegisterScreen> createState() =>
      _PhotoRegisterScreenState();
}

class _PhotoRegisterScreenState extends ConsumerState<PhotoRegisterScreen> {
  final _picker = ImagePicker();
  final List<XFile> _selected = [];
  bool _uploading = false;

  Future<void> _runLivenessCheck() async {
    final error = await ref.read(livenessProvider.notifier).runCheck(_picker);
    if (!mounted || error == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocale.maybeTranslateRaw(context, error))),
    );
  }

  Future<void> _pickFromGallery() async {
    final files = await _picker.pickMultiImage(limit: 5);
    if (files.isEmpty) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(files.take(5));
    });
  }

  Future<void> _upload() async {
    final liveness = ref.read(livenessProvider);
    if (!liveness.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('liveCheckRequired'))),
      );
      return;
    }
    if (_selected.isEmpty) {
      // 목업에서는 단순히 갤러리 열기
      await _pickFromGallery();
      if (_selected.isEmpty) return;
    }
    setState(() => _uploading = true);
    final err = await ref.read(photosProvider.notifier).uploadPhotos(_selected);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.maybeTranslateRaw(context, err))),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('photoRegistered'))),
    );
    await ref.read(pushNotificationServiceProvider).showLocalAlert(
      title: context.tr('monitoringArmedTitle'),
      body: context.tr('monitoringArmedBody'),
      data: const {'type': 'onboarding_complete'},
    );
    ref.read(livenessProvider.notifier).reset();
    context.go('/protect');
  }

  @override
  Widget build(BuildContext context) {
    final liveness = ref.watch(livenessProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/protect'),
        ),
        title: const PhotoShieldAppBarTitle(
          textColor: AppTheme.textPrimary,
          subTextColor: AppTheme.textPrimary,
          shieldColor: AppTheme.primary,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                context.tr('photoRegisterTitle'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              _LivenessCard(
                challengeText: context.tr(liveness.challengeKey),
                isVerified: liveness.isVerified,
                verifiedAt: liveness.verifiedAt,
                isChecking: liveness.isChecking,
                onPressed: _runLivenessCheck,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GestureDetector(
                  onTap: _pickFromGallery,
                  child: _DashedDropzone(files: _selected),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('photoRegisterDesc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _upload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          context.tr('selectFromGallery'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivenessCard extends StatelessWidget {
  const _LivenessCard({
    required this.challengeText,
    required this.isVerified,
    required this.verifiedAt,
    required this.isChecking,
    required this.onPressed,
  });

  final String challengeText;
  final bool isVerified;
  final DateTime? verifiedAt;
  final bool isChecking;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E1FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('liveCheckTitle'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                isVerified
                    ? context.tr('livenessVerified')
                    : context.tr('livenessPending'),
                style: TextStyle(
                  color: isVerified ? AppTheme.safe : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challengeText,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          if (verifiedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${context.tr('liveCheckVerifiedAt')}: ${AppLocale.relativeTime(context, verifiedAt!)}',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isChecking ? null : onPressed,
            icon: const Icon(Icons.camera_front_outlined),
            label: Text(context.tr('startLiveCheck')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDropzone extends StatelessWidget {
  final List<XFile> files;
  const _DashedDropzone({required this.files});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Center(
        child: files.isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 80, color: Color(0xFFB0B5BD)),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('uploadPhotoPrompt'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7B7F86),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: files
                      .map((f) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(f.path),
                              fit: BoxFit.cover,
                            ),
                          ))
                      .toList(),
                ),
              ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7CCD3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    final path = Path()..addRRect(rrect);

    const dash = 10.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, dist + dash),
          paint,
        );
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
