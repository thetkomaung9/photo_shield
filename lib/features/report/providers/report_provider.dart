import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// 데모 모드 신고 리포트 생성 — 백엔드 호출 없이 항상 성공한다.
class ReportNotifier extends FamilyNotifier<ReportState, String> {
  @override
  ReportState build(String arg) => const ReportState();

  Future<void> generate() async {
    state = const ReportState(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));
    state = ReportState(
      pdfUrl: 'https://example.com/photoshield/reports/$arg.pdf',
    );
  }
}

final reportProvider =
    NotifierProviderFamily<ReportNotifier, ReportState, String>(
  ReportNotifier.new,
);
