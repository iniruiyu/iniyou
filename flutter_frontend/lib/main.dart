import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const IniyouApp());
}

class IniyouApp extends StatelessWidget {
  const IniyouApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6EE7FF);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF101925),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'iniyou',
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF08111D),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: Color(0xFF101925),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF152131),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const IniyouHome(),
    );
  }
}

enum AppSection { feed, friends, chat, subscription, accounts, profile }

class IniyouHome extends StatefulWidget {
  const IniyouHome({super.key});

  @override
  State<IniyouHome> createState() => _IniyouHomeState();
}

class _IniyouHomeState extends State<IniyouHome> {
  final ApiClient _api = ApiClient();
  final _loginAccountController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _postTitleController = TextEditingController();
  final _postContentController = TextEditingController();
  final _friendSearchController = TextEditingController();
  final _chatComposerController = TextEditingController();
  final _externalAddressController = TextEditingController();
  final _externalSignatureController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};

  SharedPreferences? _prefs;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;

  bool _booting = true;
  bool _loading = false;
  bool _loginMode = true;
  String? _error;
  String? _flash;
  String _postVisibility = 'public';
  String _postStatus = 'published';
  String _externalProvider = 'evm';
  String _externalChain = 'ethereum';
  AppSection _section = AppSection.feed;

  CurrentUser? _user;
  List<PostItem> _posts = const [];
  List<FriendItem> _friends = const [];
  List<UserSearchItem> _searchResults = const [];
  List<ConversationItem> _conversations = const [];
  List<ChatMessage> _messages = const [];
  List<ExternalAccountItem> _externalAccounts = const [];
  SubscriptionItem? _subscription;
  FriendItem? _activeChat;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _channel?.sink.close();
    for (final controller in [
      _loginAccountController,
      _loginPasswordController,
      _registerEmailController,
      _registerPhoneController,
      _registerPasswordController,
      _displayNameController,
      _postTitleController,
      _postContentController,
      _friendSearchController,
      _chatComposerController,
      _externalAddressController,
      _externalSignatureController,
    ]) {
      controller.dispose();
    }
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Restore a persisted session before rendering the authenticated shell.
    // 在渲染登录后壳层前恢复已持久化的会话。
    _prefs = await SharedPreferences.getInstance();
    final token = _prefs?.getString('iniyou_token');
    if (token != null && token.isNotEmpty) {
      _api.token = token;
      try {
        await _refreshAll();
        _connectSocket();
      } catch (_) {
        await _logout(clearRemote: false);
      }
    }
    if (mounted) {
      setState(() => _booting = false);
    }
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _flash = null;
    });
    try {
      await action();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    final me = await _api.fetchMe();
    final results = await Future.wait([
      _api.listPosts(),
      _api.listFriends(),
      _api.listConversations(),
      _api.fetchSubscription(),
      _api.listExternalAccounts(),
    ]);
    final posts = results[0] as List<PostItem>;
    final friends = results[1] as List<FriendItem>;
    final conversations = results[2] as List<ConversationItem>;
    final subscription = results[3] as SubscriptionItem?;
    final externalAccounts = results[4] as List<ExternalAccountItem>;

    _displayNameController.text = me.displayName;
    setState(() {
      _user = me;
      _posts = posts;
      _friends = friends;
      _conversations = conversations;
      _subscription = subscription;
      _externalAccounts = externalAccounts;
      if (_activeChat != null) {
        _activeChat = friends
            .where((item) => item.id == _activeChat!.id)
            .firstOrNull;
      }
    });
    if (_activeChat != null) {
      await _loadMessages(_activeChat!, quiet: true);
    }
  }

  Future<void> _login() async {
    await _runBusy(() async {
      final response = await _api.login(
        _loginAccountController.text.trim(),
        _loginPasswordController.text,
      );
      await _prefs?.setString('iniyou_token', response.token);
      _api.token = response.token;
      await _refreshAll();
      _connectSocket();
      setState(() {
        _flash = '登录成功';
        _section = AppSection.feed;
      });
    });
  }

  Future<void> _register() async {
    await _runBusy(() async {
      final response = await _api.register(
        email: _registerEmailController.text.trim(),
        phone: _registerPhoneController.text.trim(),
        password: _registerPasswordController.text,
      );
      await _prefs?.setString('iniyou_token', response.token);
      _api.token = response.token;
      await _refreshAll();
      _connectSocket();
      setState(() {
        _flash = '注册成功';
        _section = AppSection.feed;
      });
    });
  }

  Future<void> _logout({bool clearRemote = true}) async {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel?.sink.close();
    _channel = null;
    if (clearRemote && _api.token != null) {
      try {
        await _api.logout();
      } catch (_) {}
    }
    _api.token = null;
    await _prefs?.remove('iniyou_token');
    if (!mounted) {
      return;
    }
    setState(() {
      _user = null;
      _posts = const [];
      _friends = const [];
      _searchResults = const [];
      _conversations = const [];
      _messages = const [];
      _externalAccounts = const [];
      _subscription = null;
      _activeChat = null;
      _section = AppSection.feed;
      _flash = null;
      _error = null;
    });
  }

  void _connectSocket() {
    // Reconnect realtime chat after login or session restore.
    // 在登录或恢复会话后重新连接实时聊天。
    _socketSubscription?.cancel();
    _channel?.sink.close();
    final token = _api.token;
    if (token == null || token.isEmpty) {
      return;
    }
    _channel = WebSocketChannel.connect(_api.wsUri(token));
    _socketSubscription = _channel!.stream.listen((event) async {
      if (_user == null) {
        return;
      }
      try {
        final payload = jsonDecode(event.toString()) as Map<String, dynamic>;
        final peerId = payload['from'] == _user!.id
            ? payload['to']
            : payload['from'];
        if (peerId is! String) {
          return;
        }
        final activePeer = _activeChat?.id;
        final conversations = await _api.listConversations();
        if (!mounted) {
          return;
        }
        setState(() => _conversations = conversations);
        if (activePeer == peerId) {
          final friend = _friends
              .where((item) => item.id == peerId)
              .firstOrNull;
          if (friend != null) {
            await _loadMessages(friend, quiet: true);
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _publishPost() async {
    await _runBusy(() async {
      await _api.createPost(
        title: _postTitleController.text.trim(),
        content: _postContentController.text.trim(),
        visibility: _postVisibility,
        status: _postStatus,
      );
      _postTitleController.clear();
      _postContentController.clear();
      _posts = await _api.listPosts();
      setState(() => _flash = '已发布新内容');
    });
  }

  Future<void> _toggleLike(PostItem post) async {
    await _runBusy(() async {
      final updated = await _api.toggleLike(post.id);
      _replacePost(updated);
    });
  }

  Future<void> _sharePost(PostItem post) async {
    await _runBusy(() async {
      final updated = await _api.sharePost(post.id);
      _replacePost(updated);
      setState(() => _flash = '已记录转发');
    });
  }

  Future<void> _comment(PostItem post) async {
    final controller = _commentControllers.putIfAbsent(
      post.id,
      TextEditingController.new,
    );
    final content = controller.text.trim();
    if (content.isEmpty) {
      setState(() => _error = '评论内容不能为空');
      return;
    }
    await _runBusy(() async {
      final updated = await _api.commentPost(post.id, content);
      controller.clear();
      _replacePost(updated);
    });
  }

  void _replacePost(PostItem updated) {
    final items = [..._posts];
    final index = items.indexWhere((post) => post.id == updated.id);
    if (index >= 0) {
      items[index] = updated;
    } else {
      items.insert(0, updated);
    }
    setState(() => _posts = items);
  }

  Future<void> _searchUsers() async {
    await _runBusy(() async {
      final items = await _api.searchUsers(_friendSearchController.text.trim());
      setState(() => _searchResults = items);
    });
  }

  Future<void> _addFriend(String friendId) async {
    await _runBusy(() async {
      await _api.addFriend(friendId);
      _friends = await _api.listFriends();
      _searchResults = await _api.searchUsers(
        _friendSearchController.text.trim(),
      );
      setState(() => _flash = '好友请求已发送');
    });
  }

  Future<void> _acceptFriend(String friendId) async {
    await _runBusy(() async {
      await _api.acceptFriend(friendId);
      _friends = await _api.listFriends();
      _conversations = await _api.listConversations();
      setState(() => _flash = '已接受好友请求');
    });
  }

  Future<void> _startChat(FriendItem friend) async {
    setState(() {
      _activeChat = friend;
      _section = AppSection.chat;
    });
    await _loadMessages(friend);
  }

  Future<void> _loadMessages(FriendItem friend, {bool quiet = false}) async {
    Future<void> action() async {
      final items = await _api.listMessages(friend.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _activeChat = friend;
        _messages = items;
      });
    }

    if (quiet) {
      try {
        await action();
      } catch (_) {}
      return;
    }
    await _runBusy(action);
  }

  Future<void> _sendMessage() async {
    final peer = _activeChat;
    if (peer == null) {
      setState(() => _error = '请先选择聊天对象');
      return;
    }
    final content = _chatComposerController.text.trim();
    if (content.isEmpty) {
      return;
    }
    await _runBusy(() async {
      await _api.sendMessage(peer.id, content);
      _chatComposerController.clear();
      _messages = await _api.listMessages(peer.id);
      _conversations = await _api.listConversations();
    });
  }

  Future<void> _saveProfile() async {
    await _runBusy(() async {
      _user = await _api.updateProfile(_displayNameController.text.trim());
      setState(() => _flash = '资料已更新');
    });
  }

  Future<void> _activatePlan(String planId) async {
    await _runBusy(() async {
      _subscription = await _api.activateSubscription(planId);
      _user = await _api.fetchMe();
      setState(() => _flash = '订阅已更新');
    });
  }

  Future<void> _bindExternalAccount() async {
    await _runBusy(() async {
      await _api.bindExternalAccount(
        provider: _externalProvider,
        chain: _externalChain,
        address: _externalAddressController.text.trim(),
        signature: _externalSignatureController.text.trim(),
      );
      _externalAddressController.clear();
      _externalSignatureController.clear();
      _externalAccounts = await _api.listExternalAccounts();
      setState(() => _flash = '外部账号已绑定');
    });
  }

  Future<void> _removeExternalAccount(String id) async {
    await _runBusy(() async {
      await _api.deleteExternalAccount(id);
      _externalAccounts = await _api.listExternalAccounts();
      setState(() => _flash = '外部账号已移除');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return _buildAuthView(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final rail = NavigationRail(
          selectedIndex: AppSection.values.indexOf(_section),
          onDestinationSelected: (index) {
            setState(() => _section = AppSection.values[index]);
          },
          backgroundColor: const Color(0xFF0D1623),
          labelType: wide
              ? NavigationRailLabelType.all
              : NavigationRailLabelType.selected,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.rss_feed_outlined),
              label: Text('动态'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people_alt_outlined),
              label: Text('好友'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: Text('聊天'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              label: Text('订阅'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.hub_outlined),
              label: Text('外部账号'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person_outline),
              label: Text('资料'),
            ),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(_sectionTitle),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    _user!.displayName.isEmpty ? _user!.id : _user!.displayName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: '刷新',
                onPressed: _loading ? null : () => _runBusy(_refreshAll),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: '退出',
                onPressed: _loading ? null : () => _logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: wide ? null : Drawer(child: SafeArea(child: rail)),
          body: Row(
            children: [
              if (wide) rail,
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF08111D), Color(0xFF0E1A2A)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildBanner(),
                          const SizedBox(height: 16),
                          _buildSectionBody(constraints.maxWidth),
                        ],
                      ),
                      if (_loading)
                        const Positioned(
                          top: 16,
                          right: 16,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthView(BuildContext context) {
    final title = _loginMode ? '回到 iniyou' : '创建你的 iniyou 账户';
    final subtitle = _loginMode
        ? '使用现有账号进入 Flutter 客户端。'
        : '保留旧 Web 前端的同时，新增一套 Flutter 前端。';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0xFF14334B), Color(0xFF08111D)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'iniyou',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(subtitle),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      children: [
                        ChoiceChip(
                          label: const Text('登录'),
                          selected: _loginMode,
                          onSelected: (_) => setState(() => _loginMode = true),
                        ),
                        ChoiceChip(
                          label: const Text('注册'),
                          selected: !_loginMode,
                          onSelected: (_) => setState(() => _loginMode = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_loginMode) ...[
                      TextField(
                        controller: _loginAccountController,
                        decoration: const InputDecoration(
                          labelText: '邮箱 / 手机号',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _loginPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '密码'),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _login,
                        child: const Text('登录'),
                      ),
                    ] else ...[
                      TextField(
                        controller: _registerEmailController,
                        decoration: const InputDecoration(labelText: '邮箱'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _registerPhoneController,
                        decoration: const InputDecoration(labelText: '手机号'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _registerPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '密码，至少 8 位',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _register,
                        child: const Text('创建账号'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    if (_error == null && _flash == null) {
      return const SizedBox.shrink();
    }
    final color = _error != null ? Colors.redAccent : const Color(0xFF6EE7FF);
    final message = _error ?? _flash!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(message, style: TextStyle(color: color)),
      ),
    );
  }

  Widget _buildSectionBody(double width) {
    switch (_section) {
      case AppSection.feed:
        return _buildFeedSection();
      case AppSection.friends:
        return _buildFriendsSection();
      case AppSection.chat:
        return _buildChatSection(width);
      case AppSection.subscription:
        return _buildSubscriptionSection();
      case AppSection.accounts:
        return _buildExternalAccountsSection();
      case AppSection.profile:
        return _buildProfileSection();
    }
  }

  Widget _buildFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('发布内容', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: _postTitleController,
                  decoration: const InputDecoration(labelText: '标题'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _postContentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: '说点什么'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _postVisibility,
                        decoration: const InputDecoration(labelText: '可见性'),
                        items: const [
                          DropdownMenuItem(value: 'public', child: Text('公开')),
                          DropdownMenuItem(value: 'private', child: Text('私密')),
                        ],
                        onChanged: (value) =>
                            setState(() => _postVisibility = value ?? 'public'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _postStatus,
                        decoration: const InputDecoration(labelText: '状态'),
                        items: const [
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('已发布'),
                          ),
                          DropdownMenuItem(value: 'draft', child: Text('草稿')),
                          DropdownMenuItem(value: 'hidden', child: Text('隐藏')),
                        ],
                        onChanged: (value) =>
                            setState(() => _postStatus = value ?? 'published'),
                      ),
                    ),
                    FilledButton(
                      onPressed: _loading ? null : _publishPost,
                      child: const Text('发布'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (final post in _posts) ...[
          _PostCard(
            post: post,
            commentController: _commentControllers.putIfAbsent(
              post.id,
              TextEditingController.new,
            ),
            onLike: () => _toggleLike(post),
            onShare: () => _sharePost(post),
            onComment: () => _comment(post),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildFriendsSection() {
    final acceptedFriends = _friends
        .where((item) => item.status == 'accepted')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('发现联系人', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _friendSearchController,
                        decoration: const InputDecoration(
                          labelText: '搜索 display name / 邮箱 / 手机号 / 用户 ID',
                        ),
                        onSubmitted: (_) => _searchUsers(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _loading ? null : _searchUsers,
                      child: const Text('搜索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _searchResults
                      .map(
                        (item) => SizedBox(
                          width: 280,
                          child: _InfoCard(
                            title: item.displayName,
                            lines: [
                              item.secondary,
                              if (item.relationStatus.isNotEmpty)
                                '关系: ${item.relationStatus} / ${item.direction}',
                            ],
                            trailing: FilledButton.tonal(
                              onPressed: item.relationStatus.isEmpty
                                  ? () => _addFriend(item.id)
                                  : null,
                              child: Text(
                                item.relationStatus.isEmpty ? '添加好友' : '已存在关系',
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('我的好友关系', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _friends
              .map(
                (friend) => SizedBox(
                  width: 320,
                  child: _InfoCard(
                    title: friend.displayName,
                    lines: [
                      friend.secondary,
                      '状态: ${friend.status}',
                      '方向: ${friend.direction}',
                    ],
                    trailing:
                        friend.direction == 'incoming' &&
                            friend.status == 'pending'
                        ? FilledButton.tonal(
                            onPressed: () => _acceptFriend(friend.id),
                            child: const Text('接受'),
                          )
                        : FilledButton.tonal(
                            onPressed: friend.status == 'accepted'
                                ? () => _startChat(friend)
                                : null,
                            child: const Text('聊天'),
                          ),
                  ),
                ),
              )
              .toList(),
        ),
        if (acceptedFriends.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('暂无已接受好友，先从上面搜索并建立关系。'),
          ),
      ],
    );
  }

  Widget _buildChatSection(double width) {
    final acceptedFriends = _friends
        .where((item) => item.status == 'accepted')
        .toList();
    final compact = width < 1100;
    final listPane = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最近会话', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('还没有会话记录。'),
              ),
            ..._conversations.map((item) {
              final friend = acceptedFriends
                  .where((candidate) => candidate.id == item.peerId)
                  .firstOrNull;
              if (friend == null) {
                return const SizedBox.shrink();
              }
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(friend.displayName),
                subtitle: Text(item.lastMessage),
                trailing: item.unreadCount > 0
                    ? CircleAvatar(
                        radius: 12,
                        child: Text('${item.unreadCount}'),
                      )
                    : null,
                onTap: () => _startChat(friend),
              );
            }),
            const Divider(height: 24),
            Text('好友', style: Theme.of(context).textTheme.titleMedium),
            ...acceptedFriends.map(
              (friend) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(friend.displayName),
                subtitle: Text(friend.secondary),
                selected: _activeChat?.id == friend.id,
                onTap: () => _startChat(friend),
              ),
            ),
          ],
        ),
      ),
    );
    final chatPane = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _activeChat?.displayName ?? '选择一个好友开始聊天',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 420,
              child: _activeChat == null
                  ? const Center(child: Text('选择左侧好友后会加载历史消息并接入 WebSocket。'))
                  : ListView.separated(
                      itemCount: _messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _messages[index];
                        final mine = item.from == _user!.id;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xFF1D6F87)
                                  : const Color(0xFF192535),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.content),
                                const SizedBox(height: 6),
                                Text(
                                  item.createdAtLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatComposerController,
                    decoration: const InputDecoration(labelText: '输入消息'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _loading ? null : _sendMessage,
                  child: const Text('发送'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (compact) {
      return Column(children: [listPane, const SizedBox(height: 16), chatPane]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 360, child: listPane),
        const SizedBox(width: 16),
        Expanded(child: chatPane),
      ],
    );
  }

  Widget _buildSubscriptionSection() {
    final currentPlan = _subscription?.planId.isNotEmpty == true
        ? _subscription!.planId
        : 'basic';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(
          title: '当前订阅',
          lines: [
            '计划: $currentPlan',
            '状态: ${_subscription?.status ?? 'inactive'}',
            if (_subscription?.startedAt != null)
              '开始时间: ${_subscription!.startedAtLabel}',
            if (_subscription?.endedAt != null)
              '到期时间: ${_subscription!.endedAtLabel}',
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              const [
                _PlanCard(
                  planId: 'basic',
                  title: 'Basic',
                  features: ['公共内容流', '基础资料', '默认空间'],
                ),
                _PlanCard(
                  planId: 'premium',
                  title: 'Premium',
                  features: ['私密内容', '聊天能力', '扩展社交功能'],
                ),
                _PlanCard(
                  planId: 'vip',
                  title: 'VIP',
                  features: ['高级身份层级', '长期会员', '更强展示能力'],
                ),
              ].map((card) {
                return SizedBox(width: 300, child: card);
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildExternalAccountsSection() {
    final chainsByProvider = const {
      'evm': ['ethereum', 'base', 'bsc', 'polygon'],
      'solana': ['solana'],
      'tron': ['tron'],
    };
    final chainOptions = chainsByProvider[_externalProvider]!;
    if (!chainOptions.contains(_externalChain)) {
      _externalChain = chainOptions.first;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('绑定外部账号', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _externalProvider,
                        decoration: const InputDecoration(
                          labelText: 'Provider',
                        ),
                        items: chainsByProvider.keys
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _externalProvider = value;
                            _externalChain = chainsByProvider[value]!.first;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _externalChain,
                        decoration: const InputDecoration(labelText: 'Chain'),
                        items: chainOptions
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(
                          () => _externalChain = value ?? chainOptions.first,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _externalAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Account address',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _externalSignatureController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Signature payload',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _bindExternalAccount,
                  child: const Text('绑定'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _externalAccounts
              .map(
                (item) => SizedBox(
                  width: 320,
                  child: _InfoCard(
                    title: '${item.provider.toUpperCase()} · ${item.chain}',
                    lines: [
                      item.address,
                      '状态: ${item.bindingStatus}',
                      item.createdAtLabel,
                    ],
                    trailing: FilledButton.tonal(
                      onPressed: () => _removeExternalAccount(item.id),
                      child: const Text('移除'),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(
          title: _user!.displayName.isEmpty ? _user!.id : _user!.displayName,
          lines: [
            '用户 ID: ${_user!.id}',
            if (_user!.email.isNotEmpty) '邮箱: ${_user!.email}',
            if (_user!.phone.isNotEmpty) '手机号: ${_user!.phone}',
            '等级: ${_user!.level}',
            '状态: ${_user!.status}',
          ],
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('更新展示名', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _saveProfile,
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _sectionTitle {
    switch (_section) {
      case AppSection.feed:
        return '动态广场';
      case AppSection.friends:
        return '好友关系';
      case AppSection.chat:
        return '实时聊天';
      case AppSection.subscription:
        return '订阅计划';
      case AppSection.accounts:
        return '外部账号';
      case AppSection.profile:
        return '个人资料';
    }
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.commentController,
    required this.onLike,
    required this.onShare,
    required this.onComment,
  });

  final PostItem post;
  final TextEditingController commentController;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.authorName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${post.visibility} · ${post.status} · ${post.createdAtLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(post.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(post.content),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onLike,
                  child: Text(
                    '${post.likedByMe ? '取消点赞' : '点赞'} · ${post.likesCount}',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onShare,
                  child: Text('转发 · ${post.sharesCount}'),
                ),
                Chip(label: Text('评论 ${post.commentsCount}')),
              ],
            ),
            const SizedBox(height: 12),
            if (post.comments.isNotEmpty)
              ...post.comments.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${item.authorName}: ${item.content}'),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(labelText: '写评论'),
                    onSubmitted: (_) => onComment(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: onComment,
                  child: const Text('提交'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines, this.trailing});

  final String title;
  final List<String> lines;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.planId,
    required this.title,
    required this.features,
  });

  final String planId;
  final String title;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_IniyouHomeState>();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...features.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $item'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state == null || state._loading
                  ? null
                  : () => state._activatePlan(planId),
              child: Text('启用 $planId'),
            ),
          ],
        ),
      ),
    );
  }
}

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
    // Reuse the message service host and switch the scheme for WebSocket.
    // 复用消息服务主机并切换为 WebSocket 协议。
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

  Future<List<PostItem>> listPosts() async => _list(
    await _get(accountBase, '/posts?visibility=public&limit=50'),
    PostItem.fromJson,
  );

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
    // Normalize backend errors into one client-side exception shape.
    // 将后端错误统一收敛为同一种客户端异常结构。
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

  String get createdAtLabel => _formatDateTime(createdAt);

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
      likesCount: _toInt(json['likes_count']),
      commentsCount: _toInt(json['comments_count']),
      sharesCount: _toInt(json['shares_count']),
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
      unreadCount: _toInt(json['unread_count']),
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

  String get createdAtLabel => _formatDateTime(createdAt);

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
      startedAt == null ? '-' : _formatDateTime(startedAt!);
  String get endedAtLabel => endedAt == null ? '-' : _formatDateTime(endedAt!);

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

  String get createdAtLabel => _formatDateTime(createdAt);

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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
