import 'package:flutter/material.dart';
import '../../theme/radii.dart';

class AlochiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderSide? border;
  final double? borderRadius;

  const AlochiCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadii.l),
        border: Border.fromBorderSide(
          border ?? const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: child,
    );
  }
}
