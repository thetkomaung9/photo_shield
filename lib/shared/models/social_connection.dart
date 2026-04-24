import 'social_platform.dart';

class SocialConnection {
  final SocialPlatform platform;
  final bool isConnected;
  final bool isDemo;
  final bool requiresConsoleSetup;
  final String? accountLabel;
  final DateTime? connectedAt;
  final DateTime? lastSyncAt;

  const SocialConnection({
    required this.platform,
    required this.isConnected,
    required this.isDemo,
    required this.requiresConsoleSetup,
    this.accountLabel,
    this.connectedAt,
    this.lastSyncAt,
  });

  const SocialConnection.disconnected(this.platform)
      : isConnected = false,
        isDemo = true,
        requiresConsoleSetup = true,
        accountLabel = null,
        connectedAt = null,
        lastSyncAt = null;
}
