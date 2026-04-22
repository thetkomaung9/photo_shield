import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/facebook_api_service.dart';
import '../../../core/services/instagram_api_service.dart';
import '../../../shared/models/detection.dart';

/// 통합 detections 프로바이더.
///
/// 1) 자체 백엔드(`/detections`) 호출을 먼저 시도한다.
/// 2) Meta API(Instagram + Facebook) 가 설정되어 있으면 추가 스캔 결과를 병합한다.
/// 3) 백엔드도 토큰도 모두 실패하면 Meta 서비스의 데모 데이터를 반환해
///    UI 가 비어 있지 않게 한다.
final detectionsProvider = FutureProvider<List<Detection>>((ref) async {
  final ig = ref.watch(instagramApiServiceProvider);
  final fb = ref.watch(facebookApiServiceProvider);

  // 1) 자체 백엔드 -----------------------------------------------------------
  List<Detection> backend = [];
  try {
    final res = await ApiService().dio.get('/detections');
    final list = res.data['detections'] as List? ?? [];
    backend = list.map((e) => Detection.fromJson(e)).toList();
  } on DioException catch (_) {
    backend = [];
  } catch (_) {
    backend = [];
  }

  // 2) Meta API 라이브 스캔 ---------------------------------------------------
  final tags = MetaEnv.monitorTags
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  final igLive = await ig.scanForUnauthorizedUse(
    hashtags: tags.isEmpty ? const ['내사진'] : tags,
  );
  // 백엔드에서 의심 페이지를 제공하지 않는 한 facebook 측은 보통 빈 리스트.
  final fbLive = await fb.scanForUnauthorizedUse(suspectPageIds: const []);

  // 3) 합쳐서 정렬 -----------------------------------------------------------
  final merged = <String, Detection>{};
  for (final d in [...backend, ...igLive, ...fbLive]) {
    merged[d.detectionId] = d;
  }
  final list = merged.values.toList()
    ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  return list;
});

final detectionDetailProvider = FutureProvider.family<Detection, String>((
  ref,
  id,
) async {
  // 합쳐진 리스트에서 먼저 탐색 (Meta API 결과 또는 데모 데이터 포함)
  final list = await ref.watch(detectionsProvider.future);
  final cached =
      list.where((d) => d.detectionId == id).cast<Detection?>().firstOrNull;
  if (cached != null) return cached;
  // 그 다음 자체 백엔드에 시도
  final res = await ApiService().dio.get('/detections/$id');
  return Detection.fromJson(res.data);
});

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
