import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../i18n/app_i18n.dart';
import '../models/app_models.dart';
import '../widgets/app_cards.dart';

class ShellSidebarItem {
  const ShellSidebarItem({
    required this.viewKey,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String viewKey;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

List<ShellSidebarItem> buildShellSidebarItems(
  String Function(String key) t, {
  required bool spaceOnline,
  required bool messageOnline,
}) {
  return [
    ShellSidebarItem(
      viewKey: 'services',
      label: t('sidebar.services'),
      icon: Icons.api_outlined,
      activeIcon: Icons.api,
    ),
    if (spaceOnline)
      ShellSidebarItem(
        viewKey: 'space',
        label: t('sidebar.space'),
        icon: Icons.dashboard_customize_outlined,
        activeIcon: Icons.dashboard_customize,
      ),
    ShellSidebarItem(
      viewKey: 'friends',
      label: t('sidebar.friends'),
      icon: Icons.diversity_3_outlined,
      activeIcon: Icons.diversity_3,
    ),
    if (messageOnline)
      ShellSidebarItem(
        viewKey: 'chat',
        label: t('sidebar.chat'),
        icon: Icons.forum_outlined,
        activeIcon: Icons.forum,
      ),
    ShellSidebarItem(
      viewKey: 'profile',
      label: t('sidebar.profile'),
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
    ),
  ];
}

class ShellSidebar extends StatelessWidget {
  const ShellSidebar({
    super.key,
    required this.user,
    required this.conversations,
    required this.pendingFriendCount,
    required this.loading,
    required this.selectedViewKey,
    required this.items,
    required this.onNavigate,
    required this.onRefresh,
    required this.onLogout,
    required this.currentLanguageCode,
    required this.onLanguageChanged,
    required this.currentThemeKey,
    required this.onThemeChanged,
    required this.themeOptions,
    required this.t,
  });

  final CurrentUser user;
  final List<ConversationItem> conversations;
  final int pendingFriendCount;
  final bool loading;
  final String selectedViewKey;
  final List<ShellSidebarItem> items;
  final ValueChanged<String> onNavigate;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final String currentLanguageCode;
  final ValueChanged<String> onLanguageChanged;
  final String currentThemeKey;
  final ValueChanged<String> onThemeChanged;
  final List<ThemeOption> themeOptions;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'iniyou',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            t('shell.brandTagline'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          InfoCard(
            title: user.displayName.isEmpty ? user.id : user.displayName,
            lines: [
              if (user.domain.isNotEmpty)
                '${t('sidebar.space')}: @${user.domain}',
              if (user.username.isNotEmpty) '@${user.username}',
              if (user.signature.isNotEmpty) user.signature,
              '${t('sidebar.level')}: ${user.level}',
              '${t('sidebar.unread')}: ${conversations.fold<int>(0, (sum, item) => sum + item.unreadCount)}',
            ],
          ),
          const SizedBox(height: 14),
          // Keep account-level actions inside the sidebar instead of the app bar.
          // 将账号级操作收进侧边栏，而不是放在应用栏中。
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              IconButton(
                tooltip: t('shell.refresh'),
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh),
              ),
              SettingsMenuButton(
                currentLanguageCode: currentLanguageCode,
                onLanguageChanged: onLanguageChanged,
                currentThemeKey: currentThemeKey,
                onThemeChanged: onThemeChanged,
                themeOptions: themeOptions,
                t: t,
              ),
              IconButton(
                tooltip: t('shell.logout'),
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            final selected = selectedViewKey == item.viewKey;
            final unreadCount = item.viewKey == 'chat'
                ? conversations.fold<int>(
                    0,
                    (sum, conversation) => sum + conversation.unreadCount,
                  )
                : 0;
            final badgeCount = item.viewKey == 'friends'
                ? pendingFriendCount
                : unreadCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SidebarGlassNavButton(
                label: item.label,
                icon: selected ? item.activeIcon : item.icon,
                selected: selected,
                badgeCount: badgeCount,
                onPressed: () => onNavigate(item.viewKey),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SidebarGlassNavButton extends StatelessWidget {
  const _SidebarGlassNavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.badgeCount,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final backgroundStart = selected
        ? scheme.primary.withValues(alpha: 0.18)
        : scheme.surface.withValues(alpha: 0.18);
    final backgroundEnd = selected
        ? scheme.primaryContainer.withValues(alpha: 0.12)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.08);
    final borderColor = selected
        ? scheme.primary.withValues(alpha: 0.28)
        : scheme.outlineVariant.withValues(alpha: 0.18);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        // Make sidebar navigation read as translucent glass cards instead of solid filled buttons.
        // 让侧栏导航呈现为半透明玻璃卡片，而不是实心填充按钮。
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [backgroundStart, backgroundEnd],
                ),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: (selected ? scheme.primary : scheme.shadow)
                        .withValues(alpha: selected ? 0.14 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Badge(
                    isLabelVisible: badgeCount > 0,
                    label: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: _SidebarNavGlyph(icon: icon, selected: selected),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavGlyph extends StatelessWidget {
  const _SidebarNavGlyph({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaceColor = selected
        ? scheme.primary.withValues(alpha: 0.2)
        : scheme.surface.withValues(alpha: 0.16);
    final borderColor = selected
        ? scheme.primary.withValues(alpha: 0.32)
        : scheme.outlineVariant.withValues(alpha: 0.18);
    final iconColor = selected ? scheme.primary : scheme.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceColor,
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: selected ? 0.14 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: iconColor),
    );
  }
}

class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({
    super.key,
    required this.currentLanguageCode,
    required this.onLanguageChanged,
    required this.currentThemeKey,
    required this.onThemeChanged,
    required this.themeOptions,
    required this.t,
  });

  final String currentLanguageCode;
  final ValueChanged<String> onLanguageChanged;
  final String currentThemeKey;
  final ValueChanged<String> onThemeChanged;
  final List<ThemeOption> themeOptions;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SettingsAction>(
      tooltip: t('settings.title'),
      icon: const Icon(Icons.settings_outlined),
      onSelected: (action) {
        // Route settings menu selection to the right handler.
        // 将设置菜单动作路由到对应处理函数。
        if (action.type == SettingsActionType.language) {
          onLanguageChanged(action.value);
        } else if (action.type == SettingsActionType.theme) {
          onThemeChanged(action.value);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<SettingsAction>(
            enabled: false,
            child: Text(
              t('settings.language'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final code in AppI18n.supportedLanguageCodes)
            PopupMenuItem<SettingsAction>(
              value: SettingsAction(SettingsActionType.language, code),
              child: Row(
                children: [
                  Icon(
                    code == currentLanguageCode
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(AppI18n.languageLabel(code)),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<SettingsAction>(
            enabled: false,
            child: Text(
              t('theme.title'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final option in themeOptions)
            PopupMenuItem<SettingsAction>(
              value: SettingsAction(SettingsActionType.theme, option.key),
              child: Row(
                children: [
                  Icon(
                    option.key == currentThemeKey
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(t(option.labelKey)),
                ],
              ),
            ),
        ];
      },
    );
  }
}

class ThemeOption {
  // Theme option metadata.
  // 主题选项元数据。
  const ThemeOption({required this.key, required this.labelKey});

  final String key;
  final String labelKey;
}

enum SettingsActionType { language, theme }

class SettingsAction {
  const SettingsAction(this.type, this.value);

  final SettingsActionType type;
  final String value;
}

class BannerCard extends StatelessWidget {
  const BannerCard({super.key, required this.error, required this.flash});

  final String? error;
  final String? flash;

  @override
  Widget build(BuildContext context) {
    if (error == null && flash == null) {
      return const SizedBox.shrink();
    }
    final color = error != null ? Colors.redAccent : const Color(0xFF6EE7FF);
    final message = error ?? flash!;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.18),
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.96),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                error != null
                    ? Icons.warning_amber_rounded
                    : Icons.bolt_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
