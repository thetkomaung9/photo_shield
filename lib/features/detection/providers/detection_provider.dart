import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/mock_data.dart';
import '../../../core/services/unified_monitoring_service.dart';
import '../../../shared/models/detection.dart';

/// 통합 detections 프로바이더.
///
/// 1) 기본은 [MockData.detections] 를 즉시 반환한다.
/// 2) Meta API 토큰(`META_USER_TOKEN` 등)이 설정되어 있을 때만
///    Instagram/Facebook 라이브 스캔 결과를 추가로 병합한다.
///
/// 자체 백엔드(`https://api.photoshield.kr/v1`) 는 더 이상 호출하지 않는다.
final detectionsProvider = FutureProvider<List<Detection>>((ref) async {
  try {
    final snapshot = await ref.watch(monitoringSnapshotProvider.future);
    return snapshot.detections;
  } catch (_) {
    final base = [...MockData.detections]
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
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
