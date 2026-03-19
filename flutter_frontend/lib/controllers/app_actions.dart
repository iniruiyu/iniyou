import '../api/api_client.dart';
import '../models/app_models.dart';

class DashboardBundle {
  const DashboardBundle({
    required this.user,
    required this.spaces,
    required this.publicPosts,
    required this.privatePosts,
    required this.friends,
    required this.conversations,
    required this.externalAccounts,
  });

  final CurrentUser user;
  final List<SpaceItem> spaces;
  final List<PostItem> publicPosts;
  final List<PostItem> privatePosts;
  final List<FriendItem> friends;
  final List<ConversationItem> conversations;
  final List<ExternalAccountItem> externalAccounts;
}

class ProfileBundle {
  const ProfileBundle({
    required this.profileUser,
    required this.spaces,
    required this.posts,
  });

  final UserProfileItem profileUser;
  final List<SpaceItem> spaces;
  final List<PostItem> posts;
}

class PostDetailBundle {
  const PostDetailBundle({required this.post});

  final PostItem post;
}

class FriendSearchBundle {
  const FriendSearchBundle({
    required this.friends,
    required this.searchResults,
  });

  final List<FriendItem> friends;
  final List<UserSearchItem> searchResults;
}

class FriendsBundle {
  const FriendsBundle({required this.friends, required this.conversations});

  final List<FriendItem> friends;
  final List<ConversationItem> conversations;
}

class ChatBundle {
  const ChatBundle({required this.messages, required this.conversations});

  final List<ChatMessage> messages;
  final List<ConversationItem> conversations;
}

class PostPublishBundle {
  const PostPublishBundle({required this.post, required this.posts});

  final PostItem post;
  final List<PostItem> posts;
}

class SpaceCreateBundle {
  const SpaceCreateBundle({required this.space, required this.spaces});

  final SpaceItem space;
  final List<SpaceItem> spaces;
}

class AppActions {
  const AppActions._();

  static Future<DashboardBundle> loadDashboard(ApiClient api) async {
    final user = await api.fetchMe();
    final results = await Future.wait([
      api.listSpaces(),
      api.listPosts(visibility: 'public', limit: 50),
      api.listPosts(visibility: 'private', limit: 50),
      api.listFriends(),
      api.listConversations(),
      api.listExternalAccounts(),
    ]);

    return DashboardBundle(
      user: user,
      spaces: results[0] as List<SpaceItem>,
      publicPosts: results[1] as List<PostItem>,
      privatePosts: results[2] as List<PostItem>,
      friends: results[3] as List<FriendItem>,
      conversations: results[4] as List<ConversationItem>,
      externalAccounts: results[5] as List<ExternalAccountItem>,
    );
  }

  static Future<ProfileBundle> loadProfile(
    ApiClient api, {
    required String userId,
    required bool ownProfile,
  }) async {
    final results = await Future.wait([
      api.fetchUserProfile(userId),
      // Profile pages only surface public spaces, even on the owner's page.
      // 个人主页只展示公开空间，即使是自己的主页也保持一致。
      api.listUserSpaces(userId, visibility: 'public'),
      api.listUserPosts(
        userId,
        visibility: ownProfile ? 'all' : 'public',
        limit: 50,
      ),
    ]);

    return ProfileBundle(
      profileUser: results[0] as UserProfileItem,
      spaces: results[1] as List<SpaceItem>,
      posts: results[2] as List<PostItem>,
    );
  }

  static Future<PostDetailBundle> loadPostDetail(
    ApiClient api,
    String postId,
  ) async {
    return PostDetailBundle(post: await api.getPost(postId));
  }

  static Future<SpaceCreateBundle> createSpaceAndReload(
    ApiClient api, {
    required String type,
    required String visibility,
    required String name,
    required String description,
    String? subdomain,
  }) async {
    final created = await api.createSpace(
      type: type,
      visibility: visibility,
      name: name,
      description: description,
      subdomain: subdomain,
    );
    return SpaceCreateBundle(space: created, spaces: await api.listSpaces());
  }

  static Future<PostPublishBundle> createPostAndReload(
    ApiClient api, {
    required String title,
    required String content,
    required String visibility,
    required String status,
    String? spaceId,
    String mediaType = '',
    String mediaName = '',
    String mediaMime = '',
    String mediaData = '',
  }) async {
    final post = await api.createPost(
      title: title,
      content: content,
      visibility: visibility,
      status: status,
      spaceId: spaceId,
      mediaType: mediaType,
      mediaName: mediaName,
      mediaMime: mediaMime,
      mediaData: mediaData,
    );
    return PostPublishBundle(
      post: post,
      posts: await api.listPosts(visibility: visibility, limit: 50),
    );
  }

  static Future<FriendSearchBundle> addFriendAndReload(
    ApiClient api, {
    required String friendId,
    required String query,
  }) async {
    await api.addFriend(friendId);
    final results = await Future.wait([
      api.listFriends(),
      api.searchUsers(query),
    ]);
    return FriendSearchBundle(
      friends: results[0] as List<FriendItem>,
      searchResults: results[1] as List<UserSearchItem>,
    );
  }

  static Future<FriendsBundle> acceptFriendAndReload(
    ApiClient api,
    String friendId,
  ) async {
    await api.acceptFriend(friendId);
    final results = await Future.wait([
      api.listFriends(),
      api.listConversations(),
    ]);
    return FriendsBundle(
      friends: results[0] as List<FriendItem>,
      conversations: results[1] as List<ConversationItem>,
    );
  }

  static Future<List<ChatMessage>> loadMessages(
    ApiClient api,
    String peerId,
  ) async {
    return api.listMessages(peerId);
  }

  static Future<ChatBundle> sendMessageAndReload(
    ApiClient api, {
    required String peerId,
    String content = '',
    String messageType = 'text',
    String mediaName = '',
    String mediaMime = '',
    String mediaData = '',
    int expiresInMinutes = 0,
  }) async {
    await api.sendMessage(
      peerId: peerId,
      content: content,
      messageType: messageType,
      mediaName: mediaName,
      mediaMime: mediaMime,
      mediaData: mediaData,
      expiresInMinutes: expiresInMinutes,
    );
    final results = await Future.wait([
      api.listMessages(peerId),
      api.listConversations(),
    ]);
    return ChatBundle(
      messages: results[0] as List<ChatMessage>,
      conversations: results[1] as List<ConversationItem>,
    );
  }

  static Future<CurrentUser> activatePlan(ApiClient api, String planId) async {
    // Upgrade the membership level and then refresh the account snapshot.
    // 升级会员等级后刷新账号快照，避免前端保留订阅对象。
    final results = await Future.wait([
      api.activateMembershipLevel(planId),
      api.fetchMe(),
    ]);
    return results[1] as CurrentUser;
  }

  static Future<List<ExternalAccountItem>> bindExternalAccountAndReload(
    ApiClient api, {
    required String provider,
    required String chain,
    required String address,
    required String signature,
  }) async {
    await api.bindExternalAccount(
      provider: provider,
      chain: chain,
      address: address,
      signature: signature,
    );
    return api.listExternalAccounts();
  }

  static Future<List<ExternalAccountItem>> removeExternalAccountAndReload(
    ApiClient api,
    String id,
  ) async {
    await api.deleteExternalAccount(id);
    return api.listExternalAccounts();
  }
}
