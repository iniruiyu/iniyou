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
    required this.username,
    required this.domain,
    required this.displayName,
    required this.signature,
    required this.age,
    required this.gender,
    required this.phoneVisibility,
    required this.emailVisibility,
    required this.ageVisibility,
    required this.genderVisibility,
    required this.level,
    required this.status,
  });

  final String id;
  final String email;
  final String phone;
  final String username;
  final String domain;
  final String displayName;
  final String signature;
  final int? age;
  final String gender;
  final String phoneVisibility;
  final String emailVisibility;
  final String ageVisibility;
  final String genderVisibility;
  final String level;
  final String status;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: (json['user_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      domain: (json['domain'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      signature: (json['signature'] ?? '').toString(),
      age: json['age'] is int ? json['age'] as int : int.tryParse((json['age'] ?? '').toString()),
      gender: (json['gender'] ?? '').toString(),
      phoneVisibility: (json['phone_visibility'] ?? 'private').toString(),
      emailVisibility: (json['email_visibility'] ?? 'private').toString(),
      ageVisibility: (json['age_visibility'] ?? 'private').toString(),
      genderVisibility: (json['gender_visibility'] ?? 'private').toString(),
      level: (json['level'] ?? 'basic').toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

class UserProfileItem {
  UserProfileItem({
    required this.id,
    required this.displayName,
    required this.username,
    required this.domain,
    required this.signature,
    required this.email,
    required this.phone,
    required this.age,
    required this.gender,
    required this.status,
    required this.relationStatus,
    required this.direction,
  });

  final String id;
  final String displayName;
  final String username;
  final String domain;
  final String signature;
  final String email;
  final String phone;
  final int? age;
  final String gender;
  final String status;
  final String relationStatus;
  final String direction;

  factory UserProfileItem.fromJson(Map<String, dynamic> json) {
    return UserProfileItem(
      id: (json['user_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      domain: (json['domain'] ?? '').toString(),
      signature: (json['signature'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      age: json['age'] is int ? json['age'] as int : int.tryParse((json['age'] ?? '').toString()),
      gender: (json['gender'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      relationStatus: (json['relation_status'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
    );
  }

  factory UserProfileItem.fromCurrentUser(CurrentUser user) {
    return UserProfileItem(
      id: user.id,
      displayName: user.displayName,
      username: user.username,
      domain: user.domain,
      signature: user.signature,
      email: user.email,
      phone: user.phone,
      age: user.age,
      gender: user.gender,
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
    required this.subdomain,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String type;
  final String subdomain;
  final String name;
  final String description;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublic => type == 'public';
  bool get isPrivate => type == 'private';
  String get spaceLabel => subdomain.isEmpty ? name : '$name · @$subdomain';

  factory SpaceItem.fromJson(Map<String, dynamic> json) {
    return SpaceItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      subdomain: (json['subdomain'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }
}

class PostItem {
  PostItem({
    required this.id,
    required this.userId,
    required this.spaceId,
    required this.spaceName,
    required this.spaceSubdomain,
    required this.spaceType,
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
  final String spaceId;
  final String spaceName;
  final String spaceSubdomain;
  final String spaceType;
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
  String get spaceLabel {
    if (spaceName.isNotEmpty && spaceSubdomain.isNotEmpty) {
      return '$spaceName · @$spaceSubdomain';
    }
    if (spaceName.isNotEmpty) {
      return spaceName;
    }
    if (spaceSubdomain.isNotEmpty) {
      return '@$spaceSubdomain';
    }
    return spaceType.isNotEmpty ? spaceType : visibility;
  }

  factory PostItem.fromJson(Map<String, dynamic> json) {
    final comments = (json['comments'] as List<dynamic>? ?? const [])
        .map((item) => PostComment.fromJson(item as Map<String, dynamic>))
        .toList();
    return PostItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      spaceId: (json['space_id'] ?? '').toString(),
      spaceName: (json['space_name'] ?? '').toString(),
      spaceSubdomain: (json['space_subdomain'] ?? '').toString(),
      spaceType: (json['space_type'] ?? '').toString(),
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
    required this.username,
    required this.email,
    required this.phone,
    required this.status,
    required this.direction,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String username;
  final String email;
  final String phone;
  final String status;
  final String direction;
  final DateTime createdAt;

  String get secondary {
    final parts = <String>[];
    if (username.isNotEmpty) {
      parts.add('@$username');
    }
    if (email.isNotEmpty) {
      parts.add(email);
    }
    if (phone.isNotEmpty) {
      parts.add(phone);
    }
    return parts.join(' · ');
  }

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    return FriendItem(
      id: (json['friend_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class UserSearchItem {
  UserSearchItem({
    required this.id,
    required this.displayName,
    required this.username,
    required this.email,
    required this.phone,
    required this.relationStatus,
    required this.direction,
  });

  final String id;
  final String displayName;
  final String username;
  final String email;
  final String phone;
  final String relationStatus;
  final String direction;

  String get secondary {
    final parts = <String>[];
    if (username.isNotEmpty) {
      parts.add('@$username');
    }
    if (email.isNotEmpty) {
      parts.add(email);
    }
    if (phone.isNotEmpty) {
      parts.add(phone);
    }
    return parts.join(' · ');
  }

  factory UserSearchItem.fromJson(Map<String, dynamic> json) {
    return UserSearchItem(
      id: (json['user_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
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
    required this.lastMessageType,
    required this.lastMessagePreview,
    required this.lastAt,
    required this.unreadCount,
  });

  final String peerId;
  final String lastMessage;
  final String lastMessageType;
  final String lastMessagePreview;
  final DateTime lastAt;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      peerId: (json['peer_id'] ?? '').toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      lastMessageType: (json['last_message_type'] ?? 'text').toString(),
      lastMessagePreview: (json['last_message_preview'] ?? '').toString(),
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
    required this.messageType,
    required this.content,
    required this.mediaName,
    required this.mediaMime,
    required this.mediaData,
    required this.createdAt,
    required this.readAt,
    required this.expiresAt,
  });

  final String id;
  final String from;
  final String to;
  final String messageType;
  final String content;
  final String mediaName;
  final String mediaMime;
  final String mediaData;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  String get createdAtLabel => formatDateTime(createdAt);
  bool get hasMedia => messageType != 'text' && mediaData.isNotEmpty;
  bool get isImage => messageType == 'image';
  bool get isVideo => messageType == 'video';
  bool get isAudio => messageType == 'audio';
  bool get isSticker =>
      messageType == 'text' && chatStickerTokens.contains(content.trim());
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  String get mediaLabel =>
      mediaName.isNotEmpty ? mediaName : messageType.toUpperCase();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? json['ID'] ?? '').toString(),
      from: (json['sender_id'] ?? json['SenderID'] ?? json['from'] ?? '')
          .toString(),
      to: (json['receiver_id'] ?? json['ReceiverID'] ?? json['to'] ?? '')
          .toString(),
      messageType: (json['message_type'] ?? json['MessageType'] ?? 'text')
          .toString(),
      content: (json['content'] ?? json['Content'] ?? '').toString(),
      mediaName: (json['media_name'] ?? json['MediaName'] ?? '').toString(),
      mediaMime: (json['media_mime'] ?? json['MediaMime'] ?? '').toString(),
      mediaData: (json['media_data'] ?? json['MediaData'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(
            (json['created_at'] ?? json['CreatedAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      readAt: DateTime.tryParse(
        (json['read_at'] ?? json['ReadAt'] ?? '').toString(),
      ),
      expiresAt: DateTime.tryParse(
        (json['expires_at'] ?? json['ExpiresAt'] ?? '').toString(),
      ),
    );
  }
}

// Keep the sticker token set centralized so both chat frontends render it the same way.
// 将贴纸 token 集中维护，保证双端聊天前端采用一致渲染规则。
const Set<String> chatStickerTokens = {
  '【开心】',
  '【加油】',
  '【收到】',
  '【抱抱】',
  '【赞】',
  '【感谢】',
};

class ChatAttachmentDraft {
  ChatAttachmentDraft({
    required this.messageType,
    required this.mediaName,
    required this.mediaMime,
    required this.mediaData,
    required this.originalSizeBytes,
  });

  final String messageType;
  final String mediaName;
  final String mediaMime;
  final String mediaData;
  final int originalSizeBytes;

  bool get isMedia => messageType != 'text';
  String get sizeLabel => formatByteSize(originalSizeBytes);
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

String formatByteSize(int bytes) {
  if (bytes < 1024) {
    return '${bytes}B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)}KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}
