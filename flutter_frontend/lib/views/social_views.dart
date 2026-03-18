import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:archive/archive.dart';

import '../controllers/chat_media_actions.dart';
import '../models/app_models.dart';
import 'content_sections.dart';
import '../widgets/app_cards.dart';
import '../main.dart' show ProfileTab;
import 'settings_views.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.user,
    required this.profileUser,
    required this.profilePosts,
    required this.subscription,
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
    required this.onActivatePlan,
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
    required this.t,
  });

  final CurrentUser? user;
  final UserProfileItem? profileUser;
  final List<PostItem> profilePosts;
  final SubscriptionItem? subscription;
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
  // Activate subscription plan.
  // 激活订阅方案回调。
  final ValueChanged<String> onActivatePlan;
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
  final String Function(String key) t;

  @override
  Widget build(BuildContext context) {
    final profile = profileUser;
    if (profile == null) {
      return InfoCard(title: '个人主页', lines: const ['尚未加载资料，点击左侧个人主页重新进入。']);
    }

    final isOwnProfile = user != null && profile.id == user!.id;
    final hasBlockchain = connectedChains.isNotEmpty;
    // Ensure blockchain tab is hidden when there are no accounts.
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
            '用户 ID: ${profile.id}',
            if (profile.domain.isNotEmpty) '域名身份: @${profile.domain}',
            if (profile.username.isNotEmpty) '用户名: @${profile.username}',
            if (profile.signature.isNotEmpty) '签名: ${profile.signature}',
            if (profile.email.isNotEmpty) '邮箱: ${profile.email}',
            if (profile.phone.isNotEmpty) '手机号: ${profile.phone}',
            if (profile.age != null) '年龄: ${profile.age}',
            if (profile.gender.isNotEmpty) '性别: ${profile.gender}',
            '状态: ${profile.status}',
            if (!isOwnProfile && profile.relationStatus.isNotEmpty)
              '关系: ${profile.relationStatus} / ${profile.direction}',
            if (isOwnProfile && connectedChains.isNotEmpty)
              '已连接链: ${connectedChains.join(', ')}',
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
                    '身份卡 / Identity card',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: '昵称 / Nickname',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    // Username handle / 用户名句柄：保留为可选账号标识。
                    // Username is kept as an optional account handle.
                    maxLength: 63,
                    decoration: const InputDecoration(
                      labelText: 'Username / 用户名',
                      helperText:
                          'Letters and numbers only, up to 63 characters / 仅允许英文字母和数字，长度不超过 63',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: domainController,
                    // Domain handle / 域名句柄：用于二级域名与登录入口。
                    // Domain identity / 域名身份：用于二级域名与登录。
                    maxLength: 63,
                    decoration: const InputDecoration(
                      labelText: 'Domain / 域名',
                      helperText:
                          '域名会作为身份卡和登录入口 / Domain is used as identity card and login handle',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: signatureController,
                    decoration: const InputDecoration(
                      labelText: 'Signature / 签名',
                    ),
                    maxLines: 3,
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
                            child: DropdownButtonFormField<String>(
                              initialValue: phoneVisibility,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '手机号可见范围 / Phone visibility',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'public',
                                  child: Text('公开 / Public'),
                                ),
                                DropdownMenuItem(
                                  value: 'friends',
                                  child: Text('好友可见 / Friends'),
                                ),
                                DropdownMenuItem(
                                  value: 'private',
                                  child: Text('仅自己 / Only me'),
                                ),
                              ],
                              onChanged: (value) => onPhoneVisibilityChanged(
                                value ?? phoneVisibility,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: emailVisibility,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '邮箱可见范围 / Email visibility',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'public',
                                  child: Text('公开 / Public'),
                                ),
                                DropdownMenuItem(
                                  value: 'friends',
                                  child: Text('好友可见 / Friends'),
                                ),
                                DropdownMenuItem(
                                  value: 'private',
                                  child: Text('仅自己 / Only me'),
                                ),
                              ],
                              onChanged: (value) => onEmailVisibilityChanged(
                                value ?? emailVisibility,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: ageVisibility,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '年龄可见范围 / Age visibility',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'public',
                                  child: Text('公开 / Public'),
                                ),
                                DropdownMenuItem(
                                  value: 'friends',
                                  child: Text('好友可见 / Friends'),
                                ),
                                DropdownMenuItem(
                                  value: 'private',
                                  child: Text('仅自己 / Only me'),
                                ),
                              ],
                              onChanged: (value) => onAgeVisibilityChanged(
                                value ?? ageVisibility,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: genderVisibility,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '性别可见范围 / Gender visibility',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'public',
                                  child: Text('公开 / Public'),
                                ),
                                DropdownMenuItem(
                                  value: 'friends',
                                  child: Text('好友可见 / Friends'),
                                ),
                                DropdownMenuItem(
                                  value: 'private',
                                  child: Text('仅自己 / Only me'),
                                ),
                              ],
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
                    '域名与昵称分离，域名会用于二级域名路由和登录入口。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: loading ? null : onSaveProfile,
                    child: const Text('保存身份卡 / Save identity card'),
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
                FilledButton.tonal(
                  onPressed: () => onAddFriend(profile.id),
                  child: const Text('添加好友'),
                ),
              if (profile.relationStatus == 'pending' &&
                  profile.direction == 'incoming')
                FilledButton.tonal(
                  onPressed: () => onAcceptFriend(profile.id),
                  child: const Text('接受好友'),
                ),
              if (profile.relationStatus == 'accepted')
                FilledButton.tonal(
                  onPressed: onStartChat,
                  child: const Text('发起聊天'),
                ),
            ],
          ),
        const SizedBox(height: 16),
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
                ChoiceChip(
                  label: Text(t('profile.tab.subscription')),
                  selected: effectiveTab == ProfileTab.subscription,
                  onSelected: (_) =>
                      onProfileTabChanged(ProfileTab.subscription),
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
        else if (effectiveTab == ProfileTab.subscription)
          SubscriptionView(
            subscription: subscription,
            loading: loading,
            onActivatePlan: onActivatePlan,
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
          emptyText: isOwnProfile ? '你还没有发布内容。' : '这个用户还没有公开内容。',
          commentControllerFor: commentControllerFor,
          onLike: onToggleLike,
          onShare: onSharePost,
          onComment: onCommentPost,
          onOpenAuthor: onOpenProfile,
          onOpenDetail: onOpenPostDetail,
          canEditPost: (post) => user != null && post.userId == user!.id,
          onDeletePost: onDeletePost,
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
    required this.loading,
    required this.commentController,
    required this.editTitleController,
    required this.editContentController,
    required this.editVisibility,
    required this.editStatus,
    required this.onEditVisibilityChanged,
    required this.onEditStatusChanged,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.onOpenAuthor,
    required this.onSaveEdits,
    this.onDeletePost,
  });

  final CurrentUser? user;
  final PostItem? currentPost;
  final bool loading;
  final TextEditingController commentController;
  final TextEditingController editTitleController;
  final TextEditingController editContentController;
  final String editVisibility;
  final String editStatus;
  final ValueChanged<String> onEditVisibilityChanged;
  final ValueChanged<String> onEditStatusChanged;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback onOpenAuthor;
  final VoidCallback onSaveEdits;
  final VoidCallback? onDeletePost;

  @override
  Widget build(BuildContext context) {
    final post = currentPost;
    if (post == null) {
      return InfoCard(title: '文章详情', lines: const ['先从公共空间或个人主页打开一篇文章。']);
    }

    final isOwnPost = user != null && post.userId == user!.id;
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
          onDelete: isOwnPost ? onDeletePost : null,
        ),
        const SizedBox(height: 16),
        if (isOwnPost)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('编辑文章', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editTitleController,
                    decoration: const InputDecoration(labelText: '标题'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editContentController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: '内容'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: editVisibility,
                          decoration: const InputDecoration(labelText: '可见性'),
                          items: const [
                            DropdownMenuItem(
                              value: 'public',
                              child: Text('公开'),
                            ),
                            DropdownMenuItem(
                              value: 'private',
                              child: Text('私密'),
                            ),
                          ],
                          onChanged: (value) =>
                              onEditVisibilityChanged(value ?? editVisibility),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: editStatus,
                          decoration: const InputDecoration(labelText: '状态'),
                          items: const [
                            DropdownMenuItem(
                              value: 'published',
                              child: Text('已发布'),
                            ),
                            DropdownMenuItem(value: 'draft', child: Text('草稿')),
                            DropdownMenuItem(
                              value: 'hidden',
                              child: Text('隐藏'),
                            ),
                          ],
                          onChanged: (value) =>
                              onEditStatusChanged(value ?? editStatus),
                        ),
                      ),
                      FilledButton(
                        onPressed: loading ? null : onSaveEdits,
                        child: const Text('保存修改'),
                      ),
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
                Text('搜索用户', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: '搜索 display name / 邮箱 / 手机号 / 用户 ID',
                        ),
                        onSubmitted: (_) => onSearch(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: loading ? null : onSearch,
                      child: const Text('搜索'),
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
                                '关系: ${item.relationStatus} / ${item.direction}',
                            ],
                            trailing: FilledButton.tonal(
                              onPressed: item.relationStatus.isEmpty
                                  ? () => onAddFriend(item.id)
                                  : null,
                              child: Text(
                                item.relationStatus.isEmpty ? '添加好友' : '已存在关系',
                              ),
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
                      '状态: ${friend.status}',
                      '方向: ${friend.direction}',
                    ],
                    trailing: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => onOpenProfile(friend.id),
                          child: const Text('主页'),
                        ),
                        if (friend.direction == 'incoming' &&
                            friend.status == 'pending')
                          FilledButton.tonal(
                            onPressed: () => onAcceptFriend(friend.id),
                            child: const Text('接受'),
                          )
                        else
                          FilledButton.tonal(
                            onPressed: friend.status == 'accepted'
                                ? () => onStartChat(friend)
                                : null,
                            child: const Text('聊天'),
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
                  FilledButton.tonal(
                    onPressed: () => onStartChat(activeChat!),
                    child: const Text('刷新会话'),
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
              FilledButton.tonal(
                onPressed: loading ? null : onClearAttachment,
                child: const Text('清除附件'),
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
            FilledButton(
              onPressed: loading ? null : onSendMessage,
              child: const Text('发送'),
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
          FilledButton.tonal(
            onPressed: loading ? null : onClearAttachment,
            child: const Text('移除'),
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
          TextButton(
            onPressed: () => openChatAttachment(
              mediaMime: message.mediaMime,
              mediaData: message.mediaData,
            ),
            child: const Text('打开'),
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
