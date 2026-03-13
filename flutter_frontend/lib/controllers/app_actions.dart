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
    required this.subscription,
    required this.externalAccounts,
  });

  final CurrentUser user;
  final List<SpaceItem> spaces;
  final List<PostItem> publicPosts;
  final List<PostItem> privatePosts;
  final List<FriendItem> friends;
  final List<ConversationItem> conversations;
  final SubscriptionItem? subscription;
  final List<ExternalAccountItem> externalAccounts;
}

class ProfileBundle {
  const ProfileBundle({required this.profileUser, required this.posts});

  final UserProfileItem profileUser;
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

class SubscriptionBundle {
  const SubscriptionBundle({required this.subscription, required this.user});

  final SubscriptionItem subscription;
  final CurrentUser user;
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
      api.fetchSubscription(),
      api.listExternalAccounts(),
    ]);

    return DashboardBundle(
      user: user,
      spaces: results[0] as List<SpaceItem>,
      publicPosts: results[1] as List<PostItem>,
      privatePosts: results[2] as List<PostItem>,
      friends: results[3] as List<FriendItem>,
      conversations: results[4] as List<ConversationItem>,
      subscription: results[5] as SubscriptionItem?,
      externalAccounts: results[6] as List<ExternalAccountItem>,
    );
  }

  static Future<ProfileBundle> loadProfile(
    ApiClient api, {
    required String userId,
    required bool ownProfile,
  }) async {
    final results = await Future.wait([
      api.fetchUserProfile(userId),
      api.listUserPosts(
        userId,
        visibility: ownProfile ? 'all' : 'public',
        limit: 50,
      ),
    ]);

    return ProfileBundle(
      profileUser: results[0] as UserProfileItem,
      posts: results[1] as List<PostItem>,
    );
  }

  static Future<PostDetailBundle> loadPostDetail(
    ApiClient api,
    String postId,
  ) async {
    return PostDetailBundle(post: await api.getPost(postId));
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
    required String content,
  }) async {
    await api.sendMessage(peerId, content);
    final results = await Future.wait([
      api.listMessages(peerId),
      api.listConversations(),
    ]);
    return ChatBundle(
      messages: results[0] as List<ChatMessage>,
      conversations: results[1] as List<ConversationItem>,
    );
  }

  static Future<SubscriptionBundle> activatePlan(
    ApiClient api,
    String planId,
  ) async {
    final results = await Future.wait([
      api.activateSubscription(planId),
      api.fetchMe(),
    ]);
    return SubscriptionBundle(
      subscription: results[0] as SubscriptionItem,
      user: results[1] as CurrentUser,
    );
  }
}
