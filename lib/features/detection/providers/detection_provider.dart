import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/detection.dart';

final detectionsProvider = FutureProvider<List<Detection>>((ref) async {
  final res = await ApiService().dio.get('/detections');
  final list = res.data['detections'] as List;
  return list.map((e) => Detection.fromJson(e)).toList();
});

final detectionDetailProvider = FutureProvider.family<Detection, String>((
  ref,
  id,
) async {
  final res = await ApiService().dio.get('/detections/$id');
  return Detection.fromJson(res.data);
});
