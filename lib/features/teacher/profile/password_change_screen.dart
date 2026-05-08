import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_input.dart';
import '../../../core/utils/validators.dart';
import 'password_change_provider.dart';

class PasswordChangeScreen extends ConsumerStatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  ConsumerState<PasswordChangeScreen> createState() =>
      _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends ConsumerState<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(passwordChangeProvider.notifier).change(
          oldPassword: _oldCtrl.text,
          newPassword: _newCtrl.text,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Parol o'zgartirildi",
            style: AppTextStyles.bodyS.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordChangeProvider);

    ref.listen<PasswordChangeState>(passwordChangeProvider, (_, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error!,
              style: AppTextStyles.bodyS.copyWith(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: "Parolni o'zgartirish"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(AppSpacing.s),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.brand, size: 18),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              'Yangi parol kamida 8 ta belgidan iborat bo\'lishi kerak',
                              style: AppTextStyles.bodyS
                                  .copyWith(color: AppColors.brandMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Old password
                    AlochiInput(
                      label: 'Eski parol',
                      hintText: 'Joriy parolingizni kiriting',
                      controller: _oldCtrl,
                      isPassword: true,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Eski parol'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppColors.brandMuted, size: 20),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // New password
                    AlochiInput(
                      label: 'Yangi parol',
                      hintText: 'Kamida 8 ta belgi',
                      controller: _newCtrl,
                      isPassword: true,
                      validator: (v) => Validators.compose([
                        (val) => Validators.password(val),
                        (val) {
                          if (val == _oldCtrl.text) {
                            return "Yangi parol eski paroldan farq qilishi kerak";
                          }
                          return null;
                        }
                      ])(v),
                      prefixIcon: const Icon(Icons.lock_reset_rounded,
                          color: AppColors.brandMuted, size: 20),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Confirm new password
                    AlochiInput(
                      label: 'Yangi parolni takrorlang',
                      hintText: 'Yangi parolni qaytadan kiriting',
                      controller: _confirmCtrl,
                      isPassword: true,
                      validator: (v) =>
                          Validators.passwordMatch(v, _newCtrl.text),
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.brandMuted, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sticky CTA
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.l,
              right: AppSpacing.l,
              top: AppSpacing.m,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.m,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: AlochiButton.primary(
              label: 'Saqlash',
              isLoading: state.isLoading,
              onPressed: state.isLoading ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
