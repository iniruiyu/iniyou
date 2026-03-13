import 'package:flutter/material.dart';

import 'shell_widgets.dart';

class AuthenticatedShellView extends StatelessWidget {
  const AuthenticatedShellView({
    super.key,
    required this.userLabel,
    required this.pageTitle,
    required this.pageSubtitle,
    required this.loading,
    required this.wide,
    required this.sidebar,
    required this.body,
    required this.onRefresh,
    required this.onLogout,
    required this.currentLanguageCode,
    required this.onLanguageChanged,
    required this.t,
  });

  final String userLabel;
  final String pageTitle;
  final String pageSubtitle;
  final bool loading;
  final bool wide;
  final Widget sidebar;
  final Widget body;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final String currentLanguageCode;
  final ValueChanged<String> onLanguageChanged;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pageTitle),
            Text(pageSubtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                userLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: t('shell.refresh'),
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          SettingsMenuButton(
            currentLanguageCode: currentLanguageCode,
            onLanguageChanged: onLanguageChanged,
            t: t,
          ),
          IconButton(
            tooltip: t('shell.logout'),
            onPressed: loading ? null : onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: SafeArea(child: sidebar)),
      body: Row(
        children: [
          if (wide) SizedBox(width: 260, child: sidebar),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF08111D), Color(0xFF0E1A2A)],
                ),
              ),
              child: Stack(
                children: [
                  body,
                  if (loading)
                    const Positioned(
                      top: 16,
                      right: 16,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
