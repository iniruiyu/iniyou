import 'package:flutter/material.dart';

class BilingualField extends StatelessWidget {
  const BilingualField({
    super.key,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.child,
    this.helperText,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final Widget child;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    // Keep the field label on the active language only.
    // 仅保留当前语言字段标题，避免输入控件被双语文案挤压。
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primaryLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (helperText != null && helperText!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
