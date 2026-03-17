import 'package:flutter/material.dart';

import '../models/app_models.dart';
import 'content_sections.dart';
import 'settings_views.dart';
import 'social_views.dart';
import 'view_state_helpers.dart';
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
  required VoidCallback onOpenPublicSpace,
  required ValueChanged<String> onOpenPostDetail,
}) {
  return DashboardOverviewView(
    width: width,
    user: user,
    spaces: spaces,
    publicPosts: publicPosts,
    onOpenPublicSpace: onOpenPublicSpace,
    onOpenPostDetail: onOpenPostDetail,
  );
}

Widget buildPrivateView({
  required bool loading,
  required TextEditingController spaceNameController,
  required TextEditingController spaceDescriptionController,
  required TextEditingController privatePostTitleController,
  required TextEditingController privatePostContentController,
  required String privatePostStatus,
  required List<SpaceItem> spaces,
  required List<PostItem> privatePosts,
  required CurrentUser? user,
  required TextEditingController Function(String postId) commentControllerFor,
  required ValueChanged<String> onPrivateStatusChanged,
  required VoidCallback onCreatePrivateSpace,
  required VoidCallback onPublishPrivatePost,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<String> onOpenPostDetail,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpaceComposerCard(
        type: 'private',
        loading: loading,
        nameController: spaceNameController,
        descriptionController: spaceDescriptionController,
        onSubmit: onCreatePrivateSpace,
      ),
      const SizedBox(height: 16),
      PostComposerCard(
        loading: loading,
        title: '发布私人内容',
        subtitle: '私人内容仅自己可见，适合草稿、笔记和内部记录。',
        titleController: privatePostTitleController,
        contentController: privatePostContentController,
        status: privatePostStatus,
        onStatusChanged: onPrivateStatusChanged,
        onSubmit: onPublishPrivatePost,
      ),
      const SizedBox(height: 16),
      SpaceListSection(title: '私人空间列表', spaces: privateSpaces(spaces)),
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
      ),
    ],
  );
}

Widget buildPublicView({
  required bool loading,
  required TextEditingController spaceNameController,
  required TextEditingController spaceDescriptionController,
  required TextEditingController publicPostTitleController,
  required TextEditingController publicPostContentController,
  required String publicPostStatus,
  required List<SpaceItem> spaces,
  required List<PostItem> publicPosts,
  required CurrentUser? user,
  required TextEditingController Function(String postId) commentControllerFor,
  required ValueChanged<String> onPublicStatusChanged,
  required VoidCallback onCreatePublicSpace,
  required VoidCallback onPublishPublicPost,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<String> onOpenPostDetail,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpaceComposerCard(
        type: 'public',
        loading: loading,
        nameController: spaceNameController,
        descriptionController: spaceDescriptionController,
        onSubmit: onCreatePublicSpace,
      ),
      const SizedBox(height: 16),
      PostComposerCard(
        loading: loading,
        title: '发布公共内容',
        subtitle: '公开文章会出现在公共空间和作者主页。',
        titleController: publicPostTitleController,
        contentController: publicPostContentController,
        status: publicPostStatus,
        onStatusChanged: onPublicStatusChanged,
        onSubmit: onPublishPublicPost,
      ),
      const SizedBox(height: 16),
      SpaceListSection(title: '公共空间列表', spaces: publicSpaces(spaces)),
      const SizedBox(height: 16),
      PostStreamSection(
        posts: publicPosts,
        emptyText: '公共空间里还没有内容。',
        commentControllerFor: commentControllerFor,
        onLike: onToggleLike,
        onShare: onSharePost,
        onComment: onCommentPost,
        onOpenAuthor: onOpenProfile,
        onOpenDetail: onOpenPostDetail,
        canEditPost: (post) => user != null && post.userId == user.id,
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
  required bool loading,
  required TextEditingController Function(String postId) commentControllerFor,
  required ProfileTab profileTab,
  required ValueChanged<ProfileTab> onProfileTabChanged,
  required VoidCallback onSaveProfile,
  required ValueChanged<String> onAddFriend,
  required ValueChanged<String> onAcceptFriend,
  required ValueChanged<FriendItem> onStartChat,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<String> onOpenProfile,
  required ValueChanged<String> onOpenPostDetail,
  required String Function(String key) t,
}) {
  return ProfileView(
    user: user,
    profileUser: profileUser,
    profilePosts: profilePosts,
    subscription: subscription,
    connectedChains: connectedChains(externalAccounts),
    displayNameController: displayNameController,
    loading: loading,
    commentControllerFor: commentControllerFor,
    profileTab: profileTab,
    onProfileTabChanged: onProfileTabChanged,
    currentLevel: currentLevel,
    onActivateLevel: onActivateLevel,
    onActivatePlan: onActivatePlan,
    onSaveProfile: onSaveProfile,
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
    onOpenProfile: onOpenProfile,
    onOpenPostDetail: onOpenPostDetail,
    t: t,
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
  required TextEditingController chatComposerController,
  required bool loading,
  required ValueChanged<FriendItem> onStartChat,
  required VoidCallback onSendMessage,
}) {
  return ChatView(
    width: width,
    user: user,
    activeChat: activeChat,
    acceptedFriends: acceptedFriends(friends),
    conversations: conversations,
    messages: messages,
    chatComposerController: chatComposerController,
    loading: loading,
    findFriend: (id) => findFriendById(id, friends),
    onStartChat: onStartChat,
    onSendMessage: onSendMessage,
  );
}
