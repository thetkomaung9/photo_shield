import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/services/mock_data.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/photoshield_logo.dart';

/// 설정 화면 — 데모 모드용 정적 항목들.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _push = true;
  bool _autoScan = true;

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        toolbarHeight: 64,
        title: const PhotoShieldAppBarTitle(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: context.tr('language')),
          DropdownButtonFormField<String>(
            initialValue: locale.languageCode,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Text(context.tr('english')),
              ),
              DropdownMenuItem(
                value: 'ko',
                child: Text(context.tr('korean')),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              ref.read(localeProvider.notifier).setLocale(Locale(value));
            },
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: context.tr('notifications')),
          SwitchListTile(
            value: _push,
            onChanged: (v) => setState(() => _push = v),
            title: Text(context.tr('receivePushNotifications')),
            activeThumbColor: AppTheme.primary,
          ),
          SwitchListTile(
            value: _autoScan,
            onChanged: (v) => setState(() => _autoScan = v),
            title: Text(context.tr('automaticPeriodicScan')),
            activeThumbColor: AppTheme.primary,
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: context.tr('connectedPlatforms')),
          ListTile(
            leading:
                Icon(Icons.camera_alt_outlined, color: AppTheme.instagramPink),
            title: const Text('인스타그램'),
            subtitle: Text(context.tr('demoMode')),
          ),
          ListTile(
            leading: Icon(Icons.facebook_rounded, color: Color(0xFF1877F2)),
            title: const Text('페이스북'),
            subtitle: Text(context.tr('demoMode')),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: context.tr('appInfo')),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(context.tr('version')),
            trailing: const Text('1.0.0 (demo)'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
