import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';

class AlochiSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AlochiSkeleton({
    this.width,
    this.height = 16,
    this.borderRadius,
    super.key,
  });

  @override
  State<AlochiSkeleton> createState() => _AlochiSkeletonState();
}

class _AlochiSkeletonState extends State<AlochiSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.brandSoft.withValues(alpha: _animation.value),
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(AppRadii.s),
        ),
      ),
    );
  }
}

class AlochiSkeletonCard extends StatelessWidget {
  final double height;
  const AlochiSkeletonCard({this.height = 80, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: AlochiSkeleton(
        height: height,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s, horizontal: AppSpacing.m),
      child: Row(
        children: [
          const AlochiSkeleton(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlochiSkeleton(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 16,
                ),
                const SizedBox(height: AppSpacing.xs),
                AlochiSkeleton(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
