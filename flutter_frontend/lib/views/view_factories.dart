import 'package:flutter/material.dart';

import '../models/app_models.dart';
import 'content_sections.dart';
import 'settings_views.dart';
import 'chat_view.dart';
import 'social_views.dart' hide ChatView;
import 'view_state_helpers.dart';
import '../widgets/app_cards.dart';
import '../widgets/bilingual_action_button.dart';
import '../main.dart' show ProfileTab;

const blockchainChainsByProvider = {
  'evm': ['ethereum', 'base', 'bsc', 'polygon'],
  'solana': ['solana'],
  'tron': ['tron'],
};

String normalizeBlockchainChain(String provider, String chain) {
  final chains = blockchainChainsByProvider[provider];
  if (chains == null || chains.isEmpty) {
    return chain;
  }
  if (chains.contains(chain)) {
    return chain;
  }
  return chains.first;
}

Widget buildDashboardView({
  required double width,
  required CurrentUser user,
  required List<PostItem> publicPosts,
  required VoidCallback onOpenPublicSpace,
  required ValueChanged<String> onOpenPostDetail,
  required String languageCode,
}) {
  return DashboardOverviewView(
    width: width,
    user: user,
    publicPosts: publicPosts,
    onOpenPublicSpace: onOpenPublicSpace,
    onOpenPostDetail: onOpenPostDetail,
    languageCode: languageCode,
  );
}

Widget buildSpaceView({
  required BuildContext context,
  required bool loading,
  required List<SpaceItem> spaces,
  required SpaceItem? activeSpace,
  required List<PostItem> spacePosts,
  required CurrentUser? user,
  required TextEditingController Function(String postId) commentControllerFor,
  required VoidCallback onOpenSpaceComposer,
  required VoidCallback onOpenPostComposer,
  required VoidCallback onLeaveSpace,
  required ValueChanged<SpaceItem> onEnterSpace,
  required ValueChanged<SpaceItem> onEditSpace,
  required ValueChanged<SpaceItem> onDeleteSpace,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<PostItem> onDeletePost,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<String> onOpenPostDetail,
  required String languageCode,
}) {
  // Keep the page focused on creator-owned spaces and the active feed.
  // 页面聚焦于“自己创建的空间列表 + 当前空间内容流”。
  final ownedSpaces = user == null
      ? <SpaceItem>[]
      : spaces.where((space) => space.userId == user.id).toList();
  final selectedSpace = activeSpace;
  final managedSpace = selectedSpace;
  final canPublish = user != null &&
      selectedSpace != null &&
      selectedSpace.userId == user.id;
  final canManageSelectedSpace = managedSpace != null &&
      user != null &&
      managedSpace.userId == user.id;
  return DefaultTabController(
    length: 2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
              ],
            ),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
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
                          localizedText(languageCode, '空间首页', 'Space home', '空間首頁'),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 0.08,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedSpace?.spaceLabel ?? localizedText(languageCode, '尚未进入空间', 'No space entered', '尚未進入空間'),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          localizedText(
                            languageCode,
                            '先进入空间，再浏览内容、设置空间和发布文章。',
                            'Enter a space first, then browse content, manage settings, and publish posts.',
                            '先進入空間，再瀏覽內容、設定空間和發佈文章。',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManageSelectedSpace)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        // Keep a direct exit action in the space hero.
                        // 在空间头部保留直接返回操作。
                        BilingualActionButton(
                          variant: BilingualButtonVariant.text,
                          compact: true,
                          onPressed: onLeaveSpace,
                          primaryLabel: localizedText(languageCode, '返回首页', 'Back to home', '返回首頁'),
                          secondaryLabel: 'Back to home',
                        ),
                        BilingualActionButton(
                          variant: BilingualButtonVariant.tonal,
                          compact: true,
                          onPressed: () => onEditSpace(managedSpace),
                          primaryLabel: localizedText(languageCode, '设置空间资料', 'Space settings', '設定空間資料'),
                          secondaryLabel: 'Space settings',
                        ),
                        BilingualActionButton(
                          variant: BilingualButtonVariant.filled,
                          compact: true,
                          onPressed: () => onOpenPostComposer(),
                          primaryLabel: localizedText(languageCode, '发布文章', 'Publish post', '發布文章'),
                          secondaryLabel: 'Publish post',
                        ),
                        BilingualActionButton(
                          variant: BilingualButtonVariant.text,
                          compact: true,
                          onPressed: () => onDeleteSpace(managedSpace),
                          primaryLabel: localizedText(languageCode, '删除空间', 'Delete space', '刪除空間'),
                          secondaryLabel: 'Delete space',
                        ),
                      ],
                    ),
                  if (!canManageSelectedSpace)
                    BilingualActionButton(
                      variant: BilingualButtonVariant.text,
                      compact: true,
                      onPressed: onLeaveSpace,
                      primaryLabel: localizedText(languageCode, '返回首页', 'Back to home', '返回首頁'),
                      secondaryLabel: 'Back to home',
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
              _SpaceMetaChip(
                title: localizedText(languageCode, '当前空间', 'Current space', '目前空間'),
                value: selectedSpace?.name ?? localizedText(languageCode, '未选择', 'Not selected', '未選擇'),
              ),
                  _SpaceMetaChip(
                    title: localizedText(languageCode, '可见性', 'Visibility', '可見性'),
                    value: selectedSpace == null
                        ? localizedText(languageCode, '未选择', 'Not selected', '未選擇')
                        : spaceVisibilityLabel(selectedSpace.visibility, languageCode),
                  ),
                  _SpaceMetaChip(
                    title: localizedText(languageCode, '我的空间', 'My spaces', '我的空間'),
                    value: '${ownedSpaces.length}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1120;
            final feed = _SpaceFeedCard(
              languageCode: languageCode,
              selectedSpace: selectedSpace,
              spacePosts: spacePosts,
              canPublish: canPublish,
              user: user,
              onOpenPostComposer: onOpenPostComposer,
              commentControllerFor: commentControllerFor,
              onToggleLike: onToggleLike,
              onSharePost: onSharePost,
              onCommentPost: onCommentPost,
              onOpenProfile: onOpenProfile,
              onOpenPostDetail: onOpenPostDetail,
              onDeletePost: onDeletePost,
            );
            final workspace = _SpaceWorkspaceCard(
              languageCode: languageCode,
              loading: loading,
              ownedSpaces: ownedSpaces,
              selectedSpace: selectedSpace,
              user: user,
              onEnterSpace: onEnterSpace,
              onEditSpace: onEditSpace,
              onDeleteSpace: onDeleteSpace,
              onOpenSpaceComposer: onOpenSpaceComposer,
            );
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: feed),
                  const SizedBox(width: 16),
                  SizedBox(width: 380, child: workspace),
                ],
              );
            }
            return Column(
              children: [
                workspace,
                const SizedBox(height: 16),
                feed,
              ],
            );
          },
        ),
      ],
    ),
  );
}

Widget buildPrivateView({
  required bool loading,
  required SpaceItem? activeSpace,
  required List<SpaceItem> spaces,
  required List<PostItem> privatePosts,
  required CurrentUser? user,
  required TextEditingController Function(String postId) commentControllerFor,
  required VoidCallback onOpenSpaceComposer,
  required VoidCallback onOpenPostComposer,
  required ValueChanged<SpaceItem> onEnterSpace,
  required ValueChanged<SpaceItem> onEditSpace,
  required ValueChanged<SpaceItem> onDeleteSpace,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<PostItem> onDeletePost,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<String> onOpenPostDetail,
  required String languageCode,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpaceComposerCard(
        loading: loading,
        title: localizedText(languageCode, '创建私人空间', 'Create private space', '建立私人空間'),
        subtitle: localizedText(languageCode, '私人空间适合沉淀草稿和只对自己可见的内容。', 'Private spaces are good for drafts and content visible only to you.', '私人空間適合沉澱草稿和只對自己可見的內容。'),
        detailLines: [
          localizedText(languageCode, '创建后会自动生成二级域名，便于后续通过空间入口进入。', 'A subdomain is generated automatically so you can enter it later.', '建立後會自動生成二級網域，方便之後透過空間入口進入。'),
        ],
        // 按钮统一使用双语组件 / Use the shared bilingual action button.
        buttonPrimaryLabel: localizedText(languageCode, '打开创建弹窗', 'Open create dialog', '打開建立彈窗'),
        buttonSecondaryLabel: 'Open create dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenSpaceComposer,
      ),
      const SizedBox(height: 16),
      PostComposerCard(
        loading: loading,
        title: localizedText(languageCode, '发布私人内容', 'Publish private content', '發布私人內容'),
        subtitle: localizedText(languageCode, '私人内容仅自己可见，适合草稿、笔记和内部记录。', 'Private content is visible only to you and works well for drafts, notes, and internal records.', '私人內容僅自己可見，適合草稿、筆記和內部記錄。'),
        detailLines: [
          if (activeSpace != null)
            '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${activeSpace.name}',
          localizedText(languageCode, '发布后会记录所属空间，方便后续筛选和回溯。', 'The post will be bound to the selected space for easier filtering and tracing.', '發布後會記錄所屬空間，方便後續篩選和回溯。'),
        ],
        buttonPrimaryLabel: localizedText(languageCode, '打开发布弹窗', 'Open publish dialog', '打開發布彈窗'),
        buttonSecondaryLabel: 'Open publish dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenPostComposer,
      ),
      const SizedBox(height: 16),
      SpaceListSection(
        title: localizedText(languageCode, '私人空间列表', 'Private space list', '私人空間列表'),
        spaces: privateSpaces(spaces),
        activeSpaceId: activeSpace?.id,
        currentUserId: user?.id,
        onEnterSpace: onEnterSpace,
        onEditSpace: onEditSpace,
        onDeleteSpace: onDeleteSpace,
        languageCode: languageCode,
      ),
      const SizedBox(height: 16),
      PostStreamSection(
        posts: privatePosts,
        emptyText: localizedText(languageCode, '还没有私人内容。', 'No private content yet.', '還沒有私人內容。'),
        commentControllerFor: commentControllerFor,
        onLike: onToggleLike,
        onShare: onSharePost,
        onComment: onCommentPost,
        onOpenAuthor: onOpenProfile,
        onOpenDetail: onOpenPostDetail,
        canEditPost: (post) => user != null && post.userId == user.id,
        onDeletePost: onDeletePost,
        languageCode: languageCode,
      ),
    ],
  );
}

Widget buildPublicView({
  required bool loading,
  required SpaceItem? activeSpace,
  required List<SpaceItem> spaces,
  required List<PostItem> publicPosts,
  required CurrentUser? user,
  required TextEditingController Function(String postId) commentControllerFor,
  required VoidCallback onOpenSpaceComposer,
  required VoidCallback onOpenPostComposer,
  required ValueChanged<SpaceItem> onEnterSpace,
  required ValueChanged<SpaceItem> onEditSpace,
  required ValueChanged<SpaceItem> onDeleteSpace,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<PostItem> onDeletePost,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<String> onOpenPostDetail,
  required String languageCode,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpaceComposerCard(
        loading: loading,
        title: localizedText(languageCode, '创建空间', 'Create space', '建立空間'),
        subtitle: localizedText(languageCode, '空间适合对外展示项目，也可以设置好友可见或仅自己可见。', 'Spaces are good for public projects and can also be limited to friends or just you.', '空間適合對外展示專案，也可以設定好友可見或僅自己可見。'),
        detailLines: [
          localizedText(languageCode, '创建后会生成可识别的二级域名，便于从外部直接进入。', 'A recognizable subdomain will be generated so others can enter directly.', '建立後會生成可辨識的二級網域，方便從外部直接進入。'),
        ],
        buttonPrimaryLabel: localizedText(languageCode, '打开创建弹窗', 'Open create dialog', '打開建立彈窗'),
        buttonSecondaryLabel: 'Open create dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenSpaceComposer,
      ),
      const SizedBox(height: 16),
      PostComposerCard(
        loading: loading,
        title: localizedText(languageCode, '发布空间内容', 'Publish space content', '發布空間內容'),
        subtitle: localizedText(languageCode, '空间文章会出现在空间和作者主页。', 'Space posts appear in the space feed and on the author profile.', '空間文章會出現在空間和作者主頁。'),
        detailLines: [
          if (activeSpace != null)
            '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${activeSpace.name}',
          localizedText(languageCode, '发布时会记录所属空间，便于后续查看和分享。', 'The post will be bound to the selected space for later review and sharing.', '發布時會記錄所屬空間，便於後續查看和分享。'),
        ],
        buttonPrimaryLabel: localizedText(languageCode, '打开发布弹窗', 'Open publish dialog', '打開發布彈窗'),
        buttonSecondaryLabel: 'Open publish dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenPostComposer,
      ),
      const SizedBox(height: 16),
      SpaceListSection(
        title: localizedText(languageCode, '空间列表', 'Space list', '空間列表'),
        spaces: publicSpaces(spaces),
        activeSpaceId: activeSpace?.id,
        currentUserId: user?.id,
        onEnterSpace: onEnterSpace,
        onEditSpace: onEditSpace,
        onDeleteSpace: onDeleteSpace,
        languageCode: languageCode,
      ),
      const SizedBox(height: 16),
      PostStreamSection(
        posts: publicPosts,
        emptyText: localizedText(languageCode, '空间里还没有内容。', 'There is no content in this space yet.', '空間裡還沒有內容。'),
        commentControllerFor: commentControllerFor,
        onLike: onToggleLike,
        onShare: onSharePost,
        onComment: onCommentPost,
        onOpenAuthor: onOpenProfile,
        onOpenDetail: onOpenPostDetail,
        canEditPost: (post) => user != null && post.userId == user.id,
        onDeletePost: onDeletePost,
        languageCode: languageCode,
      ),
    ],
  );
}

Widget buildProfileView({
  required CurrentUser? user,
  required UserProfileItem? profileUser,
  required List<PostItem> profilePosts,
  required SubscriptionItem? subscription,
  required List<ExternalAccountItem> externalAccounts,
  required List<FriendItem> friends,
  required String currentLevel,
  required ValueChanged<String> onActivateLevel,
  required ValueChanged<String> onActivatePlan,
  required TextEditingController displayNameController,
  required TextEditingController usernameController,
  required TextEditingController domainController,
  required TextEditingController signatureController,
  required String phoneVisibility,
  required String emailVisibility,
  required String ageVisibility,
  required String genderVisibility,
  required bool loading,
  required TextEditingController Function(String postId) commentControllerFor,
  required ProfileTab profileTab,
  required ValueChanged<ProfileTab> onProfileTabChanged,
  required VoidCallback onSaveProfile,
  required ValueChanged<String> onPhoneVisibilityChanged,
  required ValueChanged<String> onEmailVisibilityChanged,
  required ValueChanged<String> onAgeVisibilityChanged,
  required ValueChanged<String> onGenderVisibilityChanged,
  required ValueChanged<String> onAddFriend,
  required ValueChanged<String> onAcceptFriend,
  required ValueChanged<FriendItem> onStartChat,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<PostItem> onDeletePost,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<String> onOpenPostDetail,
  required ValueChanged<SpaceItem> onEnterSpace,
  required String languageCode,
  required String Function(String key) t,
  required String Function(String key) peerT,
}) {
  return ProfileView(
    user: user,
    profileUser: profileUser,
    profilePosts: profilePosts,
    subscription: subscription,
    connectedChains: connectedChains(externalAccounts),
    displayNameController: displayNameController,
    usernameController: usernameController,
    domainController: domainController,
    signatureController: signatureController,
    phoneVisibility: phoneVisibility,
    emailVisibility: emailVisibility,
    ageVisibility: ageVisibility,
    genderVisibility: genderVisibility,
    loading: loading,
    commentControllerFor: commentControllerFor,
    profileTab: profileTab,
    onProfileTabChanged: onProfileTabChanged,
    currentLevel: currentLevel,
    onActivateLevel: onActivateLevel,
    onActivatePlan: onActivatePlan,
    onSaveProfile: onSaveProfile,
    onPhoneVisibilityChanged: onPhoneVisibilityChanged,
    onEmailVisibilityChanged: onEmailVisibilityChanged,
    onAgeVisibilityChanged: onAgeVisibilityChanged,
    onGenderVisibilityChanged: onGenderVisibilityChanged,
    onAddFriend: onAddFriend,
    onAcceptFriend: onAcceptFriend,
    onStartChat: () {
      final profile = profileUser;
      if (profile == null) {
        return;
      }
      final friend = findFriendById(profile.id, friends);
      if (friend != null) {
        onStartChat(friend);
      }
    },
    onToggleLike: onToggleLike,
    onSharePost: onSharePost,
    onCommentPost: onCommentPost,
    onDeletePost: onDeletePost,
    onOpenProfile: onOpenProfile,
    onOpenPostDetail: onOpenPostDetail,
    onEnterSpace: onEnterSpace,
    languageCode: languageCode,
    t: t,
    peerT: peerT,
  );
}

Widget buildPostDetailView({
  required CurrentUser? user,
  required PostItem? currentPost,
  required bool loading,
  required TextEditingController Function(String postId) commentControllerFor,
  required TextEditingController editTitleController,
  required TextEditingController editContentController,
  required String editVisibility,
  required String editStatus,
  required ValueChanged<String> onEditVisibilityChanged,
  required ValueChanged<String> onEditStatusChanged,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<String> onOpenProfile,
  required VoidCallback onSaveEdits,
  required VoidCallback? onDeletePost,
  required String languageCode,
}) {
  final post = currentPost;
  return PostDetailView(
    user: user,
    currentPost: post,
    loading: loading,
    commentController: commentControllerFor(post?.id ?? '__missing__'),
    editTitleController: editTitleController,
    editContentController: editContentController,
    editVisibility: editVisibility,
    editStatus: editStatus,
    onEditVisibilityChanged: onEditVisibilityChanged,
    onEditStatusChanged: onEditStatusChanged,
    onLike: () {
      final current = currentPost;
      if (current != null) {
        onToggleLike(current);
      }
    },
    onShare: () {
      final current = currentPost;
      if (current != null) {
        onSharePost(current);
      }
    },
    onComment: () {
      final current = currentPost;
      if (current != null) {
        onCommentPost(current);
      }
    },
    onOpenAuthor: () {
      final current = currentPost;
      if (current != null) {
        onOpenProfile(current.userId);
      }
    },
    onSaveEdits: onSaveEdits,
    onDeletePost: onDeletePost,
    languageCode: languageCode,
  );
}

Widget buildLevelsView({
  required String currentLevel,
  required ValueChanged<String> onActivateLevel,
}) {
  return LevelsView(
    currentLevel: currentLevel,
    onActivateLevel: onActivateLevel,
  );
}

Widget buildSubscriptionView({
  required SubscriptionItem? subscription,
  required bool loading,
  required ValueChanged<String> onActivatePlan,
}) {
  return SubscriptionView(
    subscription: subscription,
    loading: loading,
    onActivatePlan: onActivatePlan,
  );
}

Widget buildBlockchainView({
  required bool loading,
  required String externalProvider,
  required String externalChain,
  required List<ExternalAccountItem> externalAccounts,
  required TextEditingController addressController,
  required TextEditingController signatureController,
  required ValueChanged<String> onProviderChanged,
  required ValueChanged<String> onChainChanged,
  required VoidCallback onBind,
  required ValueChanged<String> onRemove,
}) {
  return BlockchainView(
    loading: loading,
    externalProvider: externalProvider,
    externalChain: externalChain,
    externalAccounts: externalAccounts,
    addressController: addressController,
    signatureController: signatureController,
    onProviderChanged: onProviderChanged,
    onChainChanged: onChainChanged,
    onBind: onBind,
    onRemove: onRemove,
  );
}

Widget buildFriendsView({
  required bool loading,
  required TextEditingController searchController,
  required List<UserSearchItem> searchResults,
  required List<FriendItem> friends,
  required VoidCallback onSearch,
  required ValueChanged<String> onAddFriend,
  required ValueChanged<String> onAcceptFriend,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<FriendItem> onStartChat,
  required String languageCode,
}) {
  return FriendsView(
    loading: loading,
    searchController: searchController,
    searchResults: searchResults,
    friends: friends,
    onSearch: onSearch,
    onAddFriend: onAddFriend,
    onAcceptFriend: onAcceptFriend,
    onOpenProfile: onOpenProfile,
    onStartChat: onStartChat,
    languageCode: languageCode,
  );
}

Widget buildChatView({
  required double width,
  required CurrentUser user,
  required FriendItem? activeChat,
  required List<FriendItem> friends,
  required List<ConversationItem> conversations,
  required List<ChatMessage> messages,
  required int pendingFriendCount,
  required ChatAttachmentDraft? chatAttachment,
  required TextEditingController chatComposerController,
  required bool loading,
  required ValueChanged<FriendItem> onStartChat,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<SpaceItem> onEnterSpace,
  required Future<List<SpaceItem>> Function(String userId) loadFriendSpaces,
  required VoidCallback onSendMessage,
  required Future<void> Function(String messageType) onPickAttachment,
  required VoidCallback onClearAttachment,
  required String languageCode,
}) {
  return ChatView(
    width: width,
    user: user,
    activeChat: activeChat,
    acceptedFriends: acceptedFriends(friends),
    conversations: conversations,
    messages: messages,
    pendingFriendCount: pendingFriendCount,
    chatAttachment: chatAttachment,
    chatComposerController: chatComposerController,
    loading: loading,
    findFriend: (id) => findFriendById(id, friends),
    onStartChat: onStartChat,
    onOpenProfile: onOpenProfile,
    onEnterSpace: onEnterSpace,
    loadFriendSpaces: loadFriendSpaces,
    onSendMessage: onSendMessage,
    onPickAttachment: onPickAttachment,
    onClearAttachment: onClearAttachment,
    languageCode: languageCode,
  );
}

class _SpaceMetaChip extends StatelessWidget {
  const _SpaceMetaChip({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SpaceFeedCard extends StatelessWidget {
  const _SpaceFeedCard({
    required this.languageCode,
    required this.selectedSpace,
    required this.spacePosts,
    required this.canPublish,
    required this.user,
    required this.onOpenPostComposer,
    required this.commentControllerFor,
    required this.onToggleLike,
    required this.onSharePost,
    required this.onCommentPost,
    required this.onOpenProfile,
    required this.onOpenPostDetail,
    required this.onDeletePost,
  });

  final String languageCode;
  final SpaceItem? selectedSpace;
  final List<PostItem> spacePosts;
  final bool canPublish;
  final CurrentUser? user;
  final VoidCallback onOpenPostComposer;
  final TextEditingController Function(String postId) commentControllerFor;
  final ValueChanged<PostItem> onToggleLike;
  final ValueChanged<PostItem> onSharePost;
  final ValueChanged<PostItem> onCommentPost;
  final ValueChanged<String> onOpenProfile;
  final ValueChanged<String> onOpenPostDetail;
  final ValueChanged<PostItem> onDeletePost;

  @override
  Widget build(BuildContext context) {
    final currentUserId = user?.id;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                        localizedText(languageCode, '内容流', 'Feed', '內容流'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 0.08,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selectedSpace == null
                            ? localizedText(languageCode, '请先进入空间。', 'Enter a space first.', '請先進入空間。')
                            : localizedText(languageCode, '进入空间后即可浏览内容、点赞和评论。', 'After entering, you can browse content, like, and comment.', '進入空間後即可瀏覽內容、按讚和評論。'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (canPublish)
                  BilingualActionButton(
                    variant: BilingualButtonVariant.filled,
                    compact: true,
                    onPressed: onOpenPostComposer,
                    primaryLabel: localizedText(languageCode, '发布文章', 'Publish post', '發布文章'),
                    secondaryLabel: 'Publish post',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (selectedSpace != null)
              PostStreamSection(
                posts: spacePosts,
                emptyText: canPublish
                    ? localizedText(languageCode, '这个空间里还没有内容，点击发布开始创作。', 'There is no content in this space yet. Publish the first post.', '這個空間裡還沒有內容，點擊發布開始創作。')
                    : localizedText(languageCode, '这个空间里还没有内容。', 'There is no content in this space yet.', '這個空間裡還沒有內容。'),
                commentControllerFor: commentControllerFor,
                onLike: onToggleLike,
                onShare: onSharePost,
                onComment: onCommentPost,
                onOpenAuthor: onOpenProfile,
                onOpenDetail: onOpenPostDetail,
                canEditPost: (post) =>
                    currentUserId != null &&
                    (post.userId == currentUserId || post.spaceUserId == currentUserId),
                onDeletePost: onDeletePost,
                languageCode: languageCode,
              )
            else
              InfoCard(
                title: localizedText(languageCode, '内容流', 'Feed', '內容流'),
                lines: [
                  localizedText(languageCode, '先从上面的空间入口选择一个空间。', 'Select a space from the entry panel above first.', '先從上面的空間入口選擇一個空間。'),
                  localizedText(languageCode, '进入后即可浏览内容、点赞和评论。', 'After entering, you can browse content, like, and comment.', '進入後即可瀏覽內容、按讚和評論。'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SpaceWorkspaceCard extends StatelessWidget {
  const _SpaceWorkspaceCard({
    required this.languageCode,
    required this.loading,
    required this.ownedSpaces,
    required this.selectedSpace,
    required this.user,
    required this.onEnterSpace,
    required this.onEditSpace,
    required this.onDeleteSpace,
    required this.onOpenSpaceComposer,
  });

  final String languageCode;
  final bool loading;
  final List<SpaceItem> ownedSpaces;
  final SpaceItem? selectedSpace;
  final CurrentUser? user;
  final ValueChanged<SpaceItem> onEnterSpace;
  final ValueChanged<SpaceItem> onEditSpace;
  final ValueChanged<SpaceItem> onDeleteSpace;
  final VoidCallback onOpenSpaceComposer;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizedText(languageCode, '空间工作台', 'Space workspace', '空間工作台'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              localizedText(languageCode, '“我的空间”与“创建空间”放在同一个工作台，进入空间后再展示内容。', '"My spaces" and "Create space" share one workspace, and content appears after entering a space.', '「我的空間」與「建立空間」放在同一個工作台，進入空間後再展示內容。'),
            ),
            const SizedBox(height: 14),
            TabBar(
              tabs: [
                Tab(text: localizedText(languageCode, '我的空间', 'My spaces', '我的空間')),
                Tab(text: localizedText(languageCode, '创建空间', 'Create space', '建立空間')),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 500,
              child: TabBarView(
                children: [
                  ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (ownedSpaces.isEmpty)
                        InfoCard(
                          title: localizedText(languageCode, '我的空间', 'My spaces', '我的空間'),
                          lines: [
                            localizedText(languageCode, '当前还没有你创建的空间。', 'You have not created any spaces yet.', '目前還沒有你建立的空間。'),
                            localizedText(languageCode, '可以先创建一个空间，再进入浏览内容。', 'Create one first, then enter it to browse content.', '可以先建立一個空間，再進入瀏覽內容。'),
                          ],
                        )
                      else
                        SpaceListSection(
                          title: localizedText(languageCode, '我的空间', 'My spaces', '我的空間'),
                          spaces: ownedSpaces,
                          activeSpaceId: selectedSpace?.id,
                          currentUserId: user?.id,
                          onEnterSpace: onEnterSpace,
                          onEditSpace: onEditSpace,
                          onDeleteSpace: onDeleteSpace,
                          languageCode: languageCode,
                        ),
                    ],
                  ),
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SpaceComposerCard(
                          loading: loading,
                          title: localizedText(languageCode, '创建空间', 'Create space', '建立空間'),
                          subtitle: localizedText(languageCode, '名称、二级域名、可见范围和外观会在这里逐步完善。', 'Name, subdomain, visibility, and appearance will be refined here.', '名稱、二級網域、可見範圍和外觀會在這裡逐步完善。'),
                          detailLines: [
                            localizedText(languageCode, '空间主题和背景位已预留在布局中。', 'Theme and background slots are reserved in the layout.', '空間主題和背景位已預留在佈局中。'),
                            localizedText(languageCode, '创建完成后会自动进入新空间。', 'After creation, the new space is entered automatically.', '建立完成後會自動進入新空間。'),
                          ],
                          buttonPrimaryLabel: localizedText(languageCode, '打开创建弹窗', 'Open create dialog', '打開建立彈窗'),
                          buttonSecondaryLabel: 'Open create dialog',
                          buttonVariant: BilingualButtonVariant.filled,
                          onSubmit: onOpenSpaceComposer,
                        ),
                        const SizedBox(height: 12),
                        InfoCard(
                          title: localizedText(languageCode, '空间设置', 'Space settings', '空間設定'),
                          lines: [
                            localizedText(languageCode, '后续这里会接入空间级主题和背景图配置。', 'Space-level theme and background configuration will be added here.', '後續這裡會接入空間級主題和背景圖設定。'),
                            localizedText(languageCode, '当前版本先保留入口和布局。', 'For now, the entry points and layout are reserved.', '目前版本先保留入口與佈局。'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
