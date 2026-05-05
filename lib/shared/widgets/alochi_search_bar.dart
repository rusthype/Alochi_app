import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';

class AlochiSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const AlochiSearchBar({
    required this.hintText,
    required this.onChanged,
    this.onClear,
    super.key,
  });

  @override
  State<AlochiSearchBar> createState() => _AlochiSearchBarState();
}

class _AlochiSearchBarState extends State<AlochiSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() => _hasText = value.isNotEmpty);
          widget.onChanged(value);
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColors.brandMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.brandMuted),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.brandMuted,
                  onPressed: () {
                    _controller.clear();
                    setState(() => _hasText = false);
                    widget.onChanged('');
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
        ),
      ),
    );
  }
}
