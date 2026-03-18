import 'package:flutter/material.dart';

import 'bilingual_field.dart';

class BilingualDropdownField<T> extends StatelessWidget {
  const BilingualDropdownField({
    super.key,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.value,
    required this.items,
    required this.onChanged,
    this.helperText,
    this.enabled = true,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? helperText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Reuse the bilingual field shell so dropdowns keep the same spacing and hierarchy.
    // 复用双语字段外壳，让下拉框保持一致的间距与层级。
    return BilingualField(
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      helperText: helperText,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: items,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
