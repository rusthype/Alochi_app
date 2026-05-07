import 'package:flutter/material.dart';
import '../../theme/typography.dart';

class AlochiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool centerTitle;
  final Color? backgroundColor;

  const AlochiAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.onBack,
    this.centerTitle = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      titleTextStyle: AppTextStyles.titleL.copyWith(color: onSurface),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor, // Use theme default if null
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, size: 20, color: onSurface),
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                )
              : null),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
