import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/mock_data.dart';
import '../../../shared/models/photo.dart';

/// 등록된 사진 목록 프로바이더.
///
/// 데모 모드에서는 [MockData.photos] 를 반환하고, 사용자가 추가로 등록한
/// 사진은 메모리 상에서만 누적된다. 실제 백엔드(`/photos`)가 살아 있다고
/// 가정한 코드는 모두 제거됐다.
class PhotosNotifier extends AsyncNotifier<List<Photo>> {
  // 사용자가 데모 모드에서 새로 추가한 사진들 — 앱 재시작 시 초기화된다.
  final List<Photo> _added = [];

  @override
  Future<List<Photo>> build() async {
    // 미세한 지연으로 로딩 상태를 그대로 유지하되, 절대 실패하지 않는다.
    await Future.delayed(const Duration(milliseconds: 200));
    return [..._added, ...MockData.photos];
  }

  /// 갤러리/카메라에서 선택한 사진을 데모 목록에 추가한다.
  ///
  /// 백엔드 호출 없이 항상 성공한다. 5장 초과 시에만 안내 메시지를 반환한다.
  Future<String?> uploadPhotos(List<XFile> files) async {
    if (files.isEmpty) return '선택된 사진이 없습니다.';
    final remaining = 5 - (_added.length + MockData.photos.length);
    if (remaining <= 0) {
      return '사진 등록 한도(5장)를 초과했습니다.';
    }
    // 얼굴 학습/벡터 추출을 흉내 내는 가짜 지연.
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    for (final f in files.take(remaining)) {
      _added.insert(
        0,
        Photo(
          photoId: 'photo_local_${now.microsecondsSinceEpoch}_${f.name.hashCode}',
          thumbnailUrl: f.path, // 로컬 파일 경로
          registeredAt: now,
          status: 'monitoring',
        ),
      );
    }
    ref.invalidateSelf();
    return null;
  }

  /// 등록한 사진을 삭제한다.
  Future<void> deletePhoto(String photoId) async {
    _added.removeWhere((p) => p.photoId == photoId);
    ref.invalidateSelf();
  }
}

final photosProvider = AsyncNotifierProvider<PhotosNotifier, List<Photo>>(
  PhotosNotifier.new,
);
