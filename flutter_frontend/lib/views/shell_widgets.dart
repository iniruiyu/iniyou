import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../i18n/app_i18n.dart';
import '../models/app_models.dart';
import '../widgets/app_cards.dart';

class IniyouLogoMark extends StatelessWidget {
  const IniyouLogoMark({
    super.key,
    required this.scheme,
    this.size = 46,
    this.radius = 16,
  });

  final ColorScheme scheme;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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
            width: size * 0.43,
            height: size * 0.43,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.82),
                width: 1.8,
              ),
            ),
          ),
          Positioned(
            top: size * 0.2,
            right: size * 0.18,
            child: _LogoDot(color: scheme.primary, size: size * 0.17),
          ),
          Positioned(
            left: size * 0.18,
            bottom: size * 0.2,
            child: _LogoDot(color: scheme.tertiary, size: size * 0.17),
          ),
        ],
      ),
    );
  }
}

class _LogoDot extends StatelessWidget {
  const _LogoDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10),
        ],
      ),
    );
  }
}

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
  required bool adminPanelVisible,
  required bool learningOnline,
  required bool learningAdminVisible,
}) {
  return [
    ShellSidebarItem(
      viewKey: 'services',
      label: t('sidebar.services'),
      icon: Icons.api_outlined,
      activeIcon: Icons.api,
    ),
    if (adminPanelVisible)
      ShellSidebarItem(
        viewKey: 'admin-panel',
        label: t('sidebar.adminPanel'),
        icon: Icons.admin_panel_settings_outlined,
        activeIcon: Icons.admin_panel_settings,
      ),
    if (learningAdminVisible)
      ShellSidebarItem(
        viewKey: 'learning-admin',
        label: t('sidebar.learningAdmin'),
        icon: Icons.school_outlined,
        activeIcon: Icons.school,
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
    required this.onToggleNavigation,
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
  final VoidCallback onToggleNavigation;
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
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(scheme.surface, scheme.primary, 0.08) ?? scheme.surface,
            Color.lerp(scheme.surface, scheme.surfaceContainerHighest, 0.16) ??
                scheme.surface,
            Color.lerp(scheme.surface, scheme.tertiary, 0.06) ?? scheme.surface,
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surface.withValues(alpha: 0.92),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.76),
                ],
              ),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                IniyouLogoMark(scheme: scheme),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'iniyou',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.displayName.isEmpty ? user.id : user.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.domain.isNotEmpty
                            ? '@${user.domain}'
                            : (user.username.isNotEmpty
                                  ? '@${user.username}'
                                  : user.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          _SidebarGlassNavButton(
            label: t('shell.toggleSidebar'),
            icon: Icons.menu_open_rounded,
            selected: false,
            badgeCount: 0,
            onPressed: onToggleNavigation,
          ),
          const SizedBox(height: 10),
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
    this.compact = false,
  });

  final String currentLanguageCode;
  final ValueChanged<String> onLanguageChanged;
  final String currentThemeKey;
  final ValueChanged<String> onThemeChanged;
  final List<ThemeOption> themeOptions;
  final String Function(String key) t;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopupMenuButton<SettingsAction>(
      tooltip: t('settings.title'),
      icon: Icon(
        Icons.settings_outlined,
        size: compact ? 18 : 22,
        color: compact ? scheme.onSurface : null,
      ),
      padding: EdgeInsets.zero,
      color: scheme.surface,
      elevation: 12,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.42)),
      ),
      style: IconButton.styleFrom(
        minimumSize: Size(compact ? 40 : 48, compact ? 40 : 48),
        maximumSize: Size(compact ? 40 : 48, compact ? 40 : 48),
        padding: EdgeInsets.all(compact ? 8 : 10),
        backgroundColor: compact
            ? scheme.surface.withValues(alpha: 0.86)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
        ),
        side: BorderSide(
          color: compact
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.outlineVariant.withValues(alpha: 0.36),
        ),
      ),
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
