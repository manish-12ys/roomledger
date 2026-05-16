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
      child: Padding(padding: padding, child: child),
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

/// Animated circular progress ring widget.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 48.0,
    this.strokeWidth = 4.0,
    this.activeColor,
    this.backgroundColor,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color? activeColor;
  final Color? backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.secondary;
    final bgColor = backgroundColor ?? color.withValues(alpha: 0.12);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
            duration: AppTheme.animSlow,
            curve: AppTheme.animCurve,
            builder: (context, animatedProgress, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: animatedProgress,
                  activeColor: color,
                  backgroundColor: bgColor,
                  strokeWidth: strokeWidth,
                ),
              );
            },
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color activeColor;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -1.5708; // -pi/2 (top)
      final sweepAngle = 2 * 3.14159265 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      activeColor != oldDelegate.activeColor;
}

/// Small pill-shaped status badge.
enum StatusType { paid, partial, pending, overdue }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.type});

  final StatusType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      StatusType.paid => ('Paid', AppTheme.success),
      StatusType.partial => ('Partial', AppTheme.warning),
      StatusType.pending => ('Pending', AppTheme.info),
      StatusType.overdue => ('Overdue', AppTheme.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Timeline connector dot and line for vertical timelines.
class TimelineDot extends StatelessWidget {
  const TimelineDot({
    super.key,
    this.color,
    this.isFirst = false,
    this.isLast = false,
    this.dotSize = 10.0,
  });

  final Color? color;
  final bool isFirst;
  final bool isLast;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final dotColor = color ?? AppTheme.secondary;

    return SizedBox(
      width: 24,
      child: Column(
        children: [
          if (!isFirst)
            Expanded(
              child: Container(
                width: 2,
                color: dotColor.withValues(alpha: 0.2),
              ),
            ),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: dotColor, width: 2),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: dotColor.withValues(alpha: 0.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Matte glass surface card with gradient and subtle border.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space200),
    this.margin,
    this.onTap,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppTheme.secondary;

    final container = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceContainer.withValues(alpha: 0.92),
            AppTheme.surfaceVariant.withValues(alpha: 0.70),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          splashColor: accent.withValues(alpha: 0.06),
          highlightColor: accent.withValues(alpha: 0.04),
          child: container,
        ),
      );
    }

    return container;
  }
}

/// Animated text counter that counts up to its value
class AnimatedCounterText extends StatelessWidget {
  const AnimatedCounterText({
    super.key,
    required this.value,
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1200),
  });

  final int value;
  final String prefix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, currentValue, child) {
        return Text('$prefix$currentValue', style: style);
      },
    );
  }
}

/// A highly stylized neumorphic button for primary actions
class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: AppTheme.background, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppTheme.background,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
