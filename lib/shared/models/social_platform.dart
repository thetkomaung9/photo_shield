enum SocialPlatform {
  facebook,
  instagram,
  kakao,
  naver;
}

extension SocialPlatformX on SocialPlatform {
  String get id => switch (this) {
        SocialPlatform.facebook => 'facebook',
        SocialPlatform.instagram => 'instagram',
        SocialPlatform.kakao => 'kakao',
        SocialPlatform.naver => 'naver',
      };

  String get platformId => switch (this) {
        SocialPlatform.facebook => 'facebook',
        SocialPlatform.instagram => 'instagram',
        SocialPlatform.kakao => 'kakao_story',
        SocialPlatform.naver => 'naver',
      };

  String get labelKey => switch (this) {
        SocialPlatform.facebook => 'platformFacebook',
        SocialPlatform.instagram => 'platformInstagram',
        SocialPlatform.kakao => 'platformKakaoStory',
        SocialPlatform.naver => 'platformNaver',
      };

  String get loginLabelKey => switch (this) {
        SocialPlatform.facebook => 'loginWithFacebook',
        SocialPlatform.instagram => 'loginWithInstagram',
        SocialPlatform.kakao => 'loginWithKakao',
        SocialPlatform.naver => 'loginWithNaver',
      };

  String get pushTopic => 'monitoring_${id}';

  static SocialPlatform fromId(String id) {
    return SocialPlatform.values.firstWhere(
      (platform) => platform.id == id || platform.platformId == id,
      orElse: () => SocialPlatform.instagram,
    );
  }
}
