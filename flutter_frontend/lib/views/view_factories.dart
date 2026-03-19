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
  required String languageCode,
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
    languageCode: languageCode,
  );
}

Widget buildSpaceView({
  required bool loading,
  required List<SpaceItem> spaces,
  required SpaceItem? activeSpace,
  required List<PostItem> spacePosts,
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
  // Keep the page focused on creator-owned spaces and the active feed.
  // 页面聚焦于“自己创建的空间列表 + 当前空间内容流”。
  final ownedSpaces = user == null
      ? <SpaceItem>[]
      : spaces.where((space) => space.userId == user.id).toList();
  final selectedSpace = activeSpace;
  final canPublish = user != null &&
      selectedSpace != null &&
      selectedSpace.userId == user.id;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InfoCard(
        title: localizedText(languageCode, '空间', 'Space', '空間'),
        lines: [
          localizedText(languageCode, '只显示自己创建的空间。', 'Only spaces you created are listed here.', '只顯示自己建立的空間。'),
          localizedText(languageCode, '进入空间后即可浏览内容，并记录所属空间。', 'Enter a space to browse its feed and keep posts bound to it.', '進入空間後即可瀏覽內容，並記錄所屬空間。'),
          if (selectedSpace == null)
            localizedText(languageCode, '先从下方空间列表选择一个空间。', 'Pick a space from the list below first.', '先從下方空間列表選擇一個空間。'),
          if (selectedSpace != null)
            '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${selectedSpace.spaceLabel}',
          if (selectedSpace != null)
            '${localizedText(languageCode, '可见性', 'Visibility', '可見性')}: ${spaceVisibilityLabel(selectedSpace.visibility, languageCode)}',
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 360,
            child: SpaceComposerCard(
              loading: loading,
              title: localizedText(languageCode, '创建空间', 'Create space', '建立空間'),
              subtitle: localizedText(languageCode, '新空间会自动生成二级域名，名称和域名分开维护。', 'A new space gets its own subdomain; name and subdomain are managed separately.', '新空間會自動生成二級網域，名稱和網域分開維護。'),
              detailLines: [
                localizedText(languageCode, '空间列表仅保留自己创建的空间。', 'Only spaces you created stay in the list.', '空間列表僅保留自己建立的空間。'),
                localizedText(languageCode, '可见范围和空间名称可以独立调整。', 'Visibility and space name can be adjusted independently.', '可見範圍和空間名稱可以獨立調整。'),
              ],
              buttonPrimaryLabel: localizedText(languageCode, '打开创建弹窗', 'Open create dialog', '打開建立彈窗'),
              buttonSecondaryLabel: 'Open create dialog',
              buttonVariant: BilingualButtonVariant.filled,
              onSubmit: onOpenSpaceComposer,
            ),
          ),
          SizedBox(
            width: 360,
            child: canPublish
                ? PostComposerCard(
                    loading: loading,
                    title: localizedText(languageCode, '发布内容', 'Publish content', '發布內容'),
                    subtitle: localizedText(languageCode, '支持图文和小视频，内容会记录在当前空间。', 'Images and short videos are supported, and posts are recorded in the current space.', '支援圖文和小影片，內容會記錄在目前空間。'),
                    detailLines: [
                      '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${selectedSpace.name} · @${selectedSpace.subdomain}',
                      localizedText(languageCode, '创建者进入空间后可以直接发帖，其他人可点赞和评论。', 'Creators can publish immediately after entering the space, while others can like and comment.', '建立者進入空間後可以直接發帖，其他人可按讚和評論。'),
                    ],
                    buttonPrimaryLabel: localizedText(languageCode, '打开发布弹窗', 'Open publish dialog', '打開發布彈窗'),
                    buttonSecondaryLabel: 'Open publish dialog',
                    buttonVariant: BilingualButtonVariant.filled,
                    onSubmit: onOpenPostComposer,
                  )
                : SizedBox(
                    width: 360,
                    child: InfoCard(
                      title: localizedText(languageCode, '发布权限', 'Publish access', '發布權限'),
                      lines: [
                        if (selectedSpace == null)
                          localizedText(languageCode, '先选择一个空间，再开始浏览或发布内容。', 'Select a space first, then browse or publish content.', '先選擇一個空間，再開始瀏覽或發布內容。')
                        else
                          localizedText(languageCode, '只有空间创建者可以发帖，其他人可点赞和评论。', 'Only the creator can publish; others can like and comment.', '只有空間建立者可以發帖，其他人可按讚和評論。'),
                        localizedText(languageCode, '内容会按空间可见性展示给其他人。', 'Content is shown to others according to space visibility.', '內容會依空間可見性展示給其他人。'),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      const SizedBox(height: 16),
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
      const SizedBox(height: 16),
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
              user != null &&
              (post.userId == user.id || post.spaceUserId == user.id),
          onDeletePost: onDeletePost,
          languageCode: languageCode,
        )
      else
        InfoCard(
          title: localizedText(languageCode, '内容流', 'Feed', '內容流'),
          lines: [
            localizedText(languageCode, '先从上面的空间列表选择一个空间。', 'Select a space from the list above first.', '先從上面的空間列表選擇一個空間。'),
            localizedText(languageCode, '进入后即可浏览内容、点赞和评论。', 'After entering, you can browse content, like, and comment.', '進入後即可瀏覽內容、按讚和評論。'),
          ],
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
            '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${activeSpace.name} · @${activeSpace.subdomain}',
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
            '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${activeSpace.name} · @${activeSpace.subdomain}',
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
  required List<SpaceItem> profileSpaces,
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
    profileSpaces: profileSpaces,
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
    onSendMessage: onSendMessage,
    onPickAttachment: onPickAttachment,
    onClearAttachment: onClearAttachment,
    languageCode: languageCode,
  );
}
