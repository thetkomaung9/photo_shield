import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/photo_provider.dart';

class PhotoRegisterScreen extends ConsumerStatefulWidget {
  const PhotoRegisterScreen({super.key});

  @override
  ConsumerState<PhotoRegisterScreen> createState() =>
      _PhotoRegisterScreenState();
}

class _PhotoRegisterScreenState extends ConsumerState<PhotoRegisterScreen> {
  final _picker = ImagePicker();
  final List<XFile> _selected = [];
  _UploadStatus _status = _UploadStatus.idle;

  Future<void> _pick(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final files = await _picker.pickMultiImage(limit: 5);
      setState(
        () => _selected
          ..clear()
          ..addAll(files.take(5)),
      );
    } else {
      final file = await _picker.pickImage(source: source);
      if (file != null)
        setState(
          () => _selected
            ..clear()
            ..add(file),
        );
    }
  }

  Future<void> _upload() async {
    if (_selected.isEmpty) return;
    setState(() => _status = _UploadStatus.detecting);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _status = _UploadStatus.extracting);

    final error = await ref
        .read(photosProvider.notifier)
        .uploadPhotos(_selected);

    if (!mounted) return;
    if (error != null) {
      setState(() => _status = _UploadStatus.idle);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      setState(() => _status = _UploadStatus.done);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/photos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사진 등록')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_status == _UploadStatus.idle) ...[
              _PhotoPreview(files: _selected),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('갤러리'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('카메라'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '최대 5장까지 등록 가능합니다. 정면 사진을 사용해 주세요.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                label: '등록하기',
                onPressed: _selected.isEmpty ? null : _upload,
              ),
            ] else ...[
              const Spacer(),
              _UploadProgress(status: _status),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final List<XFile> files;
  const _PhotoPreview({required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              SizedBox(height: 8),
              Text(
                '사진을 선택해 주세요',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(files[i].path),
            width: 160,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final _UploadStatus status;
  const _UploadProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (label: '얼굴 감지 중', done: status.index >= 1),
      (label: '벡터 추출 중', done: status.index >= 2),
      (label: '등록 완료', done: status == _UploadStatus.done),
    ];

    return Column(
      children: [
        if (status == _UploadStatus.done)
          const Icon(Icons.check_circle, color: AppTheme.safe, size: 80)
        else
          const CircularProgressIndicator(),
        const SizedBox(height: 24),
        ...steps.map(
          (s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  s.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: s.done ? AppTheme.safe : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.label,
                  style: TextStyle(
                    color: s.done
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight: s.done ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _UploadStatus { idle, detecting, extracting, done }
