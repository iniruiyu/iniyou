import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/app_models.dart';
import 'content_sections.dart';
import 'learning_view.dart';
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

Widget buildServicesView({
  required bool spaceOnline,
  required bool messageOnline,
  required bool adminOnline,
  required bool learningOnline,
  required bool isAdmin,
  required VoidCallback onOpenAdminPanel,
  required VoidCallback onOpenProfile,
  required VoidCallback onOpenSpace,
  required VoidCallback onOpenChat,
  required VoidCallback onOpenLearning,
  required VoidCallback onOpenLearningAdmin,
  required VoidCallback onRefresh,
  required String languageCode,
}) {
  return ServicesView(
    spaceOnline: spaceOnline,
    messageOnline: messageOnline,
    adminOnline: adminOnline,
    learningOnline: learningOnline,
    isAdmin: isAdmin,
    onOpenAdminPanel: onOpenAdminPanel,
    onOpenProfile: onOpenProfile,
    onOpenSpace: onOpenSpace,
    onOpenChat: onOpenChat,
    onOpenLearning: onOpenLearning,
    onOpenLearningAdmin: onOpenLearningAdmin,
    onRefresh: onRefresh,
    languageCode: languageCode,
  );
}

Widget buildAdminPanelView({
  required AdminOverview? overview,
  required String? overviewError,
  required bool spaceOnline,
  required bool messageOnline,
  required bool adminOnline,
  required bool learningOnline,
  required VoidCallback onOpenAccountAdmin,
  required VoidCallback onOpenSpaceAdmin,
  required VoidCallback onOpenMessageAdmin,
  required VoidCallback onOpenServices,
  required VoidCallback onOpenProfile,
  required VoidCallback onOpenSpace,
  required VoidCallback onOpenChat,
  required VoidCallback onOpenLearning,
  required VoidCallback onOpenLearningAdmin,
  required VoidCallback onRefresh,
  required String languageCode,
}) {
  return SiteAdminPanelView(
    overview: overview,
    overviewError: overviewError,
    spaceOnline: spaceOnline,
    messageOnline: messageOnline,
    adminOnline: adminOnline,
    learningOnline: learningOnline,
    onOpenAccountAdmin: onOpenAccountAdmin,
    onOpenSpaceAdmin: onOpenSpaceAdmin,
    onOpenMessageAdmin: onOpenMessageAdmin,
    onOpenServices: onOpenServices,
    onOpenProfile: onOpenProfile,
    onOpenSpace: onOpenSpace,
    onOpenChat: onOpenChat,
    onOpenLearning: onOpenLearning,
    onOpenLearningAdmin: onOpenLearningAdmin,
    onRefresh: onRefresh,
    languageCode: languageCode,
  );
}

Widget buildServiceAdminConsoleView({
  required AdminOverview? overview,
  AdminSpaceOverview? spaceOverview,
  String? spaceOverviewError,
  AdminMessageOverview? messageOverview,
  String? messageOverviewError,
  required String serviceKey,
  required String title,
  required String subtitle,
  required List<String> modules,
  required VoidCallback onBackToAdmin,
  required VoidCallback onOpenService,
  required VoidCallback onRefresh,
  required String languageCode,
}) {
  return ServiceAdminConsoleView(
    overview: overview,
    spaceOverview: spaceOverview,
    spaceOverviewError: spaceOverviewError,
    messageOverview: messageOverview,
    messageOverviewError: messageOverviewError,
    serviceKey: serviceKey,
    title: title,
    subtitle: subtitle,
    modules: modules,
    onBackToAdmin: onBackToAdmin,
    onOpenService: onOpenService,
    onRefresh: onRefresh,
    languageCode: languageCode,
  );
}

Widget buildLearningCourseView({
  required String languageCode,
  required String activeCourseId,
  required bool isAdmin,
  bool adminWorkspaceOnly = false,
  required ApiClient apiClient,
  required ValueChanged<String> onSelectCourse,
  required VoidCallback onBackToServices,
}) {
  return buildLearningView(
    languageCode: languageCode,
    activeCourseId: activeCourseId,
    isAdmin: isAdmin,
    adminWorkspaceOnly: adminWorkspaceOnly,
    apiClient: apiClient,
    onSelectCourse: onSelectCourse,
    onBackToServices: onBackToServices,
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
  required ValueChanged<PostItem> onEditPost,
  required String languageCode,
}) {
  // Keep the page focused on creator-owned spaces and the active posts area.
  // 页面聚焦于“自己创建的空间列表 + 当前空间帖子区”。
  final ownedSpaces = user == null
      ? <SpaceItem>[]
      : uniqueSpacesById(
          spaces.where((space) => space.userId == user.id).toList(),
        );
  final selectedSpace = activeSpace;
  final managedSpace = selectedSpace;
  final canPublish =
      user != null && selectedSpace != null && selectedSpace.userId == user.id;
  final canManageSelectedSpace =
      managedSpace != null && user != null && managedSpace.userId == user.id;

  void openSpaceWorkspaceMenu() {
    // Open the workspace as a modal popover when a space is already entered.
    // 进入具体空间后，以模态弹层方式打开空间工作台。
    if (selectedSpace == null) {
      return;
    }
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        barrierLabel: localizedText(
          languageCode,
          '关闭空间工作台',
          'Close workspace',
          '關閉空間工作台',
        ),
        builder: (dialogContext) {
          void closeDialog() {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }

          return DefaultTabController(
            length: 2,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      maxHeight: MediaQuery.sizeOf(dialogContext).height - 32,
                    ),
                    child: SingleChildScrollView(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: _SpaceWorkspaceCard(
                              languageCode: languageCode,
                              loading: loading,
                              ownedSpaces: ownedSpaces,
                              selectedSpace: selectedSpace,
                              user: user,
                              onEnterSpace: (space) {
                                closeDialog();
                                onEnterSpace(space);
                              },
                              onEditSpace: (space) {
                                closeDialog();
                                onEditSpace(space);
                              },
                              onDeleteSpace: (space) {
                                closeDialog();
                                onDeleteSpace(space);
                              },
                              onOpenSpaceComposer: () {
                                closeDialog();
                                onOpenSpaceComposer();
                              },
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Material(
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.surfaceContainerHighest,
                              shape: const CircleBorder(),
                              elevation: 6,
                              child: IconButton(
                                tooltip: localizedText(
                                  languageCode,
                                  '关闭',
                                  'Close',
                                  '關閉',
                                ),
                                onPressed: closeDialog,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
                Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
              ],
            ),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
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
                          localizedText(
                            languageCode,
                            '空间首页',
                            'Space home',
                            '空間首頁',
                          ),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 0.08,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedSpace?.spaceLabel ??
                              localizedText(
                                languageCode,
                                '尚未进入空间',
                                'No space entered',
                                '尚未進入空間',
                              ),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          localizedText(
                            languageCode,
                            '先进入空间，再浏览帖子、发布文章。',
                            'Enter a space first, then browse posts and publish.',
                            '先進入空間，再瀏覽貼文、發佈文章。',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedSpace != null)
                    BilingualActionButton(
                      variant: BilingualButtonVariant.tonal,
                      compact: true,
                      onPressed: openSpaceWorkspaceMenu,
                      primaryLabel: localizedText(
                        languageCode,
                        '空间工作台',
                        'Space workspace',
                        '空間工作台',
                      ),
                      secondaryLabel: 'Space workspace',
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
                          primaryLabel: localizedText(
                            languageCode,
                            '返回首页',
                            'Back to home',
                            '返回首頁',
                          ),
                          secondaryLabel: 'Back to home',
                        ),
                        BilingualActionButton(
                          variant: BilingualButtonVariant.filled,
                          compact: true,
                          onPressed: () => onOpenPostComposer(),
                          primaryLabel: localizedText(
                            languageCode,
                            '发布文章',
                            'Publish post',
                            '發布文章',
                          ),
                          secondaryLabel: 'Publish post',
                        ),
                        BilingualActionButton(
                          variant: BilingualButtonVariant.text,
                          compact: true,
                          onPressed: () => onDeleteSpace(managedSpace),
                          primaryLabel: localizedText(
                            languageCode,
                            '删除空间',
                            'Delete space',
                            '刪除空間',
                          ),
                          secondaryLabel: 'Delete space',
                        ),
                      ],
                    ),
                  if (!canManageSelectedSpace)
                    BilingualActionButton(
                      variant: BilingualButtonVariant.text,
                      compact: true,
                      onPressed: onLeaveSpace,
                      primaryLabel: localizedText(
                        languageCode,
                        '返回首页',
                        'Back to home',
                        '返回首頁',
                      ),
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
                    title: localizedText(
                      languageCode,
                      '当前空间',
                      'Current space',
                      '目前空間',
                    ),
                    value:
                        selectedSpace?.name ??
                        localizedText(
                          languageCode,
                          '未选择',
                          'Not selected',
                          '未選擇',
                        ),
                  ),
                  _SpaceMetaChip(
                    title: localizedText(
                      languageCode,
                      '可见性',
                      'Visibility',
                      '可見性',
                    ),
                    value: selectedSpace == null
                        ? localizedText(
                            languageCode,
                            '未选择',
                            'Not selected',
                            '未選擇',
                          )
                        : spaceVisibilityLabel(
                            selectedSpace.visibility,
                            languageCode,
                          ),
                  ),
                  _SpaceMetaChip(
                    title: localizedText(
                      languageCode,
                      '我的空间',
                      'My spaces',
                      '我的空間',
                    ),
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
            final feed = selectedSpace == null
                ? null
                : _SpaceFeedCard(
                    languageCode: languageCode,
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
                    onEditPost: onEditPost,
                    onDeletePost: onDeletePost,
                  );
            if (feed == null) {
              return _SpaceWorkspaceCard(
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
            }
            return feed;
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
  required ValueChanged<PostItem> onEditPost,
  required String languageCode,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpaceComposerCard(
        loading: loading,
        title: localizedText(
          languageCode,
          '创建私人空间',
          'Create private space',
          '建立私人空間',
        ),
        subtitle: localizedText(
          languageCode,
          '私人空间适合沉淀草稿和只对自己可见的内容。',
          'Private spaces are good for drafts and content visible only to you.',
          '私人空間適合沉澱草稿和只對自己可見的內容。',
        ),
        detailLines: [
          localizedText(
            languageCode,
            '创建后会自动生成二级域名，便于后续通过空间入口进入。',
            'A subdomain is generated automatically so you can enter it later.',
            '建立後會自動生成二級網域，方便之後透過空間入口進入。',
          ),
        ],
        // 按钮统一使用双语组件 / Use the shared bilingual action button.
        buttonPrimaryLabel: localizedText(
          languageCode,
          '打开创建弹窗',
          'Open create dialog',
          '打開建立彈窗',
        ),
        buttonSecondaryLabel: 'Open create dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenSpaceComposer,
      ),
      const SizedBox(height: 16),
      PostComposerCard(
        loading: loading,
        title: localizedText(
          languageCode,
          '发布私人内容',
          'Publish private content',
          '發布私人內容',
        ),
        subtitle: localizedText(
          languageCode,
          '私人内容仅自己可见，适合草稿、笔记和内部记录。',
          'Private content is visible only to you and works well for drafts, notes, and internal records.',
          '私人內容僅自己可見，適合草稿、筆記和內部記錄。',
        ),
        detailLines: [
          if (activeSpace != null)
            '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${activeSpace.name}',
          localizedText(
            languageCode,
            '发布后会记录所属空间，方便后续筛选和回溯。',
            'The post will be bound to the selected space for easier filtering and tracing.',
            '發布後會記錄所屬空間，方便後續篩選和回溯。',
          ),
        ],
        buttonPrimaryLabel: localizedText(
          languageCode,
          '打开发布弹窗',
          'Open publish dialog',
          '打開發布彈窗',
        ),
        buttonSecondaryLabel: 'Open publish dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenPostComposer,
      ),
      const SizedBox(height: 16),
      SpaceListSection(
        title: localizedText(
          languageCode,
          '私人空间列表',
          'Private space list',
          '私人空間列表',
        ),
        spaces: uniqueSpacesById(privateSpaces(spaces)),
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
        emptyText: localizedText(
          languageCode,
          '还没有私人内容。',
          'No private content yet.',
          '還沒有私人內容。',
        ),
        commentControllerFor: commentControllerFor,
        onLike: onToggleLike,
        onShare: onSharePost,
        onComment: onCommentPost,
        onOpenAuthor: onOpenProfile,
        onOpenDetail: onOpenPostDetail,
        onEditPost: onEditPost,
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
  required ValueChanged<PostItem> onEditPost,
  required String languageCode,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SpaceComposerCard(
        loading: loading,
        title: localizedText(languageCode, '创建空间', 'Create space', '建立空間'),
        subtitle: localizedText(
          languageCode,
          '空间适合对外展示项目，也可以设置好友可见或仅自己可见。',
          'Spaces are good for public projects and can also be limited to friends or just you.',
          '空間適合對外展示專案，也可以設定好友可見或僅自己可見。',
        ),
        detailLines: [
          localizedText(
            languageCode,
            '创建后会生成可识别的二级域名，便于从外部直接进入。',
            'A recognizable subdomain will be generated so others can enter directly.',
            '建立後會生成可辨識的二級網域，方便從外部直接進入。',
          ),
        ],
        buttonPrimaryLabel: localizedText(
          languageCode,
          '打开创建弹窗',
          'Open create dialog',
          '打開建立彈窗',
        ),
        buttonSecondaryLabel: 'Open create dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenSpaceComposer,
      ),
      const SizedBox(height: 16),
      PostComposerCard(
        loading: loading,
        title: localizedText(
          languageCode,
          '发布空间内容',
          'Publish space content',
          '發布空間內容',
        ),
        subtitle: localizedText(
          languageCode,
          '空间文章会出现在空间和作者主页。',
          'Space posts appear in the space and on the author profile.',
          '空間文章會出現在空間和作者主頁。',
        ),
        detailLines: [
          if (activeSpace != null)
            '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${activeSpace.name}',
          localizedText(
            languageCode,
            '发布时会记录所属空间，便于后续查看和分享。',
            'The post will be bound to the selected space for later review and sharing.',
            '發布時會記錄所屬空間，便於後續查看和分享。',
          ),
        ],
        buttonPrimaryLabel: localizedText(
          languageCode,
          '打开发布弹窗',
          'Open publish dialog',
          '打開發布彈窗',
        ),
        buttonSecondaryLabel: 'Open publish dialog',
        buttonVariant: BilingualButtonVariant.filled,
        onSubmit: onOpenPostComposer,
      ),
      const SizedBox(height: 16),
      SpaceListSection(
        title: localizedText(languageCode, '空间列表', 'Space list', '空間列表'),
        spaces: uniqueSpacesById(publicSpaces(spaces)),
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
        emptyText: localizedText(
          languageCode,
          '空间里还没有内容。',
          'There is no content in this space yet.',
          '空間裡還沒有內容。',
        ),
        commentControllerFor: commentControllerFor,
        onLike: onToggleLike,
        onShare: onSharePost,
        onComment: onCommentPost,
        onOpenAuthor: onOpenProfile,
        onOpenDetail: onOpenPostDetail,
        onEditPost: onEditPost,
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
  required List<ExternalAccountItem> externalAccounts,
  required List<FriendItem> friends,
  required String currentLevel,
  required Future<bool> Function(String) onActivateLevel,
  required TextEditingController displayNameController,
  required TextEditingController usernameController,
  required TextEditingController domainController,
  required TextEditingController avatarUrlController,
  required TextEditingController signatureController,
  required TextEditingController birthDateController,
  required TextEditingController genderController,
  required String phoneVisibility,
  required String emailVisibility,
  required String ageVisibility,
  required String genderVisibility,
  required bool loading,
  required TextEditingController Function(String postId) commentControllerFor,
  required ProfileTab profileTab,
  required ValueChanged<ProfileTab> onProfileTabChanged,
  required Future<bool> Function() onSaveProfile,
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
  required ValueChanged<PostItem> onEditPost,
  required ValueChanged<SpaceItem> onEnterSpace,
  required String languageCode,
  required String Function(String key) t,
  required String Function(String key) peerT,
}) {
  return ProfileSummaryView(
    user: user,
    profileUser: profileUser,
    profileSpaces: profileSpaces,
    friends: friends,
    connectedChains: connectedChains(externalAccounts),
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
    loading: loading,
    currentLevel: currentLevel,
    onActivateLevel: onActivateLevel,
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
    onEnterSpace: onEnterSpace,
    languageCode: languageCode,
    t: t,
    peerT: peerT,
  );
}

Widget buildPostDetailView({
  required CurrentUser? user,
  required PostItem? currentPost,
  required TextEditingController Function(String postId) commentControllerFor,
  required ValueChanged<PostItem> onEditPost,
  required ValueChanged<PostItem> onToggleLike,
  required ValueChanged<PostItem> onSharePost,
  required ValueChanged<PostItem> onCommentPost,
  required ValueChanged<String> onOpenProfile,
  required VoidCallback? onDeletePost,
  required String languageCode,
}) {
  final post = currentPost;
  return PostDetailView(
    user: user,
    currentPost: post,
    commentController: commentControllerFor(post?.id ?? '__missing__'),
    onEditPost: onEditPost,
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
    onDeletePost: onDeletePost,
    languageCode: languageCode,
  );
}

Widget buildLevelsView({
  required String currentLevel,
  required Future<bool> Function(String) onActivateLevel,
}) {
  return LevelsView(
    currentLevel: currentLevel,
    onActivateLevel: onActivateLevel,
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

class ServicesView extends StatelessWidget {
  const ServicesView({
    super.key,
    required this.spaceOnline,
    required this.messageOnline,
    required this.adminOnline,
    required this.learningOnline,
    required this.isAdmin,
    required this.onOpenAdminPanel,
    required this.onOpenProfile,
    required this.onOpenSpace,
    required this.onOpenChat,
    required this.onOpenLearning,
    required this.onOpenLearningAdmin,
    required this.onRefresh,
    required this.languageCode,
  });

  final bool spaceOnline;
  final bool messageOnline;
  final bool adminOnline;
  final bool learningOnline;
  final bool isAdmin;
  final VoidCallback onOpenAdminPanel;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSpace;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenLearning;
  final VoidCallback onOpenLearningAdmin;
  final VoidCallback onRefresh;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    final cardWidth = availableWidth > 960
        ? (availableWidth - 16) / 2
        : availableWidth;
    final cards = <Widget>[
      _MicroserviceCard(
        title: localizedText(
          languageCode,
          '账号微服务',
          'Account microservice',
          '帳號微服務',
        ),
        subtitle: localizedText(
          languageCode,
          '登录、资料、会员与链上扩展都从这里进入。',
          'Sign in, profile, membership, and chain extensions start here.',
          '登入、資料、會員與鏈上擴充都從這裡進入。',
        ),
        statusLabel: localizedText(languageCode, '在线', 'Online', '線上'),
        modules: [
          localizedText(languageCode, '个人资料', 'Profile', '個人資料'),
          localizedText(languageCode, '联系方式', 'Contact details', '聯絡資訊'),
          localizedText(languageCode, '隐私设置', 'Privacy settings', '隱私設定'),
          localizedText(languageCode, '会员等级', 'Membership', '會員等級'),
          localizedText(languageCode, '链上账号', 'Blockchain', '鏈上帳號'),
        ],
        actionLabel: localizedText(
          languageCode,
          '进入个人主页',
          'Open profile',
          '進入個人主頁',
        ),
        onOpen: onOpenProfile,
      ),
      if (isAdmin)
        _MicroserviceCard(
          title: localizedText(
            languageCode,
            '管理员微服务',
            'Admin service',
            '管理員微服務',
          ),
          subtitle: localizedText(
            languageCode,
            '集中查看站点服务状态、管理员工作区和跨微服务入口。',
            'Review site-wide service health, administrator workspaces, and cross-service entries in one place.',
            '集中查看站點服務狀態、管理員工作區與跨微服務入口。',
          ),
          statusLabel: localizedText(
            languageCode,
            adminOnline ? '在线' : '离线',
            adminOnline ? 'Online' : 'Offline',
            adminOnline ? '線上' : '離線',
          ),
          modules: [
            localizedText(languageCode, '服务总览', 'Service overview', '服務總覽'),
            localizedText(languageCode, '管理员入口', 'Admin entries', '管理員入口'),
            localizedText(languageCode, '健康状态', 'Health status', '健康狀態'),
            localizedText(languageCode, '统一跳转', 'Unified routing', '統一路由'),
          ],
          actionLabel: localizedText(
            languageCode,
            '打开管理面板',
            'Open admin panel',
            '打開管理面板',
          ),
          onOpen: adminOnline ? onOpenAdminPanel : onRefresh,
        ),
      if (spaceOnline)
        _MicroserviceCard(
          title: localizedText(
            languageCode,
            '空间微服务',
            'Space microservice',
            '空間微服務',
          ),
          subtitle: localizedText(
            languageCode,
            '空间、帖子、媒体与工作台入口都由这里承载。',
            'Spaces, posts, media, and the workspace entry live here.',
            '空間、貼文、媒體與工作台入口都由這裡承載。',
          ),
          statusLabel: localizedText(languageCode, '在线', 'Online', '線上'),
          modules: [
            localizedText(languageCode, '空间工作台', 'Workspace', '工作台'),
            localizedText(languageCode, '创建空间', 'Create space', '建立空間'),
            localizedText(languageCode, '帖子流', 'Post feed', '貼文串流'),
            localizedText(languageCode, '媒体预览', 'Media preview', '媒體預覽'),
            localizedText(languageCode, '公开内容', 'Public content', '公開內容'),
          ],
          actionLabel: localizedText(
            languageCode,
            '打开空间',
            'Open space',
            '打開空間',
          ),
          onOpen: onOpenSpace,
        ),
      if (messageOnline)
        _MicroserviceCard(
          title: localizedText(
            languageCode,
            '消息微服务',
            'Message microservice',
            '訊息微服務',
          ),
          subtitle: localizedText(
            languageCode,
            '好友关系、会话摘要与实时消息都在这里汇聚。',
            'Friend relations, conversation summaries, and live messages live here.',
            '好友關係、會話摘要與即時訊息都在這裡匯聚。',
          ),
          statusLabel: localizedText(languageCode, '在线', 'Online', '線上'),
          modules: [
            localizedText(languageCode, '好友关系', 'Friends', '好友關係'),
            localizedText(languageCode, '会话列表', 'Conversations', '會話列表'),
            localizedText(languageCode, '未读消息', 'Unread', '未讀訊息'),
            localizedText(languageCode, '实时聊天', 'Live chat', '即時聊天'),
          ],
          actionLabel: localizedText(languageCode, '打开聊天', 'Open chat', '打開聊天'),
          onOpen: onOpenChat,
        ),
      if (learningOnline)
        _MicroserviceCard(
          title: localizedText(
            languageCode,
            '学习服务',
            'Learning service',
            '學習服務',
          ),
          subtitle: localizedText(
            languageCode,
            '英语、编程、AI 等课程统一在这里查看，并完整渲染 Markdown 内容。',
            'English, programming, AI, and other lessons live here with full Markdown rendering.',
            '英語、程式、AI 等課程統一在這裡查看，並完整渲染 Markdown 內容。',
          ),
          statusLabel: localizedText(languageCode, '在线', 'Online', '線上'),
          modules: [
            localizedText(languageCode, '英语', 'English', '英語'),
            localizedText(languageCode, '编程', 'Programming', '程式'),
            localizedText(languageCode, 'AI', 'AI', 'AI'),
            localizedText(
              languageCode,
              'Markdown 课程',
              'Markdown lessons',
              'Markdown 課程',
            ),
            localizedText(
              languageCode,
              'Mermaid 思维导图',
              'Mermaid mind maps',
              'Mermaid 思維導圖',
            ),
          ],
          actionLabel: localizedText(
            languageCode,
            '打开课程',
            'Open courses',
            '打開課程',
          ),
          onOpen: onOpenLearning,
          secondaryActionLabel: isAdmin
              ? localizedText(languageCode, '课程后台', 'Course console', '課程後台')
              : null,
          onSecondaryOpen: isAdmin ? onOpenLearningAdmin : null,
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedText(
                            languageCode,
                            '服务导航',
                            'Service navigation',
                            '服務導航',
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizedText(
                            languageCode,
                            '只显示在线的微服务入口，离线模块会自动隐藏。',
                            'Only online microservice entry points are shown. Offline modules hide automatically.',
                            '只顯示線上的微服務入口，離線模組會自動隱藏。',
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  BilingualActionButton(
                    variant: BilingualButtonVariant.tonal,
                    compact: true,
                    onPressed: onRefresh,
                    primaryLabel: localizedText(
                      languageCode,
                      '刷新状态',
                      'Refresh status',
                      '重新整理狀態',
                    ),
                    secondaryLabel: 'Refresh status',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final card in cards) SizedBox(width: cardWidth, child: card),
            ],
          ),
        ],
      ),
    );
  }
}

class SiteAdminPanelView extends StatelessWidget {
  const SiteAdminPanelView({
    super.key,
    required this.overview,
    required this.overviewError,
    required this.spaceOnline,
    required this.messageOnline,
    required this.adminOnline,
    required this.learningOnline,
    required this.onOpenAccountAdmin,
    required this.onOpenSpaceAdmin,
    required this.onOpenMessageAdmin,
    required this.onOpenServices,
    required this.onOpenProfile,
    required this.onOpenSpace,
    required this.onOpenChat,
    required this.onOpenLearning,
    required this.onOpenLearningAdmin,
    required this.onRefresh,
    required this.languageCode,
  });

  final AdminOverview? overview;
  final String? overviewError;
  final bool spaceOnline;
  final bool messageOnline;
  final bool adminOnline;
  final bool learningOnline;
  final VoidCallback onOpenAccountAdmin;
  final VoidCallback onOpenSpaceAdmin;
  final VoidCallback onOpenMessageAdmin;
  final VoidCallback onOpenServices;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSpace;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenLearning;
  final VoidCallback onOpenLearningAdmin;
  final VoidCallback onRefresh;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final totalServices = overview?.totalServices ?? 5;
    final onlineServices =
        overview?.onlineServices ??
        (1 +
            (adminOnline ? 1 : 0) +
            (spaceOnline ? 1 : 0) +
            (messageOnline ? 1 : 0) +
            (learningOnline ? 1 : 0));
    final offlineServices =
        overview?.offlineServices ?? (totalServices - onlineServices);
    final adminWorkspaces =
        overview?.adminWorkspaces ?? (1 + (learningOnline ? 1 : 0));
    final checkedAt = overview?.checkedAt?.toLocal();
    final hasLiveOverview =
        overview != null && overview!.services.isNotEmpty;
    final serviceMeta = <String, ({
      String title,
      String subtitle,
      String actionLabel,
      VoidCallback? onOpen,
      VoidCallback? onSecondaryOpen,
      String? secondaryActionLabel,
    })>{
      'admin': (
        title: localizedText(
          languageCode,
          '管理员微服务',
          'Admin service',
          '管理員微服務',
        ),
        subtitle: localizedText(
          languageCode,
          '承接网站总管理面板与站点级管理员总览。',
          'Back the site-wide admin panel and administrator overview.',
          '承接網站總管理面板與站點級管理員總覽。',
        ),
        actionLabel: localizedText(
          languageCode,
          '刷新管理面板',
          'Refresh admin panel',
          '重新整理管理面板',
        ),
        onOpen: adminOnline ? onRefresh : null,
        onSecondaryOpen: null,
        secondaryActionLabel: null,
      ),
      'account': (
        title: localizedText(
          languageCode,
          '账号微服务',
          'Account microservice',
          '帳號微服務',
        ),
        subtitle: localizedText(
          languageCode,
          '身份、资料、会员与权限基线。',
          'Identity, profile, membership, and permission baseline.',
          '身份、資料、會員與權限基線。',
        ),
        actionLabel: localizedText(
          languageCode,
          '进入个人主页',
          'Open profile',
          '進入個人主頁',
        ),
        onOpen: onOpenProfile,
        onSecondaryOpen: onOpenAccountAdmin,
        secondaryActionLabel: localizedText(
          languageCode,
          '管理控制页',
          'Admin console',
          '管理控制頁',
        ),
      ),
      'space': (
        title: localizedText(
          languageCode,
          '空间微服务',
          'Space microservice',
          '空間微服務',
        ),
        subtitle: localizedText(
          languageCode,
          '空间、帖子与内容上下文。',
          'Spaces, posts, and content context.',
          '空間、貼文與內容上下文。',
        ),
        actionLabel: localizedText(languageCode, '打开空间', 'Open space', '打開空間'),
        onOpen: spaceOnline ? onOpenSpace : null,
        onSecondaryOpen: spaceOnline ? onOpenSpaceAdmin : null,
        secondaryActionLabel: localizedText(
          languageCode,
          '管理控制页',
          'Admin console',
          '管理控制頁',
        ),
      ),
      'message': (
        title: localizedText(
          languageCode,
          '消息微服务',
          'Message microservice',
          '訊息微服務',
        ),
        subtitle: localizedText(
          languageCode,
          '好友关系、会话和即时消息。',
          'Friend relations, conversations, and live messaging.',
          '好友關係、會話與即時訊息。',
        ),
        actionLabel: localizedText(languageCode, '打开聊天', 'Open chat', '打開聊天'),
        onOpen: messageOnline ? onOpenChat : null,
        onSecondaryOpen: messageOnline ? onOpenMessageAdmin : null,
        secondaryActionLabel: localizedText(
          languageCode,
          '管理控制页',
          'Admin console',
          '管理控制頁',
        ),
      ),
      'learning': (
        title: localizedText(languageCode, '学习服务', 'Learning service', '學習服務'),
        subtitle: localizedText(
          languageCode,
          '课程浏览、课程后台与内容发布。',
          'Lesson browsing, course console, and content publishing.',
          '課程瀏覽、課程後台與內容發布。',
        ),
        actionLabel: localizedText(
          languageCode,
          '打开课程',
          'Open learning',
          '打開課程',
        ),
        onOpen: learningOnline ? onOpenLearning : null,
        onSecondaryOpen: learningOnline ? onOpenLearningAdmin : null,
        secondaryActionLabel: localizedText(
          languageCode,
          '课程后台',
          'Course console',
          '課程後台',
        ),
      ),
    };
    final liveServiceCards = hasLiveOverview
        ? overview!.services.map((service) {
            final meta = serviceMeta[service.key];
            final extraParts = <String>[
              localizedText(
                languageCode,
                service.online ? '健康' : '离线',
                service.online ? 'Healthy' : 'Offline',
                service.online ? '健康' : '離線',
              ),
              if (service.required)
                localizedText(languageCode, '必需', 'Required', '必需'),
              if (service.latencyMs > 0) '${service.latencyMs} ms',
              if (service.baseUrl.isNotEmpty) service.baseUrl,
            ];
            return _AdminServiceStatusCard(
              title: meta?.title ?? service.title,
              subtitle: meta?.subtitle ?? service.title,
              online: service.online,
              actionLabel:
                  meta?.actionLabel ??
                  localizedText(languageCode, '打开', 'Open', '打開'),
              onOpen: meta?.onOpen,
              onSecondaryOpen: meta?.onSecondaryOpen,
              secondaryActionLabel: meta?.secondaryActionLabel,
              languageCode: languageCode,
              metaText: extraParts.join(' · '),
            );
          }).toList()
        : <Widget>[];
    final fallbackServiceCards = <Widget>[
      _AdminServiceStatusCard(
        title: serviceMeta['admin']!.title,
        subtitle: serviceMeta['admin']!.subtitle,
        online: adminOnline,
        actionLabel: serviceMeta['admin']!.actionLabel,
        onOpen: serviceMeta['admin']!.onOpen,
        languageCode: languageCode,
      ),
      _AdminServiceStatusCard(
        title: serviceMeta['account']!.title,
        subtitle: serviceMeta['account']!.subtitle,
        online: true,
        actionLabel: serviceMeta['account']!.actionLabel,
        onOpen: serviceMeta['account']!.onOpen,
        languageCode: languageCode,
      ),
      _AdminServiceStatusCard(
        title: serviceMeta['space']!.title,
        subtitle: serviceMeta['space']!.subtitle,
        online: spaceOnline,
        actionLabel: serviceMeta['space']!.actionLabel,
        onOpen: serviceMeta['space']!.onOpen,
        languageCode: languageCode,
      ),
      _AdminServiceStatusCard(
        title: serviceMeta['message']!.title,
        subtitle: serviceMeta['message']!.subtitle,
        online: messageOnline,
        actionLabel: serviceMeta['message']!.actionLabel,
        onOpen: serviceMeta['message']!.onOpen,
        languageCode: languageCode,
      ),
      _AdminServiceStatusCard(
        title: serviceMeta['learning']!.title,
        subtitle: serviceMeta['learning']!.subtitle,
        online: learningOnline,
        actionLabel: serviceMeta['learning']!.actionLabel,
        secondaryActionLabel: serviceMeta['learning']!.secondaryActionLabel,
        onOpen: serviceMeta['learning']!.onOpen,
        onSecondaryOpen: serviceMeta['learning']!.onSecondaryOpen,
        languageCode: languageCode,
      ),
    ];
    final serviceCards = hasLiveOverview ? liveServiceCards : fallbackServiceCards;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
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
                                '网站总管理面板',
                                'Site-wide admin panel',
                                '網站總管理面板',
                              ),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localizedText(
                                languageCode,
                                '这里集中查看站点服务健康状态，并进入课程后台、空间与消息工作区。',
                                'Review site service health here and jump into learning, space, and messaging workspaces.',
                                '這裡集中查看站點服務健康狀態，並進入課程後台、空間與訊息工作區。',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          BilingualActionButton(
                            variant: BilingualButtonVariant.tonal,
                            compact: true,
                            onPressed: onOpenServices,
                            primaryLabel: localizedText(
                              languageCode,
                              '服务导航',
                              'Service navigation',
                              '服務導航',
                            ),
                            secondaryLabel: 'Service navigation',
                          ),
                          BilingualActionButton(
                            variant: BilingualButtonVariant.filled,
                            compact: true,
                            onPressed: onRefresh,
                            primaryLabel: localizedText(
                              languageCode,
                              '刷新状态',
                              'Refresh status',
                              '重新整理狀態',
                            ),
                            secondaryLabel: 'Refresh status',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (overviewError != null || checkedAt != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        overviewError ??
                            [
                              '${checkedAt!.year.toString().padLeft(4, '0')}-${checkedAt.month.toString().padLeft(2, '0')}-${checkedAt.day.toString().padLeft(2, '0')}',
                              '${checkedAt.hour.toString().padLeft(2, '0')}:${checkedAt.minute.toString().padLeft(2, '0')}:${checkedAt.second.toString().padLeft(2, '0')}',
                              if (overview?.degraded == true)
                                localizedText(
                                  languageCode,
                                  '站点当前处于降级状态',
                                  'The site is currently degraded.',
                                  '站點目前處於降級狀態',
                                ),
                            ].join(' · '),
                      ),
                    ),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AdminKpiCard(
                        label: localizedText(
                          languageCode,
                          '总服务数',
                          'Total services',
                          '總服務數',
                        ),
                        value: '$totalServices',
                      ),
                      _AdminKpiCard(
                        label: localizedText(
                          languageCode,
                          '在线服务',
                          'Online services',
                          '在線服務',
                        ),
                        value: '$onlineServices',
                      ),
                      _AdminKpiCard(
                        label: localizedText(
                          languageCode,
                          '离线服务',
                          'Offline services',
                          '離線服務',
                        ),
                        value: '$offlineServices',
                      ),
                      _AdminKpiCard(
                        label: localizedText(
                          languageCode,
                          '管理工作区',
                          'Admin workspaces',
                          '管理工作區',
                        ),
                        value: '$adminWorkspaces',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final card in serviceCards)
                SizedBox(
                  width: MediaQuery.sizeOf(context).width > 960
                      ? (MediaQuery.sizeOf(context).width - 64) / 2
                      : double.infinity,
                  child: card,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ServiceAdminConsoleView extends StatelessWidget {
  const ServiceAdminConsoleView({
    super.key,
    required this.overview,
    this.spaceOverview,
    this.spaceOverviewError,
    this.messageOverview,
    this.messageOverviewError,
    required this.serviceKey,
    required this.title,
    required this.subtitle,
    required this.modules,
    required this.onBackToAdmin,
    required this.onOpenService,
    required this.onRefresh,
    required this.languageCode,
  });

  final AdminOverview? overview;
  final AdminSpaceOverview? spaceOverview;
  final String? spaceOverviewError;
  final AdminMessageOverview? messageOverview;
  final String? messageOverviewError;
  final String serviceKey;
  final String title;
  final String subtitle;
  final List<String> modules;
  final VoidCallback onBackToAdmin;
  final VoidCallback onOpenService;
  final VoidCallback onRefresh;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    AdminServiceStatus? service;
    for (final item in overview?.services ?? const <AdminServiceStatus>[]) {
      if (item.key == serviceKey) {
        service = item;
        break;
      }
    }
    final online = service?.online ?? false;
    final details = <String>[
      localizedText(
        languageCode,
        online ? '在线' : '离线',
        online ? 'Online' : 'Offline',
        online ? '線上' : '離線',
      ),
      if (service?.required == true)
        localizedText(languageCode, '必需服务', 'Required service', '必需服務'),
      if ((service?.latencyMs ?? 0) > 0) '${service!.latencyMs} ms',
      if ((service?.baseUrl ?? '').isNotEmpty) service!.baseUrl,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
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
                              title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(subtitle),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          BilingualActionButton(
                            variant: BilingualButtonVariant.tonal,
                            compact: true,
                            onPressed: onBackToAdmin,
                            primaryLabel: localizedText(
                              languageCode,
                              '返回总控',
                              'Back to admin',
                              '返回總控',
                            ),
                            secondaryLabel: 'Back',
                          ),
                          BilingualActionButton(
                            variant: BilingualButtonVariant.filled,
                            compact: true,
                            onPressed: online ? onOpenService : null,
                            primaryLabel: localizedText(
                              languageCode,
                              '打开服务页',
                              'Open service',
                              '打開服務頁',
                            ),
                            secondaryLabel: 'Open service',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(details.join(' · ')),
                  ),
                  if (serviceKey == 'space' &&
                      (spaceOverviewError != null || spaceOverview != null)) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        spaceOverviewError ??
                            [
                              'Spaces ${spaceOverview?.totalSpaces ?? 0}',
                              'Active ${spaceOverview?.activeSpaces ?? 0}',
                              'Posts ${spaceOverview?.totalPosts ?? 0}',
                              'Draft ${spaceOverview?.draftPosts ?? 0}',
                            ].join(' · '),
                      ),
                    ),
                  ],
                  if (serviceKey == 'message' &&
                      (messageOverviewError != null || messageOverview != null)) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        messageOverviewError ??
                            [
                              'Messages ${messageOverview?.totalMessages ?? 0}',
                              'Unread ${messageOverview?.unreadMessages ?? 0}',
                              'Conversations ${messageOverview?.activeConversations ?? 0}',
                              'Friends ${messageOverview?.connectedFriends ?? 0}',
                            ].join(' · '),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizedText(
                            languageCode,
                            '管理控制项',
                            'Management modules',
                            '管理控制項',
                          ),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: onRefresh,
                        primaryLabel: localizedText(
                          languageCode,
                          '刷新状态',
                          'Refresh status',
                          '重新整理狀態',
                        ),
                        secondaryLabel: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: modules
                        .map(
                          (item) => Chip(
                            label: Text(item),
                          ),
                        )
                        .toList(),
                  ),
                  if (serviceKey == 'space' && spaceOverview != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      localizedText(
                        languageCode,
                        '最近空间',
                        'Recent spaces',
                        '最近空間',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...spaceOverview!.recentSpaces.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          '${item.name} · @${item.subdomain}\n${item.ownerName} · ${item.type} · ${item.visibility} · ${item.status} · ${item.postsCount} posts',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      localizedText(
                        languageCode,
                        '最近帖子',
                        'Recent posts',
                        '最近貼文',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...spaceOverview!.recentPosts.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          '${item.title.isEmpty ? localizedText(languageCode, "（未命名）", "(untitled)", "（未命名）") : item.title}\n${item.authorName} · ${item.spaceName.isEmpty ? localizedText(languageCode, "未绑定空间", "No space", "未綁定空間") : item.spaceName} · ${item.visibility} · ${item.status}',
                        ),
                      ),
                    ),
                  ],
                  if (serviceKey == 'message' && messageOverview != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      localizedText(
                        languageCode,
                        '最近会话',
                        'Recent conversations',
                        '最近會話',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...messageOverview!.recentConversations.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          '${item.participantAName} · ${item.participantBName}\n${item.lastPreview} · ${item.lastMessageType} · ${item.messageCount} messages · ${item.unreadCount} unread',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      localizedText(
                        languageCode,
                        '最近消息',
                        'Recent messages',
                        '最近訊息',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...messageOverview!.recentMessages.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          '${item.senderName} → ${item.receiverName}\n${item.preview} · ${item.messageType}${item.readAt == null ? ' · unread' : ''}${item.expiresAt != null ? ' · expires' : ''}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicroserviceCard extends StatelessWidget {
  const _MicroserviceCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.modules,
    required this.actionLabel,
    required this.onOpen,
    this.secondaryActionLabel,
    this.onSecondaryOpen,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final List<String> modules;
  final String actionLabel;
  final VoidCallback onOpen;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(label: Text(statusLabel)),
              ],
            ),
            const SizedBox(height: 10),
            Text(subtitle),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final module in modules) Chip(label: Text(module)),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if ((secondaryActionLabel ?? '').isNotEmpty &&
                      onSecondaryOpen != null)
                    BilingualActionButton(
                      variant: BilingualButtonVariant.tonal,
                      compact: true,
                      onPressed: onSecondaryOpen,
                      primaryLabel: secondaryActionLabel!,
                      secondaryLabel: secondaryActionLabel!,
                    ),
                  BilingualActionButton(
                    variant: BilingualButtonVariant.filled,
                    compact: true,
                    onPressed: onOpen,
                    primaryLabel: actionLabel,
                    secondaryLabel: actionLabel,
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

class _AdminKpiCard extends StatelessWidget {
  const _AdminKpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AdminServiceStatusCard extends StatelessWidget {
  const _AdminServiceStatusCard({
    required this.title,
    required this.subtitle,
    required this.online,
    required this.actionLabel,
    required this.languageCode,
    this.metaText,
    this.secondaryActionLabel,
    this.onOpen,
    this.onSecondaryOpen,
  });

  final String title;
  final String subtitle;
  final bool online;
  final String actionLabel;
  final String languageCode;
  final String? metaText;
  final String? secondaryActionLabel;
  final VoidCallback? onOpen;
  final VoidCallback? onSecondaryOpen;

  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    online
                        ? localizedText(languageCode, '在线', 'Online', '線上')
                        : localizedText(languageCode, '离线', 'Offline', '離線'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(subtitle),
            if ((metaText ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                metaText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if ((secondaryActionLabel ?? '').isNotEmpty &&
                      onSecondaryOpen != null)
                    BilingualActionButton(
                      variant: BilingualButtonVariant.tonal,
                      compact: true,
                      onPressed: onSecondaryOpen,
                      primaryLabel: secondaryActionLabel!,
                      secondaryLabel: secondaryActionLabel!,
                    ),
                  BilingualActionButton(
                    variant: online
                        ? BilingualButtonVariant.filled
                        : BilingualButtonVariant.tonal,
                    compact: true,
                    onPressed: onOpen,
                    primaryLabel: actionLabel,
                    secondaryLabel: actionLabel,
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

class _SpaceMetaChip extends StatelessWidget {
  const _SpaceMetaChip({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SpaceFeedCard extends StatelessWidget {
  const _SpaceFeedCard({
    required this.languageCode,
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
    required this.onEditPost,
    required this.onDeletePost,
  });

  final String languageCode;
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
  final ValueChanged<PostItem> onEditPost;
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
            if (canPublish)
              Align(
                alignment: Alignment.centerRight,
                child: BilingualActionButton(
                  variant: BilingualButtonVariant.filled,
                  compact: true,
                  onPressed: onOpenPostComposer,
                  primaryLabel: localizedText(
                    languageCode,
                    '发布文章',
                    'Publish post',
                    '發布文章',
                  ),
                  secondaryLabel: 'Publish post',
                ),
              ),
            const SizedBox(height: 14),
            PostStreamSection(
              posts: spacePosts,
              emptyText: canPublish
                  ? localizedText(
                      languageCode,
                      '这个空间里还没有内容，点击发布开始创作。',
                      'There is no content in this space yet. Publish the first post.',
                      '這個空間裡還沒有內容，點擊發布開始創作。',
                    )
                  : localizedText(
                      languageCode,
                      '这个空间里还没有内容。',
                      'There is no content in this space yet.',
                      '這個空間裡還沒有內容。',
                    ),
              commentControllerFor: commentControllerFor,
              onLike: onToggleLike,
              onShare: onSharePost,
              onComment: onCommentPost,
              onOpenAuthor: onOpenProfile,
              onOpenDetail: onOpenPostDetail,
              onEditPost: onEditPost,
              canEditPost: (post) =>
                  currentUserId != null &&
                  (post.userId == currentUserId ||
                      post.spaceUserId == currentUserId),
              onDeletePost: onDeletePost,
              languageCode: languageCode,
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              localizedText(
                languageCode,
                '“我的空间”与“创建空间”放在同一个工作台。',
                '"My spaces" and "Create space" share one workspace.',
                '「我的空間」與「建立空間」放在同一個工作台。',
              ),
            ),
            const SizedBox(height: 14),
            TabBar(
              tabs: [
                Tab(
                  text: localizedText(
                    languageCode,
                    '我的空间',
                    'My spaces',
                    '我的空間',
                  ),
                ),
                Tab(
                  text: localizedText(
                    languageCode,
                    '创建空间',
                    'Create space',
                    '建立空間',
                  ),
                ),
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
                          title: localizedText(
                            languageCode,
                            '我的空间',
                            'My spaces',
                            '我的空間',
                          ),
                          lines: [
                            localizedText(
                              languageCode,
                              '当前还没有你创建的空间。',
                              'You have not created any spaces yet.',
                              '目前還沒有你建立的空間。',
                            ),
                            localizedText(
                              languageCode,
                              '可以先创建一个空间，再进入浏览内容。',
                              'Create one first, then enter it to browse content.',
                              '可以先建立一個空間，再進入瀏覽內容。',
                            ),
                          ],
                        )
                      else
                        SpaceListSection(
                          title: localizedText(
                            languageCode,
                            '我的空间',
                            'My spaces',
                            '我的空間',
                          ),
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
                          title: localizedText(
                            languageCode,
                            '创建空间',
                            'Create space',
                            '建立空間',
                          ),
                          subtitle: localizedText(
                            languageCode,
                            '名称、二级域名和可见范围会在这里逐步完善。',
                            'Name, subdomain, and visibility will be refined here.',
                            '名稱、二級網域和可見範圍會在這裡逐步完善。',
                          ),
                          detailLines: [
                            localizedText(
                              languageCode,
                              '创建完成后会自动进入新空间。',
                              'After creation, the new space is entered automatically.',
                              '建立完成後會自動進入新空間。',
                            ),
                          ],
                          buttonPrimaryLabel: localizedText(
                            languageCode,
                            '打开创建弹窗',
                            'Open create dialog',
                            '打開建立彈窗',
                          ),
                          buttonSecondaryLabel: 'Open create dialog',
                          buttonVariant: BilingualButtonVariant.filled,
                          onSubmit: onOpenSpaceComposer,
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
