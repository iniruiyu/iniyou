import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';

class RememberedCredentials {
  const RememberedCredentials({
    required this.account,
    required this.password,
  });

  final String account;
  final String password;
}

class SessionActions {
  const SessionActions._();

  static const _tokenKey = 'iniyou_token';
  static const _rememberCredentialsKey = 'iniyou_auth_remember';
  static const _rememberAccountKey = 'iniyou_auth_account';
  static const _rememberPasswordKey = 'iniyou_auth_password';

  static String? readToken(SharedPreferences prefs) =>
      prefs.getString(_tokenKey);

  static Future<void> persistToken(
    SharedPreferences prefs,
    String token,
  ) async {
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
  }

  static bool readRememberCredentials(SharedPreferences prefs) =>
      prefs.getBool(_rememberCredentialsKey) ?? false;

  static RememberedCredentials? readRememberedCredentials(
    SharedPreferences prefs,
  ) {
    if (!readRememberCredentials(prefs)) {
      return null;
    }
    final account = prefs.getString(_rememberAccountKey) ?? '';
    final password = prefs.getString(_rememberPasswordKey) ?? '';
    if (account.isEmpty && password.isEmpty) {
      return null;
    }
    return RememberedCredentials(account: account, password: password);
  }

  static Future<void> persistRememberedCredentials(
    SharedPreferences prefs, {
    required bool remember,
    String account = '',
    String password = '',
  }) async {
    await prefs.setBool(_rememberCredentialsKey, remember);
    if (remember) {
      await prefs.setString(_rememberAccountKey, account);
      await prefs.setString(_rememberPasswordKey, password);
      return;
    }
    await prefs.remove(_rememberAccountKey);
    await prefs.remove(_rememberPasswordKey);
  }

  static Future<void> setRememberCredentialsEnabled(
    SharedPreferences prefs,
    bool remember,
  ) async {
    await prefs.setBool(_rememberCredentialsKey, remember);
    if (remember) {
      return;
    }
    await prefs.remove(_rememberAccountKey);
    await prefs.remove(_rememberPasswordKey);
  }

  static Future<void> clearRememberedCredentials(
    SharedPreferences prefs,
  ) async {
    await persistRememberedCredentials(prefs, remember: false);
  }

  static Future<String> login(
    ApiClient api,
    SharedPreferences prefs, {
    required String account,
    required String password,
  }) async {
    final response = await api.login(account, password);
    await persistToken(prefs, response.token);
    api.token = response.token;
    return response.token;
  }

  static Future<String> register(
    ApiClient api,
    SharedPreferences prefs, {
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await api.register(
      email: email,
      phone: phone,
      password: password,
    );
    await persistToken(prefs, response.token);
    api.token = response.token;
    return response.token;
  }

  static Future<void> logout(
    ApiClient api,
    SharedPreferences prefs, {
    bool clearRemote = true,
  }) async {
    final token = api.token;
    if (clearRemote && token != null && token.isNotEmpty) {
      try {
        await api.logout();
      } catch (_) {}
    }
    api.token = null;
    await removeToken(prefs);
  }

  static WebSocketChannel? connectSocket(ApiClient api) {
    final token = api.token;
    if (token == null || token.isEmpty) {
      return null;
    }
    return WebSocketChannel.connect(api.wsUri(token));
  }

  static String? extractPeerIdFromSocketEvent(
    Object event,
    String currentUserId,
  ) {
    try {
      final payload = jsonDecode(event.toString()) as Map<String, dynamic>;
      final peerId = payload['from'] == currentUserId
          ? payload['to']
          : payload['from'];
      if (peerId is! String || peerId.isEmpty) {
        return null;
      }
      return peerId;
    } catch (_) {
      return null;
    }
  }

  static bool restoreSession(ApiClient api, SharedPreferences prefs) {
    final token = readToken(prefs);
    if (token == null || token.isEmpty) {
      return false;
    }
    api.token = token;
    return true;
  }
}
