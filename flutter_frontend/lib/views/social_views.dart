import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:archive/archive.dart';

import '../controllers/chat_media_actions.dart';
import '../models/app_models.dart';
import 'content_sections.dart';
import 'view_state_helpers.dart';
import '../widgets/app_cards.dart';
import '../widgets/bilingual_action_button.dart';
import '../widgets/bilingual_field.dart';
import '../widgets/bilingual_dropdown_field.dart';
import '../widgets/bilingual_dropdown_options.dart';
import '../main.dart' show ProfileTab;
import 'settings_views.dart';

// Split the profile editor by section so each entry opens a focused dialog.
// 将个人主页编辑器按区块拆分，让每个入口只打开对应的专用弹窗。
enum _ProfileEditorSection { personal, contact, privacy }

String _profileAvatarInitials(String displayName) {
  // Keep avatar fallbacks stable when no remote image is configured.
  // 当未配置远程头像时，保持头像回退字样稳定可读。
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) {
    return 'IN';
  }
  final runes = trimmed.runes.take(2).toList();
  return String.fromCharCodes(runes).toUpperCase();
}

String _formatProfileBirthDateLabel(String value, String languageCode) {
  // Format YYYY-MM-DD values into a reader-friendly localized label.
  // 将 YYYY-MM-DD 值格式化成更易读的本地化日期标签。
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) {
    return value.trim();
  }
  return localizedText(
    languageCode,
    '${parsed.year}年${parsed.month}月${parsed.day}日',
    '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}',
    '${parsed.year}年${parsed.month}月${parsed.day}日',
  );
}

String _formatProfileBirthdayLabel(String value, String languageCode) {
  // Format the derived month-day birthday string for summary cards.
  // 格式化派生的月-日生日字符串，供摘要卡展示。
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  final parts = trimmed.split('-');
  if (parts.length != 2) {
    return trimmed;
  }
  final month = int.tryParse(parts[0]);
  final day = int.tryParse(parts[1]);
  if (month == null || day == null) {
    return trimmed;
  }
  return localizedText(
    languageCode,
    '$month月$day日',
    '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    '$month月$day日',
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.avatarUrl,
    this.radius = 30,
  });

  final String displayName;
  final String avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedUrl = avatarUrl.trim();
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: normalizedUrl.isEmpty
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.92),
                  theme.colorScheme.tertiary.withValues(alpha: 0.78),
                ],
              )
            : null,
        image: normalizedUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(normalizedUrl),
                fit: BoxFit.cover,
              )
            : null,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: normalizedUrl.isEmpty
          ? Text(
              _profileAvatarInitials(displayName),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.user,
    required this.profileUser,
    required this.profilePosts,
    required this.connectedChains,
    required this.displayNameController,
    required this.usernameController,
    required this.domainController,
    required this.avatarUrlController,
    required this.signatureController,
    required this.birthDateController,
    required this.genderController,
    required this.phoneVisibility,
    required this.emailVisibility,
    required this.ageVisibility,
    required this.genderVisibility,
    required this.loading,
    required this.commentControllerFor,
    required this.profileTab,
    required this.onProfileTabChanged,
    required this.currentLevel,
    required this.onActivateLevel,
    required this.onSaveProfile,
    required this.onPhoneVisibilityChanged,
    required this.onEmailVisibilityChanged,
    required this.onAgeVisibilityChanged,
    required this.onGenderVisibilityChanged,
    required this.onAddFriend,
    required this.onAcceptFriend,
    required this.onStartChat,
    required this.onToggleLike,
    required this.onSharePost,
    required this.onCommentPost,
    required this.onDeletePost,
    required this.onOpenProfile,
    required this.onOpenPostDetail,
    required this.onEditPost,
    required this.onEnterSpace,
    required this.languageCode,
    required this.t,
    required this.peerT,
  });

  final CurrentUser? user;
  final UserProfileItem? profileUser;
  final List<PostItem> profilePosts;
  final List<String> connectedChains;
  final TextEditingController displayNameController;
  final TextEditingController usernameController;
  final TextEditingController domainController;
  final TextEditingController avatarUrlController;
  final TextEditingController signatureController;
  final TextEditingController birthDateController;
  final TextEditingController genderController;
  final String phoneVisibility;
  final String emailVisibility;
  final String ageVisibility;
  final String genderVisibility;
  final bool loading;
  final TextEditingController Function(String postId) commentControllerFor;
  // Current profile tab.
  // 当前个人主页选项卡。
  final ProfileTab profileTab;
  // Profile tab change handler.
  // 个人主页选项卡切换回调。
  final ValueChanged<ProfileTab> onProfileTabChanged;
  // Current level for membership.
  // 当前会员等级。
  final String currentLevel;
  // Activate membership level.
  // 激活会员等级回调。
  final ValueChanged<String> onActivateLevel;
  final VoidCallback onSaveProfile;
  final ValueChanged<String> onPhoneVisibilityChanged;
  final ValueChanged<String> onEmailVisibilityChanged;
  final ValueChanged<String> onAgeVisibilityChanged;
  final ValueChanged<String> onGenderVisibilityChanged;
  final ValueChanged<String> onAddFriend;
  final ValueChanged<String> onAcceptFriend;
  final VoidCallback onStartChat;
  final ValueChanged<PostItem> onToggleLike;
  final ValueChanged<PostItem> onSharePost;
  final ValueChanged<PostItem> onCommentPost;
  final ValueChanged<PostItem> onDeletePost;
  final ValueChanged<String> onOpenProfile;
  final ValueChanged<String> onOpenPostDetail;
  final ValueChanged<PostItem> onEditPost;
  final ValueChanged<SpaceItem> onEnterSpace;
  final String languageCode;
  final String Function(String key) t;
  final String Function(String key) peerT;

  @override
  Widget build(BuildContext context) {
    final profile = profileUser;
    if (profile == null) {
      return InfoCard(
        title: localizedText(languageCode, '个人主页', 'Profile', '個人主頁'),
        lines: [
          localizedText(
            languageCode,
            '尚未加载资料，点击左侧个人主页重新进入。',
            'Profile data is not loaded yet. Tap the profile entry on the left to reopen it.',
            '尚未載入資料，點擊左側個人主頁重新進入。',
          ),
        ],
      );
    }

    final isOwnProfile = user != null && profile.id == user!.id;
    final hasBlockchain = connectedChains.isNotEmpty;
    // Use a shared placeholder when a viewer is not allowed to see a field.
    // 当查看者无权看到字段时，使用统一的未公开占位。
    final hiddenText = localizedText(languageCode, '未公开', 'Not public', '未公開');
    String showHiddenText(String value) {
      return value.trim().isNotEmpty ? value : hiddenText;
    }

    String showHiddenNumber(int? value) {
      return value != null ? value.toString() : hiddenText;
    }

    // Ensure the blockchain tab is hidden when there are no accounts.
    // 链上账号为空时隐藏对应选项卡。
    final effectiveTab = !hasBlockchain && profileTab == ProfileTab.blockchain
        ? ProfileTab.levels
        : profileTab;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isOwnProfile) ...[
          InfoCard(
            title: profile.displayName,
            lines: [
              '${localizedText(languageCode, '用户 ID', 'User ID', '使用者 ID')}: ${profile.id}',
              if (profile.domain.isNotEmpty)
                '${localizedText(languageCode, '域名身份', 'Domain identity', '網域身份')}: @${profile.domain}',
              if (profile.username.isNotEmpty)
                '${localizedText(languageCode, '用户名', 'Username', '使用者名稱')}: @${profile.username}',
              '${localizedText(languageCode, '签名', 'Signature', '簽名')}: ${showHiddenText(profile.signature)}',
              '${localizedText(languageCode, '邮箱', 'Email', '信箱')}: ${showHiddenText(profile.email)}',
              '${localizedText(languageCode, '手机号', 'Phone', '手機號')}: ${showHiddenText(profile.phone)}',
              '${localizedText(languageCode, '生日', 'Birthday', '生日')}: ${showHiddenText(profile.birthday.isNotEmpty ? _formatProfileBirthdayLabel(profile.birthday, languageCode) : '')}',
              '${localizedText(languageCode, '年龄', 'Age', '年齡')}: ${showHiddenNumber(profile.age)}',
              '${localizedText(languageCode, '性别', 'Gender', '性別')}: ${showHiddenText(profile.gender)}',
              '${localizedText(languageCode, '状态', 'Status', '狀態')}: ${profile.status}',
              if (profile.relationStatus.isNotEmpty)
                '${localizedText(languageCode, '关系', 'Relation', '關係')}: ${profile.relationStatus} · ${profile.direction}',
              if (connectedChains.isNotEmpty)
                '${localizedText(languageCode, '已连接链', 'Connected chains', '已連接鏈')}: ${connectedChains.join(', ')}',
            ],
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileAvatar(
                  displayName: profile.displayName,
                  avatarUrl: profile.avatarUrl,
                  radius: 28,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (profile.relationStatus.isEmpty)
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: () => onAddFriend(profile.id),
                        primaryLabel: localizedText(
                          languageCode,
                          '添加好友',
                          'Add friend',
                          '新增好友',
                        ),
                        secondaryLabel: 'Add friend',
                      ),
                    if (profile.relationStatus == 'pending' &&
                        profile.direction == 'incoming')
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: () => onAcceptFriend(profile.id),
                        primaryLabel: localizedText(
                          languageCode,
                          '接受好友',
                          'Accept friend',
                          '接受好友',
                        ),
                        secondaryLabel: 'Accept friend',
                      ),
                    if (profile.relationStatus == 'accepted')
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: onStartChat,
                        primaryLabel: localizedText(
                          languageCode,
                          '发起聊天',
                          'Start chat',
                          '發起聊天',
                        ),
                        secondaryLabel: 'Start chat',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!isOwnProfile)
          InfoCard(
            title: localizedText(
              languageCode,
              '资料摘要',
              'Profile summary',
              '資料摘要',
            ),
            subtitle: localizedText(
              languageCode,
              '未公开的字段会显示为“未公开”。',
              'Hidden fields are shown as "Not public".',
              '未公開的欄位會顯示為「未公開」。',
            ),
            lines: [
              '${localizedText(languageCode, '昵称', 'Nickname', '暱稱')}: ${showHiddenText(profile.displayName)}',
              '${localizedText(languageCode, '用户 ID', 'User ID', '使用者 ID')}: ${showHiddenText(profile.id)}',
              if (profile.domain.isNotEmpty)
                '${localizedText(languageCode, '域名身份', 'Domain identity', '網域身份')}: @${profile.domain}',
              if (profile.username.isNotEmpty)
                '${localizedText(languageCode, '用户名', 'Username', '使用者名稱')}: @${profile.username}',
              '${localizedText(languageCode, '签名', 'Signature', '簽名')}: ${showHiddenText(profile.signature)}',
              '${localizedText(languageCode, '邮箱', 'Email', '信箱')}: ${showHiddenText(profile.email)}',
              '${localizedText(languageCode, '手机号', 'Phone', '手機號')}: ${showHiddenText(profile.phone)}',
              '${localizedText(languageCode, '生日', 'Birthday', '生日')}: ${showHiddenText(profile.birthday.isNotEmpty ? _formatProfileBirthdayLabel(profile.birthday, languageCode) : '')}',
              '${localizedText(languageCode, '年龄', 'Age', '年齡')}: ${showHiddenNumber(profile.age)}',
              '${localizedText(languageCode, '性别', 'Gender', '性別')}: ${showHiddenText(profile.gender)}',
            ],
            trailing: _ProfileAvatar(
              displayName: profile.displayName,
              avatarUrl: profile.avatarUrl,
              radius: 32,
            ),
          ),
        if (!isOwnProfile) const SizedBox(height: 16),
        if (isOwnProfile)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedText(
                                languageCode,
                                '身份卡',
                                'Identity card',
                                '身分卡',
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              localizedText(
                                languageCode,
                                '下面信息可直接编辑，用户 ID 仅作展示。',
                                'The fields below are editable, and the user ID is display-only.',
                                '下方資訊可直接編輯，使用者 ID 僅作展示。',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('profile.identity.userId'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.id,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  BilingualField(
                    primaryLabel: t('profile.identity.nickname'),
                    secondaryLabel: peerT('profile.identity.nickname'),
                    child: TextField(
                      controller: displayNameController,
                      decoration: InputDecoration(
                        hintText: t('dashboard.displayNamePlaceholder'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  BilingualField(
                    // Username handle / 用户名句柄：保留为可选账号标识。
                    primaryLabel: t('profile.identity.username'),
                    secondaryLabel: peerT('profile.identity.username'),
                    child: TextField(
                      controller: usernameController,
                      maxLength: 63,
                      buildCounter:
                          (
                            BuildContext context, {
                            required int currentLength,
                            required bool isFocused,
                            required int? maxLength,
                          }) => null,
                      decoration: InputDecoration(
                        hintText: t('dashboard.usernamePlaceholder'),
                      ),
                    ),
                    helperText: t('dashboard.usernameHint'),
                  ),
                  const SizedBox(height: 12),
                  BilingualField(
                    // Domain handle / 域名句柄：用于二级域名与登录入口。
                    // Domain identity / 域名身份：用于二级域名与登录。
                    primaryLabel: t('profile.identity.domain'),
                    secondaryLabel: peerT('profile.identity.domain'),
                    child: TextField(
                      controller: domainController,
                      maxLength: 63,
                      buildCounter:
                          (
                            BuildContext context, {
                            required int currentLength,
                            required bool isFocused,
                            required int? maxLength,
                          }) => null,
                      decoration: InputDecoration(
                        hintText: t('profile.identity.domainPlaceholder'),
                      ),
                    ),
                    helperText: t('profile.identity.domainHint'),
                  ),
                  const SizedBox(height: 12),
                  BilingualField(
                    primaryLabel: t('profile.identity.signature'),
                    secondaryLabel: peerT('profile.identity.signature'),
                    child: TextField(
                      controller: signatureController,
                      decoration: InputDecoration(
                        hintText: t('profile.identity.signaturePlaceholder'),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Responsive visibility grid / 可见范围响应式网格：宽屏两列、窄屏单列，避免双语标签挤压。
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final fieldWidth = constraints.maxWidth >= 720
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: BilingualDropdownField<String>(
                              primaryLabel: t(
                                'profile.identity.phoneVisibility',
                              ),
                              secondaryLabel: peerT(
                                'profile.identity.phoneVisibility',
                              ),
                              value: phoneVisibility,
                              items: buildIdentityVisibilityItems(languageCode),
                              onChanged: (value) => onPhoneVisibilityChanged(
                                value ?? phoneVisibility,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: BilingualDropdownField<String>(
                              primaryLabel: t(
                                'profile.identity.emailVisibility',
                              ),
                              secondaryLabel: peerT(
                                'profile.identity.emailVisibility',
                              ),
                              value: emailVisibility,
                              items: buildIdentityVisibilityItems(languageCode),
                              onChanged: (value) => onEmailVisibilityChanged(
                                value ?? emailVisibility,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: BilingualDropdownField<String>(
                              primaryLabel: t('profile.identity.ageVisibility'),
                              secondaryLabel: peerT(
                                'profile.identity.ageVisibility',
                              ),
                              value: ageVisibility,
                              items: buildIdentityVisibilityItems(languageCode),
                              onChanged: (value) => onAgeVisibilityChanged(
                                value ?? ageVisibility,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: BilingualDropdownField<String>(
                              primaryLabel: t(
                                'profile.identity.genderVisibility',
                              ),
                              secondaryLabel: peerT(
                                'profile.identity.genderVisibility',
                              ),
                              value: genderVisibility,
                              items: buildIdentityVisibilityItems(languageCode),
                              onChanged: (value) => onGenderVisibilityChanged(
                                value ?? genderVisibility,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizedText(
                      languageCode,
                      '域名与昵称分离，域名会用于二级域名路由和登录入口。',
                      'The domain is separate from the nickname and used for subdomain routing and login.',
                      '網域與暱稱分離，網域會用於二級網域路由和登入入口。',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  // Profile save action uses the shared bilingual button.
                  // 个人资料保存动作统一使用双语按钮组件。
                  BilingualActionButton(
                    onPressed: loading ? null : onSaveProfile,
                    primaryLabel: localizedText(
                      languageCode,
                      '保存身份卡',
                      'Save identity card',
                      '儲存身分卡',
                    ),
                    secondaryLabel: 'Save identity card',
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (profile.relationStatus.isEmpty)
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  onPressed: () => onAddFriend(profile.id),
                  primaryLabel: localizedText(
                    languageCode,
                    '添加好友',
                    'Add friend',
                    '新增好友',
                  ),
                  secondaryLabel: 'Add friend',
                ),
              if (profile.relationStatus == 'pending' &&
                  profile.direction == 'incoming')
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  onPressed: () => onAcceptFriend(profile.id),
                  primaryLabel: localizedText(
                    languageCode,
                    '接受好友',
                    'Accept friend',
                    '接受好友',
                  ),
                  secondaryLabel: 'Accept friend',
                ),
              if (profile.relationStatus == 'accepted')
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  onPressed: onStartChat,
                  primaryLabel: localizedText(
                    languageCode,
                    '发起聊天',
                    'Start chat',
                    '發起聊天',
                  ),
                  secondaryLabel: 'Start chat',
                ),
            ],
          ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ChoiceChip(
                  label: Text(t('profile.tab.levels')),
                  selected: effectiveTab == ProfileTab.levels,
                  onSelected: (_) => onProfileTabChanged(ProfileTab.levels),
                ),
                if (hasBlockchain)
                  ChoiceChip(
                    label: Text(t('profile.tab.blockchain')),
                    selected: effectiveTab == ProfileTab.blockchain,
                    onSelected: (_) =>
                        onProfileTabChanged(ProfileTab.blockchain),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (effectiveTab == ProfileTab.levels)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LevelsView(
                currentLevel: currentLevel,
                onActivateLevel: (level) async {
                  onActivateLevel(level);
                  return true;
                },
              ),
            ],
          )
        else if (hasBlockchain)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoCard(
                title: t('profile.blockchain.title'),
                lines: [
                  '${t('profile.blockchain.total')}: ${connectedChains.isEmpty ? t('profile.blockchain.empty') : connectedChains.join(', ')}',
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: connectedChains
                    .map(
                      (chain) => SizedBox(
                        width: 240,
                        child: InfoCard(
                          title: chain,
                          lines: [t('profile.blockchain.connected')],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        const SizedBox(height: 16),
        PostStreamSection(
          posts: profilePosts,
          emptyText: isOwnProfile
              ? localizedText(
                  languageCode,
                  '你还没有发布内容。',
                  'You have not posted anything yet.',
                  '你還沒有發布內容。',
                )
              : localizedText(
                  languageCode,
                  '这个用户还没有公开内容。',
                  'This user has no public content yet.',
                  '這個使用者還沒有公開內容。',
                ),
          commentControllerFor: commentControllerFor,
          onLike: onToggleLike,
          onShare: onSharePost,
          onComment: onCommentPost,
          onOpenAuthor: onOpenProfile,
          onOpenDetail: onOpenPostDetail,
          onEditPost: onEditPost,
          canEditPost: (post) => user != null && post.userId == user!.id,
          onDeletePost: onDeletePost,
          languageCode: languageCode,
        ),
      ],
    );
  }
}

class ProfileSummaryView extends StatelessWidget {
  const ProfileSummaryView({
    super.key,
    required this.user,
    required this.profileUser,
    required this.profileSpaces,
    required this.friends,
    required this.connectedChains,
    required this.displayNameController,
    required this.usernameController,
    required this.domainController,
    required this.avatarUrlController,
    required this.signatureController,
    required this.birthDateController,
    required this.genderController,
    required this.phoneVisibility,
    required this.emailVisibility,
    required this.ageVisibility,
    required this.genderVisibility,
    required this.loading,
    required this.currentLevel,
    required this.onActivateLevel,
    required this.onSaveProfile,
    required this.onPhoneVisibilityChanged,
    required this.onEmailVisibilityChanged,
    required this.onAgeVisibilityChanged,
    required this.onGenderVisibilityChanged,
    required this.onAddFriend,
    required this.onAcceptFriend,
    required this.onStartChat,
    required this.onEnterSpace,
    required this.languageCode,
    required this.t,
    required this.peerT,
  });

  final CurrentUser? user;
  final UserProfileItem? profileUser;
  final List<SpaceItem> profileSpaces;
  final List<FriendItem> friends;
  final List<String> connectedChains;
  final TextEditingController displayNameController;
  final TextEditingController usernameController;
  final TextEditingController domainController;
  final TextEditingController avatarUrlController;
  final TextEditingController signatureController;
  final TextEditingController birthDateController;
  final TextEditingController genderController;
  final String phoneVisibility;
  final String emailVisibility;
  final String ageVisibility;
  final String genderVisibility;
  final bool loading;
  final String currentLevel;
  final Future<bool> Function(String) onActivateLevel;
  final Future<bool> Function() onSaveProfile;
  final ValueChanged<String> onPhoneVisibilityChanged;
  final ValueChanged<String> onEmailVisibilityChanged;
  final ValueChanged<String> onAgeVisibilityChanged;
  final ValueChanged<String> onGenderVisibilityChanged;
  final ValueChanged<String> onAddFriend;
  final ValueChanged<String> onAcceptFriend;
  final VoidCallback onStartChat;
  final ValueChanged<SpaceItem> onEnterSpace;
  final String languageCode;
  final String Function(String key) t;
  final String Function(String key) peerT;

  String _visibilityLabel(String value) {
    switch (value) {
      case 'public':
        return localizedText(languageCode, '公开', 'Public', '公開');
      case 'friends':
        return localizedText(languageCode, '好友可见', 'Friends only', '好友可見');
      case 'private':
      default:
        return localizedText(languageCode, '仅自己', 'Only me', '僅自己');
    }
  }

  String _profileEditorTitle(_ProfileEditorSection section) {
    switch (section) {
      case _ProfileEditorSection.personal:
        return t('profile.identity.personalTitle');
      case _ProfileEditorSection.contact:
        return t('profile.identity.contactTitle');
      case _ProfileEditorSection.privacy:
        return t('profile.identity.privacyTitle');
    }
  }

  String _profileEditorSaveKey(_ProfileEditorSection section) {
    switch (section) {
      case _ProfileEditorSection.personal:
        return 'profile.identity.saveProfile';
      case _ProfileEditorSection.contact:
        return 'profile.identity.saveContact';
      case _ProfileEditorSection.privacy:
        return 'profile.identity.savePrivacy';
    }
  }

  String? _profileDraftError(_ProfileEditorSection section) {
    if (section == _ProfileEditorSection.privacy) {
      return null;
    }
    final displayName = displayNameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final domain = domainController.text.trim().toLowerCase();
    final birthDate = birthDateController.text.trim();
    final handlePattern = RegExp(r'^[a-zA-Z0-9]{1,63}$');
    if (displayName.isEmpty) {
      return localizedText(
        languageCode,
        '昵称不能为空',
        'Nickname cannot be empty.',
        '暱稱不能為空。',
      );
    }
    if (domain.isEmpty) {
      return localizedText(
        languageCode,
        '域名不能为空',
        'Domain cannot be empty.',
        '網域不能為空。',
      );
    }
    if (username.isNotEmpty && !handlePattern.hasMatch(username)) {
      return localizedText(
        languageCode,
        '用户名只能包含英文字母和数字，且最长 63 个字符',
        'Username can contain letters and numbers only, up to 63 characters.',
        '使用者名稱只能包含英文字母和數字，且最長 63 個字元。',
      );
    }
    if (!handlePattern.hasMatch(domain)) {
      return localizedText(
        languageCode,
        '域名只能包含英文字母和数字，且最长 63 个字符',
        'Domain can contain letters and numbers only, up to 63 characters.',
        '網域只能包含英文字母和數字，且最長 63 個字元。',
      );
    }
    if (birthDate.isNotEmpty) {
      final parsedBirthDate = DateTime.tryParse(birthDate);
      if (parsedBirthDate == null) {
        return t('profile.identity.birthDateError');
      }
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      final normalizedBirthDate = DateTime(
        parsedBirthDate.year,
        parsedBirthDate.month,
        parsedBirthDate.day,
      );
      if (normalizedBirthDate.isAfter(normalizedToday)) {
        return t('profile.identity.birthDateFutureError');
      }
    }
    return null;
  }

  Future<void> _openProfileEditor(
    BuildContext context, {
    required _ProfileEditorSection section,
  }) async {
    // Refresh the shared draft from the current profile before opening a section dialog.
    // 打开分区弹窗前先从当前资料回填共享草稿，避免关闭后残留旧输入。
    final profile = profileUser;
    if (profile != null) {
      displayNameController.text = profile.displayName;
      usernameController.text = profile.username;
      domainController.text = profile.domain;
      avatarUrlController.text = profile.avatarUrl;
      signatureController.text = profile.signature;
      birthDateController.text = profile.birthDate;
      genderController.text = profile.gender;
    }
    // Keep the dialog tied to the tapped action so each section opens its own form.
    // 让弹窗内容跟随点击入口，确保每个区块都打开自己的表单。
    String? dialogError;
    await showDialog<void>(
      context: context,
      barrierDismissible: !loading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              title: Text(_profileEditorTitle(section)),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dialogError != null) ...[
                        Text(
                          dialogError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _ProfileIdentityEditorBody(
                        section: section,
                        email: profile?.email ?? '',
                        phone: profile?.phone ?? '',
                        displayNameController: displayNameController,
                        usernameController: usernameController,
                        domainController: domainController,
                        avatarUrlController: avatarUrlController,
                        signatureController: signatureController,
                        birthDateController: birthDateController,
                        genderController: genderController,
                        phoneVisibility: phoneVisibility,
                        emailVisibility: emailVisibility,
                        ageVisibility: ageVisibility,
                        genderVisibility: genderVisibility,
                        onPhoneVisibilityChanged: onPhoneVisibilityChanged,
                        onEmailVisibilityChanged: onEmailVisibilityChanged,
                        onAgeVisibilityChanged: onAgeVisibilityChanged,
                        onGenderVisibilityChanged: onGenderVisibilityChanged,
                        languageCode: languageCode,
                        t: t,
                        peerT: peerT,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                BilingualActionButton(
                  variant: BilingualButtonVariant.text,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  primaryLabel: localizedText(
                    languageCode,
                    '取消',
                    'Cancel',
                    '取消',
                  ),
                  secondaryLabel: 'Cancel',
                ),
                BilingualActionButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final validationError = _profileDraftError(section);
                          if (validationError != null) {
                            setDialogState(() {
                              dialogError = validationError;
                            });
                            return;
                          }
                          setDialogState(() {
                            dialogError = null;
                          });
                          final saved = await onSaveProfile();
                          if (!saved) {
                            if (!dialogContext.mounted) {
                              return;
                            }
                            setDialogState(() {
                              dialogError = localizedText(
                                languageCode,
                                '保存失败，请重试。',
                                'Save failed, please try again.',
                                '儲存失敗，請再試一次。',
                              );
                            });
                            return;
                          }
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  primaryLabel: t(_profileEditorSaveKey(section)),
                  secondaryLabel: peerT(_profileEditorSaveKey(section)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openMembershipSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizedText(
                      languageCode,
                      '切换会员等级',
                      'Switch membership level',
                      '切換會員等級',
                    ),
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  LevelsView(
                    currentLevel: currentLevel,
                    onActivateLevel: (level) async {
                      final saved = await onActivateLevel(level);
                      if (saved && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      return saved;
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = profileUser;
    if (profile == null) {
      return InfoCard(
        title: localizedText(languageCode, '个人主页', 'Profile', '個人主頁'),
        lines: [
          localizedText(
            languageCode,
            '尚未加载资料，点击左侧个人主页重新进入。',
            'Profile data is not loaded yet. Tap the profile entry on the left to reopen it.',
            '尚未載入資料，點擊左側個人主頁重新進入。',
          ),
        ],
      );
    }

    final isOwnProfile = user != null && profile.id == user!.id;
    final hasBlockchain = connectedChains.isNotEmpty;
    final notAvailableText = localizedText(languageCode, '暂无', 'N/A', '暫無');
    final birthDateLabel = profile.birthDate.isNotEmpty
        ? _formatProfileBirthDateLabel(profile.birthDate, languageCode)
        : notAvailableText;
    final birthdayLabel = profile.birthday.isNotEmpty
        ? _formatProfileBirthdayLabel(profile.birthday, languageCode)
        : notAvailableText;
    final ownerBirthDateLabel = birthDateController.text.trim().isNotEmpty
        ? _formatProfileBirthDateLabel(birthDateController.text, languageCode)
        : birthDateLabel;
    final ownerBirthdayLabel = birthDateController.text.trim().isNotEmpty
        ? _formatProfileBirthdayLabel(
            birthDateController.text.trim().length >= 5
                ? birthDateController.text.trim().substring(5)
                : '',
            languageCode,
          )
        : birthdayLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Own profile uses the lower identity cards instead of repeating the top hero block.
        // 自己主页改用下方身份卡，避免顶部英雄卡与下方信息重复。
        if (!isOwnProfile)
          InfoCard(
            title: profile.displayName,
            lines: [
              '${localizedText(languageCode, '用户 ID', 'User ID', '使用者 ID')}: ${profile.id}',
              if (profile.domain.isNotEmpty)
                '${localizedText(languageCode, '域名身份', 'Domain identity', '網域身份')}: @${profile.domain}',
              if (profile.username.isNotEmpty)
                '${localizedText(languageCode, '用户名', 'Username', '使用者名稱')}: @${profile.username}',
              if (profile.signature.isNotEmpty)
                '${localizedText(languageCode, '签名', 'Signature', '簽名')}: ${profile.signature}',
              if (profile.status.isNotEmpty)
                '${localizedText(languageCode, '状态', 'Status', '狀態')}: ${profile.status}',
              if (profile.relationStatus.isNotEmpty)
                '${localizedText(languageCode, '关系', 'Relation', '關係')}: ${profile.relationStatus} · ${profile.direction}',
            ],
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (profile.relationStatus.isEmpty)
                  BilingualActionButton(
                    variant: BilingualButtonVariant.tonal,
                    compact: true,
                    onPressed: () => onAddFriend(profile.id),
                    primaryLabel: localizedText(
                      languageCode,
                      '添加好友',
                      'Add friend',
                      '新增好友',
                    ),
                    secondaryLabel: 'Add friend',
                  ),
                if (profile.relationStatus == 'pending' &&
                    profile.direction == 'incoming')
                  BilingualActionButton(
                    variant: BilingualButtonVariant.tonal,
                    compact: true,
                    onPressed: () => onAcceptFriend(profile.id),
                    primaryLabel: localizedText(
                      languageCode,
                      '接受好友',
                      'Accept friend',
                      '接受好友',
                    ),
                    secondaryLabel: 'Accept friend',
                  ),
                if (profile.relationStatus == 'accepted')
                  BilingualActionButton(
                    variant: BilingualButtonVariant.tonal,
                    compact: true,
                    onPressed: onStartChat,
                    primaryLabel: localizedText(
                      languageCode,
                      '发起聊天',
                      'Start chat',
                      '發起聊天',
                    ),
                    secondaryLabel: 'Start chat',
                  ),
              ],
            ),
          ),
        if (isOwnProfile) ...[
          const SizedBox(height: 16),
          // Keep only quick-glance stats on the personal home.
          // 个人主页这里只保留快速概览统计。
          LayoutBuilder(
            builder: (context, constraints) {
              return TopSummaryRow(
                width: constraints.maxWidth,
                cards: buildHomeSummaryCards(
                  spaces: profileSpaces,
                  friends: friends,
                  t: t,
                  languageCode: languageCode,
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        if (isOwnProfile)
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 1200
                  ? (constraints.maxWidth - 32) / 3
                  : constraints.maxWidth >= 820
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              // Keep the personal, contact, and privacy cards visually separated on wide screens.
              // 在宽屏下把个人资料、联系方式和隐私卡片分开排布。
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: InfoCard(
                      title: t('profile.identity.personalTitle'),
                      subtitle: t('profile.identity.personalSub'),
                      lines: [
                        '${localizedText(languageCode, '用户 ID', 'User ID', '使用者 ID')}: ${profile.id}',
                        '${localizedText(languageCode, '昵称', 'Nickname', '暱稱')}: ${profile.displayName}',
                        if (profile.username.isNotEmpty)
                          '${localizedText(languageCode, '用户名', 'Username', '使用者名稱')}: @${profile.username}',
                        if (profile.domain.isNotEmpty)
                          '${localizedText(languageCode, '域名', 'Domain', '網域')}: @${profile.domain}',
                        '${localizedText(languageCode, '签名', 'Signature', '簽名')}: ${profile.signature.isNotEmpty ? profile.signature : notAvailableText}',
                      ],
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ProfileAvatar(
                            displayName: profile.displayName,
                            avatarUrl: profile.avatarUrl,
                            radius: 30,
                          ),
                          const SizedBox(height: 12),
                          BilingualActionButton(
                            variant: BilingualButtonVariant.tonal,
                            compact: true,
                            onPressed: () => _openProfileEditor(
                              context,
                              section: _ProfileEditorSection.personal,
                            ),
                            primaryLabel: t('profile.identity.editAction'),
                            secondaryLabel: peerT(
                              'profile.identity.editAction',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: InfoCard(
                      title: t('profile.identity.contactTitle'),
                      subtitle: t('profile.identity.contactSub'),
                      lines: [
                        '${localizedText(languageCode, '邮箱', 'Email', '信箱')}: ${profile.email.isNotEmpty ? profile.email : notAvailableText}',
                        '${localizedText(languageCode, '手机号', 'Phone', '手機號')}: ${profile.phone.isNotEmpty ? profile.phone : notAvailableText}',
                        '${localizedText(languageCode, '出生日期', 'Birth date', '出生日期')}: $ownerBirthDateLabel',
                        '${localizedText(languageCode, '生日', 'Birthday', '生日')}: $ownerBirthdayLabel',
                        '${localizedText(languageCode, '年龄', 'Age', '年齡')}: ${profile.age != null ? profile.age.toString() : notAvailableText}',
                        '${localizedText(languageCode, '性别', 'Gender', '性別')}: ${profile.gender.isNotEmpty ? profile.gender : notAvailableText}',
                      ],
                      trailing: BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: () => _openProfileEditor(
                          context,
                          section: _ProfileEditorSection.contact,
                        ),
                        primaryLabel: t('profile.identity.contactAction'),
                        secondaryLabel: peerT('profile.identity.contactAction'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: InfoCard(
                      title: t('profile.identity.privacyTitle'),
                      subtitle: t('profile.identity.privacySub'),
                      lines: [
                        '${localizedText(languageCode, '手机号可见范围', 'Phone visibility', '手機號可見範圍')}: ${_visibilityLabel(phoneVisibility)}',
                        '${localizedText(languageCode, '邮箱可见范围', 'Email visibility', '信箱可見範圍')}: ${_visibilityLabel(emailVisibility)}',
                        '${localizedText(languageCode, '年龄可见范围', 'Age visibility', '年齡可見範圍')}: ${_visibilityLabel(ageVisibility)}',
                        '${localizedText(languageCode, '性别可见范围', 'Gender visibility', '性別可見範圍')}: ${_visibilityLabel(genderVisibility)}',
                      ],
                      trailing: BilingualActionButton(
                        variant: BilingualButtonVariant.text,
                        compact: true,
                        onPressed: () => _openProfileEditor(
                          context,
                          section: _ProfileEditorSection.privacy,
                        ),
                        primaryLabel: t('profile.identity.privacyAction'),
                        secondaryLabel: peerT('profile.identity.privacyAction'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
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
                              t('profile.membership.title'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t('profile.membership.current'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentLevel.toUpperCase(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            BilingualActionButton(
                              variant: BilingualButtonVariant.tonal,
                              onPressed: () => _openMembershipSheet(context),
                              primaryLabel: t('profile.membership.subscribe'),
                              secondaryLabel: peerT(
                                'profile.membership.subscribe',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: hasBlockchain
                        ? Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.all(20),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                20,
                              ),
                              title: Text(
                                t('profile.blockchain.title'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              subtitle: Text(
                                '${t('profile.blockchain.total')}: ${connectedChains.length}',
                              ),
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: connectedChains
                                      .map((chain) => Chip(label: Text(chain)))
                                      .toList(),
                                ),
                              ],
                            ),
                          )
                        : InfoCard(
                            title: t('profile.blockchain.title'),
                            lines: [t('profile.blockchain.empty')],
                          ),
                  ),
                ],
              );
            },
          ),
        if (isOwnProfile) const SizedBox(height: 16),
        Text(
          t('profile.spaces.title'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SpaceListSection(
          title: t('profile.spaces.publicList'),
          spaces: profileSpaces,
          activeSpaceId: null,
          currentUserId: user?.id,
          onEnterSpace: onEnterSpace,
          languageCode: languageCode,
        ),
      ],
    );
  }
}

class _ProfileIdentityEditorBody extends StatelessWidget {
  const _ProfileIdentityEditorBody({
    required this.section,
    required this.email,
    required this.phone,
    required this.displayNameController,
    required this.usernameController,
    required this.domainController,
    required this.avatarUrlController,
    required this.signatureController,
    required this.birthDateController,
    required this.genderController,
    required this.phoneVisibility,
    required this.emailVisibility,
    required this.ageVisibility,
    required this.genderVisibility,
    required this.onPhoneVisibilityChanged,
    required this.onEmailVisibilityChanged,
    required this.onAgeVisibilityChanged,
    required this.onGenderVisibilityChanged,
    required this.languageCode,
    required this.t,
    required this.peerT,
  });

  final _ProfileEditorSection section;
  final String email;
  final String phone;
  final TextEditingController displayNameController;
  final TextEditingController usernameController;
  final TextEditingController domainController;
  final TextEditingController avatarUrlController;
  final TextEditingController signatureController;
  final TextEditingController birthDateController;
  final TextEditingController genderController;
  final String phoneVisibility;
  final String emailVisibility;
  final String ageVisibility;
  final String genderVisibility;
  final ValueChanged<String> onPhoneVisibilityChanged;
  final ValueChanged<String> onEmailVisibilityChanged;
  final ValueChanged<String> onAgeVisibilityChanged;
  final ValueChanged<String> onGenderVisibilityChanged;
  final String languageCode;
  final String Function(String key) t;
  final String Function(String key) peerT;

  @override
  Widget build(BuildContext context) {
    // Render only the selected section so the dialog stays focused on one task.
    // 只渲染弹窗入口对应的区块，让表单始终聚焦单一编辑任务。
    final parsedBirthDate = DateTime.tryParse(birthDateController.text.trim());
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final notAvailableText = localizedText(languageCode, '暂无', 'N/A', '暫無');
    final contactEmail = email.isNotEmpty ? email : notAvailableText;
    final contactPhone = phone.isNotEmpty ? phone : notAvailableText;
    final normalizedBirthDate = parsedBirthDate == null
        ? null
        : DateTime(
            parsedBirthDate.year,
            parsedBirthDate.month,
            parsedBirthDate.day,
          );
    final derivedAge = normalizedBirthDate == null
        ? null
        : () {
            var age = normalizedToday.year - normalizedBirthDate.year;
            if (normalizedToday.month < normalizedBirthDate.month ||
                (normalizedToday.month == normalizedBirthDate.month &&
                    normalizedToday.day < normalizedBirthDate.day)) {
              age--;
            }
            return age >= 0 ? age : null;
          }();
    final derivedBirthdayLabel = normalizedBirthDate == null
        ? localizedText(languageCode, '未设置', 'Not set', '未設定')
        : localizedText(
            languageCode,
            '${normalizedBirthDate.month}月${normalizedBirthDate.day}日',
            '${normalizedBirthDate.month.toString().padLeft(2, '0')}-${normalizedBirthDate.day.toString().padLeft(2, '0')}',
            '${normalizedBirthDate.month}月${normalizedBirthDate.day}日',
          );
    switch (section) {
      case _ProfileEditorSection.personal:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualField(
              primaryLabel: t('profile.identity.nickname'),
              secondaryLabel: peerT('profile.identity.nickname'),
              child: TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  hintText: t('dashboard.displayNamePlaceholder'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            BilingualField(
              primaryLabel: t('profile.identity.username'),
              secondaryLabel: peerT('profile.identity.username'),
              child: TextField(
                controller: usernameController,
                maxLength: 63,
                buildCounter:
                    (
                      BuildContext context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) => null,
                decoration: InputDecoration(
                  hintText: t('dashboard.usernamePlaceholder'),
                ),
              ),
              helperText: t('dashboard.usernameHint'),
            ),
            const SizedBox(height: 12),
            BilingualField(
              primaryLabel: t('profile.identity.domain'),
              secondaryLabel: peerT('profile.identity.domain'),
              child: TextField(
                controller: domainController,
                maxLength: 63,
                buildCounter:
                    (
                      BuildContext context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) => null,
                decoration: InputDecoration(
                  hintText: t('profile.identity.domainPlaceholder'),
                ),
              ),
              helperText: t('profile.identity.domainHint'),
            ),
            const SizedBox(height: 12),
            BilingualField(
              primaryLabel: t('profile.identity.avatarLabel'),
              secondaryLabel: peerT('profile.identity.avatarLabel'),
              child: TextField(
                controller: avatarUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: t('profile.identity.avatarPlaceholder'),
                ),
              ),
              helperText: t('profile.identity.avatarHint'),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.48),
                ),
              ),
              child: Row(
                children: [
                  _ProfileAvatar(
                    displayName: displayNameController.text,
                    avatarUrl: avatarUrlController.text,
                    radius: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      localizedText(
                        languageCode,
                        '头像会立即用于个人主页卡片和资料摘要。',
                        'The avatar is used immediately in the profile card and summary.',
                        '頭像會立即用於個人主頁卡片與資料摘要。',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BilingualField(
              primaryLabel: t('profile.identity.signature'),
              secondaryLabel: peerT('profile.identity.signature'),
              child: TextField(
                controller: signatureController,
                decoration: InputDecoration(
                  hintText: t('profile.identity.signaturePlaceholder'),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      case _ProfileEditorSection.contact:
        // Contact info editor keeps email and phone visible as read-only account data.
        // 联系方式编辑区把邮箱和手机号作为只读账号资料展示。
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualField(
              primaryLabel: t('profile.identity.emailLabel'),
              secondaryLabel: peerT('profile.identity.emailLabel'),
              child: TextFormField(
                initialValue: contactEmail,
                readOnly: true,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 12),
            BilingualField(
              primaryLabel: t('profile.identity.phoneLabel'),
              secondaryLabel: peerT('profile.identity.phoneLabel'),
              child: TextFormField(
                initialValue: contactPhone,
                readOnly: true,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('profile.identity.contactNote'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            BilingualField(
              primaryLabel: t('profile.identity.birthDateLabel'),
              secondaryLabel: peerT('profile.identity.birthDateLabel'),
              child: TextField(
                controller: birthDateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: t('profile.identity.birthDatePlaceholder'),
                  suffixIcon: IconButton(
                    tooltip: localizedText(
                      languageCode,
                      '选择出生日期',
                      'Pick birth date',
                      '選擇出生日期',
                    ),
                    onPressed: () async {
                      final initialDate =
                          normalizedBirthDate ?? normalizedToday;
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1900, 1, 1),
                        lastDate: normalizedToday,
                      );
                      if (selected == null) {
                        return;
                      }
                      birthDateController.text =
                          '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                      if (context.mounted) {
                        (context as Element).markNeedsBuild();
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded),
                  ),
                ),
                onTap: () async {
                  final initialDate = normalizedBirthDate ?? normalizedToday;
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1900, 1, 1),
                    lastDate: normalizedToday,
                  );
                  if (selected == null) {
                    return;
                  }
                  birthDateController.text =
                      '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                  if (context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              helperText:
                  '${t('profile.identity.birthdayLabel')}: $derivedBirthdayLabel · ${t('profile.identity.ageLabel')}: ${derivedAge?.toString() ?? localizedText(languageCode, '暂无', 'N/A', '暫無')}',
            ),
            const SizedBox(height: 12),
            BilingualField(
              primaryLabel: t('profile.identity.genderLabel'),
              secondaryLabel: peerT('profile.identity.genderLabel'),
              child: TextField(
                controller: genderController,
                decoration: InputDecoration(
                  hintText: t('profile.identity.genderPlaceholder'),
                ),
              ),
            ),
          ],
        );
      case _ProfileEditorSection.privacy:
        return LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth >= 720
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: BilingualDropdownField<String>(
                    primaryLabel: t('profile.identity.phoneVisibility'),
                    secondaryLabel: peerT('profile.identity.phoneVisibility'),
                    value: phoneVisibility,
                    items: buildIdentityVisibilityItems(languageCode),
                    onChanged: (value) =>
                        onPhoneVisibilityChanged(value ?? phoneVisibility),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: BilingualDropdownField<String>(
                    primaryLabel: t('profile.identity.emailVisibility'),
                    secondaryLabel: peerT('profile.identity.emailVisibility'),
                    value: emailVisibility,
                    items: buildIdentityVisibilityItems(languageCode),
                    onChanged: (value) =>
                        onEmailVisibilityChanged(value ?? emailVisibility),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: BilingualDropdownField<String>(
                    primaryLabel: t('profile.identity.ageVisibility'),
                    secondaryLabel: peerT('profile.identity.ageVisibility'),
                    value: ageVisibility,
                    items: buildIdentityVisibilityItems(languageCode),
                    onChanged: (value) =>
                        onAgeVisibilityChanged(value ?? ageVisibility),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: BilingualDropdownField<String>(
                    primaryLabel: t('profile.identity.genderVisibility'),
                    secondaryLabel: peerT('profile.identity.genderVisibility'),
                    value: genderVisibility,
                    items: buildIdentityVisibilityItems(languageCode),
                    onChanged: (value) =>
                        onGenderVisibilityChanged(value ?? genderVisibility),
                  ),
                ),
              ],
            );
          },
        );
    }
  }
}

class PostDetailView extends StatelessWidget {
  const PostDetailView({
    super.key,
    required this.user,
    required this.currentPost,
    required this.commentController,
    required this.onEditPost,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.onOpenAuthor,
    required this.languageCode,
    this.onDeletePost,
  });

  final CurrentUser? user;
  final PostItem? currentPost;
  final TextEditingController commentController;
  final ValueChanged<PostItem> onEditPost;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback onOpenAuthor;
  final String languageCode;
  final VoidCallback? onDeletePost;

  @override
  Widget build(BuildContext context) {
    final post = currentPost;
    if (post == null) {
      return InfoCard(
        title: localizedText(languageCode, '文章详情', 'Post detail', '文章詳情'),
        lines: [
          localizedText(
            languageCode,
            '先从公共空间或个人主页打开一篇文章。',
            'Open a post from a public space or profile first.',
            '先從公開空間或個人主頁打開一篇文章。',
          ),
        ],
      );
    }

    final canManagePost =
        user != null &&
        (post.userId == user!.id || post.spaceUserId == user!.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostCard(
          post: post,
          commentController: commentController,
          onLike: onLike,
          onShare: onShare,
          onComment: onComment,
          onOpenAuthor: onOpenAuthor,
          onEdit: canManagePost ? () => onEditPost(post) : null,
          onDelete: canManagePost ? onDeletePost : null,
        ),
        if (canManagePost) ...[
          const SizedBox(height: 16),
          InfoCard(
            title: localizedText(languageCode, '编辑提示', 'Editing note', '編輯提示'),
            lines: [
              localizedText(
                languageCode,
                '点击文章卡片右上角的“编辑”会弹出窗口。保存、添加图片/视频和清除媒体都在弹窗内完成。',
                'Tap the Edit button in the card header to open a modal dialog. Save, add image or video, and clear media all happen inside the dialog.',
                '點擊文章卡片右上角的「編輯」會彈出視窗。儲存、添加圖片/影片與清除媒體都在彈窗內完成。',
              ),
              localizedText(
                languageCode,
                '上传的图片会保持等比例缩放，最长边限制为 1600px。',
                'Uploaded images keep their aspect ratio, and the long edge is capped at 1600px.',
                '上傳的圖片會保持等比例縮放，最長邊限制為 1600px。',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class FriendsView extends StatelessWidget {
  const FriendsView({
    super.key,
    required this.loading,
    required this.searchController,
    required this.searchResults,
    required this.friends,
    required this.onSearch,
    required this.onAddFriend,
    required this.onAcceptFriend,
    required this.onOpenProfile,
    required this.onStartChat,
    required this.languageCode,
  });

  final bool loading;
  final TextEditingController searchController;
  final List<UserSearchItem> searchResults;
  final List<FriendItem> friends;
  final VoidCallback onSearch;
  final ValueChanged<String> onAddFriend;
  final ValueChanged<String> onAcceptFriend;
  final ValueChanged<String> onOpenProfile;
  final ValueChanged<FriendItem> onStartChat;
  final String languageCode;

  Future<void> _openFriendProfileDialog(
    BuildContext context,
    FriendItem friend,
  ) async {
    // Open a summary-only modal preview so private contact fields stay hidden.
    // 打开仅含摘要的弹层预览，避免把私密联系方式直接展示出来。
    final hiddenText = localizedText(languageCode, '未公开', 'Not public', '未公開');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            localizedText(languageCode, '好友主页', 'Friend profile', '好友主頁'),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
          child: InfoCard(
            title: friend.displayName,
            lines: [
              '${localizedText(languageCode, '用户名', 'Username', '使用者名稱')}: ${friend.username.isNotEmpty ? friend.username : localizedText(languageCode, '暂无', 'N/A', '暫無')}',
              if (friend.secondary.isNotEmpty)
                  '${localizedText(languageCode, '公开摘要', 'Public summary', '公開摘要')}: ${friend.secondary}',
                '${localizedText(languageCode, '邮箱', 'Email', '信箱')}: ${friend.email.isNotEmpty ? friend.email : hiddenText}',
                '${localizedText(languageCode, '手机号', 'Phone', '手機號')}: ${friend.phone.isNotEmpty ? friend.phone : hiddenText}',
                '${localizedText(languageCode, '状态', 'Status', '狀態')}: ${friend.status}',
                '${localizedText(languageCode, '方向', 'Direction', '方向')}: ${friend.direction}',
              ],
            ),
          ),
          actions: [
            BilingualActionButton(
              variant: BilingualButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
              primaryLabel: localizedText(languageCode, '关闭', 'Close', '關閉'),
              secondaryLabel: 'Close',
            ),
            BilingualActionButton(
              variant: BilingualButtonVariant.tonal,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onOpenProfile(friend.id);
              },
              primaryLabel: localizedText(
                languageCode,
                '打开完整主页',
                'Open full profile',
                '開啟完整主頁',
              ),
              secondaryLabel: 'Open full profile',
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // Search users / 搜索用户：仅显示当前语言。
                Text(
                  localizedText(languageCode, '搜索用户', 'Search users', '搜尋使用者'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: localizedText(
                            languageCode,
                            '搜索 display name、邮箱、手机号、用户 ID',
                            'Search display name, email, phone, or user ID',
                            '搜尋顯示名稱、信箱、手機號碼或使用者 ID',
                          ),
                        ),
                        onSubmitted: (_) => onSearch(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search action uses the shared bilingual button.
                    // 搜索动作统一使用双语按钮组件。
                    BilingualActionButton(
                      onPressed: loading ? null : onSearch,
                      primaryLabel: localizedText(
                        languageCode,
                        '搜索',
                        'Search',
                        '搜尋',
                      ),
                      secondaryLabel: 'Search',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: searchResults
                      .map(
                        (item) => SizedBox(
                          width: 300,
                          child: InfoCard(
                            title: item.displayName,
                            lines: [
                              item.secondary,
                              if (item.relationStatus.isNotEmpty)
                                '${localizedText(languageCode, '关系', 'Relation', '關係')}: ${item.relationStatus} · ${item.direction}',
                            ],
                            trailing: BilingualActionButton(
                              variant: BilingualButtonVariant.tonal,
                              onPressed: item.relationStatus.isEmpty
                                  ? () => onAddFriend(item.id)
                                  : null,
                              primaryLabel: item.relationStatus.isEmpty
                                  ? localizedText(
                                      languageCode,
                                      '添加好友',
                                      'Add friend',
                                      '新增好友',
                                    )
                                  : localizedText(
                                      languageCode,
                                      '已存在关系',
                                      'Relationship exists',
                                      '已有關係',
                                    ),
                              secondaryLabel: item.relationStatus.isEmpty
                                  ? 'Add friend'
                                  : 'Relationship exists',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: friends
              .map(
                (friend) => SizedBox(
                  width: 320,
                  child: InfoCard(
                    title: friend.displayName,
                    lines: [
                      friend.secondary,
                      '${localizedText(languageCode, '状态', 'Status', '狀態')}: ${friend.status}',
                      '${localizedText(languageCode, '方向', 'Direction', '方向')}: ${friend.direction}',
                    ],
                    trailing: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        BilingualActionButton(
                          variant: BilingualButtonVariant.tonal,
                          onPressed: () =>
                              _openFriendProfileDialog(context, friend),
                          primaryLabel: localizedText(
                            languageCode,
                            '主页',
                            'Profile',
                            '主頁',
                          ),
                          secondaryLabel: 'Profile',
                        ),
                        if (friend.direction == 'incoming' &&
                            friend.status == 'pending')
                          BilingualActionButton(
                            variant: BilingualButtonVariant.tonal,
                            onPressed: () => onAcceptFriend(friend.id),
                            primaryLabel: localizedText(
                              languageCode,
                              '接受',
                              'Accept',
                              '接受',
                            ),
                            secondaryLabel: 'Accept',
                          )
                        else
                          BilingualActionButton(
                            variant: BilingualButtonVariant.tonal,
                            onPressed: friend.status == 'accepted'
                                ? () => onStartChat(friend)
                                : null,
                            primaryLabel: localizedText(
                              languageCode,
                              '聊天',
                              'Chat',
                              '聊天',
                            ),
                            secondaryLabel: 'Chat',
                          ),
                      ],
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

class ChatView extends StatelessWidget {
  const ChatView({
    super.key,
    required this.width,
    required this.user,
    required this.activeChat,
    required this.acceptedFriends,
    required this.conversations,
    required this.messages,
    required this.pendingFriendCount,
    required this.chatAttachment,
    required this.chatComposerController,
    required this.loading,
    required this.findFriend,
    required this.onStartChat,
    required this.onSendMessage,
    required this.onPickAttachment,
    required this.onClearAttachment,
    required this.languageCode,
  });

  final double width;
  final CurrentUser user;
  final FriendItem? activeChat;
  final List<FriendItem> acceptedFriends;
  final List<ConversationItem> conversations;
  final List<ChatMessage> messages;
  final int pendingFriendCount;
  final ChatAttachmentDraft? chatAttachment;
  final TextEditingController chatComposerController;
  final bool loading;
  final FriendItem? Function(String id) findFriend;
  final ValueChanged<FriendItem> onStartChat;
  final VoidCallback onSendMessage;
  final Future<void> Function(String messageType) onPickAttachment;
  final VoidCallback onClearAttachment;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final compact = width < 1100;
    final listPane = _buildListPane(context);
    final chatPane = _buildChatPane(context);

    if (compact) {
      return Column(children: [listPane, const SizedBox(height: 16), chatPane]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 380, child: listPane),
        const SizedBox(width: 16),
        Expanded(child: chatPane),
      ],
    );
  }

  Widget _buildSelectableSummaryCard({
    required BuildContext context,
    required String title,
    required List<String> lines,
    required VoidCallback onTap,
    Widget? trailing,
    bool selected = false,
  }) {
    // Keep chat-side summary cards visually aligned with the shared card system.
    // 让聊天侧栏摘要卡与统一卡片系统保持一致。
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const SizedBox(height: 8),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListPane(BuildContext context) {
    final totalUnread = conversations.fold<int>(
      0,
      (sum, item) => sum + item.unreadCount,
    );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '最近会话',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (totalUnread > 0)
                  Badge(
                    isLabelVisible: true,
                    label: Text(totalUnread > 99 ? '99+' : '$totalUnread'),
                    child: const Icon(Icons.mark_chat_unread_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (pendingFriendCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('有 $pendingFriendCount 个好友请求待处理。'),
              ),
            if (pendingFriendCount > 0) const SizedBox(height: 12),
            if (conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('还没有会话记录。'),
              ),
            ...conversations.map((item) {
              final friend = findFriend(item.peerId);
              if (friend == null) {
                return const SizedBox.shrink();
              }
              final isSelected = activeChat?.id == friend.id;
              return _buildSelectableSummaryCard(
                context: context,
                title: friend.displayName,
                lines: [
                  friend.secondary,
                  item.lastMessagePreview.isNotEmpty
                      ? item.lastMessagePreview
                      : item.lastMessage,
                ],
                trailing: item.hasUnread
                    ? CircleAvatar(
                        radius: 12,
                        child: Text('${item.unreadCount}'),
                      )
                    : null,
                selected: isSelected,
                onTap: () => onStartChat(friend),
              );
            }),
            const Divider(height: 24),
            Text('好友', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...acceptedFriends.map(
              (friend) => _buildSelectableSummaryCard(
                context: context,
                title: friend.displayName,
                lines: [
                  friend.secondary,
                  '${localizedText(languageCode, '状态', 'Status', '狀態')}: ${friend.status}',
                ],
                selected: activeChat?.id == friend.id,
                onTap: () => onStartChat(friend),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPane(BuildContext context) {
    final mediaAttachment = chatAttachment;
    final height = width < 1100 ? 420.0 : 520.0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeChat?.displayName ?? '选择一个好友开始聊天',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeChat?.secondary ?? '选择左侧好友后会加载历史消息。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (activeChat != null)
                  BilingualActionButton(
                    variant: BilingualButtonVariant.tonal,
                    onPressed: () => onStartChat(activeChat!),
                    primaryLabel: '刷新会话',
                    secondaryLabel: 'Refresh chat',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (mediaAttachment != null) ...[
              _buildAttachmentDraft(context, mediaAttachment),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: height,
              child: activeChat == null
                  ? const Center(child: Text('选择左侧好友后会加载历史消息并接入 WebSocket。'))
                  : ListView.separated(
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = messages[index];
                        final mine = item.from == user.id;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: width < 1100 ? width * 0.82 : 460,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: mine
                                    ? const Color(0xFF1D6F87)
                                    : const Color(0xFF192535),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: mine
                                      ? const Color(
                                          0xFF2FD0FF,
                                        ).withValues(alpha: 0.4)
                                      : Colors.white10,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.hasMedia) ...[
                                    _buildMediaMessage(context, item),
                                    if (item.content.isNotEmpty)
                                      const SizedBox(height: 10),
                                  ],
                                  if (item.content.isNotEmpty)
                                    Text(
                                      item.content,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        item.createdAtLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      if (item.expiresAt != null)
                                        Text(
                                          '临时消息 · ${formatDateTime(item.expiresAt!)} 自动删除',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            _buildComposer(context, mediaAttachment),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    ChatAttachmentDraft? mediaAttachment,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: loading ? null : () => onPickAttachment('image'),
              icon: const Icon(Icons.image_outlined),
              label: const Text('图片'),
            ),
            FilledButton.tonalIcon(
              onPressed: loading ? null : () => onPickAttachment('video'),
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('视频'),
            ),
            FilledButton.tonalIcon(
              onPressed: loading ? null : () => onPickAttachment('audio'),
              icon: const Icon(Icons.mic_none_outlined),
              label: const Text('语音'),
            ),
            if (mediaAttachment != null)
              BilingualActionButton(
                variant: BilingualButtonVariant.tonal,
                onPressed: loading ? null : onClearAttachment,
                primaryLabel: '清除附件',
                secondaryLabel: 'Clear attachment',
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: chatComposerController,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(labelText: '输入消息或附件说明'),
                onSubmitted: (_) => onSendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            BilingualActionButton(
              onPressed: loading ? null : onSendMessage,
              primaryLabel: '发送',
              secondaryLabel: 'Send',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentDraft(
    BuildContext context,
    ChatAttachmentDraft attachment,
  ) {
    final icon = switch (attachment.messageType) {
      'image' => Icons.image_outlined,
      'video' => Icons.video_library_outlined,
      'audio' => Icons.mic_none_outlined,
      _ => Icons.attach_file,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.mediaName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${attachment.messageType} · ${attachment.sizeLabel} · 7天后自动删除',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BilingualActionButton(
            variant: BilingualButtonVariant.tonal,
            onPressed: loading ? null : onClearAttachment,
            primaryLabel: '移除',
            secondaryLabel: 'Remove',
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMessage(BuildContext context, ChatMessage message) {
    final bytes = _decodeMediaBytes(message.mediaData);
    if (message.isImage && bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            message.isVideo
                ? Icons.video_library_outlined
                : message.isAudio
                ? Icons.mic_none_outlined
                : Icons.image_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.mediaLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  message.mediaMime.isNotEmpty
                      ? message.mediaMime
                      : message.messageType,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          BilingualActionButton(
            variant: BilingualButtonVariant.text,
            compact: true,
            onPressed: () => openChatAttachment(
              mediaMime: message.mediaMime,
              mediaData: message.mediaData,
            ),
            primaryLabel: '打开',
            secondaryLabel: 'Open',
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeMediaBytes(String mediaData) {
    if (mediaData.isEmpty) {
      return null;
    }
    try {
      // Decode and inflate the compressed attachment payload.
      // 解码并展开已压缩的附件载荷。
      final rawBytes = Uint8List.fromList(base64Decode(mediaData));
      try {
        return Uint8List.fromList(GZipDecoder().decodeBytes(rawBytes));
      } catch (_) {
        return rawBytes;
      }
    } catch (_) {
      return null;
    }
  }
}
