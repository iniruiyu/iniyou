import 'package:flutter/material.dart';

enum BilingualButtonVariant {
  filled,
  tonal,
  outlined,
  text,
}

class BilingualActionButton extends StatelessWidget {
  const BilingualActionButton({
    super.key,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPressed,
    this.variant = BilingualButtonVariant.filled,
    this.compact = false,
    this.tooltip,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPressed;
  final BilingualButtonVariant variant;
  final bool compact;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    // Keep the action label on the active language only.
    // 仅保留当前语言按钮文案，避免双语堆叠挤占布局。
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(compact ? 999 : 18);
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 14 : 18,
      vertical: compact ? 11 : 14,
    );
    final child = _BilingualActionButtonLabel(
      primaryLabel: primaryLabel,
      compact: compact,
    );
    final content = switch (variant) {
      BilingualButtonVariant.filled => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? [
                      colorScheme.primary,
                      Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.24) ?? colorScheme.primary,
                    ]
                  : [
                      colorScheme.surfaceContainerHighest,
                      colorScheme.surfaceContainerHighest,
                    ],
            ),
            borderRadius: radius,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
        ),
        child: _ActionButtonSurface(
          onPressed: onPressed,
          padding: padding,
          radius: radius,
          foreground: colorScheme.onPrimary,
          child: child,
        ),
        ),
      BilingualButtonVariant.tonal => Container(
          decoration: BoxDecoration(
            color: enabled ? colorScheme.secondaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: radius,
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
        ),
        child: _ActionButtonSurface(
          onPressed: onPressed,
          padding: padding,
          radius: radius,
          foreground: colorScheme.onSecondaryContainer,
          child: child,
        ),
        ),
      BilingualButtonVariant.outlined => Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: radius,
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: enabled ? 0.8 : 0.4)),
        ),
        child: _ActionButtonSurface(
          onPressed: onPressed,
          padding: padding,
          radius: radius,
          foreground: colorScheme.primary,
          child: child,
        ),
      ),
      BilingualButtonVariant.text => _ActionButtonSurface(
          onPressed: onPressed,
          padding: padding,
          radius: radius,
          foreground: colorScheme.primary,
          child: child,
        ),
    };
    final safeTooltip = tooltip?.trim() ?? '';
    if (safeTooltip.isEmpty) {
      return content;
    }
    return Tooltip(message: safeTooltip, child: content);
  }
}

class _ActionButtonSurface extends StatelessWidget {
  const _ActionButtonSurface({
    required this.onPressed,
    required this.padding,
    required this.radius,
    required this.foreground,
    required this.child,
  });

  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final BorderRadius radius;
  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.55,
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: IconTheme.merge(
                data: IconThemeData(color: foreground),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BilingualActionButtonLabel extends StatelessWidget {
  const _BilingualActionButtonLabel({
    required this.primaryLabel,
    required this.compact,
  });

  final String primaryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryStyle = (compact
            ? theme.textTheme.labelMedium
            : theme.textTheme.labelLarge)
        ?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.1,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          primaryLabel,
          textAlign: TextAlign.center,
          style: primaryStyle,
        ),
      ],
    );
  }
}
