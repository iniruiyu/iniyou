import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';

class SessionActions {
  const SessionActions._();

  static const _tokenKey = 'iniyou_token';

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

  static bool restoreSession(ApiClient api, SharedPreferences prefs) {
    final token = readToken(prefs);
    if (token == null || token.isEmpty) {
      return false;
    }
    api.token = token;
    return true;
  }
}
