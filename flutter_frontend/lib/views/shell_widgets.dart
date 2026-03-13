import 'package:flutter/material.dart';

import '../i18n/app_i18n.dart';
import '../models/app_models.dart';
import '../widgets/app_cards.dart';

class ShellSidebarItem {
  const ShellSidebarItem({
    required this.viewKey,
    required this.label,
    required this.icon,
  });

  final String viewKey;
  final String label;
  final IconData icon;
}

List<ShellSidebarItem> buildShellSidebarItems(String Function(String key) t) {
  return [
    ShellSidebarItem(
      viewKey: 'dashboard',
      label: t('sidebar.dashboard'),
      icon: Icons.dashboard_outlined,
    ),
    ShellSidebarItem(
      viewKey: 'private',
      label: t('sidebar.private'),
      icon: Icons.lock_outline,
    ),
    ShellSidebarItem(
      viewKey: 'public',
      label: t('sidebar.public'),
      icon: Icons.public,
    ),
    ShellSidebarItem(
      viewKey: 'profile',
      label: t('sidebar.profile'),
      icon: Icons.person_outline,
    ),
    ShellSidebarItem(
      viewKey: 'levels',
      label: t('sidebar.levels'),
      icon: Icons.stars_outlined,
    ),
    ShellSidebarItem(
      viewKey: 'subscription',
      label: t('sidebar.subscription'),
      icon: Icons.workspace_premium_outlined,
    ),
    ShellSidebarItem(
      viewKey: 'blockchain',
      label: t('sidebar.blockchain'),
      icon: Icons.hub_outlined,
    ),
    ShellSidebarItem(
      viewKey: 'friends',
      label: t('sidebar.friends'),
      icon: Icons.people_alt_outlined,
    ),
    ShellSidebarItem(
      viewKey: 'chat',
      label: t('sidebar.chat'),
      icon: Icons.chat_bubble_outline,
    ),
  ];
}

class ShellSidebar extends StatelessWidget {
  const ShellSidebar({
    super.key,
    required this.user,
    required this.subscription,
    required this.conversations,
    required this.selectedViewKey,
    required this.items,
    required this.onNavigate,
    required this.t,
  });

  final CurrentUser user;
  final SubscriptionItem? subscription;
  final List<ConversationItem> conversations;
  final String selectedViewKey;
  final List<ShellSidebarItem> items;
  final ValueChanged<String> onNavigate;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1623),
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
              '${t('sidebar.level')}: ${user.level}',
              '${t('sidebar.plan')}: ${subscription?.planId.isNotEmpty == true ? subscription!.planId : 'basic'}',
              '${t('sidebar.unread')}: ${conversations.fold<int>(0, (sum, item) => sum + item.unreadCount)}',
            ],
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            final selected = selectedViewKey == item.viewKey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: selected
                      ? const Color(0xFF1D6F87)
                      : const Color(0xFF152131),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onPressed: () => onNavigate(item.viewKey),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18),
                    const SizedBox(width: 10),
                    Text(item.label),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({
    super.key,
    required this.currentLanguageCode,
    required this.onLanguageChanged,
    required this.t,
  });

  final String currentLanguageCode;
  final ValueChanged<String> onLanguageChanged;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: t('settings.title'),
      icon: const Icon(Icons.settings_outlined),
      onSelected: onLanguageChanged,
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              t('settings.language'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final code in AppI18n.supportedLanguageCodes)
            PopupMenuItem<String>(
              value: code,
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
        ];
      },
    );
  }
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(message, style: TextStyle(color: color)),
      ),
    );
  }
}
