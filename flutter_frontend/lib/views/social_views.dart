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
    required this.signatureController,
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
  final TextEditingController signatureController;
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
    // Ensure the blockchain tab is hidden when there are no accounts.
    // 链上账号为空时隐藏对应选项卡。
    final effectiveTab = !hasBlockchain && profileTab == ProfileTab.blockchain
        ? ProfileTab.levels
        : profileTab;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            if (profile.email.isNotEmpty)
              '${localizedText(languageCode, '邮箱', 'Email', '信箱')}: ${profile.email}',
            if (profile.phone.isNotEmpty)
              '${localizedText(languageCode, '手机号', 'Phone', '手機號')}: ${profile.phone}',
            if (profile.age != null)
              '${localizedText(languageCode, '年龄', 'Age', '年齡')}: ${profile.age}',
            if (profile.gender.isNotEmpty)
              '${localizedText(languageCode, '性别', 'Gender', '性別')}: ${profile.gender}',
            '${localizedText(languageCode, '状态', 'Status', '狀態')}: ${profile.status}',
            if (!isOwnProfile && profile.relationStatus.isNotEmpty)
              '${localizedText(languageCode, '关系', 'Relation', '關係')}: ${profile.relationStatus} · ${profile.direction}',
            if (isOwnProfile && connectedChains.isNotEmpty)
              '${localizedText(languageCode, '已连接链', 'Connected chains', '已連接鏈')}: ${connectedChains.join(', ')}',
          ],
        ),
        const SizedBox(height: 16),
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
                  Text(
                    localizedText(languageCode, '身份卡', 'Identity card', '身分卡'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
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
                onActivateLevel: onActivateLevel,
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
                '图片会保持等比例缩放，并限制最大显示尺寸。',
                'Images keep their aspect ratio and are capped at a maximum display size.',
                '圖片會保持等比例縮放，並限制最大顯示尺寸。',
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
                          onPressed: () => onOpenProfile(friend.id),
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
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  title: Text(friend.displayName),
                  subtitle: Text(
                    item.lastMessagePreview.isNotEmpty
                        ? item.lastMessagePreview
                        : item.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: item.hasUnread
                      ? CircleAvatar(
                          radius: 12,
                          child: Text('${item.unreadCount}'),
                        )
                      : null,
                  selected: isSelected,
                  onTap: () => onStartChat(friend),
                ),
              );
            }),
            const Divider(height: 24),
            Text('好友', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...acceptedFriends.map(
              (friend) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(friend.displayName),
                subtitle: Text(friend.secondary),
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
