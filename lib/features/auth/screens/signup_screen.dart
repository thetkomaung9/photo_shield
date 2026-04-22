import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_locale.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('agreeTermsRequired'))));
      return;
    }
    final error = await ref
        .read(authProvider.notifier)
        .signup(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _pwCtrl.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      if (!mounted) return;
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      if (isAuthenticated) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('signupCompleteLogin'))),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('signupTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: context.tr('name')),
                validator: (v) => v == null || v.length < 2
                    ? context.tr('nameMinLength')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: context.tr('email')),
                validator: (v) => v == null || !v.contains('@')
                    ? context.tr('enterValidEmail')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: context.tr('password')),
                validator: (v) {
                  if (v == null || v.length < 8)
                    return context.tr('passwordMinLength');
                  final hasLetter = v.contains(RegExp(r'[a-zA-Z]'));
                  final hasDigit = v.contains(RegExp(r'\d'));
                  final hasSpecial = v.contains(RegExp(r'[!@#\$%^&*]'));
                  if (!hasLetter || !hasDigit || !hasSpecial) {
                    return context.tr('passwordComplex');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwConfirmCtrl,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: context.tr('confirmPassword')),
                validator: (v) =>
                    v != _pwCtrl.text ? context.tr('passwordMismatch') : null,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                title: Text(context.tr('agreeTerms')),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: context.tr('signup'),
                onPressed: _signup,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
