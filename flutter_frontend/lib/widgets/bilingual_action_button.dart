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
    final child = _BilingualActionButtonLabel(
      primaryLabel: primaryLabel,
      compact: compact,
    );
    Widget button;
    switch (variant) {
      case BilingualButtonVariant.filled:
        button = FilledButton(onPressed: onPressed, child: child);
        break;
      case BilingualButtonVariant.tonal:
        button = FilledButton.tonal(onPressed: onPressed, child: child);
        break;
      case BilingualButtonVariant.outlined:
        button = OutlinedButton(onPressed: onPressed, child: child);
        break;
      case BilingualButtonVariant.text:
        button = TextButton(onPressed: onPressed, child: child);
        break;
    }
    final safeTooltip = tooltip?.trim() ?? '';
    if (safeTooltip.isEmpty) {
      return button;
    }
    return Tooltip(message: safeTooltip, child: button);
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
