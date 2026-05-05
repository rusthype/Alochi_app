import 'package:flutter/material.dart';
import '../../theme/radii.dart';

class AlochiCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderSide? border;
  final double? borderRadius;
  final VoidCallback? onTap;

  const AlochiCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.onTap,
  });

  @override
  State<AlochiCard> createState() => _AlochiCardState();
}

class _AlochiCardState extends State<AlochiCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            borderRadius:
                BorderRadius.circular(widget.borderRadius ?? AppRadii.l),
            border: Border.fromBorderSide(
              widget.border ?? const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
