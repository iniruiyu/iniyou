import 'package:flutter/material.dart';

class AuthenticatedShellView extends StatelessWidget {
  const AuthenticatedShellView({
    super.key,
    required this.pageTitle,
    required this.pageSubtitle,
    required this.compactMode,
    required this.loading,
    required this.wide,
    required this.sidebarCollapsed,
    required this.sidebar,
    required this.body,
    required this.onToggleSidebar,
    required this.onCompactBack,
    required this.backgroundGradient,
    required this.topNav,
    required this.showTopNav,
    required this.floatingNotice,
    required this.t,
  });

  final String pageTitle;
  final String pageSubtitle;
  final bool compactMode;
  final bool loading;
  final bool wide;
  // Sidebar collapsed state.
  // 侧边栏折叠状态。
  final bool sidebarCollapsed;
  final Widget sidebar;
  final Widget body;
  // Toggle sidebar collapsed/expanded.
  // 切换侧边栏折叠/展开。
  final VoidCallback onToggleSidebar;
  // Back action for the compact space shell.
  // 紧凑空间壳层的返回动作。
  final VoidCallback onCompactBack;
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
        leadingWidth: compactMode ? null : (wide ? 56 : null),
        // Keep nav buttons on the same row as the toggle button.
        // 将导航按钮与折叠按钮放在同一行。
        title: compactMode
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pageTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (pageSubtitle.isNotEmpty)
                    Text(
                      pageSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              )
            : (showTopNav
                  ? topNav
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pageTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (pageSubtitle.isNotEmpty)
                          Text(
                            pageSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    )),
        leading: compactMode
            ? IconButton(
                tooltip: t('spaces.backAction'),
                onPressed: onCompactBack,
                icon: const Icon(Icons.arrow_back),
              )
            : wide
            ? IconButton(
                tooltip: t('shell.toggleSidebar'),
                onPressed: onToggleSidebar,
                icon: Icon(sidebarCollapsed ? Icons.menu : Icons.menu_open),
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
        actions: const [],
        bottom: null,
      ),
      drawer: wide && !compactMode
          ? null
          : (compactMode ? null : Drawer(child: SafeArea(child: sidebar))),
      body: compactMode
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: backgroundGradient,
                ),
              ),
              child: Stack(
                children: [
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
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  body,
                  if (!compactMode && floatingNotice != null)
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
            )
          : Row(
              children: [
                if (wide && !sidebarCollapsed)
                  SizedBox(width: 260, child: sidebar),
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
                                    Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.14),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        body,
                        if (!compactMode && floatingNotice != null)
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
