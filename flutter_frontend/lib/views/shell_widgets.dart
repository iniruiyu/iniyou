import 'package:flutter/material.dart';

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

const defaultShellSidebarItems = [
  ShellSidebarItem(
    viewKey: 'dashboard',
    label: '工作台',
    icon: Icons.dashboard_outlined,
  ),
  ShellSidebarItem(viewKey: 'private', label: '私人空间', icon: Icons.lock_outline),
  ShellSidebarItem(viewKey: 'public', label: '公共空间', icon: Icons.public),
  ShellSidebarItem(
    viewKey: 'profile',
    label: '个人主页',
    icon: Icons.person_outline,
  ),
  ShellSidebarItem(viewKey: 'levels', label: '等级', icon: Icons.stars_outlined),
  ShellSidebarItem(
    viewKey: 'subscription',
    label: '订阅',
    icon: Icons.workspace_premium_outlined,
  ),
  ShellSidebarItem(
    viewKey: 'blockchain',
    label: '区块链',
    icon: Icons.hub_outlined,
  ),
  ShellSidebarItem(
    viewKey: 'friends',
    label: '好友',
    icon: Icons.people_alt_outlined,
  ),
  ShellSidebarItem(
    viewKey: 'chat',
    label: '聊天',
    icon: Icons.chat_bubble_outline,
  ),
];

class ShellSidebar extends StatelessWidget {
  const ShellSidebar({
    super.key,
    required this.user,
    required this.subscription,
    required this.conversations,
    required this.selectedViewKey,
    required this.items,
    required this.onNavigate,
  });

  final CurrentUser user;
  final SubscriptionItem? subscription;
  final List<ConversationItem> conversations;
  final String selectedViewKey;
  final List<ShellSidebarItem> items;
  final ValueChanged<String> onNavigate;

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
            'Private + Public Spaces',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          InfoCard(
            title: user.displayName.isEmpty ? user.id : user.displayName,
            lines: [
              '等级: ${user.level}',
              '计划: ${subscription?.planId.isNotEmpty == true ? subscription!.planId : 'basic'}',
              '未读会话: ${conversations.fold<int>(0, (sum, item) => sum + item.unreadCount)}',
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
