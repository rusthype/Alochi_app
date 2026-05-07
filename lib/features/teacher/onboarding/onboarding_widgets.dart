import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final int activeIndex;
  final int totalPages;

  const OnboardingPageIndicator({
    super.key,
    required this.activeIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brand : AppColors.brandSoft,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Screens ichiga wrap qilib kirish animatsiyasi beradi.
class OnboardingEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const OnboardingEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<OnboardingEntrance> createState() => _OnboardingEntranceState();
}

class _OnboardingEntranceState extends State<OnboardingEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Stagger animatsiyasi uchun — har element ketma-ket chiqadi.
class OnboardingStaggerItem extends StatelessWidget {
  final int index;
  final Widget child;

  const OnboardingStaggerItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingEntrance(
      delay: Duration(milliseconds: 100 + index * 80),
      child: child,
    );
  }
}
