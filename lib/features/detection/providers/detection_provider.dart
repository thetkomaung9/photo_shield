import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/services/facebook_api_service.dart';
import '../../../core/services/instagram_api_service.dart';
import '../../../core/services/mock_data.dart';
import '../../../shared/models/detection.dart';

/// 통합 detections 프로바이더.
///
/// 1) 기본은 [MockData.detections] 를 즉시 반환한다.
/// 2) Meta API 토큰(`META_USER_TOKEN` 등)이 설정되어 있을 때만
///    Instagram/Facebook 라이브 스캔 결과를 추가로 병합한다.
///
/// 자체 백엔드(`https://api.photoshield.kr/v1`) 는 더 이상 호출하지 않는다.
final detectionsProvider = FutureProvider<List<Detection>>((ref) async {
  // 기본 데모 데이터 — 절대 실패하지 않는다.
  final base = [...MockData.detections];

  // Meta 토큰이 있을 때만 라이브 스캔 시도.
  final hasMetaToken = MetaEnv.userToken.isNotEmpty;
  if (!hasMetaToken) {
    base.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return base;
  }

  try {
    final ig = ref.watch(instagramApiServiceProvider);
    final fb = ref.watch(facebookApiServiceProvider);

    final tags = MetaEnv.monitorTags
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final igLive = await ig.scanForUnauthorizedUse(
      hashtags: tags.isEmpty ? const ['내사진'] : tags,
    );
    final fbLive =
        await fb.scanForUnauthorizedUse(suspectPageIds: const []);

    final merged = <String, Detection>{};
    for (final d in [...base, ...igLive, ...fbLive]) {
      merged[d.detectionId] = d;
    }
    final list = merged.values.toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return list;
  } catch (_) {
    // Meta 호출이 어떤 이유로든 실패해도 데모 데이터는 그대로 보여준다.
    base.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return base;
  }
});

/// 단일 탐지 상세 — 캐시된 리스트에서 우선 검색하고, 없으면 데모에서 재탐색.
final detectionDetailProvider = FutureProvider.family<Detection, String>((
  ref,
  id,
) async {
  final list = await ref.watch(detectionsProvider.future);
  for (final d in list) {
    if (d.detectionId == id) return d;
  }
  final fallback = MockData.findDetection(id);
  if (fallback != null) return fallback;
  // 절대 외부 API 를 호출하지 않고, 데모 데이터의 첫 항목을 안전하게 반환한다.
  return MockData.detections.first;
});
