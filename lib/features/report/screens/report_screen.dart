import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/report_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String detectionId;
  const ReportScreen({super.key, required this.detectionId});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider(widget.detectionId).notifier).generate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider(widget.detectionId));

    return Scaffold(
      appBar: AppBar(title: const Text('신고 리포트')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: state.isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('PDF 리포트를 생성하고 있습니다...'),
                  ],
                ),
              )
            : state.error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '리포트 생성에 실패했습니다.\n화면 캡처를 이용해 주세요.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(reportProvider(widget.detectionId).notifier)
                          .generate(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // PDF 미리보기 영역
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 64,
                              color: AppTheme.danger,
                            ),
                            SizedBox(height: 12),
                            Text(
                              '신고 리포트 PDF',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'PhotoShield Korea 이미지 도용 피해 신고 리포트',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'PDF 저장',
                    onPressed: state.pdfUrl != null
                        ? () => launchUrl(Uri.parse(state.pdfUrl!))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(ApiConstants.ecrmUrl)),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('경찰청 ECRM 신고하기'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(ApiConstants.instagramReportUrl),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined,
                              color: Color(0xFFE1306C)),
                          label: const Text('인스타그램 신고'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(ApiConstants.facebookReportUrl),
                          ),
                          icon: const Icon(Icons.facebook,
                              color: Color(0xFF1877F2)),
                          label: const Text('페이스북 신고'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.pdfUrl != null)
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('신고 완료로 처리되었습니다.')),
                        );
                      },
                      child: const Text('신고 완료 처리'),
                    ),
                ],
              ),
      ),
    );
  }
}
