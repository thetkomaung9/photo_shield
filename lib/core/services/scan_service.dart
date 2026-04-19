import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

/// 스캔/모니터링 서비스
/// FastAPI 백엔드의 /scan 엔드포인트와 통신
class ScanService {
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;
  ScanService._internal();

  final _dio = ApiService().dio;

  /// 수동 스캔 시작
  /// 백엔드에서 크롤링 + AI 매칭 작업을 백그라운드로 실행
  Future<ScanResult> startManualScan() async {
    try {
      final res = await _dio.post('/scan/start');
      return ScanResult(
        success: true,
        message: res.data['message'] ?? '스캔이 시작되었습니다.',
        scanId: res.data['scan_id'],
      );
    } on DioException catch (e) {
      final code = e.response?.data?['error']?['code'];
      if (code == 'SCAN_IN_PROGRESS') {
        return const ScanResult(
          success: false,
          message: '이미 스캔이 진행 중입니다.',
        );
      }
      if (code == 'NO_PHOTOS_REGISTERED') {
        return const ScanResult(
          success: false,
          message: '등록된 사진이 없습니다. 먼저 사진을 등록해 주세요.',
        );
      }
      return const ScanResult(
        success: false,
        message: '스캔 시작에 실패했습니다.',
      );
    }
  }

  /// 스캔 상태 확인
  Future<ScanStatus> getScanStatus() async {
    try {
      final res = await _dio.get('/scan/status');
      return ScanStatus.fromJson(res.data);
    } catch (_) {
      return const ScanStatus(
        isRunning: false,
        progress: 0,
        lastScanAt: null,
        nextScanAt: null,
      );
    }
  }

  /// 스캔 중단
  Future<bool> cancelScan() async {
    try {
      await _dio.post('/scan/cancel');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 모니터링 플랫폼 설정 조회
  Future<List<MonitoringPlatform>> getPlatforms() async {
    try {
      final res = await _dio.get('/scan/platforms');
      final list = res.data['platforms'] as List;
      return list.map((e) => MonitoringPlatform.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 모니터링 플랫폼 활성화/비활성화
  Future<bool> togglePlatform(String platformId, bool enabled) async {
    try {
      await _dio
          .patch('/scan/platforms/$platformId', data: {'enabled': enabled});
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ScanResult {
  final bool success;
  final String message;
  final String? scanId;

  const ScanResult({
    required this.success,
    required this.message,
    this.scanId,
  });
}

class ScanStatus {
  final bool isRunning;
  final int progress; // 0-100
  final DateTime? lastScanAt;
  final DateTime? nextScanAt;
  final String? currentPlatform;
  final int? foundCount;

  const ScanStatus({
    required this.isRunning,
    required this.progress,
    this.lastScanAt,
    this.nextScanAt,
    this.currentPlatform,
    this.foundCount,
  });

  factory ScanStatus.fromJson(Map<String, dynamic> json) => ScanStatus(
        isRunning: json['is_running'] ?? false,
        progress: json['progress'] ?? 0,
        lastScanAt: json['last_scan_at'] != null
            ? DateTime.parse(json['last_scan_at'])
            : null,
        nextScanAt: json['next_scan_at'] != null
            ? DateTime.parse(json['next_scan_at'])
            : null,
        currentPlatform: json['current_platform'],
        foundCount: json['found_count'],
      );
}

class MonitoringPlatform {
  final String id;
  final String name;
  final String iconUrl;
  final bool enabled;
  final bool isOfficialApi; // 공식 API 사용 여부 (네이버, 카카오)

  const MonitoringPlatform({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.enabled,
    required this.isOfficialApi,
  });

  factory MonitoringPlatform.fromJson(Map<String, dynamic> json) =>
      MonitoringPlatform(
        id: json['id'],
        name: json['name'],
        iconUrl: json['icon_url'] ?? '',
        enabled: json['enabled'] ?? true,
        isOfficialApi: json['is_official_api'] ?? false,
      );
}

/// Scan Status Provider
class ScanStatusNotifier extends StateNotifier<ScanStatus> {
  final ScanService _service;

  ScanStatusNotifier(this._service)
      : super(const ScanStatus(isRunning: false, progress: 0));

  Future<void> refresh() async {
    state = await _service.getScanStatus();
  }

  Future<ScanResult> startScan() async {
    final result = await _service.startManualScan();
    if (result.success) {
      await refresh();
    }
    return result;
  }

  Future<void> cancelScan() async {
    await _service.cancelScan();
    await refresh();
  }
}

final scanServiceProvider = Provider<ScanService>((ref) => ScanService());

final scanStatusProvider =
    StateNotifierProvider<ScanStatusNotifier, ScanStatus>((ref) {
  return ScanStatusNotifier(ref.watch(scanServiceProvider));
});

final platformsProvider = FutureProvider<List<MonitoringPlatform>>((ref) async {
  return ref.watch(scanServiceProvider).getPlatforms();
});
