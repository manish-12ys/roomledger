import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSpacing extends StatelessWidget {
  const AppSpacing({super.key, this.height = 0, this.width = 0});

  final double height;
  final double width;

  const AppSpacing.vertical(this.height, {super.key}) : width = 0;
  const AppSpacing.horizontal(this.width, {super.key}) : height = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: width);
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppTheme.space200),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin,
      color: AppTheme.surfaceVariant,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: card,
      );
    }

    return card;
  }
}

enum ActionButtonVariant { primary, secondary, ghost }

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = ActionButtonVariant.primary,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final ActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style;

    switch (variant) {
      case ActionButtonVariant.secondary:
        style = OutlinedButton.styleFrom(
          foregroundColor: AppTheme.onSurface,
          side: const BorderSide(color: AppTheme.secondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space200,
            vertical: AppTheme.space150,
          ),
        );
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: AppTheme.secondary),
          label: Text(label),
          style: style,
        );
      case ActionButtonVariant.ghost:
        style = TextButton.styleFrom(
          foregroundColor: AppTheme.onSurface,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space200,
            vertical: AppTheme.space150,
          ),
        );
        return TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: AppTheme.onSurface),
          label: Text(label),
          style: style,
        );
      case ActionButtonVariant.primary:
        style = FilledButton.styleFrom(
          backgroundColor: AppTheme.secondary,
          foregroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space200,
            vertical: AppTheme.space150,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        );
        return FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: AppTheme.primary),
          label: Text(label),
          style: style,
        );
    }
  }
}
