import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../shared/widgets/alochi_button.dart';
import '../../shared/widgets/alochi_input.dart';
import '../../shared/widgets/alochi_card.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      ref.read(authProvider.notifier).login(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.user != null) {
        // In the sprint plan, it goes to /dashboard
        context.go('/dashboard');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Teal "A" mark + logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "A'lochi",
                    style: AppTextStyles.displayM.copyWith(color: AppColors.brand),
                  ),
                  const SizedBox(height: 48),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xush kelibsiz!',
                          style: AppTextStyles.displayL.copyWith(color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tizimga kirish uchun ma\'lumotlaringizni kiriting',
                          style: AppTextStyles.body.copyWith(color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  AlochiCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AlochiInput(
                          label: 'Email',
                          hintText: 'example@gmail.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email kiriting';
                            if (!v.contains('@')) return 'Email noto\'g\'ri';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AlochiInput(
                          label: 'Parol',
                          hintText: '********',
                          controller: _passwordCtrl,
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Parol kiriting';
                            if (v.length < 6) return 'Parol kamida 6 ta belgi';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                activeColor: AppColors.brand,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Eslab qolish',
                              style: AppTextStyles.bodyS.copyWith(color: AppColors.ink),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: Text(
                                'Parolni unutdingizmi?',
                                style: AppTextStyles.label.copyWith(color: AppColors.brand),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        AlochiButton.primary(
                          label: 'Kirish',
                          onPressed: _login,
                          isLoading: auth.isLoading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
