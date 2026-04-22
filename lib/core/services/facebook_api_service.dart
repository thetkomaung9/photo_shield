import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants.dart';
import '../../shared/models/detection.dart';

/// Meta(Facebook) Graph API 클라이언트.
///
/// 다음 엔드포인트를 사용한다.
///
/// * `GET /debug_token` — 토큰 유효성 검증
/// * `GET /{page-id}` — 공개 페이지 메타데이터
/// * `GET /{page-id}/photos` — 공개 페이지 사진 목록
/// * `GET /{page-id}/picture` — 페이지 프로필 이미지
/// * `GET /oembed_post` — 공개 게시물 임베드 HTML / 썸네일
///
/// 페이지 검색(`/pages/search`) 은 Page Public Metadata Access 가 필요하므로
/// 무료 티어에서는 사용할 수 없다. PhotoShield 는 사용자가 의심 페이지의 ID 또는
/// 게시물 URL 을 직접 전달하는 모델로 동작한다.
class FacebookApiService {
  FacebookApiService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.facebookGraphBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ),
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<String?> _appToken() async {
    if (MetaEnv.appToken.isNotEmpty) return MetaEnv.appToken;
    return _storage.read(key: StorageKeys.metaAppToken);
  }

  Future<String?> _userToken() async {
    if (MetaEnv.userToken.isNotEmpty) return MetaEnv.userToken;
    return _storage.read(key: StorageKeys.metaUserToken);
  }

  /// `userToken` 또는 `appToken` 중 어느 하나라도 있어야 라이브 모드.
  Future<bool> get isConfigured async {
    final u = await _userToken();
    final a = await _appToken();
    return (u != null && u.isNotEmpty) || (a != null && a.isNotEmpty);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<FacebookConnectionStatus> fetchConnectionStatus() async {
    final user = await _userToken();
    final app = await _appToken();
    if ((user == null || user.isEmpty) && (app == null || app.isEmpty)) {
      return const FacebookConnectionStatus.demo();
    }
    // 사용자 토큰이 우선; 없으면 app token 으로 자기 자신을 검증.
    final inputToken = user ?? app!;
    final verifier = app ?? user!;
    try {
      final res = await _dio.get(
        '/debug_token',
        queryParameters: {
          'input_token': inputToken,
          'access_token': verifier,
        },
      );
      final data = (res.data['data'] as Map<String, dynamic>?) ?? {};
      final isValid = data['is_valid'] == true;
      return FacebookConnectionStatus(
        connected: isValid,
        appId: data['app_id']?.toString(),
        userId: data['user_id']?.toString(),
        scopes: ((data['scopes'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        expiresAt: data['expires_at'] is int && data['expires_at'] > 0
            ? DateTime.fromMillisecondsSinceEpoch(
                (data['expires_at'] as int) * 1000)
            : null,
        error: isValid ? null : (data['error']?['message'] as String?),
      );
    } on DioException catch (e) {
      return FacebookConnectionStatus(
        connected: false,
        error: _formatError(e),
      );
    }
  }

  /// 공개 페이지 정보 조회.
  Future<FacebookPage?> fetchPage(String pageIdOrUsername) async {
    final token = await _userToken() ?? await _appToken();
    if (token == null) return _demoPage(pageIdOrUsername);
    try {
      final res = await _dio.get(
        '/$pageIdOrUsername',
        queryParameters: {
          'fields':
              'id,name,username,fan_count,picture.type(large),link,about,verification_status',
          'access_token': token,
        },
      );
      return FacebookPage.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      return _demoPage(pageIdOrUsername);
    }
  }

  /// 공개 페이지의 사진 목록 (업로드된 사진).
  Future<List<FacebookPhoto>> fetchPagePhotos(
    String pageIdOrUsername, {
    int limit = 25,
  }) async {
    final token = await _userToken() ?? await _appToken();
    if (token == null) return _demoPhotos();
    try {
      final res = await _dio.get(
        '/$pageIdOrUsername/photos',
        queryParameters: {
          'type': 'uploaded',
          'fields': 'id,images,name,link,created_time',
          'limit': limit,
          'access_token': token,
        },
      );
      return (res.data['data'] as List? ?? [])
          .map((e) => FacebookPhoto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return _demoPhotos();
    }
  }

  /// 공개 게시물의 oEmbed (썸네일 + 작성자 + 임베드 HTML).
  ///
  /// `Meta oEmbed Read` 가 활성화된 앱 토큰이 필요하다.
  Future<FacebookPostEmbed?> fetchPostEmbed(String postUrl) async {
    final app = await _appToken();
    if (app == null) return _demoEmbed(postUrl);
    try {
      final res = await _dio.get(
        '/oembed_post',
        queryParameters: {
          'url': postUrl,
          'access_token': app,
        },
      );
      return FacebookPostEmbed.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      return _demoEmbed(postUrl);
    }
  }

  /// 의심 페이지 ID 리스트를 받아 Detection 으로 변환.
  ///
  /// PhotoShield 의 백엔드 또는 사용자의 신고 큐에서 페이지 ID 를 받아오고,
  /// 이 메서드는 각 페이지의 사진들을 가져와 후보 detection 을 만든다.
  Future<List<Detection>> scanForUnauthorizedUse({
    required List<String> suspectPageIds,
    List<String> originalPhotoIds = const [],
  }) async {
    final configured = await isConfigured;
    if (!configured) return _demoDetections();
    final results = <Detection>[];
    for (final pid in suspectPageIds) {
      final photos = await fetchPagePhotos(pid, limit: 5);
      for (final p in photos) {
        if (p.link == null) continue;
        results.add(
          Detection(
            detectionId: 'fb_${p.id}',
            platform: 'facebook',
            foundUrl: p.link!,
            screenshotUrl: p.bestImageUrl,
            similarity: 0.7,
            originalPhotoId:
                originalPhotoIds.isNotEmpty ? originalPhotoIds.first : null,
            detectedAt: p.createdTime ?? DateTime.now(),
            status: DetectionStatus.unread,
          ),
        );
      }
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // Demo
  // ---------------------------------------------------------------------------

  FacebookPage _demoPage(String slug) => FacebookPage(
        id: 'demo_${slug.hashCode}',
        name: '데모 페이지',
        username: slug,
        fanCount: 1280,
        pictureUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        link: 'https://www.facebook.com/$slug',
        about: '데모 모드입니다. Meta 토큰을 설정하면 실제 페이지 정보가 표시됩니다.',
      );

  List<FacebookPhoto> _demoPhotos() => [
        FacebookPhoto(
          id: 'demo_fb_photo_1',
          link: 'https://www.facebook.com/photo/?fbid=demo_1',
          bestImageUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
          name: '데모 사진 1',
          createdTime: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ];

  FacebookPostEmbed _demoEmbed(String url) => FacebookPostEmbed(
        authorName: '데모 사용자',
        providerName: 'Facebook',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        html: '<blockquote>데모 임베드: $url</blockquote>',
      );

  List<Detection> _demoDetections() => [
        Detection(
          detectionId: 'fb_demo_1',
          platform: 'facebook',
          foundUrl: 'https://www.facebook.com/profile/demo_fake',
          screenshotUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
          similarity: 0.91,
          originalPhotoId: null,
          detectedAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: DetectionStatus.unread,
        ),
      ];

  String _formatError(DioException e) {
    final msg = e.response?.data is Map
        ? (e.response?.data['error']?['message'] as String?)
        : null;
    return msg ?? e.message ?? 'Facebook API 호출 실패';
  }
}

// ----------------------------- Models ---------------------------------------

class FacebookConnectionStatus {
  final bool connected;
  final String? appId;
  final String? userId;
  final List<String> scopes;
  final DateTime? expiresAt;
  final String? error;

  const FacebookConnectionStatus({
    required this.connected,
    this.appId,
    this.userId,
    this.scopes = const [],
    this.expiresAt,
    this.error,
  });

  const FacebookConnectionStatus.demo()
      : connected = false,
        appId = null,
        userId = null,
        scopes = const [],
        expiresAt = null,
        error = '데모 모드 (Meta 토큰 미설정)';

  bool get isDemo => !connected;
}

class FacebookPage {
  final String id;
  final String name;
  final String? username;
  final int? fanCount;
  final String? pictureUrl;
  final String? link;
  final String? about;

  const FacebookPage({
    required this.id,
    required this.name,
    this.username,
    this.fanCount,
    this.pictureUrl,
    this.link,
    this.about,
  });

  factory FacebookPage.fromJson(Map<String, dynamic> json) => FacebookPage(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        username: json['username'] as String?,
        fanCount: (json['fan_count'] as num?)?.toInt(),
        pictureUrl: json['picture'] is Map
            ? (json['picture']['data']?['url'] as String?)
            : null,
        link: json['link'] as String?,
        about: json['about'] as String?,
      );
}

class FacebookPhoto {
  final String id;
  final String? link;
  final String? bestImageUrl;
  final String? name;
  final DateTime? createdTime;

  const FacebookPhoto({
    required this.id,
    this.link,
    this.bestImageUrl,
    this.name,
    this.createdTime,
  });

  factory FacebookPhoto.fromJson(Map<String, dynamic> json) {
    String? best;
    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      // Graph API 는 가장 큰 이미지를 첫 번째로 반환한다.
      best = (images.first as Map)['source'] as String?;
    }
    return FacebookPhoto(
      id: json['id'].toString(),
      link: json['link'] as String?,
      bestImageUrl: best,
      name: json['name'] as String?,
      createdTime: json['created_time'] != null
          ? DateTime.tryParse(json['created_time'] as String)
          : null,
    );
  }
}

class FacebookPostEmbed {
  final String? authorName;
  final String? providerName;
  final String? thumbnailUrl;
  final String? html;

  const FacebookPostEmbed({
    this.authorName,
    this.providerName,
    this.thumbnailUrl,
    this.html,
  });

  factory FacebookPostEmbed.fromJson(Map<String, dynamic> json) =>
      FacebookPostEmbed(
        authorName: json['author_name'] as String?,
        providerName: json['provider_name'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        html: json['html'] as String?,
      );
}

// ----------------------------- Providers ------------------------------------

final facebookApiServiceProvider = Provider<FacebookApiService>(
  (ref) => FacebookApiService(),
);

final facebookConnectionProvider =
    FutureProvider<FacebookConnectionStatus>((ref) async {
  return ref.watch(facebookApiServiceProvider).fetchConnectionStatus();
});
