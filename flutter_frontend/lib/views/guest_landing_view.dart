import 'package:flutter/material.dart';

import 'shell_widgets.dart';
import '../widgets/bilingual_action_button.dart';

class GuestLandingView extends StatelessWidget {
  const GuestLandingView({
    super.key,
    required this.loginMode,
    required this.loading,
    required this.error,
    required this.loginAccountController,
    required this.loginPasswordController,
    required this.rememberLoginCredentials,
    required this.registerEmailController,
    required this.registerPhoneController,
    required this.registerPasswordController,
    required this.onToggleMode,
    required this.onRememberLoginCredentialsChanged,
    required this.onLoginDraftChanged,
    required this.onLogin,
    required this.onRegister,
    required this.currentLanguageCode,
    required this.onLanguageChanged,
    required this.currentThemeKey,
    required this.onThemeChanged,
    required this.themeOptions,
    required this.t,
    required this.peerT,
  });

  final bool loginMode;
  final bool loading;
  final String? error;
  final TextEditingController loginAccountController;
  final TextEditingController loginPasswordController;
  final bool rememberLoginCredentials;
  final TextEditingController registerEmailController;
  final TextEditingController registerPhoneController;
  final TextEditingController registerPasswordController;
  final ValueChanged<bool> onToggleMode;
  final ValueChanged<bool> onRememberLoginCredentialsChanged;
  final VoidCallback onLoginDraftChanged;
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
  final String Function(String key) peerT;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(scheme.surface, scheme.primary, 0.12) ?? scheme.surface,
              Color.lerp(scheme.surface, scheme.tertiary, 0.08) ?? scheme.surface,
              Color.lerp(scheme.surface, scheme.surfaceContainerHighest, 0.18) ??
                  scheme.surface,
            ],
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
                rememberLoginCredentials: rememberLoginCredentials,
                registerEmailController: registerEmailController,
                registerPhoneController: registerPhoneController,
                registerPasswordController: registerPasswordController,
                onToggleMode: onToggleMode,
                onRememberLoginCredentialsChanged:
                    onRememberLoginCredentialsChanged,
                onLoginDraftChanged: onLoginDraftChanged,
                onLogin: onLogin,
                onRegister: onRegister,
                t: t,
                peerT: peerT,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _LandingLogoMark(scheme: scheme),
                                const SizedBox(width: 12),
                                Text(
                                  'iniyou',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            SettingsMenuButton(
                              currentLanguageCode: currentLanguageCode,
                              onLanguageChanged: onLanguageChanged,
                              currentThemeKey: currentThemeKey,
                              onThemeChanged: onThemeChanged,
                              themeOptions: themeOptions,
                              t: t,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        auth,
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
    required this.rememberLoginCredentials,
    required this.registerEmailController,
    required this.registerPhoneController,
    required this.registerPasswordController,
    required this.onToggleMode,
    required this.onRememberLoginCredentialsChanged,
    required this.onLoginDraftChanged,
    required this.onLogin,
    required this.onRegister,
    required this.t,
    required this.peerT,
  });

  final bool loginMode;
  final bool loading;
  final String? error;
  final TextEditingController loginAccountController;
  final TextEditingController loginPasswordController;
  final bool rememberLoginCredentials;
  final TextEditingController registerEmailController;
  final TextEditingController registerPhoneController;
  final TextEditingController registerPasswordController;
  final ValueChanged<bool> onToggleMode;
  final ValueChanged<bool> onRememberLoginCredentialsChanged;
  final VoidCallback onLoginDraftChanged;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final String Function(String key) t;
  final String Function(String key) peerT;

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
            Text(t('auth.entry'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
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
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: t('auth.account')),
                onChanged: (_) => onLoginDraftChanged(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: loginPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: t('auth.password')),
                onChanged: (_) => onLoginDraftChanged(),
                onSubmitted: (_) {
                  if (!loading) {
                    onLogin();
                  }
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: rememberLoginCredentials,
                onChanged: loading
                    ? null
                    : (value) =>
                          onRememberLoginCredentialsChanged(value ?? false),
                title: Text(t('auth.rememberCredentials')),
              ),
              const SizedBox(height: 4),
              // Primary action buttons use the shared bilingual style.
              // 主操作按钮统一使用双语样式组件。
              BilingualActionButton(
                onPressed: loading ? null : onLogin,
                primaryLabel: t('auth.login'),
                secondaryLabel: peerT('auth.login'),
              ),
            ] else ...[
              TextField(
                controller: registerEmailController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: t('auth.email')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: registerPhoneController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: t('auth.phone')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: registerPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: t('auth.passwordHint')),
                onSubmitted: (_) {
                  if (!loading) {
                    onRegister();
                  }
                },
              ),
              const SizedBox(height: 16),
              BilingualActionButton(
                onPressed: loading ? null : onRegister,
                primaryLabel: t('auth.register'),
                secondaryLabel: peerT('auth.register'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LandingLogoMark extends StatelessWidget {
  const _LandingLogoMark({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.24),
            scheme.tertiary.withValues(alpha: 0.18),
            scheme.surfaceContainerHighest.withValues(alpha: 0.86),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.82),
                width: 1.8,
              ),
            ),
          ),
          Positioned(
            top: 9,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 9,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.tertiary,
                boxShadow: [
                  BoxShadow(
                    color: scheme.tertiary.withValues(alpha: 0.26),
                    blurRadius: 10,
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
