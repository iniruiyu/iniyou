import '../models/app_models.dart';
import '../main.dart' show AppView;
import '../widgets/app_cards.dart';

String localizedText(
  String languageCode,
  String zh,
  String en, [
  String? tw,
]) {
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
  required List<SpaceItem> spaces,
  required List<FriendItem> friends,
  required SubscriptionItem? subscription,
  required List<ExternalAccountItem> externalAccounts,
  required String Function(String key) t,
  required String languageCode,
}) {
  final chains = connectedChains(externalAccounts);
  // Count only public-type spaces in the dashboard summary.
  // 仪表盘摘要只统计公共类型空间，避免把旧私人空间算进去。
  final visibleSpaces = publicSpaces(spaces);
  return [
    SummaryCardData(
      t('summary.spaces'),
      '${visibleSpaces.length}',
      localizedText(
        languageCode,
        '可见空间总数',
        'Visible spaces',
        '可見空間總數',
      ),
    ),
    SummaryCardData(
      t('summary.friends'),
      '${acceptedFriends(friends).length}',
      '${t('summary.totalRelations')} ${friends.length}',
    ),
    SummaryCardData(
      t('summary.subscription'),
      subscription?.planId.isNotEmpty == true ? subscription!.planId : 'basic',
      '${t('summary.status')} ${subscription?.status ?? t('summary.inactive')}',
    ),
    SummaryCardData(
      t('summary.chains'),
      '${externalAccounts.length}',
      chains.isEmpty ? t('summary.noChains') : chains.join(', '),
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
      return t('page.dashboard');
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
    case AppView.subscription:
      return t('page.subscription');
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
      return t('subtitle.dashboard');
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
    case AppView.subscription:
      return t('subtitle.subscription');
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
      return 'dashboard';
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
    case AppView.subscription:
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
    case 'dashboard':
      return AppView.dashboard;
    case 'space':
    case 'private':
    case 'public':
      return AppView.space;
    case 'profile':
      return AppView.profile;
    case 'levels':
      return AppView.levels;
    case 'subscription':
      return AppView.subscription;
    case 'blockchain':
      return AppView.blockchain;
    case 'friends':
      return AppView.friends;
    case 'chat':
      return AppView.chat;
    default:
      return AppView.dashboard;
  }
}
