class Detection {
  final String detectionId;
  final String platform;
  final String foundUrl;
  final String? screenshotUrl;
  final double similarity;
  final String? originalPhotoId;
  final DateTime detectedAt;
  final DetectionStatus status;
  final String? reportUrl;

  const Detection({
    required this.detectionId,
    required this.platform,
    required this.foundUrl,
    this.screenshotUrl,
    required this.similarity,
    this.originalPhotoId,
    required this.detectedAt,
    required this.status,
    this.reportUrl,
  });

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
    detectionId: json['detection_id'],
    platform: json['platform'],
    foundUrl: json['found_url'],
    screenshotUrl: json['screenshot_url'],
    similarity: (json['similarity'] as num).toDouble(),
    originalPhotoId: json['original_photo_id'],
    detectedAt: DateTime.parse(json['detected_at']),
    status: DetectionStatus.fromString(json['status']),
    reportUrl: json['report_url'],
  );
}

enum DetectionStatus {
  unread,
  read,
  reported,
  falsePositive;

  static DetectionStatus fromString(String s) => switch (s) {
    'read' => read,
    'reported' => reported,
    'false_positive' => falsePositive,
    _ => unread,
  };

  String get label => switch (this) {
    unread => '미확인',
    read => '확인됨',
    reported => '신고완료',
    falsePositive => '오탐지',
  };
}
