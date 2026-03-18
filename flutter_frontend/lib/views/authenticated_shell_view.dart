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
    required this.sidebarCollapsed,
    required this.sidebar,
    required this.body,
    required this.onRefresh,
    required this.onLogout,
    required this.onToggleSidebar,
    required this.currentLanguageCode,
    required this.onLanguageChanged,
    required this.currentThemeKey,
    required this.onThemeChanged,
    required this.themeOptions,
    required this.backgroundGradient,
    required this.topNav,
    required this.showTopNav,
    required this.floatingNotice,
    required this.t,
  });

  final String userLabel;
  final String pageTitle;
  final String pageSubtitle;
  final bool loading;
  final bool wide;
  // Sidebar collapsed state.
  // 侧边栏折叠状态。
  final bool sidebarCollapsed;
  final Widget sidebar;
  final Widget body;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  // Toggle sidebar collapsed/expanded.
  // 切换侧边栏折叠/展开。
  final VoidCallback onToggleSidebar;
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
  // Background gradient colors.
  // 背景渐变颜色。
  final List<Color> backgroundGradient;
  // Top navigation widget.
  // 顶部导航组件。
  final PreferredSizeWidget topNav;
  // Show top navigation buttons.
  // 是否显示顶部导航按钮。
  final bool showTopNav;
  // Floating reminder banner in the content shell.
  // 内容壳层中的浮动提醒卡片。
  final Widget? floatingNotice;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        // Keep nav buttons on the same row as the toggle button.
        // 将导航按钮与折叠按钮放在同一行。
        title: showTopNav ? topNav : const SizedBox.shrink(),
        leading: wide
            ? IconButton(
                tooltip: t('shell.toggleSidebar'),
                onPressed: onToggleSidebar,
                icon: Icon(sidebarCollapsed ? Icons.menu_open : Icons.menu),
              )
            : Builder(
                builder: (context) {
                  return IconButton(
                    tooltip: t('shell.toggleSidebar'),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu),
                  );
                },
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
            currentThemeKey: currentThemeKey,
            onThemeChanged: onThemeChanged,
            themeOptions: themeOptions,
            t: t,
          ),
          IconButton(
            tooltip: t('shell.logout'),
            onPressed: loading ? null : onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: null,
      ),
      drawer: wide ? null : Drawer(child: SafeArea(child: sidebar)),
      body: Row(
        children: [
          if (wide && !sidebarCollapsed) SizedBox(width: 260, child: sidebar),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: backgroundGradient,
                ),
              ),
              child: Stack(
                children: [
                  // Add soft atmospheric glows so the shell feels less flat.
                  // 增加柔和氛围光斑，让壳层背景不再过于平直。
                  Positioned(
                    top: -120,
                    right: -80,
                    child: IgnorePointer(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -160,
                    left: -120,
                    child: IgnorePointer(
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  body,
                  if (floatingNotice != null)
                    PositionedDirectional(
                      top: 16,
                      end: 16,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: floatingNotice!,
                      ),
                    ),
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
