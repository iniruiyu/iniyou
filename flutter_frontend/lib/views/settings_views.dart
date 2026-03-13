import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_cards.dart';

class LevelsView extends StatelessWidget {
  const LevelsView({
    super.key,
    required this.currentLevel,
    required this.onActivateLevel,
  });

  final String currentLevel;
  final ValueChanged<String> onActivateLevel;

  @override
  Widget build(BuildContext context) {
    final cards = [
      const LevelCardData(
        level: 'basic',
        title: 'Basic',
        text: '默认身份，可访问工作台、公共空间和基础资料。',
      ),
      const LevelCardData(
        level: 'premium',
        title: 'Premium',
        text: '解锁私密内容、好友互动和更完整的工作流。',
      ),
      const LevelCardData(
        level: 'vip',
        title: 'VIP',
        text: '强化身份层级和长期会员展示，适合高活跃用户。',
      ),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((item) {
        final active = currentLevel == item.level;
        return SizedBox(
          width: 320,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(item.text),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: active
                        ? null
                        : () => onActivateLevel(item.level),
                    child: Text(active ? '当前等级' : '切换到 ${item.level}'),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({
    super.key,
    required this.subscription,
    required this.loading,
    required this.onActivatePlan,
  });

  final SubscriptionItem? subscription;
  final bool loading;
  final ValueChanged<String> onActivatePlan;

  @override
  Widget build(BuildContext context) {
    final currentPlan = subscription?.planId.isNotEmpty == true
        ? subscription!.planId
        : 'basic';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: '当前订阅',
          lines: [
            '计划: $currentPlan',
            '状态: ${subscription?.status ?? 'inactive'}',
            if (subscription?.startedAt != null)
              '开始时间: ${subscription!.startedAtLabel}',
            if (subscription?.endedAt != null)
              '到期时间: ${subscription!.endedAtLabel}',
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            PlanCard(
              planId: 'basic',
              title: 'Basic',
              features: const ['公共内容流', '基础资料', '默认空间'],
              isLoading: loading,
              onActivate: onActivatePlan,
            ),
            PlanCard(
              planId: 'premium',
              title: 'Premium',
              features: const ['私密内容', '聊天能力', '扩展社交功能'],
              isLoading: loading,
              onActivate: onActivatePlan,
            ),
            PlanCard(
              planId: 'vip',
              title: 'VIP',
              features: const ['高级身份层级', '长期会员', '更强展示能力'],
              isLoading: loading,
              onActivate: onActivatePlan,
            ),
          ].map((card) => SizedBox(width: 300, child: card)).toList(),
        ),
      ],
    );
  }
}

class BlockchainView extends StatelessWidget {
  const BlockchainView({
    super.key,
    required this.loading,
    required this.externalProvider,
    required this.externalChain,
    required this.externalAccounts,
    required this.addressController,
    required this.signatureController,
    required this.onProviderChanged,
    required this.onChainChanged,
    required this.onBind,
    required this.onRemove,
  });

  final bool loading;
  final String externalProvider;
  final String externalChain;
  final List<ExternalAccountItem> externalAccounts;
  final TextEditingController addressController;
  final TextEditingController signatureController;
  final ValueChanged<String> onProviderChanged;
  final ValueChanged<String> onChainChanged;
  final VoidCallback onBind;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final chainsByProvider = const {
      'evm': ['ethereum', 'base', 'bsc', 'polygon'],
      'solana': ['solana'],
      'tron': ['tron'],
    };
    final chainOptions = chainsByProvider[externalProvider]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('绑定外部账号', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        initialValue: externalProvider,
                        decoration: const InputDecoration(
                          labelText: 'Provider',
                        ),
                        items: chainsByProvider.keys
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onProviderChanged(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: externalChain,
                        decoration: const InputDecoration(labelText: 'Chain'),
                        items: chainOptions
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onChainChanged(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Account address',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: signatureController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Signature payload',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: loading ? null : onBind,
                  child: const Text('绑定'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: externalAccounts
              .map(
                (item) => SizedBox(
                  width: 320,
                  child: InfoCard(
                    title: '${item.provider.toUpperCase()} · ${item.chain}',
                    lines: [
                      item.address,
                      '状态: ${item.bindingStatus}',
                      item.createdAtLabel,
                    ],
                    trailing: FilledButton.tonal(
                      onPressed: () => onRemove(item.id),
                      child: const Text('移除'),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
