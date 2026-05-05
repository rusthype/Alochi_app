import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_input.dart';
import '../../../core/models/teacher_profile_model.dart';
import '../../../core/utils/validators.dart';
import 'profile_provider.dart';
import 'profile_edit_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile(TeacherProfileModel profile) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = profile.name;
    _phoneCtrl.text = profile.phone;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final ok = await ref
        .read(profileEditProvider.notifier)
        .save(name: name, phone: phone.isEmpty ? null : phone);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil yangilandi',
            style: AppTextStyles.bodyS.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(teacherProfileProvider);
    final editState = ref.watch(profileEditProvider);

    // Show error from edit provider
    ref.listen<ProfileEditState>(profileEditProvider, (_, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error!,
              style: AppTextStyles.bodyS.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: 'Profilni tahrirlash'),
      body: profileAsync.when(
        data: (profile) {
          _initFromProfile(profile);
          return _EditBody(
            formKey: _formKey,
            profile: profile,
            nameCtrl: _nameCtrl,
            phoneCtrl: _phoneCtrl,
            isLoading: editState.isLoading,
            onSubmit: _submit,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (_, __) => _EditBodyFallback(
          formKey: _formKey,
          nameCtrl: _nameCtrl,
          phoneCtrl: _phoneCtrl,
          isLoading: editState.isLoading,
          onSubmit: _submit,
        ),
      ),
    );
  }
}

// ─── Edit body (with profile pre-filled) ─────────────────────────────────────

class _EditBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TeacherProfileModel profile;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EditBody({
    required this.formKey,
    required this.profile,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar with camera icon (upload deferred to V1.2)
                  Center(
                    child: Stack(
                      children: [
                        AlochiAvatar(name: profile.name, size: 80),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Center(
                    child: Text(
                      'Rasm o\'zgartirish V1.2 da',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.brandMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Name field
                  AlochiInput(
                    label: 'Ism familiya',
                    hintText: 'Masalan: Shoiraxon Yusupova',
                    controller: nameCtrl,
                    validator: Validators.compose([
                      (v) => Validators.required(v, fieldName: 'Ism familiya'),
                      Validators.minLength(2, fieldName: 'Ism familiya'),
                    ]),
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.brandMuted, size: 20),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Phone field
                  AlochiInput(
                    label: 'Telefon raqam',
                    hintText: '+998 XX XXX XX XX',
                    controller: phoneCtrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.phone(v);
                    },
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: AppColors.brandMuted, size: 20),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Username — read only
                  _ReadOnlyField(
                    label: 'Username',
                    value: '@${profile.username}',
                    icon: Icons.alternate_email_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Sticky CTA
        _StickySubmitBar(isLoading: isLoading, onSubmit: onSubmit),
      ],
    );
  }
}

// ─── Fallback body (when profile load failed) ─────────────────────────────────

class _EditBodyFallback extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EditBodyFallback({
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: AlochiAvatar(name: 'Ustoz', size: 80),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AlochiInput(
                    label: 'Ism familiya',
                    hintText: 'Masalan: Shoiraxon Yusupova',
                    controller: nameCtrl,
                    validator: Validators.compose([
                      (v) => Validators.required(v, fieldName: 'Ism familiya'),
                      Validators.minLength(2, fieldName: 'Ism familiya'),
                    ]),
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.brandMuted, size: 20),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  AlochiInput(
                    label: 'Telefon raqam',
                    hintText: '+998 XX XXX XX XX',
                    controller: phoneCtrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.phone(v);
                    },
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: AppColors.brandMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        _StickySubmitBar(isLoading: isLoading, onSubmit: onSubmit),
      ],
    );
  }
}


// ─── Read-only field ──────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.brandMuted),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(AppRadii.s),
            border: Border.all(color: AppColors.brandLight),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brandMuted, size: 20),
              const SizedBox(width: AppSpacing.s),
              Text(
                value,
                style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sticky submit bar ────────────────────────────────────────────────────────

class _StickySubmitBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;

  const _StickySubmitBar({required this.isLoading, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.m,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.m,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: AlochiButton.primary(
        label: 'Saqlash',
        isLoading: isLoading,
        onPressed: isLoading ? null : onSubmit,
      ),
    );
  }
}
