import 'package:flutter/material.dart';

import 'shell_widgets.dart';

class AuthenticatedHomeView extends StatelessWidget {
  const AuthenticatedHomeView({
    super.key,
    required this.width,
    required this.error,
    required this.flash,
    required this.sectionBody,
  });

  final double width;
  final String? error;
  final String? flash;
  final Widget sectionBody;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        BannerCard(error: error, flash: flash),
        const SizedBox(height: 16),
        sectionBody,
      ],
    );
  }
}
