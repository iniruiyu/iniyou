import 'package:flutter/material.dart';

import '../widgets/app_cards.dart';

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
              final wide = constraints.maxWidth >= 1080;
              final hero = _LandingHero();
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
              );
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: hero),
                              const SizedBox(width: 20),
                              SizedBox(width: 420, child: auth),
                            ],
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [hero, const SizedBox(height: 20), auth],
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

class _LandingHero extends StatelessWidget {
  const _LandingHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'iniyou',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          '先完成账号流程，再进入工作台。',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          '普通 Web 前端和 Flutter 前端现在保持同一套信息架构。未登录时先进入登录或注册，登录后再进入私人空间、公共空间、好友、聊天和区块链接入页面。',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            HeroStatCard(
              index: '01',
              label: '登录或注册',
              text: '统一入口，减少未登录状态下的分叉页面。',
            ),
            HeroStatCard(
              index: '02',
              label: '进入工作台',
              text: '登录后可查看仪表盘、空间、关系和聊天。',
            ),
            HeroStatCard(
              index: '03',
              label: '双前端并存',
              text: 'Legacy Web 与 Flutter 前端保持一致的页面结构。',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auth Flow',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF6EE7FF),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '未登录态聚焦在账号流程',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  '将账号入口、工作台预览和功能说明拆开，避免在未登录时提前暴露完整业务模块。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FeatureChipCard(title: '私人空间', text: '沉淀草稿、笔记和仅自己可见的记录。'),
                    FeatureChipCard(title: '公共空间', text: '展示项目、发布内容并建立公开连接。'),
                    FeatureChipCard(title: '实时互动', text: '登录后进入聊天、好友和资料工作台。'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final title = loginMode ? '回到 iniyou' : '创建你的 iniyou 账户';
    final subtitle = loginMode ? '输入账号后直接进入工作台。' : '创建账号后自动进入你的空间。';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('账号入口', style: Theme.of(context).textTheme.labelLarge),
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
                  label: const Text('登录'),
                  selected: loginMode,
                  onSelected: (_) => onToggleMode(true),
                ),
                ChoiceChip(
                  label: const Text('注册'),
                  selected: !loginMode,
                  onSelected: (_) => onToggleMode(false),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (loginMode) ...[
              TextField(
                controller: loginAccountController,
                decoration: const InputDecoration(labelText: '邮箱 / 手机号'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: loginPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loading ? null : onLogin,
                child: const Text('登录'),
              ),
            ] else ...[
              TextField(
                controller: registerEmailController,
                decoration: const InputDecoration(labelText: '邮箱'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: registerPhoneController,
                decoration: const InputDecoration(labelText: '手机号'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: registerPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码，至少 8 位'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loading ? null : onRegister,
                child: const Text('创建账号'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
