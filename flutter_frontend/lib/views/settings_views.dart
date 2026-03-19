import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_cards.dart';
import '../widgets/bilingual_action_button.dart';
import '../widgets/bilingual_dropdown_field.dart';

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
                  // Level switch action uses the shared bilingual button.
                  // 等级切换动作统一使用双语按钮组件。
                  BilingualActionButton(
                    onPressed: active ? null : () => onActivateLevel(item.level),
                    primaryLabel: active ? '当前等级' : '切换到 ${item.level}',
                    secondaryLabel: active ? 'Current level' : 'Switch to ${item.level}',
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
                      child: BilingualDropdownField<String>(
                        primaryLabel: '提供方',
                        secondaryLabel: 'Provider',
                        value: externalProvider,
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
                      child: BilingualDropdownField<String>(
                        primaryLabel: '链网络',
                        secondaryLabel: 'Chain',
                        value: externalChain,
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
                // Bind action uses the shared bilingual button.
                // 绑定动作统一使用双语按钮组件。
                BilingualActionButton(
                  onPressed: loading ? null : onBind,
                  primaryLabel: '绑定',
                  secondaryLabel: 'Bind',
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
                    trailing: BilingualActionButton(
                      variant: BilingualButtonVariant.text,
                      onPressed: () => onRemove(item.id),
                      primaryLabel: '移除',
                      secondaryLabel: 'Remove',
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
