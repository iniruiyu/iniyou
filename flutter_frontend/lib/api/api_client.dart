import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

class ApiClient {
  static const String accountBase = String.fromEnvironment(
    'ACCOUNT_API_BASE',
    defaultValue: 'http://localhost:8080/api/v1',
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

  Future<CurrentUser> updateProfile(String displayName) async =>
      CurrentUser.fromJson(
        await _put(accountBase, '/me', {'display_name': displayName}),
      );

  Future<List<SpaceItem>> listSpaces() async =>
      _list(await _get(accountBase, '/spaces'), SpaceItem.fromJson);

  Future<SpaceItem> createSpace({
    required String type,
    required String name,
    required String description,
  }) async {
    return SpaceItem.fromJson(
      await _post(accountBase, '/spaces', {
        'type': type,
        'name': name,
        'description': description,
      }),
    );
  }

  Future<List<PostItem>> listPosts({
    String visibility = 'public',
    int limit = 50,
  }) async {
    return _list(
      await _get(accountBase, '/posts?visibility=$visibility&limit=$limit'),
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
        accountBase,
        '/users/$userId/posts?visibility=$visibility&limit=$limit',
      ),
      PostItem.fromJson,
    );
  }

  Future<PostItem> getPost(String id) async =>
      PostItem.fromJson(await _get(accountBase, '/posts/$id'));

  Future<PostItem> createPost({
    required String title,
    required String content,
    required String visibility,
    required String status,
  }) async {
    return PostItem.fromJson(
      await _post(accountBase, '/posts', {
        'title': title,
        'content': content,
        'visibility': visibility,
        'status': status,
      }),
    );
  }

  Future<PostItem> updatePost({
    required String id,
    required String title,
    required String content,
    required String visibility,
    required String status,
  }) async {
    return PostItem.fromJson(
      await _patch(accountBase, '/posts/$id', {
        'title': title,
        'content': content,
        'visibility': visibility,
        'status': status,
      }),
    );
  }

  Future<PostItem> toggleLike(String id) async =>
      PostItem.fromJson(await _post(accountBase, '/posts/$id/likes', {}));

  Future<PostItem> commentPost(String id, String content) async =>
      PostItem.fromJson(
        await _post(accountBase, '/posts/$id/comments', {'content': content}),
      );

  Future<PostItem> sharePost(String id) async =>
      PostItem.fromJson(await _post(accountBase, '/posts/$id/shares', {}));

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

  Future<void> sendMessage(String peerId, String content) async {
    await _post(messageBase, '/messages', {
      'peer_id': peerId,
      'content': content,
    });
  }

  Future<SubscriptionItem?> fetchSubscription() async {
    final json = await _get(accountBase, '/subscriptions/current');
    if ((json['plan_id'] ?? '').toString().isEmpty) {
      return null;
    }
    return SubscriptionItem.fromJson(json);
  }

  Future<SubscriptionItem> activateSubscription(String planId) async =>
      SubscriptionItem.fromJson(
        await _post(accountBase, '/subscriptions', {'plan_id': planId}),
      );

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
