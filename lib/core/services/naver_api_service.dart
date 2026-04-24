import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/models/detection.dart';
import 'api_service.dart';
import '../constants.dart';

class NaverApiService {
  NaverApiService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? ApiService().dio,
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<String?> _accessToken() =>
      _storage.read(key: StorageKeys.naverAccessToken);

  Future<bool> get isConfigured async {
    final token = await _accessToken();
    return NaverEnv.isConfigured || (token != null && token.isNotEmpty);
  }

  Future<NaverConnectionStatus> fetchConnectionStatus() async {
    final token = await _accessToken();
    if (token == null || token.isEmpty) {
      return const NaverConnectionStatus.demo();
    }

    return NaverConnectionStatus(
      connected: true,
      accountName: 'Naver linked user',
      connectedAt: DateTime.now(),
    );
  }

  Future<List<Detection>> scanForUnauthorizedUse({
    required List<String> keywords,
    List<String> originalPhotoIds = const [],
  }) async {
    final token = await _accessToken();
    if (token == null || token.isEmpty) {
      return _demoDetections();
    }

    if (keywords.isEmpty) {
      return const [];
    }

    try {
      final response = await _dio.post(
        ApiConstants.resolveBackendUrl(MonitoringEnv.naverEndpoint),
        data: {
          'keywords': keywords,
          'originalPhotoIds': originalPhotoIds,
          'accessToken': token,
        },
      );

      return _parseDetections(response.data, 'naver_blog', originalPhotoIds);
    } on DioException {
      return _demoDetections();
    }
  }

  List<Detection> _parseDetections(
    dynamic responseData,
    String defaultPlatform,
    List<String> originalPhotoIds,
  ) {
    final rawList = switch (responseData) {
      List<dynamic> list => list,
      Map<String, dynamic> map when map['detections'] is List<dynamic> =>
        map['detections'] as List<dynamic>,
      Map<String, dynamic> map when map['items'] is List<dynamic> =>
        map['items'] as List<dynamic>,
      _ => const <dynamic>[],
    };

    return rawList.whereType<Map>().map((raw) {
      final map = Map<String, dynamic>.from(raw);
      return Detection(
        detectionId: map['detectionId']?.toString() ??
            map['id']?.toString() ??
            'naver_${map.hashCode}',
        platform: map['platform']?.toString() ?? defaultPlatform,
        foundUrl: map['foundUrl']?.toString() ??
            map['url']?.toString() ??
            'https://blog.naver.com/',
        screenshotUrl:
            map['screenshotUrl']?.toString() ?? map['imageUrl']?.toString(),
        similarity: (map['similarity'] as num?)?.toDouble() ?? 0.0,
        originalPhotoId: map['originalPhotoId']?.toString() ??
            (originalPhotoIds.isNotEmpty ? originalPhotoIds.first : null),
        detectedAt: DateTime.tryParse(map['detectedAt']?.toString() ?? '') ??
            DateTime.now(),
        status: _parseStatus(map['status']?.toString()),
      );
    }).toList();
  }

  DetectionStatus _parseStatus(String? rawStatus) {
    switch (rawStatus) {
      case 'read':
        return DetectionStatus.read;
      case 'reported':
        return DetectionStatus.reported;
      default:
        return DetectionStatus.unread;
    }
  }

  List<Detection> _demoDetections() => [
        Detection(
          detectionId: 'naver_demo_pipeline_1',
          platform: 'naver_blog',
          foundUrl: 'https://blog.naver.com/fakeuser123/photo',
          screenshotUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600',
          similarity: 0.87,
          detectedAt: DateTime.now().subtract(const Duration(days: 2)),
          status: DetectionStatus.reported,
        ),
      ];
}

class NaverConnectionStatus {
  final bool connected;
  final String? accountName;
  final DateTime? connectedAt;
  final String? error;

  const NaverConnectionStatus({
    required this.connected,
    this.accountName,
    this.connectedAt,
    this.error,
  });

  const NaverConnectionStatus.demo()
      : connected = false,
        accountName = null,
        connectedAt = null,
        error = null;
}

final naverApiServiceProvider = Provider<NaverApiService>((ref) {
  return NaverApiService();
});
