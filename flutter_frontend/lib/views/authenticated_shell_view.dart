import 'dart:ui' as ui;

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
    required this.sidebarBuilder,
    required this.body,
    required this.onToggleSidebar,
    required this.onCompactBack,
    required this.backgroundGradient,
    required this.topNavBuilder,
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
  final Widget Function(BuildContext context, bool inDrawer) sidebarBuilder;
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
  // Top navigation builder.
  // 顶部导航构建器。
  final Widget Function(BuildContext context) topNavBuilder;
  // Show top navigation buttons.
  // 是否显示顶部导航按钮。
  final bool showTopNav;
  // Floating reminder banner in the content shell.
  // 内容壳层中的浮动提醒卡片。
  final Widget? floatingNotice;
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        leadingWidth: compactMode ? 72 : null,
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              )
            : (showTopNav
                  ? Builder(builder: topNavBuilder)
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    )),
        leading: compactMode
            ? _ShellToolbarIconButton(
                tooltip: t('spaces.backAction'),
                onPressed: onCompactBack,
                icon: Icons.arrow_back_rounded,
              )
            : null,
        actions: const [],
        bottom: null,
      ),
      drawer: wide && !compactMode
          ? null
          : (compactMode
                ? null
                : Drawer(
                    child: SafeArea(
                      child: Builder(
                        builder: (context) => sidebarBuilder(context, true),
                      ),
                    ),
                  )),
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
                              scheme.primary.withValues(alpha: 0.12),
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
                              scheme.tertiary.withValues(alpha: 0.14),
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
                  SizedBox(
                    width: 260,
                    child: Builder(
                      builder: (context) => sidebarBuilder(context, false),
                    ),
                  ),
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
                                    scheme.primary.withValues(alpha: 0.12),
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
                                    scheme.tertiary.withValues(alpha: 0.14),
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

class _ShellToolbarIconButton extends StatelessWidget {
  const _ShellToolbarIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.emphasized = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final backgroundStart = emphasized
        ? scheme.primary.withValues(alpha: 0.18)
        : scheme.surface.withValues(alpha: 0.18);
    final backgroundEnd = emphasized
        ? scheme.primaryContainer.withValues(alpha: 0.12)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.08);
    final borderColor = emphasized
        ? scheme.primary.withValues(alpha: 0.3)
        : scheme.outlineVariant.withValues(alpha: 0.2);
    final iconColor = emphasized
        ? scheme.onPrimaryContainer.withValues(alpha: 0.96)
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, top: 8, bottom: 8),
      child: Tooltip(
        message: tooltip,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            // Use a translucent glass shell instead of an opaque icon button.
            // 使用半透明玻璃外壳替代不透明图标按钮。
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [backgroundStart, backgroundEnd],
                    ),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: (emphasized ? scheme.primary : scheme.shadow)
                            .withValues(alpha: emphasized ? 0.16 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 1,
                        left: 12,
                        right: 12,
                        child: IgnorePointer(
                          child: Container(
                            height: 1.2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.3),
                                  Colors.white.withValues(alpha: 0.02),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Icon(icon, size: 22, color: iconColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
