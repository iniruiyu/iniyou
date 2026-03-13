import 'package:flutter/material.dart';

import '../models/app_models.dart';
import 'content_sections.dart';
import '../widgets/app_cards.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.user,
    required this.profileUser,
    required this.profilePosts,
    required this.connectedChains,
    required this.displayNameController,
    required this.loading,
    required this.commentControllerFor,
    required this.onSaveProfile,
    required this.onAddFriend,
    required this.onAcceptFriend,
    required this.onStartChat,
    required this.onToggleLike,
    required this.onSharePost,
    required this.onCommentPost,
    required this.onOpenProfile,
    required this.onOpenPostDetail,
  });

  final CurrentUser? user;
  final UserProfileItem? profileUser;
  final List<PostItem> profilePosts;
  final List<String> connectedChains;
  final TextEditingController displayNameController;
  final bool loading;
  final TextEditingController Function(String postId) commentControllerFor;
  final VoidCallback onSaveProfile;
  final ValueChanged<String> onAddFriend;
  final ValueChanged<String> onAcceptFriend;
  final VoidCallback onStartChat;
  final ValueChanged<PostItem> onToggleLike;
  final ValueChanged<PostItem> onSharePost;
  final ValueChanged<PostItem> onCommentPost;
  final ValueChanged<String> onOpenProfile;
  final ValueChanged<String> onOpenPostDetail;

  @override
  Widget build(BuildContext context) {
    final profile = profileUser;
    if (profile == null) {
      return InfoCard(title: '个人主页', lines: const ['尚未加载资料，点击左侧个人主页重新进入。']);
    }

    final isOwnProfile = user != null && profile.id == user!.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: profile.displayName,
          lines: [
            '用户 ID: ${profile.id}',
            if (profile.email.isNotEmpty) '邮箱: ${profile.email}',
            if (profile.phone.isNotEmpty) '手机号: ${profile.phone}',
            '状态: ${profile.status}',
            if (!isOwnProfile && profile.relationStatus.isNotEmpty)
              '关系: ${profile.relationStatus} / ${profile.direction}',
            if (isOwnProfile)
              '已连接链: ${connectedChains.isEmpty ? '暂无' : connectedChains.join(', ')}',
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
                  Text('更新展示名', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: loading ? null : onSaveProfile,
                    child: const Text('保存'),
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
    required this.chatComposerController,
    required this.loading,
    required this.findFriend,
    required this.onStartChat,
    required this.onSendMessage,
  });

  final double width;
  final CurrentUser user;
  final FriendItem? activeChat;
  final List<FriendItem> acceptedFriends;
  final List<ConversationItem> conversations;
  final List<ChatMessage> messages;
  final TextEditingController chatComposerController;
  final bool loading;
  final FriendItem? Function(String id) findFriend;
  final ValueChanged<FriendItem> onStartChat;
  final VoidCallback onSendMessage;

  @override
  Widget build(BuildContext context) {
    final compact = width < 1100;
    final listPane = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最近会话', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
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
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(friend.displayName),
                subtitle: Text(item.lastMessage),
                trailing: item.unreadCount > 0
                    ? CircleAvatar(
                        radius: 12,
                        child: Text('${item.unreadCount}'),
                      )
                    : null,
                onTap: () => onStartChat(friend),
              );
            }),
            const Divider(height: 24),
            Text('好友', style: Theme.of(context).textTheme.titleMedium),
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

    final chatPane = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeChat?.displayName ?? '选择一个好友开始聊天',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 460,
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
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xFF1D6F87)
                                  : const Color(0xFF192535),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.content),
                                const SizedBox(height: 6),
                                Text(
                                  item.createdAtLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatComposerController,
                    decoration: const InputDecoration(labelText: '输入消息'),
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
        ),
      ),
    );

    if (compact) {
      return Column(children: [listPane, const SizedBox(height: 16), chatPane]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 360, child: listPane),
        const SizedBox(width: 16),
        Expanded(child: chatPane),
      ],
    );
  }
}
