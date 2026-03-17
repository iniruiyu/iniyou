import 'package:flutter/material.dart';

import 'shell_widgets.dart';

class GuestLandingView extends StatelessWidget {
  const GuestLandingView({
    super.key,
    required this.loginMode,
    required this.loading,
    required this.error,
    required this.loginAccountController,
    required this.loginPasswordController,
    required this.registerEmailController,
    required this.registerPhoneController,
    required this.registerPasswordController,
    required this.onToggleMode,
    required this.onLogin,
    required this.onRegister,
    required this.currentLanguageCode,
    required this.onLanguageChanged,
    required this.currentThemeKey,
    required this.onThemeChanged,
    required this.themeOptions,
    required this.t,
  });

  final bool loginMode;
  final bool loading;
  final String? error;
  final TextEditingController loginAccountController;
  final TextEditingController loginPasswordController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPhoneController;
  final TextEditingController registerPasswordController;
  final ValueChanged<bool> onToggleMode;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final String currentLanguageCode;
  final ValueChanged<String> onLanguageChanged;
  // Current theme key for skin switching.
  // 皮肤切换的当前主题键。
  final String currentThemeKey;
  // Theme change handler.
  // 主题切换回调。
  final ValueChanged<String> onThemeChanged;
  // Available theme options.
  // 可选主题列表。
  final List<ThemeOption> themeOptions;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07111B), Color(0xFF13324A)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final auth = _AuthCard(
                loginMode: loginMode,
                loading: loading,
                error: error,
                loginAccountController: loginAccountController,
                loginPasswordController: loginPasswordController,
                registerEmailController: registerEmailController,
                registerPhoneController: registerPhoneController,
                registerPasswordController: registerPasswordController,
                onToggleMode: onToggleMode,
                onLogin: onLogin,
                onRegister: onRegister,
                t: t,
              );
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SettingsMenuButton(
                              currentLanguageCode: currentLanguageCode,
                              onLanguageChanged: onLanguageChanged,
                              currentThemeKey: currentThemeKey,
                              onThemeChanged: onThemeChanged,
                              themeOptions: themeOptions,
                              t: t,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        auth,
                        const SizedBox(height: 14),
                        Text(
                          t('auth.note'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.loginMode,
    required this.loading,
    required this.error,
    required this.loginAccountController,
    required this.loginPasswordController,
    required this.registerEmailController,
    required this.registerPhoneController,
    required this.registerPasswordController,
    required this.onToggleMode,
    required this.onLogin,
    required this.onRegister,
    required this.t,
  });

  final bool loginMode;
  final bool loading;
  final String? error;
  final TextEditingController loginAccountController;
  final TextEditingController loginPasswordController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPhoneController;
  final TextEditingController registerPasswordController;
  final ValueChanged<bool> onToggleMode;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    final title = loginMode ? t('auth.loginTitle') : t('auth.registerTitle');
    final subtitle = loginMode ? t('auth.loginSub') : t('auth.registerSub');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('auth.entry'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: Text(t('auth.login')),
                  selected: loginMode,
                  onSelected: (_) => onToggleMode(true),
                ),
                ChoiceChip(
                  label: Text(t('auth.register')),
                  selected: !loginMode,
                  onSelected: (_) => onToggleMode(false),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (loginMode) ...[
              TextField(
                controller: loginAccountController,
                decoration: InputDecoration(labelText: t('auth.account')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: loginPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: t('auth.password')),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loading ? null : onLogin,
                child: Text(t('auth.login')),
              ),
            ] else ...[
              TextField(
                controller: registerEmailController,
                decoration: InputDecoration(labelText: t('auth.email')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: registerPhoneController,
                decoration: InputDecoration(labelText: t('auth.phone')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: registerPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: t('auth.passwordHint')),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loading ? null : onRegister,
                child: Text(t('auth.register')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
