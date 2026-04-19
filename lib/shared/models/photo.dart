class Photo {
  final String photoId;
  final String? thumbnailUrl;
  final DateTime registeredAt;
  final String status;

  const Photo({
    required this.photoId,
    this.thumbnailUrl,
    required this.registeredAt,
    required this.status,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    photoId: json['photo_id'],
    thumbnailUrl: json['thumbnail_url'],
    registeredAt: DateTime.parse(json['registered_at']),
    status: json['status'] ?? 'monitoring',
  );
}
