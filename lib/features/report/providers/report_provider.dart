import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

class ReportState {
  final bool isLoading;
  final String? pdfUrl;
  final String? error;
  const ReportState({this.isLoading = false, this.pdfUrl, this.error});
  ReportState copyWith({bool? isLoading, String? pdfUrl, String? error}) =>
      ReportState(
        isLoading: isLoading ?? this.isLoading,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        error: error,
      );
}

class ReportNotifier extends FamilyNotifier<ReportState, String> {
  @override
  ReportState build(String arg) => const ReportState();

  Future<void> generate() async {
    state = const ReportState(isLoading: true);
    try {
      final res = await ApiService().dio.post('/detections/$arg/report');
      state = ReportState(pdfUrl: res.data['pdf_url']);
    } catch (_) {
      state = const ReportState(error: 'PDF 생성 실패');
    }
  }
}

final reportProvider =
    NotifierProviderFamily<ReportNotifier, ReportState, String>(
      ReportNotifier.new,
    );
