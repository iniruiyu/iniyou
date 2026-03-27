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

  static Future<List<T>> _safeList<T>(Future<List<T>> future) async {
    // Convert optional service failures into empty lists instead of hard errors.
    // 将可选微服务失败转换为空列表，而不是直接抛错。
    try {
      return await future;
    } catch (_) {
      return <T>[];
    }
  }

  static Future<DashboardBundle> loadDashboard(
    ApiClient api, {
    bool spaceServiceOnline = true,
    bool messageServiceOnline = true,
  }) async {
    final user = await api.fetchMe();

    return DashboardBundle(
      user: user,
      spaces: spaceServiceOnline
          ? await _safeList(api.listSpaces())
          : <SpaceItem>[],
      publicPosts: spaceServiceOnline
          ? await _safeList(api.listPosts(visibility: 'public', limit: 50))
          : <PostItem>[],
      privatePosts: spaceServiceOnline
          ? await _safeList(api.listPosts(visibility: 'private', limit: 50))
          : <PostItem>[],
      friends: await _safeList(api.listFriends()),
      conversations: messageServiceOnline
          ? await _safeList(api.listConversations())
          : <ConversationItem>[],
      externalAccounts: await _safeList(api.listExternalAccounts()),
    );
  }

  static Future<ProfileBundle> loadProfile(
    ApiClient api, {
    required String userId,
    required bool ownProfile,
    bool spaceServiceOnline = true,
  }) async {
    return ProfileBundle(
      profileUser: await api.fetchUserProfile(userId),
      spaces: spaceServiceOnline
          ? await _safeList(
              // Profile pages only surface public spaces, even on the owner's page.
              // 个人主页只展示公开空间，即使是自己的主页也保持一致。
              api.listUserSpaces(userId, visibility: 'public'),
            )
          : <SpaceItem>[],
      posts: spaceServiceOnline
          ? await _safeList(
              api.listUserPosts(
                userId,
                visibility: ownProfile ? 'all' : 'public',
                limit: 50,
              ),
            )
          : <PostItem>[],
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
    List<PostAttachmentDraft> mediaItems = const [],
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
      mediaItems: mediaItems,
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
    return FriendSearchBundle(
      friends: await _safeList(api.listFriends()),
      searchResults: await _safeList(api.searchUsers(query)),
    );
  }

  static Future<FriendsBundle> acceptFriendAndReload(
    ApiClient api,
    String friendId,
  ) async {
    await api.acceptFriend(friendId);
    return FriendsBundle(
      friends: await _safeList(api.listFriends()),
      conversations: await _safeList(api.listConversations()),
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
    return ChatBundle(
      messages: await _safeList(api.listMessages(peerId)),
      conversations: await _safeList(api.listConversations()),
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
