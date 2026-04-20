import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      ).showSnackBar(const SnackBar(content: Text('이용약관에 동의해 주세요.')));
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
          const SnackBar(content: Text('가입이 완료되었습니다. 로그인해 주세요.')),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (v) =>
                    v == null || v.length < 2 ? '이름은 2자 이상 입력해 주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '이메일'),
                validator: (v) => v == null || !v.contains('@')
                    ? '올바른 이메일 형식을 입력해 주세요.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호'),
                validator: (v) {
                  if (v == null || v.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                  final hasLetter = v.contains(RegExp(r'[a-zA-Z]'));
                  final hasDigit = v.contains(RegExp(r'\d'));
                  final hasSpecial = v.contains(RegExp(r'[!@#\$%^&*]'));
                  if (!hasLetter || !hasDigit || !hasSpecial) {
                    return '영문, 숫자, 특수문자를 포함해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwConfirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                validator: (v) => v != _pwCtrl.text ? '비밀번호가 일치하지 않습니다.' : null,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                title: const Text('이용약관 및 개인정보 처리방침에 동의합니다'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: '가입하기',
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
