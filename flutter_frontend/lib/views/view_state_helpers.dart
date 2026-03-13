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

List<SpaceItem> privateSpaces(List<SpaceItem> spaces) {
  return spaces.where((space) => space.type == 'private').toList();
}

List<SpaceItem> publicSpaces(List<SpaceItem> spaces) {
  return spaces.where((space) => space.type == 'public').toList();
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
}) {
  final chains = connectedChains(externalAccounts);
  return [
    SummaryCardData(
      '空间',
      '${spaces.length}',
      '私人 ${privateSpaces(spaces).length} / 公共 ${publicSpaces(spaces).length}',
    ),
    SummaryCardData(
      '好友',
      '${acceptedFriends(friends).length}',
      '总关系 ${friends.length}',
    ),
    SummaryCardData(
      '订阅',
      subscription?.planId.isNotEmpty == true ? subscription!.planId : 'basic',
      '状态 ${subscription?.status ?? 'inactive'}',
    ),
    SummaryCardData(
      '链上账号',
      '${externalAccounts.length}',
      chains.isEmpty ? '尚未连接链' : chains.join(', '),
    ),
  ];
}

String pageTitleForView(
  AppView view, {
  UserProfileItem? profileUser,
  PostItem? currentPost,
}) {
  switch (view) {
    case AppView.dashboard:
      return '工作台';
    case AppView.privateSpace:
      return '私人空间';
    case AppView.publicSpace:
      return '公共空间';
    case AppView.profile:
      return profileUser?.displayName.isNotEmpty == true
          ? profileUser!.displayName
          : '个人主页';
    case AppView.postDetail:
      return currentPost?.title.isNotEmpty == true
          ? currentPost!.title
          : '文章详情';
    case AppView.levels:
      return '等级体系';
    case AppView.subscription:
      return '订阅计划';
    case AppView.blockchain:
      return '区块链接入';
    case AppView.friends:
      return '好友关系';
    case AppView.chat:
      return '实时聊天';
  }
}

String pageSubtitleForView(AppView view) {
  switch (view) {
    case AppView.dashboard:
      return '汇总账号、空间、订阅、好友与实时互动状态。';
    case AppView.privateSpace:
      return '管理仅自己可见的内容、草稿和私人空间。';
    case AppView.publicSpace:
      return '发布公开内容、查看广场动态并打开作者主页。';
    case AppView.profile:
      return '查看用户资料、关系状态和历史文章。';
    case AppView.postDetail:
      return '查看完整正文、评论和互动统计。';
    case AppView.levels:
      return '等级与计划联动，决定展示身份和能力范围。';
    case AppView.subscription:
      return '管理当前会员计划和续费动作。';
    case AppView.blockchain:
      return '绑定链上账号并查看已连接链摘要。';
    case AppView.friends:
      return '搜索用户、发起好友请求并处理待接受关系。';
    case AppView.chat:
      return '查看会话摘要并发送实时消息。';
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
      return 'levels';
    case AppView.subscription:
      return 'subscription';
    case AppView.blockchain:
      return 'blockchain';
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
