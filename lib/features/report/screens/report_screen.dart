import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/photoshield_logo.dart';
import '../providers/report_provider.dart';

/// 신고하기 화면 — 목업과 동일한 3개 액션 리스트 + 즉시 신고 착수 버튼.
class ReportScreen extends ConsumerWidget {
  final String detectionId;
  const ReportScreen({super.key, required this.detectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        toolbarHeight: 64,
        title: const PhotoShieldAppBarTitle(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/monitor'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  context.tr('reportTitle'),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _ReportTile(
                icon: const _InstagramIcon(),
                label: context.tr('reportInstagram'),
                onTap: () => _launch(ApiConstants.instagramReportUrl),
              ),
              const SizedBox(height: 12),
              _ReportTile(
                icon: const _KakaoIcon(),
                label: context.tr('reportKakaoStory'),
                onTap: () => _launch(
                    'https://cs.kakao.com/helps?service=8&category=251'),
              ),
              const SizedBox(height: 12),
              _ReportTile(
                icon:
                    const Icon(Icons.gavel, color: AppTheme.primary, size: 26),
                label: context.tr('legalGuide'),
                onTap: () => _launch(ApiConstants.ecrmUrl),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(reportProvider(detectionId).notifier).generate();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('reportStarted'))),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.tr('startReportNow'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ReportTile extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _ReportTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 32, child: Center(child: icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstagramIcon extends StatelessWidget {
  const _InstagramIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFEDA77),
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child:
          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
    );
  }
}

class _KakaoIcon extends StatelessWidget {
  const _KakaoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.kakaoYellow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'K',
          style: TextStyle(
            color: Color(0xFF3C1E1E),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
