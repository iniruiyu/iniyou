import '../models/app_models.dart';
import '../main.dart' show AppView;
import '../widgets/app_cards.dart';

String localizedText(String languageCode, String zh, String en, [String? tw]) {
  // Resolve a short UI label for the currently selected language.
  // 根据当前设置语言解析短句式界面文案。
  switch (languageCode) {
    case 'en-US':
      return en;
    case 'zh-TW':
      return tw ?? zh;
    default:
      return zh;
  }
}

FriendItem? findFriendById(String id, List<FriendItem> items) {
  for (final item in items) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
}

List<FriendItem> acceptedFriends(List<FriendItem> friends) {
  return friends.where((item) => item.status == 'accepted').toList();
}

SpaceItem? findSpaceById(List<SpaceItem> spaces, String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final space in spaces) {
    if (space.id == id) {
      return space;
    }
  }
  return null;
}

SpaceItem? firstSpaceOfType(List<SpaceItem> spaces, String type) {
  for (final space in spaces) {
    if (space.type == type) {
      return space;
    }
  }
  return null;
}

String spaceTypeLabel(String type, String languageCode) {
  // Map legacy space types to the active language label only.
  // 将历史空间类型映射为当前语言标签。
  switch (type) {
    case 'private':
      return localizedText(languageCode, '私人空间', 'Private space', '私人空間');
    case 'public':
    default:
      return localizedText(languageCode, '空间', 'Space', '空間');
  }
}

String spaceVisibilityLabel(String visibility, String languageCode) {
  // Map space visibility values to the active language label only.
  // 将空间可见性映射为当前语言标签。
  switch (visibility) {
    case 'friends':
      return localizedText(languageCode, '好友可见', 'Friends only', '好友可見');
    case 'private':
      return localizedText(languageCode, '仅自己可见', 'Only me', '僅自己可見');
    default:
      return localizedText(languageCode, '所有人可见', 'Public', '所有人可見');
  }
}

List<SpaceItem> privateSpaces(List<SpaceItem> spaces) {
  return spaces.where((space) => space.type == 'private').toList();
}

List<SpaceItem> publicSpaces(List<SpaceItem> spaces) {
  return spaces.where((space) => space.type == 'public').toList();
}

List<SpaceItem> uniqueSpacesById(List<SpaceItem> spaces) {
  // Drop duplicate space IDs so pickers and cards stay stable after refreshes.
  // 按空间 ID 去重，避免刷新后下拉框和卡片出现重复项。
  final seenIds = <String>{};
  return spaces.where((space) => seenIds.add(space.id)).toList();
}

List<PostItem> postsForSpace(List<PostItem> posts, String? spaceId) {
  if (spaceId == null || spaceId.isEmpty) {
    return posts;
  }
  return posts.where((post) => post.spaceId == spaceId).toList();
}

List<String> connectedChains(List<ExternalAccountItem> externalAccounts) {
  final values = <String>{};
  for (final item in externalAccounts) {
    if (item.bindingStatus == 'active' && item.chain.isNotEmpty) {
      values.add(item.chain);
    }
  }
  return values.toList()..sort();
}

List<SummaryCardData> buildHomeSummaryCards({
  required List<FriendItem> friends,
  required String Function(String key) t,
}) {
  // Keep the owner summary focused on relationships instead of personal-space counts.
  // 让个人主页概览只保留关系信息，不再展示自己的空间数量。
  return [
    SummaryCardData(
      t('summary.friends'),
      '${acceptedFriends(friends).length}',
      '${t('summary.totalRelations')} ${friends.length}',
    ),
  ];
}

String pageTitleForView(
  AppView view, {
  UserProfileItem? profileUser,
  PostItem? currentPost,
  SpaceItem? activePrivateSpace,
  SpaceItem? activePublicSpace,
  required String Function(String key) t,
}) {
  switch (view) {
    case AppView.dashboard:
      return t('page.profile');
    case AppView.services:
      return t('page.services');
    case AppView.adminPanel:
      return t('page.adminPanel');
    case AppView.accountAdmin:
      return t('page.accountAdmin');
    case AppView.spaceAdmin:
      return t('page.spaceAdmin');
    case AppView.messageAdmin:
      return t('page.messageAdmin');
    case AppView.learning:
      return t('page.learning');
    case AppView.learningAdmin:
      return t('page.learningAdmin');
    case AppView.space:
      final activeSpace = activePublicSpace ?? activePrivateSpace;
      if (activeSpace?.name.isNotEmpty == true) {
        return '${t('page.space')} · ${activeSpace!.name}';
      }
      return t('page.space');
    case AppView.privateSpace:
    case AppView.publicSpace:
      final activeSpace = activePublicSpace ?? activePrivateSpace;
      if (activeSpace?.name.isNotEmpty == true) {
        return '${t('page.space')} · ${activeSpace!.name}';
      }
      return t('page.space');
    case AppView.profile:
      if (profileUser?.displayName.isNotEmpty == true &&
          profileUser?.domain.isNotEmpty == true) {
        return '${profileUser!.displayName} · @${profileUser.domain}';
      }
      if (profileUser?.displayName.isNotEmpty == true) {
        return profileUser!.displayName;
      }
      if (profileUser?.domain.isNotEmpty == true) {
        return '@${profileUser!.domain}';
      }
      if (profileUser?.username.isNotEmpty == true) {
        return '@${profileUser!.username}';
      }
      return t('page.profile');
    case AppView.postDetail:
      return currentPost?.title.isNotEmpty == true
          ? currentPost!.title
          : t('page.postDetail');
    case AppView.levels:
      return t('page.levels');
    case AppView.blockchain:
      return t('page.blockchain');
    case AppView.friends:
      return t('page.friends');
    case AppView.chat:
      return t('page.chat');
  }
}

String pageSubtitleForView(
  AppView view, {
  SpaceItem? activePrivateSpace,
  SpaceItem? activePublicSpace,
  required String Function(String key) t,
}) {
  switch (view) {
    case AppView.dashboard:
      return t('subtitle.profile');
    case AppView.services:
      return t('subtitle.services');
    case AppView.adminPanel:
      return t('subtitle.adminPanel');
    case AppView.accountAdmin:
      return t('subtitle.accountAdmin');
    case AppView.spaceAdmin:
      return t('subtitle.spaceAdmin');
    case AppView.messageAdmin:
      return t('subtitle.messageAdmin');
    case AppView.learning:
      return t('subtitle.learning');
    case AppView.learningAdmin:
      return t('subtitle.learningAdmin');
    case AppView.space:
      return t('subtitle.space');
    case AppView.privateSpace:
    case AppView.publicSpace:
      return t('subtitle.space');
    case AppView.profile:
      return t('subtitle.profile');
    case AppView.postDetail:
      return t('subtitle.postDetail');
    case AppView.levels:
      return t('subtitle.levels');
    case AppView.blockchain:
      return t('subtitle.blockchain');
    case AppView.friends:
      return t('subtitle.friends');
    case AppView.chat:
      return t('subtitle.chat');
  }
}

String sidebarViewKey(AppView view) {
  if (view == AppView.postDetail) {
    return 'space';
  }
  switch (view) {
    case AppView.dashboard:
      return 'profile';
    case AppView.services:
      return 'services';
    case AppView.adminPanel:
    case AppView.accountAdmin:
    case AppView.spaceAdmin:
    case AppView.messageAdmin:
      return 'admin-panel';
    case AppView.learning:
      return 'services';
    case AppView.learningAdmin:
      return 'learning-admin';
    case AppView.space:
    case AppView.privateSpace:
    case AppView.publicSpace:
      return 'space';
    case AppView.profile:
      return 'profile';
    case AppView.postDetail:
      return 'space';
    case AppView.levels:
      return 'profile';
    case AppView.blockchain:
      return 'profile';
    case AppView.friends:
      return 'friends';
    case AppView.chat:
      return 'chat';
  }
}

AppView appViewFromKey(String key) {
  switch (key) {
    case 'space':
    case 'private':
    case 'public':
      return AppView.space;
    case 'profile':
      return AppView.profile;
    case 'levels':
      return AppView.levels;
    case 'blockchain':
      return AppView.blockchain;
    case 'friends':
      return AppView.friends;
    case 'chat':
      return AppView.chat;
    case 'dashboard':
      return AppView.profile;
    case 'services':
      return AppView.services;
    case 'admin-panel':
      return AppView.adminPanel;
    case 'account-admin':
      return AppView.accountAdmin;
    case 'space-admin':
      return AppView.spaceAdmin;
    case 'message-admin':
      return AppView.messageAdmin;
    case 'learning':
      return AppView.learning;
    case 'learning-admin':
      return AppView.learningAdmin;
    default:
      return AppView.profile;
  }
}
