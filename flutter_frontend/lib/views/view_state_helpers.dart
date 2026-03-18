import '../models/app_models.dart';
import '../main.dart' show AppView;
import '../widgets/app_cards.dart';

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
}) {
  final chains = connectedChains(externalAccounts);
  return [
    SummaryCardData(
      t('summary.spaces'),
      '${spaces.length}',
      '${t('summary.private')} ${privateSpaces(spaces).length} / ${t('summary.public')} ${publicSpaces(spaces).length}',
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
    case AppView.privateSpace:
      if (activePrivateSpace?.name.isNotEmpty == true) {
        return '${t('page.private')} · ${activePrivateSpace!.name}';
      }
      return t('page.private');
    case AppView.publicSpace:
      if (activePublicSpace?.name.isNotEmpty == true) {
        return '${t('page.public')} · ${activePublicSpace!.name}';
      }
      return t('page.public');
    case AppView.profile:
      if (profileUser?.displayName.isNotEmpty == true &&
          profileUser?.username.isNotEmpty == true) {
        return '${profileUser!.displayName} · @${profileUser.username}';
      }
      if (profileUser?.displayName.isNotEmpty == true) {
        return profileUser!.displayName;
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
    case AppView.privateSpace:
      if (activePrivateSpace?.subdomain.isNotEmpty == true) {
        return '${t('subtitle.private')} · @${activePrivateSpace!.subdomain}';
      }
      return t('subtitle.private');
    case AppView.publicSpace:
      if (activePublicSpace?.subdomain.isNotEmpty == true) {
        return '${t('subtitle.public')} · @${activePublicSpace!.subdomain}';
      }
      return t('subtitle.public');
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
    return 'public';
  }
  switch (view) {
    case AppView.dashboard:
      return 'dashboard';
    case AppView.privateSpace:
      return 'private';
    case AppView.publicSpace:
      return 'public';
    case AppView.profile:
      return 'profile';
    case AppView.postDetail:
      return 'public';
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
    case 'private':
      return AppView.privateSpace;
    case 'public':
      return AppView.publicSpace;
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
