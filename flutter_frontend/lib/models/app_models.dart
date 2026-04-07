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

class MarkdownFileDocument {
  MarkdownFileDocument({
    required this.path,
    required this.content,
    required this.size,
    required this.updatedAt,
    required this.status,
  });

  final String path;
  final String content;
  final int size;
  final DateTime? updatedAt;
  final String status;

  factory MarkdownFileDocument.fromJson(Map<String, dynamic> json) {
    return MarkdownFileDocument(
      path: (json['path'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      size: toInt(json['size']),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class MarkdownFileSummary {
  MarkdownFileSummary({
    required this.path,
    required this.size,
    required this.updatedAt,
    required this.status,
  });

  final String path;
  final int size;
  final DateTime? updatedAt;
  final String status;

  factory MarkdownFileSummary.fromJson(Map<String, dynamic> json) {
    return MarkdownFileSummary(
      path: (json['path'] ?? '').toString(),
      size: toInt(json['size']),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class AdminOverview {
  AdminOverview({
    required this.totalServices,
    required this.onlineServices,
    required this.offlineServices,
    required this.adminWorkspaces,
    required this.degraded,
    required this.checkedAt,
    required this.services,
    required this.workspaces,
  });

  final int totalServices;
  final int onlineServices;
  final int offlineServices;
  final int adminWorkspaces;
  final bool degraded;
  final DateTime? checkedAt;
  final List<AdminServiceStatus> services;
  final List<AdminWorkspaceStatus> workspaces;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    final servicesJson = json['services'];
    final workspacesJson = json['workspaces'];
    return AdminOverview(
      totalServices: toInt(json['total_services']),
      onlineServices: toInt(json['online_services']),
      offlineServices: toInt(json['offline_services']),
      adminWorkspaces: toInt(json['admin_workspaces']),
      degraded: json['degraded'] == true,
      checkedAt: DateTime.tryParse((json['checked_at'] ?? '').toString()),
      services: servicesJson is List
          ? servicesJson
                .whereType<Map<String, dynamic>>()
                .map(AdminServiceStatus.fromJson)
                .toList()
          : const [],
      workspaces: workspacesJson is List
          ? workspacesJson
                .whereType<Map<String, dynamic>>()
                .map(AdminWorkspaceStatus.fromJson)
                .toList()
          : const [],
    );
  }
}

class AdminAccountOverview {
  AdminAccountOverview({
    required this.totalUsers,
    required this.adminUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.activeSubscriptions,
    required this.boundExternalAccounts,
    required this.recentUsers,
    required this.recentBindings,
  });

  final int totalUsers;
  final int adminUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int activeSubscriptions;
  final int boundExternalAccounts;
  final List<AdminAccountUserSummary> recentUsers;
  final List<AdminExternalAccountSummary> recentBindings;

  factory AdminAccountOverview.fromJson(Map<String, dynamic> json) {
    final recentUsersJson = json['recent_users'];
    final recentBindingsJson = json['recent_bindings'];
    return AdminAccountOverview(
      totalUsers: toInt(json['total_users']),
      adminUsers: toInt(json['admin_users']),
      activeUsers: toInt(json['active_users']),
      inactiveUsers: toInt(json['inactive_users']),
      activeSubscriptions: toInt(json['active_subscriptions']),
      boundExternalAccounts: toInt(json['bound_external_accounts']),
      recentUsers: recentUsersJson is List
          ? recentUsersJson
                .whereType<Map<String, dynamic>>()
                .map(AdminAccountUserSummary.fromJson)
                .toList()
          : const [],
      recentBindings: recentBindingsJson is List
          ? recentBindingsJson
                .whereType<Map<String, dynamic>>()
                .map(AdminExternalAccountSummary.fromJson)
                .toList()
          : const [],
    );
  }
}

class AdminAccountUserSummary {
  AdminAccountUserSummary({
    required this.id,
    required this.displayName,
    required this.username,
    required this.domain,
    required this.level,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String username;
  final String domain;
  final String level;
  final String status;
  final DateTime? createdAt;

  factory AdminAccountUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminAccountUserSummary(
      id: (json['id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      domain: (json['domain'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class AdminExternalAccountSummary {
  AdminExternalAccountSummary({
    required this.id,
    required this.userId,
    required this.userName,
    required this.provider,
    required this.chain,
    required this.accountAddress,
    required this.bindingStatus,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String provider;
  final String chain;
  final String accountAddress;
  final String bindingStatus;
  final DateTime? createdAt;

  factory AdminExternalAccountSummary.fromJson(Map<String, dynamic> json) {
    return AdminExternalAccountSummary(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      userName: (json['user_name'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      chain: (json['chain'] ?? '').toString(),
      accountAddress: (json['account_address'] ?? '').toString(),
      bindingStatus: (json['binding_status'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class AdminServiceStatus {
  AdminServiceStatus({
    required this.key,
    required this.title,
    required this.baseUrl,
    required this.healthUrl,
    required this.online,
    required this.required,
    required this.latencyMs,
    required this.workspaceKey,
  });

  final String key;
  final String title;
  final String baseUrl;
  final String healthUrl;
  final bool online;
  final bool required;
  final int latencyMs;
  final String workspaceKey;

  factory AdminServiceStatus.fromJson(Map<String, dynamic> json) {
    return AdminServiceStatus(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      baseUrl: (json['base_url'] ?? '').toString(),
      healthUrl: (json['health_url'] ?? '').toString(),
      online: json['online'] == true,
      required: json['required'] == true,
      latencyMs: toInt(json['latency_ms']),
      workspaceKey: (json['workspace_key'] ?? '').toString(),
    );
  }
}

class AdminWorkspaceStatus {
  AdminWorkspaceStatus({
    required this.key,
    required this.title,
    required this.serviceKey,
    required this.available,
  });

  final String key;
  final String title;
  final String serviceKey;
  final bool available;

  factory AdminWorkspaceStatus.fromJson(Map<String, dynamic> json) {
    return AdminWorkspaceStatus(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      serviceKey: (json['service_key'] ?? '').toString(),
      available: json['available'] == true,
    );
  }
}

class AdminSpaceOverview {
  AdminSpaceOverview({
    required this.totalSpaces,
    required this.activeSpaces,
    required this.privateSpaces,
    required this.publicSpaces,
    required this.totalPosts,
    required this.draftPosts,
    required this.publishedPosts,
    required this.archivedPosts,
    required this.recentSpaces,
    required this.recentPosts,
  });

  final int totalSpaces;
  final int activeSpaces;
  final int privateSpaces;
  final int publicSpaces;
  final int totalPosts;
  final int draftPosts;
  final int publishedPosts;
  final int archivedPosts;
  final List<AdminSpaceSummary> recentSpaces;
  final List<AdminPostSummary> recentPosts;

  factory AdminSpaceOverview.fromJson(Map<String, dynamic> json) {
    final recentSpacesJson = json['recent_spaces'];
    final recentPostsJson = json['recent_posts'];
    return AdminSpaceOverview(
      totalSpaces: toInt(json['total_spaces']),
      activeSpaces: toInt(json['active_spaces']),
      privateSpaces: toInt(json['private_spaces']),
      publicSpaces: toInt(json['public_spaces']),
      totalPosts: toInt(json['total_posts']),
      draftPosts: toInt(json['draft_posts']),
      publishedPosts: toInt(json['published_posts']),
      archivedPosts: toInt(json['archived_posts']),
      recentSpaces: recentSpacesJson is List
          ? recentSpacesJson
                .whereType<Map<String, dynamic>>()
                .map(AdminSpaceSummary.fromJson)
                .toList()
          : const [],
      recentPosts: recentPostsJson is List
          ? recentPostsJson
                .whereType<Map<String, dynamic>>()
                .map(AdminPostSummary.fromJson)
                .toList()
          : const [],
    );
  }
}

class AdminMessageOverview {
  AdminMessageOverview({
    required this.totalMessages,
    required this.unreadMessages,
    required this.activeConversations,
    required this.connectedFriends,
    required this.mediaMessages,
    required this.ephemeralMessages,
    required this.recentMessages,
    required this.recentConversations,
  });

  final int totalMessages;
  final int unreadMessages;
  final int activeConversations;
  final int connectedFriends;
  final int mediaMessages;
  final int ephemeralMessages;
  final List<AdminMessageSummary> recentMessages;
  final List<AdminConversationSummary> recentConversations;

  factory AdminMessageOverview.fromJson(Map<String, dynamic> json) {
    final recentMessagesJson = json['recent_messages'];
    final recentConversationsJson = json['recent_conversations'];
    return AdminMessageOverview(
      totalMessages: toInt(json['total_messages']),
      unreadMessages: toInt(json['unread_messages']),
      activeConversations: toInt(json['active_conversations']),
      connectedFriends: toInt(json['connected_friends']),
      mediaMessages: toInt(json['media_messages']),
      ephemeralMessages: toInt(json['ephemeral_messages']),
      recentMessages: recentMessagesJson is List
          ? recentMessagesJson
                .whereType<Map<String, dynamic>>()
                .map(AdminMessageSummary.fromJson)
                .toList()
          : const [],
      recentConversations: recentConversationsJson is List
          ? recentConversationsJson
                .whereType<Map<String, dynamic>>()
                .map(AdminConversationSummary.fromJson)
                .toList()
          : const [],
    );
  }
}

class AdminMessageSummary {
  AdminMessageSummary({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.messageType,
    required this.preview,
    required this.readAt,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String messageType;
  final String preview;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory AdminMessageSummary.fromJson(Map<String, dynamic> json) {
    return AdminMessageSummary(
      id: (json['id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      senderName: (json['sender_name'] ?? '').toString(),
      receiverId: (json['receiver_id'] ?? '').toString(),
      receiverName: (json['receiver_name'] ?? '').toString(),
      messageType: (json['message_type'] ?? '').toString(),
      preview: (json['preview'] ?? '').toString(),
      readAt: DateTime.tryParse((json['read_at'] ?? '').toString()),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class AdminConversationSummary {
  AdminConversationSummary({
    required this.participantAId,
    required this.participantAName,
    required this.participantBId,
    required this.participantBName,
    required this.lastMessageType,
    required this.lastPreview,
    required this.lastAt,
    required this.messageCount,
    required this.unreadCount,
  });

  final String participantAId;
  final String participantAName;
  final String participantBId;
  final String participantBName;
  final String lastMessageType;
  final String lastPreview;
  final DateTime? lastAt;
  final int messageCount;
  final int unreadCount;

  factory AdminConversationSummary.fromJson(Map<String, dynamic> json) {
    return AdminConversationSummary(
      participantAId: (json['participant_a_id'] ?? '').toString(),
      participantAName: (json['participant_a_name'] ?? '').toString(),
      participantBId: (json['participant_b_id'] ?? '').toString(),
      participantBName: (json['participant_b_name'] ?? '').toString(),
      lastMessageType: (json['last_message_type'] ?? '').toString(),
      lastPreview: (json['last_preview'] ?? '').toString(),
      lastAt: DateTime.tryParse((json['last_at'] ?? '').toString()),
      messageCount: toInt(json['message_count']),
      unreadCount: toInt(json['unread_count']),
    );
  }
}

class AdminSpaceSummary {
  AdminSpaceSummary({
    required this.id,
    required this.name,
    required this.subdomain,
    required this.type,
    required this.visibility,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    required this.postsCount,
    required this.updatedAt,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String subdomain;
  final String type;
  final String visibility;
  final String status;
  final String ownerId;
  final String ownerName;
  final int postsCount;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  factory AdminSpaceSummary.fromJson(Map<String, dynamic> json) {
    return AdminSpaceSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      subdomain: (json['subdomain'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      visibility: (json['visibility'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      ownerId: (json['owner_id'] ?? '').toString(),
      ownerName: (json['owner_name'] ?? '').toString(),
      postsCount: toInt(json['posts_count']),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class AdminPostSummary {
  AdminPostSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.visibility,
    required this.authorId,
    required this.authorName,
    required this.spaceId,
    required this.spaceName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final String visibility;
  final String authorId;
  final String authorName;
  final String spaceId;
  final String spaceName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminPostSummary.fromJson(Map<String, dynamic> json) {
    return AdminPostSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      visibility: (json['visibility'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      authorName: (json['author_name'] ?? '').toString(),
      spaceId: (json['space_id'] ?? '').toString(),
      spaceName: (json['space_name'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }
}

class GoExecutionResult {
  GoExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.durationMs,
    required this.timedOut,
  });

  final String stdout;
  final String stderr;
  final int exitCode;
  final int durationMs;
  final bool timedOut;

  factory GoExecutionResult.fromJson(Map<String, dynamic> json) {
    return GoExecutionResult(
      stdout: (json['stdout'] ?? '').toString(),
      stderr: (json['stderr'] ?? '').toString(),
      exitCode: toInt(json['exit_code']),
      durationMs: toInt(json['duration_ms']),
      timedOut: json['timed_out'] == true,
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
    required this.avatarUrl,
    required this.signature,
    required this.birthDate,
    required this.birthday,
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
  final String avatarUrl;
  final String signature;
  final String birthDate;
  final String birthday;
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
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      signature: (json['signature'] ?? '').toString(),
      birthDate: (json['birth_date'] ?? '').toString(),
      birthday: (json['birthday'] ?? '').toString(),
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse((json['age'] ?? '').toString()),
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
    required this.avatarUrl,
    required this.signature,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.birthday,
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
  final String avatarUrl;
  final String signature;
  final String email;
  final String phone;
  final String birthDate;
  final String birthday;
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
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      signature: (json['signature'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      birthDate: (json['birth_date'] ?? '').toString(),
      birthday: (json['birthday'] ?? '').toString(),
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse((json['age'] ?? '').toString()),
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
      avatarUrl: user.avatarUrl,
      signature: user.signature,
      email: user.email,
      phone: user.phone,
      birthDate: user.birthDate,
      birthday: user.birthday,
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
    required this.visibility,
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
  final String visibility;
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
      visibility: (json['visibility'] ?? json['type'] ?? 'public').toString(),
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
    required this.spaceUserId,
    required this.spaceName,
    required this.spaceSubdomain,
    required this.spaceType,
    required this.authorName,
    required this.title,
    required this.content,
    required this.mediaType,
    required this.mediaName,
    required this.mediaMime,
    required this.mediaData,
    required this.mediaItems,
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
  final String spaceUserId;
  final String spaceName;
  final String spaceSubdomain;
  final String spaceType;
  final String authorName;
  final String title;
  final String content;
  final String mediaType;
  final String mediaName;
  final String mediaMime;
  final String mediaData;
  final List<PostAttachmentDraft> mediaItems;
  final String status;
  final String visibility;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool likedByMe;
  final DateTime createdAt;
  final List<PostComment> comments;

  String get createdAtLabel => formatDateTime(createdAt);
  String get mediaUrl {
    // Build a browser-friendly data URL for inline media previews.
    // 构建便于浏览器内联预览的 data URL。
    if (mediaItems.isNotEmpty) {
      return mediaItems.first.mediaUrl;
    }
    if (mediaData.isEmpty) {
      return '';
    }
    final mime = mediaMime.isNotEmpty ? mediaMime : 'application/octet-stream';
    return 'data:$mime;base64,$mediaData';
  }

  bool get hasMedia => mediaItems.isNotEmpty || mediaData.isNotEmpty;
  bool get isImage =>
      mediaItems.isNotEmpty ? mediaItems.first.isImage : mediaType == 'image';
  bool get isVideo =>
      mediaItems.isNotEmpty ? mediaItems.first.isVideo : mediaType == 'video';
  bool get hasMultipleMedia => mediaItems.length > 1;

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
    final mediaItems = _parsePostAttachmentItems(json);
    final primaryMedia = mediaItems.isNotEmpty
        ? mediaItems.first
        : PostAttachmentDraft.fromJson(json);
    return PostItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      spaceId: (json['space_id'] ?? '').toString(),
      spaceUserId: (json['space_user_id'] ?? '').toString(),
      spaceName: (json['space_name'] ?? '').toString(),
      spaceSubdomain: (json['space_subdomain'] ?? '').toString(),
      spaceType: (json['space_type'] ?? '').toString(),
      authorName: (json['author_name'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      mediaType: primaryMedia.mediaType.isNotEmpty
          ? primaryMedia.mediaType
          : (json['media_type'] ?? 'text').toString(),
      mediaName: primaryMedia.mediaName,
      mediaMime: primaryMedia.mediaMime,
      mediaData: primaryMedia.mediaData,
      mediaItems: List.unmodifiable(mediaItems),
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

List<PostAttachmentDraft> _parsePostAttachmentItems(Map<String, dynamic> json) {
  // Normalize the shared media_items payload and keep legacy single-media fallback.
  // 规范化共享的 media_items 载荷，并保留旧版单媒体字段回退。
  final rawItems = json['media_items'] ?? json['mediaItems'];
  final parsedItems = <PostAttachmentDraft>[];
  if (rawItems is List) {
    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        continue;
      }
      final attachment = PostAttachmentDraft.fromJson(
        rawItem.cast<String, dynamic>(),
      );
      if (attachment.mediaData.isNotEmpty) {
        parsedItems.add(attachment);
      }
    }
  }
  if (parsedItems.isNotEmpty) {
    return parsedItems;
  }
  final legacyAttachment = PostAttachmentDraft.fromJson(json);
  return legacyAttachment.mediaData.isNotEmpty ? [legacyAttachment] : [];
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
    // Keep friend list and search results on the public-summary path only.
    // 好友列表和搜索结果只保留公开摘要，不再默认拼出联系方式。
    final parts = <String>[];
    if (username.isNotEmpty) {
      parts.add('@$username');
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
    // Keep search cards on the public-summary path only.
    // 搜索卡片只保留公开摘要，不再默认拼出联系方式。
    final parts = <String>[];
    if (username.isNotEmpty) {
      parts.add('@$username');
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

class PostAttachmentDraft {
  PostAttachmentDraft({
    required this.mediaType,
    required this.mediaName,
    required this.mediaMime,
    required this.mediaData,
    required this.originalSizeBytes,
  });

  final String mediaType;
  final String mediaName;
  final String mediaMime;
  final String mediaData;
  final int originalSizeBytes;

  factory PostAttachmentDraft.fromJson(Map<String, dynamic> json) {
    // Parse either a backend media item or a legacy single-media payload.
    // 解析后端媒体项或旧版单媒体载荷。
    final mediaType = (json['media_type'] ?? json['mediaType'] ?? 'text')
        .toString();
    final mediaName = (json['media_name'] ?? json['mediaName'] ?? '')
        .toString();
    final mediaMime = (json['media_mime'] ?? json['mediaMime'] ?? '')
        .toString();
    final mediaData = (json['media_data'] ?? json['mediaData'] ?? '')
        .toString();
    final originalSizeBytes = toInt(
      json['original_size_bytes'] ?? json['originalSizeBytes'],
    );
    return PostAttachmentDraft(
      mediaType: mediaType,
      mediaName: mediaName,
      mediaMime: mediaMime,
      mediaData: mediaData,
      originalSizeBytes: originalSizeBytes > 0
          ? originalSizeBytes
          : (mediaData.isEmpty ? 0 : _estimateDecodedByteLength(mediaData)),
    );
  }

  bool get isMedia => mediaType.isNotEmpty;
  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
  String get sizeLabel => formatByteSize(originalSizeBytes);
  String get mediaUrl {
    // Reuse the raw payload as a data URL for preview and open actions.
    // 复用原始载荷生成 data URL，供预览和打开操作使用。
    if (mediaData.isEmpty) {
      return '';
    }
    final mime = mediaMime.isNotEmpty ? mediaMime : 'application/octet-stream';
    return 'data:$mime;base64,$mediaData';
  }

  Map<String, dynamic> toRequestJson() {
    // Serialize the attachment back into the shared API payload shape.
    // 将附件序列化回共享的 API 载荷格式。
    return {
      'media_type': mediaType,
      'media_name': mediaName,
      'media_mime': mediaMime,
      'media_data': mediaData,
    };
  }
}

int _estimateDecodedByteLength(String base64Data) {
  // Estimate decoded byte length from the base64 payload without a second decode.
  // 不再额外解码时，根据 base64 载荷估算原始字节长度。
  final normalized = base64Data.trim();
  if (normalized.isEmpty) {
    return 0;
  }
  final padding = normalized.endsWith('==')
      ? 2
      : normalized.endsWith('=')
      ? 1
      : 0;
  return ((normalized.length * 3) ~/ 4) - padding;
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
