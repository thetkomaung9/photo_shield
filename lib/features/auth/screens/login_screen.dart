import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/services/social_auth_service.dart';
import '../../../core/services/unified_monitoring_service.dart';
import '../../../core/theme.dart';
import '../../../shared/models/social_platform.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

// ignore: constant_identifier_names
const bool _useMockAuth = true; // auth_provider.dart 와 동기화

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      context.go('/home');
    }
  }

  Future<void> _loginWithSocial(SocialPlatform platform) async {
    final connection =
        await ref.read(authProvider.notifier).loginWithSocial(platform);
    if (!mounted) return;
    if (connection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Social login failed. Check provider setup.')),
      );
      return;
    }

    final message = connection.requiresConsoleSetup
        ? context.tr('socialLoginDemoConnected')
        : context.tr('socialLoginLiveConnected');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(socialConnectionsProvider);
    ref.invalidate(monitoringSnapshotProvider);
    context.go('/photos/register');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  context.tr('loginTitle'),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('loginWelcome'),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.tr('email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? context.tr('enterValidEmail')
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: context.tr('password'),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 8
                      ? context.tr('enterPassword')
                      : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: context.tr('login'),
                  onPressed: _login,
                  isLoading: isLoading,
                ),
                if (_useMockAuth) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🧪 ${context.tr('devTestAccount')}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                            '${context.tr('testEmailLabel')}: test@photoshield.kr',
                            style: const TextStyle(fontSize: 12)),
                        Text('${context.tr('testPasswordLabel')}: Test1234!',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        context.tr('socialLoginDivider'),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),
                ...SocialPlatform.values.map(
                  (platform) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SocialLoginButton(
                      platform: platform,
                      label: context.tr(platform.loginLabelKey),
                      isLoading: isLoading,
                      onPressed: () => _loginWithSocial(platform),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/signup'),
                    child: Text(context.tr('noAccountSignup')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.platform,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final SocialPlatform platform;
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = switch (platform) {
      SocialPlatform.kakao => const Color(0xFF3C1E1E),
      _ => Colors.white,
    };
    final backgroundColor = switch (platform) {
      SocialPlatform.facebook => const Color(0xFF1877F2),
      SocialPlatform.instagram => const Color(0xFFDD2A7B),
      SocialPlatform.kakao => const Color(0xFFFFE812),
      SocialPlatform.naver => const Color(0xFF03C75A),
    };
    final icon = switch (platform) {
      SocialPlatform.facebook => Icons.facebook_rounded,
      SocialPlatform.instagram => Icons.camera_alt_rounded,
      SocialPlatform.kakao => Icons.chat_bubble_rounded,
      SocialPlatform.naver => Icons.language_rounded,
    };

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon, color: foregroundColor),
      label: Text(
        label,
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
