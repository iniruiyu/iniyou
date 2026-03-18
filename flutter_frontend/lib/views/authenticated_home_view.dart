import 'package:flutter/material.dart';

import 'shell_widgets.dart';

class AuthenticatedHomeView extends StatelessWidget {
  const AuthenticatedHomeView({
    super.key,
    required this.width,
    required this.error,
    required this.flash,
    required this.sectionBody,
    this.stretchBody = false,
  });

  final double width;
  final String? error;
  final String? flash;
  final Widget sectionBody;
  final bool stretchBody;

  @override
  Widget build(BuildContext context) {
    if (stretchBody) {
      return SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BannerCard(error: error, flash: flash),
              const SizedBox(height: 16),
              Expanded(child: sectionBody),
            ],
          ),
        ),
      );
    }
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
