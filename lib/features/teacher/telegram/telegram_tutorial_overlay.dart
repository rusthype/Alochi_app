import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';

class TelegramTutorialOverlay extends StatefulWidget {
  const TelegramTutorialOverlay({super.key});

  @override
  State<TelegramTutorialOverlay> createState() =>
      _TelegramTutorialOverlayState();
}

class _TelegramTutorialOverlayState extends State<TelegramTutorialOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.qr_code_2_rounded,
      'iconColor': AppColors.brand,
      'title': "QR kodni ko'rsating",
      'description': "Ota-onaga ekranizni ko'rsating yoki QR kodni ulashing",
    },
    {
      'icon': Icons.send_rounded,
      'iconColor': const Color(0xFF0088CC),
      'title': "Bot ulanadi",
      'description': "Ota-ona Telegram'da botni topib 'Start' bosadi",
    },
    {
      'icon': Icons.notifications_active_rounded,
      'iconColor': AppColors.success,
      'title': "Bildirishnomalar keladi",
      'description': "Davomat va baholar haqida avtomatik xabarlar keladi",
    },
  ];

  Future<void> _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('telegram_tutorial_seen', true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color:
                            (step['iconColor'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: step['iconColor'] as Color,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      step['title'] as String,
                      style:
                          AppTextStyles.titleL.copyWith(color: AppColors.ink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      child: Text(
                        step['description'] as String,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.brandMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppColors.brand
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _steps.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _onFinish();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.m),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPage < _steps.length - 1 ? "Keyingi" : "Tushundim",
                style: AppTextStyles.titleM,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
