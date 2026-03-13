import 'package:flutter/material.dart';

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
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        auth,
                        const SizedBox(height: 14),
                        Text(
                          'Auth Flow 已保留。未登录首页当前仅提供登录和注册入口，主页展示内容后续补充。',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
