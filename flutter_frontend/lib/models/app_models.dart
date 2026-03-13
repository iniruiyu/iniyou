class AuthToken {
  AuthToken({required this.userId, required this.token});

  final String userId;
  final String token;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      userId: (json['user_id'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }
}

class CurrentUser {
  CurrentUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.displayName,
    required this.level,
    required this.status,
  });

  final String id;
  final String email;
  final String phone;
  final String displayName;
  final String level;
  final String status;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: (json['user_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      level: (json['level'] ?? 'basic').toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

class UserProfileItem {
  UserProfileItem({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.status,
    required this.relationStatus,
    required this.direction,
  });

  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String status;
  final String relationStatus;
  final String direction;

  factory UserProfileItem.fromJson(Map<String, dynamic> json) {
    return UserProfileItem(
      id: (json['user_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      relationStatus: (json['relation_status'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
    );
  }

  factory UserProfileItem.fromCurrentUser(CurrentUser user) {
    return UserProfileItem(
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      phone: user.phone,
      status: user.status,
      relationStatus: '',
      direction: '',
    );
  }
}

class SpaceItem {
  SpaceItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.description,
  });

  final String id;
  final String userId;
  final String type;
  final String name;
  final String description;

  factory SpaceItem.fromJson(Map<String, dynamic> json) {
    return SpaceItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class PostItem {
  PostItem({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.status,
    required this.visibility,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.likedByMe,
    required this.createdAt,
    required this.comments,
  });

  final String id;
  final String userId;
  final String authorName;
  final String title;
  final String content;
  final String status;
  final String visibility;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool likedByMe;
  final DateTime createdAt;
  final List<PostComment> comments;

  String get createdAtLabel => formatDateTime(createdAt);

  factory PostItem.fromJson(Map<String, dynamic> json) {
    final comments = (json['comments'] as List<dynamic>? ?? const [])
        .map((item) => PostComment.fromJson(item as Map<String, dynamic>))
        .toList();
    return PostItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      authorName: (json['author_name'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      status: (json['status'] ?? 'published').toString(),
      visibility: (json['visibility'] ?? 'public').toString(),
      likesCount: toInt(json['likes_count']),
      commentsCount: toInt(json['comments_count']),
      sharesCount: toInt(json['shares_count']),
      likedByMe: (json['liked_by_me'] ?? false) as bool,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      comments: comments,
    );
  }
}

class PostComment {
  PostComment({
    required this.id,
    required this.authorName,
    required this.content,
  });

  final String id;
  final String authorName;
  final String content;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: (json['id'] ?? '').toString(),
      authorName: (json['author_name'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }
}

class FriendItem {
  FriendItem({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.status,
    required this.direction,
  });

  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String status;
  final String direction;

  String get secondary =>
      [email, phone].where((item) => item.isNotEmpty).join(' · ');

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    return FriendItem(
      id: (json['friend_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
    );
  }
}

class UserSearchItem {
  UserSearchItem({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.relationStatus,
    required this.direction,
  });

  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String relationStatus;
  final String direction;

  String get secondary =>
      [email, phone].where((item) => item.isNotEmpty).join(' · ');

  factory UserSearchItem.fromJson(Map<String, dynamic> json) {
    return UserSearchItem(
      id: (json['user_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      relationStatus: (json['relation_status'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
    );
  }
}

class ConversationItem {
  ConversationItem({
    required this.peerId,
    required this.lastMessage,
    required this.lastAt,
    required this.unreadCount,
  });

  final String peerId;
  final String lastMessage;
  final DateTime lastAt;
  final int unreadCount;

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      peerId: (json['peer_id'] ?? '').toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      lastAt:
          DateTime.tryParse((json['last_at'] ?? '').toString()) ??
          DateTime.now(),
      unreadCount: toInt(json['unread_count']),
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String from;
  final String to;
  final String content;
  final DateTime createdAt;

  String get createdAtLabel => formatDateTime(createdAt);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      from: (json['sender_id'] ?? json['from'] ?? '').toString(),
      to: (json['receiver_id'] ?? json['to'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class SubscriptionItem {
  SubscriptionItem({
    required this.planId,
    required this.status,
    required this.startedAt,
    required this.endedAt,
  });

  final String planId;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  String get startedAtLabel =>
      startedAt == null ? '-' : formatDateTime(startedAt!);
  String get endedAtLabel => endedAt == null ? '-' : formatDateTime(endedAt!);

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      planId: (json['plan_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startedAt: DateTime.tryParse((json['started_at'] ?? '').toString()),
      endedAt: DateTime.tryParse((json['ended_at'] ?? '').toString()),
    );
  }
}

class ExternalAccountItem {
  ExternalAccountItem({
    required this.id,
    required this.provider,
    required this.chain,
    required this.address,
    required this.bindingStatus,
    required this.createdAt,
  });

  final String id;
  final String provider;
  final String chain;
  final String address;
  final String bindingStatus;
  final DateTime createdAt;

  String get createdAtLabel => formatDateTime(createdAt);

  factory ExternalAccountItem.fromJson(Map<String, dynamic> json) {
    return ExternalAccountItem(
      id: (json['id'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      chain: (json['chain'] ?? '').toString(),
      address: (json['account_address'] ?? '').toString(),
      bindingStatus: (json['binding_status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

int toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse('$value') ?? 0;
}

String formatDateTime(DateTime time) {
  final local = time.toLocal();
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${pad(local.month)}-${pad(local.day)} ${pad(local.hour)}:${pad(local.minute)}';
}
