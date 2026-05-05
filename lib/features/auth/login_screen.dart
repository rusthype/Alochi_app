import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../theme/radii.dart';
import '../../shared/widgets/alochi_button.dart';
import '../../shared/widgets/alochi_input.dart';
import '../../shared/widgets/alochi_card.dart';
import '../../core/utils/validators.dart';
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
      final username = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      ref.read(authProvider.notifier).login(username, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.user != null && prev?.user == null) {
        final role = next.user!.role;
        if (role == 'teacher') {
          context.go('/teacher/dashboard');
        } else {
          // Non-teacher: show message and logout
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Bu ilova faqat ustozlar uchun. Iltimos, alohida ilovadan foydalaning',
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.m),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          ref.read(authProvider.notifier).logout();
        }
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
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
                    "A'lochi Ustoz",
                    style:
                        AppTextStyles.displayM.copyWith(color: AppColors.brand),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Ustoz platformasi',
                      style: AppTextStyles.bodyS.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xush kelibsiz!',
                          style: AppTextStyles.displayL
                              .copyWith(color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ustoz hisobiga kirish',
                          style: AppTextStyles.body
                              .copyWith(color: const Color(0xFF6B7280)),
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
                          label: 'Foydalanuvchi nomi',
                          hintText: 'shoiraxon_0579',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.text,
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              size: 20),
                          validator: Validators.username,
                        ),
                        const SizedBox(height: 20),
                        AlochiInput(
                          label: 'Parol',
                          hintText: '********',
                          controller: _passwordCtrl,
                          isPassword: true,
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          validator: (v) =>
                              Validators.required(v, fieldName: 'Parol'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                                activeColor: AppColors.brand,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Eslab qolish',
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.ink),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: Text(
                                'Parolni unutdingizmi?',
                                style: AppTextStyles.label
                                    .copyWith(color: AppColors.brand),
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
