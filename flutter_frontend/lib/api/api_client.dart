import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

List<Map<String, dynamic>> _serializePostMediaItems(
  List<PostAttachmentDraft> mediaItems,
) {
  // Convert post attachments into the shared request payload shape.
  // 将文章附件转换为共享的请求载荷格式。
  return mediaItems
      .where((item) => item.mediaData.isNotEmpty)
      .map((item) => item.toRequestJson())
      .toList();
}

class ApiClient {
  static const String accountBase = String.fromEnvironment(
    'ACCOUNT_API_BASE',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  static const String spaceBase = String.fromEnvironment(
    'SPACE_API_BASE',
    defaultValue: 'http://localhost:8082/api/v1',
  );
  static const String messageBase = String.fromEnvironment(
    'MESSAGE_API_BASE',
    defaultValue: 'http://localhost:8081/api/v1',
  );

  String? token;

  Uri wsUri(String token) {
    final parsed = Uri.parse(messageBase);
    final scheme = parsed.scheme == 'https' ? 'wss' : 'ws';
    return parsed.replace(
      scheme: scheme,
      path: '/ws',
      queryParameters: {'token': token},
    );
  }

  Future<AuthToken> login(String account, String password) async {
    final json = await _post(accountBase, '/login', {
      'account': account,
      'password': password,
    });
    return AuthToken.fromJson(json);
  }

  Future<AuthToken> register({
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await _post(accountBase, '/register', {
      'email': email,
      'phone': phone,
      'password': password,
    });
    return AuthToken.fromJson(json);
  }

  Future<void> logout() async {
    await _post(accountBase, '/logout', {});
  }

  Future<CurrentUser> fetchMe() async =>
      CurrentUser.fromJson(await _get(accountBase, '/me'));

  Future<CurrentUser> updateProfile({
    required String displayName,
    required String username,
    required String domain,
    required String signature,
    String phoneVisibility = '',
    String emailVisibility = '',
    String ageVisibility = '',
    String genderVisibility = '',
  }) async => CurrentUser.fromJson(
    await _put(accountBase, '/me', {
      'display_name': displayName,
      'username': username,
      'domain': domain,
      'signature': signature,
      if (phoneVisibility.isNotEmpty) 'phone_visibility': phoneVisibility,
      if (emailVisibility.isNotEmpty) 'email_visibility': emailVisibility,
      if (ageVisibility.isNotEmpty) 'age_visibility': ageVisibility,
      if (genderVisibility.isNotEmpty) 'gender_visibility': genderVisibility,
    }),
  );

  Future<List<SpaceItem>> listSpaces() async =>
      _list(await _get(spaceBase, '/spaces'), SpaceItem.fromJson);

  Future<List<SpaceItem>> listUserSpaces(
    String userId, {
    String visibility = 'public',
  }) async {
    final encoded = Uri.encodeComponent(userId);
    final scopedVisibility = Uri.encodeQueryComponent(visibility);
    return _list(
      await _get(
        spaceBase,
        '/users/$encoded/spaces?visibility=$scopedVisibility',
      ),
      SpaceItem.fromJson,
    );
  }

  Future<SpaceItem> createSpace({
    required String type,
    required String visibility,
    required String name,
    required String description,
    String? subdomain,
  }) async {
    final body = {
      'type': type,
      'visibility': visibility,
      'name': name,
      'description': description,
      if ((subdomain ?? '').trim().isNotEmpty) 'subdomain': subdomain!.trim(),
    };
    return SpaceItem.fromJson(await _post(spaceBase, '/spaces', body));
  }

  Future<SpaceItem> updateSpace({
    required String id,
    required String name,
    required String description,
    required String subdomain,
    required String visibility,
  }) async {
    return SpaceItem.fromJson(
      await _patch(spaceBase, '/spaces/$id', {
        'name': name,
        'description': description,
        'subdomain': subdomain,
        'visibility': visibility,
      }),
    );
  }

  Future<void> deleteSpace(String id) async {
    await _delete(spaceBase, '/spaces/$id');
  }

  Future<List<PostItem>> listPosts({
    String visibility = 'public',
    int limit = 50,
  }) async {
    return _list(
      await _get(spaceBase, '/posts?visibility=$visibility&limit=$limit'),
      PostItem.fromJson,
    );
  }

  Future<List<PostItem>> listUserPosts(
    String userId, {
    String visibility = 'public',
    int limit = 50,
  }) async {
    return _list(
      await _get(
        spaceBase,
        '/users/$userId/posts?visibility=$visibility&limit=$limit',
      ),
      PostItem.fromJson,
    );
  }

  Future<PostItem> getPost(String id) async =>
      PostItem.fromJson(await _get(spaceBase, '/posts/$id'));

  Future<PostItem> createPost({
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
    final payloadItems = _serializePostMediaItems(mediaItems);
    final hasLegacyMedia =
        mediaType.trim().isNotEmpty ||
        mediaName.trim().isNotEmpty ||
        mediaMime.trim().isNotEmpty ||
        mediaData.trim().isNotEmpty;
    final primaryMedia = payloadItems.isNotEmpty
        ? payloadItems.first
        : (hasLegacyMedia
              ? {
                  'media_type': mediaType.trim(),
                  'media_name': mediaName.trim(),
                  'media_mime': mediaMime.trim(),
                  'media_data': mediaData.trim(),
                }
              : null);
    final body = {
      'title': title,
      'content': content,
      'visibility': visibility,
      'status': status,
      if ((spaceId ?? '').trim().isNotEmpty) 'space_id': spaceId!.trim(),
      if (payloadItems.isNotEmpty) 'media_items': payloadItems,
      if (primaryMedia != null &&
          (primaryMedia['media_type'] as String).trim().isNotEmpty)
        'media_type': primaryMedia['media_type'],
      if (primaryMedia != null &&
          (primaryMedia['media_name'] as String).trim().isNotEmpty)
        'media_name': primaryMedia['media_name'],
      if (primaryMedia != null &&
          (primaryMedia['media_mime'] as String).trim().isNotEmpty)
        'media_mime': primaryMedia['media_mime'],
      if (primaryMedia != null &&
          (primaryMedia['media_data'] as String).trim().isNotEmpty)
        'media_data': primaryMedia['media_data'],
    };
    return PostItem.fromJson(await _post(spaceBase, '/posts', body));
  }

  Future<PostItem> updatePost({
    required String id,
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
    bool clearMedia = false,
  }) async {
    final payloadItems = _serializePostMediaItems(mediaItems);
    final hasLegacyMedia =
        mediaType.trim().isNotEmpty ||
        mediaName.trim().isNotEmpty ||
        mediaMime.trim().isNotEmpty ||
        mediaData.trim().isNotEmpty;
    final primaryMedia = payloadItems.isNotEmpty
        ? payloadItems.first
        : (hasLegacyMedia
              ? {
                  'media_type': mediaType.trim(),
                  'media_name': mediaName.trim(),
                  'media_mime': mediaMime.trim(),
                  'media_data': mediaData.trim(),
                }
              : null);
    final body = {
      'title': title,
      'content': content,
      'visibility': visibility,
      'status': status,
      if ((spaceId ?? '').trim().isNotEmpty) 'space_id': spaceId!.trim(),
      if (payloadItems.isNotEmpty) 'media_items': payloadItems,
      if (primaryMedia != null &&
          (primaryMedia['media_type'] as String).trim().isNotEmpty)
        'media_type': primaryMedia['media_type'],
      if (primaryMedia != null &&
          (primaryMedia['media_name'] as String).trim().isNotEmpty)
        'media_name': primaryMedia['media_name'],
      if (primaryMedia != null &&
          (primaryMedia['media_mime'] as String).trim().isNotEmpty)
        'media_mime': primaryMedia['media_mime'],
      if (primaryMedia != null &&
          (primaryMedia['media_data'] as String).trim().isNotEmpty)
        'media_data': primaryMedia['media_data'],
      if (clearMedia) 'clear_media': true,
    };
    return PostItem.fromJson(await _patch(spaceBase, '/posts/$id', body));
  }

  Future<void> deletePost(String id) async {
    await _delete(spaceBase, '/posts/$id');
  }

  Future<PostItem> toggleLike(String id) async =>
      PostItem.fromJson(await _post(spaceBase, '/posts/$id/likes', {}));

  Future<PostItem> commentPost(String id, String content) async =>
      PostItem.fromJson(
        await _post(spaceBase, '/posts/$id/comments', {'content': content}),
      );

  Future<PostItem> sharePost(String id) async =>
      PostItem.fromJson(await _post(spaceBase, '/posts/$id/shares', {}));

  Future<List<PostItem>> listSpacePosts(
    String spaceId, {
    String visibility = 'all',
    int limit = 50,
  }) async {
    final encoded = Uri.encodeComponent(spaceId);
    final query = Uri(
      queryParameters: {'visibility': visibility, 'limit': '$limit'},
    ).query;
    return _list(
      await _get(spaceBase, '/spaces/$encoded/posts?$query'),
      PostItem.fromJson,
    );
  }

  Future<List<FriendItem>> listFriends() async =>
      _list(await _get(accountBase, '/friends'), FriendItem.fromJson);

  Future<List<UserSearchItem>> searchUsers(String query) async {
    if (query.isEmpty) {
      return const [];
    }
    final encoded = Uri.encodeQueryComponent(query);
    return _list(
      await _get(accountBase, '/users/search?q=$encoded'),
      UserSearchItem.fromJson,
    );
  }

  Future<UserProfileItem> fetchUserProfile(String userId) async =>
      UserProfileItem.fromJson(
        await _get(accountBase, '/users/$userId/profile'),
      );

  Future<UserProfileItem> fetchUserProfileByUsername(String username) async =>
      UserProfileItem.fromJson(
        await _get(
          accountBase,
          '/users/username/${Uri.encodeComponent(username)}/profile',
        ),
      );

  Future<UserProfileItem> fetchUserProfileByDomain(String domain) async =>
      UserProfileItem.fromJson(
        await _get(
          accountBase,
          '/users/domain/${Uri.encodeComponent(domain)}/profile',
        ),
      );

  Future<void> addFriend(String friendId) async {
    await _post(accountBase, '/friends', {'friend_id': friendId});
  }

  Future<void> acceptFriend(String friendId) async {
    await _post(accountBase, '/friends/accept', {'friend_id': friendId});
  }

  Future<List<ConversationItem>> listConversations() async => _list(
    await _get(messageBase, '/conversations'),
    ConversationItem.fromJson,
  );

  Future<List<ChatMessage>> listMessages(String peerId) async {
    final encoded = Uri.encodeQueryComponent(peerId);
    return _list(
      await _get(messageBase, '/messages?peer_id=$encoded&limit=100&offset=0'),
      ChatMessage.fromJson,
    );
  }

  Future<void> sendMessage({
    required String peerId,
    String content = '',
    String messageType = 'text',
    String mediaName = '',
    String mediaMime = '',
    String mediaData = '',
    int expiresInMinutes = 0,
  }) async {
    await _post(messageBase, '/messages', {
      'peer_id': peerId,
      'content': content,
      'message_type': messageType,
      'media_name': mediaName,
      'media_mime': mediaMime,
      'media_data': mediaData,
      'expires_in_minutes': expiresInMinutes,
    });
  }

  Future<void> activateMembershipLevel(String planId) async {
    // Keep the billing call internal so the UI only talks about membership levels.
    // 保留账单接口的内部调用，让界面只展示会员等级概念。
    await _post(accountBase, '/subscriptions', {'plan_id': planId});
  }

  Future<List<ExternalAccountItem>> listExternalAccounts() async => _list(
    await _get(accountBase, '/external-accounts'),
    ExternalAccountItem.fromJson,
  );

  Future<void> bindExternalAccount({
    required String provider,
    required String chain,
    required String address,
    required String signature,
  }) async {
    await _post(accountBase, '/external-accounts', {
      'provider': provider,
      'chain': chain,
      'account_address': address,
      'signature_payload': signature,
    });
  }

  Future<void> deleteExternalAccount(String id) async {
    await _delete(accountBase, '/external-accounts/$id');
  }

  Future<Map<String, dynamic>> _get(String base, String path) async {
    final response = await http.get(
      Uri.parse('$base$path'),
      headers: _headers(),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String base,
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$base$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _put(
    String base,
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$base$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _patch(
    String base,
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse('$base$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _delete(String base, String path) async {
    final response = await http.delete(
      Uri.parse('$base$path'),
      headers: _headers(),
    );
    return _decode(response);
  }

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    final tokenValue = token;
    if (tokenValue != null && tokenValue.isNotEmpty) {
      headers['Authorization'] = 'Bearer $tokenValue';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(
        (body['error'] ?? body['message'] ?? 'request failed').toString(),
      );
    }
    return body;
  }

  List<T> _list<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) convert,
  ) {
    final items = (json['items'] as List<dynamic>? ?? const []);
    return items.map((item) => convert(item as Map<String, dynamic>)).toList();
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
