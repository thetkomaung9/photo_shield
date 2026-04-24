import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/services/mock_data.dart';
import '../../../core/services/social_auth_service.dart';
import '../../../core/theme.dart';
import '../../../shared/models/social_platform.dart';
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
    final connections = ref.watch(socialConnectionsProvider);
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
          ...connections.when(
            data: (items) => items.map((connection) {
              final subtitle = !connection.isConnected
                  ? context.tr('consoleSetupNeeded')
                  : (connection.isDemo
                      ? context.tr('connectedDemo')
                      : context.tr('connectedLive'));
              return ListTile(
                leading:
                    _SettingsPlatformIcon(id: connection.platform.platformId),
                title: Text(AppLocale.platform(
                    context, connection.platform.platformId)),
                subtitle: Text(subtitle),
                trailing: connection.accountLabel == null
                    ? null
                    : Text(
                        connection.accountLabel!,
                        style: const TextStyle(fontSize: 12),
                      ),
              );
            }).toList(),
            loading: () => [const LinearProgressIndicator()],
            error: (_, __) => [
              ListTile(
                title: Text(context.tr('connectedPlatforms')),
                subtitle: Text(context.tr('consoleSetupNeeded')),
              ),
            ],
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

class _SettingsPlatformIcon extends StatelessWidget {
  const _SettingsPlatformIcon({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'instagram':
        return Icon(Icons.camera_alt_outlined, color: AppTheme.instagramPink);
      case 'facebook':
        return const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2));
      case 'kakao_story':
        return const Icon(Icons.chat_bubble_rounded,
            color: AppTheme.kakaoYellow);
      case 'naver':
        return const Icon(Icons.language_rounded, color: AppTheme.naverGreen);
      default:
        return const Icon(Icons.public);
    }
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
