class LivenessCheck {
  final bool isChecking;
  final bool isVerified;
  final String challengeKey;
  final String? capturePath;
  final DateTime? verifiedAt;
  final String? error;

  const LivenessCheck({
    this.isChecking = false,
    this.isVerified = false,
    this.challengeKey = 'livenessPromptBlink',
    this.capturePath,
    this.verifiedAt,
    this.error,
  });

  LivenessCheck copyWith({
    bool? isChecking,
    bool? isVerified,
    String? challengeKey,
    String? capturePath,
    DateTime? verifiedAt,
    String? error,
    bool clearCapturePath = false,
    bool clearVerifiedAt = false,
    bool clearError = false,
  }) {
    return LivenessCheck(
      isChecking: isChecking ?? this.isChecking,
      isVerified: isVerified ?? this.isVerified,
      challengeKey: challengeKey ?? this.challengeKey,
      capturePath: clearCapturePath ? null : (capturePath ?? this.capturePath),
      verifiedAt: clearVerifiedAt ? null : (verifiedAt ?? this.verifiedAt),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
