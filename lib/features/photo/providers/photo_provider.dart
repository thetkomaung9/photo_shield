import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/photo.dart';

class PhotosNotifier extends AsyncNotifier<List<Photo>> {
  @override
  Future<List<Photo>> build() async {
    final res = await ApiService().dio.get('/photos');
    final list = res.data['photos'] as List;
    return list.map((e) => Photo.fromJson(e)).toList();
  }

  Future<String?> uploadPhotos(List<XFile> files) async {
    try {
      final formData = FormData.fromMap({
        'files': await Future.wait(
          files.map(
            (f) async => await MultipartFile.fromFile(f.path, filename: f.name),
          ),
        ),
      });
      await ApiService().dio.post('/photos', data: formData);
      ref.invalidateSelf();
      return null;
    } on DioException catch (e) {
      final code = e.response?.data?['error']?['code'];
      if (code == 'FACE_NOT_DETECTED') return '얼굴을 인식할 수 없습니다. 정면 사진을 사용해 주세요.';
      if (code == 'PHOTO_LIMIT_EXCEEDED') return '사진 등록 한도(5장)를 초과했습니다.';
      return '사진 등록에 실패했습니다.';
    }
  }

  Future<void> deletePhoto(String photoId) async {
    await ApiService().dio.delete('/photos/$photoId');
    ref.invalidateSelf();
  }
}

final photosProvider = AsyncNotifierProvider<PhotosNotifier, List<Photo>>(
  PhotosNotifier.new,
);
