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
  required List<SpaceItem> spaces,
  required List<PostItem> publicPosts,
  required SpaceItem? activePrivateSpace,
  required SpaceItem? activePublicSpace,
  required VoidCallback onOpenPublicSpace,
  required ValueChanged<String> onOpenPostDetail,
}) {
  return DashboardOverviewView(
    width: width,
    user: user,
    spaces: spaces,
    publicPosts: publicPosts,
    activePrivateSpace: activePrivateSpace,
    activePublicSpace: activePublicSpace,
    onOpenPublicSpace: onOpenPublicSpace,
    onOpenPostDetail: onOpenPostDetail,
  );
}

Widget buildSpaceView({
  required bool loading,
  required List<SpaceItem> spaces,
  required SpaceItem? activeSpace,
  required List<PostItem> privatePosts,
  required List<PostItem> publicPosts,
  required CurrentUser? user,
  required TextEditingController Function(String postId) commentControllerFor,
  required VoidCallback onOpenPrivateSpaceComposer,
  required VoidCallback onOpenPublicSpaceComposer,
  required VoidCallback onOpenPrivatePostComposer,
  required VoidCallback onOpenPublicPostComposer,
  required ValueChanged<SpaceItem> onEnterSpace,
  required ValueChanged<SpaceItem> onEditSpace,
  required ValueChanged<SpaceItem> onDeleteSpace,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<PostItem> onDeletePost,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<String> onOpenPostDetail,
}) {
  // Combine the visible space entry points into one page.
  // 将可见空间入口合并到同一页面。
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InfoCard(
        title: '空间总览',
        lines: const [
          '在同一页面管理可见空间与内容发布。',
          '域名身份和空间二级域名都可以直接作为入口。',
        ],
      ),
      const SizedBox(height: 16),
      buildPublicView(
        loading: loading,
        // Keep the visible space card synced with the currently selected space.
        // 让可见空间卡片始终跟随当前选中的空间。
        activeSpace: activeSpace ?? firstSpaceOfType(spaces, 'public'),
        spaces: spaces,
        publicPosts: publicPosts,
        user: user,
        commentControllerFor: commentControllerFor,
        onOpenSpaceComposer: onOpenPublicSpaceComposer,
        onOpenPostComposer: onOpenPublicPostComposer,
        onEnterSpace: onEnterSpace,
        onEditSpace: onEditSpace,
        onDeleteSpace: onDeleteSpace,
        onToggleLike: onToggleLike,
        onSharePost: onSharePost,
        onCommentPost: onCommentPost,
        onDeletePost: onDeletePost,
        onOpenProfile: onOpenProfile,
        onOpenPostDetail: onOpenPostDetail,
      ),
    ],
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
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpaceComposerCard(
        loading: loading,
        title: '创建私人空间',
        subtitle: '私人空间适合沉淀草稿和只对自己可见的内容。',
        detailLines: const ['创建后会自动生成二级域名，便于后续通过空间入口进入。'],
        // 按钮统一使用双语组件 / Use the shared bilingual action button.
        buttonPrimaryLabel: '打开创建弹窗',
        buttonSecondaryLabel: 'Open create dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenSpaceComposer,
      ),
      const SizedBox(height: 16),
      PostComposerCard(
        loading: loading,
        title: '发布私人内容',
        subtitle: '私人内容仅自己可见，适合草稿、笔记和内部记录。',
        detailLines: [
          if (activeSpace != null)
            '当前空间：${activeSpace.name} · @${activeSpace.subdomain}',
          '发布后会记录所属空间，方便后续筛选和回溯。',
        ],
        buttonPrimaryLabel: '打开发布弹窗',
        buttonSecondaryLabel: 'Open publish dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenPostComposer,
      ),
      const SizedBox(height: 16),
      SpaceListSection(
        title: '私人空间列表',
        spaces: privateSpaces(spaces),
        activeSpaceId: activeSpace?.id,
        currentUserId: user?.id,
        onEnterSpace: onEnterSpace,
        onEditSpace: onEditSpace,
        onDeleteSpace: onDeleteSpace,
      ),
      const SizedBox(height: 16),
      PostStreamSection(
        posts: privatePosts,
        emptyText: '还没有私人内容。',
        commentControllerFor: commentControllerFor,
        onLike: onToggleLike,
        onShare: onSharePost,
        onComment: onCommentPost,
        onOpenAuthor: onOpenProfile,
        onOpenDetail: onOpenPostDetail,
        canEditPost: (post) => user != null && post.userId == user.id,
        onDeletePost: onDeletePost,
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
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpaceComposerCard(
        loading: loading,
        title: '创建空间',
        subtitle: '空间适合对外展示项目，也可以设置好友可见或仅自己可见。',
        detailLines: const ['创建后会生成可识别的二级域名，便于从外部直接进入。'],
        buttonPrimaryLabel: '打开创建弹窗',
        buttonSecondaryLabel: 'Open create dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenSpaceComposer,
      ),
      const SizedBox(height: 16),
      PostComposerCard(
        loading: loading,
        title: '发布空间内容',
        subtitle: '空间文章会出现在空间和作者主页。',
        detailLines: [
          if (activeSpace != null)
            '当前空间：${activeSpace.name} · @${activeSpace.subdomain}',
          '发布时会记录所属空间，便于后续查看和分享。',
        ],
        buttonPrimaryLabel: '打开发布弹窗',
        buttonSecondaryLabel: 'Open publish dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenPostComposer,
      ),
      const SizedBox(height: 16),
      SpaceListSection(
        title: '空间列表',
        spaces: publicSpaces(spaces),
        activeSpaceId: activeSpace?.id,
        currentUserId: user?.id,
        onEnterSpace: onEnterSpace,
        onEditSpace: onEditSpace,
        onDeleteSpace: onDeleteSpace,
      ),
      const SizedBox(height: 16),
      PostStreamSection(
        posts: publicPosts,
        emptyText: '空间里还没有内容。',
        commentControllerFor: commentControllerFor,
        onLike: onToggleLike,
        onShare: onSharePost,
        onComment: onCommentPost,
        onOpenAuthor: onOpenProfile,
        onOpenDetail: onOpenPostDetail,
        canEditPost: (post) => user != null && post.userId == user.id,
        onDeletePost: onDeletePost,
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
  required VoidCallback onSendMessage,
  required Future<void> Function(String messageType) onPickAttachment,
  required VoidCallback onClearAttachment,
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
    onSendMessage: onSendMessage,
    onPickAttachment: onPickAttachment,
    onClearAttachment: onClearAttachment,
  );
}
