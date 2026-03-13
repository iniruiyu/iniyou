import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api/api_client.dart';
import 'models/app_models.dart';
import 'widgets/app_cards.dart';

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

enum AppView {
  dashboard,
  privateSpace,
  publicSpace,
  profile,
  postDetail,
  levels,
  subscription,
  blockchain,
  friends,
  chat,
}

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
  final _publicPostTitleController = TextEditingController();
  final _publicPostContentController = TextEditingController();
  final _privatePostTitleController = TextEditingController();
  final _privatePostContentController = TextEditingController();
  final _friendSearchController = TextEditingController();
  final _chatComposerController = TextEditingController();
  final _externalAddressController = TextEditingController();
  final _externalSignatureController = TextEditingController();
  final _spaceNameController = TextEditingController();
  final _spaceDescriptionController = TextEditingController();
  final _editPostTitleController = TextEditingController();
  final _editPostContentController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};

  SharedPreferences? _prefs;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;

  bool _booting = true;
  bool _loading = false;
  bool _loginMode = true;
  String? _error;
  String? _flash;
  String _publicPostStatus = 'published';
  String _privatePostStatus = 'draft';
  String _externalProvider = 'evm';
  String _externalChain = 'ethereum';
  String _editPostVisibility = 'public';
  String _editPostStatus = 'published';
  AppView _view = AppView.dashboard;

  CurrentUser? _user;
  UserProfileItem? _profileUser;
  PostItem? _currentPost;
  List<SpaceItem> _spaces = const [];
  List<PostItem> _publicPosts = const [];
  List<PostItem> _privatePosts = const [];
  List<PostItem> _profilePosts = const [];
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
      _publicPostTitleController,
      _publicPostContentController,
      _privatePostTitleController,
      _privatePostContentController,
      _friendSearchController,
      _chatComposerController,
      _externalAddressController,
      _externalSignatureController,
      _spaceNameController,
      _spaceDescriptionController,
      _editPostTitleController,
      _editPostContentController,
    ]) {
      controller.dispose();
    }
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
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
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    final me = await _api.fetchMe();
    final results = await Future.wait([
      _api.listSpaces(),
      _api.listPosts(visibility: 'public', limit: 50),
      _api.listPosts(visibility: 'private', limit: 50),
      _api.listFriends(),
      _api.listConversations(),
      _api.fetchSubscription(),
      _api.listExternalAccounts(),
    ]);

    final spaces = results[0] as List<SpaceItem>;
    final publicPosts = results[1] as List<PostItem>;
    final privatePosts = results[2] as List<PostItem>;
    final friends = results[3] as List<FriendItem>;
    final conversations = results[4] as List<ConversationItem>;
    final subscription = results[5] as SubscriptionItem?;
    final externalAccounts = results[6] as List<ExternalAccountItem>;

    _displayNameController.text = me.displayName;

    if (!mounted) {
      return;
    }

    setState(() {
      _user = me;
      _spaces = spaces;
      _publicPosts = publicPosts;
      _privatePosts = privatePosts;
      _friends = friends;
      _conversations = conversations;
      _subscription = subscription;
      _externalAccounts = externalAccounts;
      if (_activeChat != null) {
        _activeChat = _findFriend(_activeChat!.id, friends);
      }
    });

    if (_profileUser != null) {
      await _loadProfile(_profileUser!.id, quiet: true);
    }
    if (_currentPost != null) {
      await _loadPostDetail(_currentPost!.id, quiet: true);
    }
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
      if (!mounted) {
        return;
      }
      setState(() {
        _flash = '登录成功';
        _view = AppView.dashboard;
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
      if (!mounted) {
        return;
      }
      setState(() {
        _flash = '注册成功';
        _view = AppView.dashboard;
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
      _profileUser = null;
      _currentPost = null;
      _spaces = const [];
      _publicPosts = const [];
      _privatePosts = const [];
      _profilePosts = const [];
      _friends = const [];
      _searchResults = const [];
      _conversations = const [];
      _messages = const [];
      _externalAccounts = const [];
      _subscription = null;
      _activeChat = null;
      _view = AppView.dashboard;
      _flash = null;
      _error = null;
    });
  }

  void _connectSocket() {
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
        final conversations = await _api.listConversations();
        if (!mounted) {
          return;
        }
        setState(() => _conversations = conversations);
        if (_activeChat?.id == peerId) {
          final friend = _findFriend(peerId, _friends);
          if (friend != null) {
            await _loadMessages(friend, quiet: true);
          }
        }
      } catch (_) {}
    });
  }

  void _navigateTo(AppView view) {
    if (view == AppView.profile && _user != null) {
      _openProfile(_user!.id);
      return;
    }
    if (mounted) {
      setState(() {
        _view = view;
        _error = null;
        _flash = null;
      });
    }
  }

  Future<void> _createSpace(String type) async {
    final name = _spaceNameController.text.trim();
    final description = _spaceDescriptionController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '空间名称不能为空');
      return;
    }
    await _runBusy(() async {
      await _api.createSpace(type: type, name: name, description: description);
      _spaceNameController.clear();
      _spaceDescriptionController.clear();
      _spaces = await _api.listSpaces();
      if (!mounted) {
        return;
      }
      setState(() {
        _flash = type == 'private' ? '已创建私人空间' : '已创建公共空间';
      });
    });
  }

  Future<void> _publishPost({
    required String visibility,
    required TextEditingController titleController,
    required TextEditingController contentController,
    required String status,
  }) async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = '标题和内容不能为空');
      return;
    }
    await _runBusy(() async {
      final created = await _api.createPost(
        title: title,
        content: content,
        visibility: visibility,
        status: status,
      );
      titleController.clear();
      contentController.clear();
      _applyPostUpdate(created);
      if (visibility == 'public') {
        _publicPosts = await _api.listPosts(visibility: 'public', limit: 50);
      } else {
        _privatePosts = await _api.listPosts(visibility: 'private', limit: 50);
      }
      if (!mounted) {
        return;
      }
      setState(() => _flash = visibility == 'public' ? '公共内容已发布' : '私人内容已保存');
    });
  }

  Future<void> _toggleLike(PostItem post) async {
    await _runBusy(() async {
      final updated = await _api.toggleLike(post.id);
      _applyPostUpdate(updated);
    });
  }

  Future<void> _sharePost(PostItem post) async {
    await _runBusy(() async {
      final updated = await _api.sharePost(post.id);
      _applyPostUpdate(updated);
      if (!mounted) {
        return;
      }
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
      _applyPostUpdate(updated);
    });
  }

  void _applyPostUpdate(PostItem updated) {
    List<PostItem> syncList(List<PostItem> items, String visibility) {
      final next = [...items];
      final index = next.indexWhere((post) => post.id == updated.id);
      final shouldExist = updated.visibility == visibility;
      if (index >= 0 && !shouldExist) {
        next.removeAt(index);
      } else if (index >= 0) {
        next[index] = updated;
      } else if (shouldExist) {
        next.insert(0, updated);
      }
      return next;
    }

    setState(() {
      _publicPosts = syncList(_publicPosts, 'public');
      _privatePosts = syncList(_privatePosts, 'private');
      final profileIndex = _profilePosts.indexWhere(
        (post) => post.id == updated.id,
      );
      if (profileIndex >= 0) {
        final next = [..._profilePosts];
        next[profileIndex] = updated;
        _profilePosts = next;
      }
      if (_currentPost?.id == updated.id) {
        _currentPost = updated;
      }
    });
  }

  Future<void> _openProfile(String userId) async {
    await _runBusy(() => _loadProfile(userId));
  }

  Future<void> _loadProfile(String userId, {bool quiet = false}) async {
    Future<void> action() async {
      final ownProfile = _user != null && userId == _user!.id;
      final results = await Future.wait([
        _api.fetchUserProfile(userId),
        _api.listUserPosts(
          userId,
          visibility: ownProfile ? 'all' : 'public',
          limit: 50,
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _profileUser = results[0] as UserProfileItem;
        _profilePosts = results[1] as List<PostItem>;
        _view = AppView.profile;
      });
    }

    if (quiet) {
      try {
        await action();
      } catch (_) {}
      return;
    }
    await action();
  }

  Future<void> _openPostDetail(String postId) async {
    await _runBusy(() => _loadPostDetail(postId));
  }

  Future<void> _loadPostDetail(String postId, {bool quiet = false}) async {
    Future<void> action() async {
      final post = await _api.getPost(postId);
      if (!mounted) {
        return;
      }
      _editPostTitleController.text = post.title;
      _editPostContentController.text = post.content;
      setState(() {
        _currentPost = post;
        _editPostVisibility = post.visibility;
        _editPostStatus = post.status;
        _view = AppView.postDetail;
      });
    }

    if (quiet) {
      try {
        await action();
      } catch (_) {}
      return;
    }
    await action();
  }

  Future<void> _savePostEdits() async {
    final post = _currentPost;
    if (post == null) {
      return;
    }
    await _runBusy(() async {
      final updated = await _api.updatePost(
        id: post.id,
        title: _editPostTitleController.text.trim(),
        content: _editPostContentController.text.trim(),
        visibility: _editPostVisibility,
        status: _editPostStatus,
      );
      _applyPostUpdate(updated);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPost = updated;
        _flash = '文章已更新';
      });
    });
  }

  Future<void> _searchUsers() async {
    await _runBusy(() async {
      final items = await _api.searchUsers(_friendSearchController.text.trim());
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      setState(() => _flash = '好友请求已发送');
    });
  }

  Future<void> _acceptFriend(String friendId) async {
    await _runBusy(() async {
      await _api.acceptFriend(friendId);
      _friends = await _api.listFriends();
      _conversations = await _api.listConversations();
      if (_profileUser?.id == friendId) {
        await _loadProfile(friendId, quiet: true);
      }
      if (!mounted) {
        return;
      }
      setState(() => _flash = '已接受好友请求');
    });
  }

  Future<void> _startChat(FriendItem friend) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeChat = friend;
      _view = AppView.chat;
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
      if (_profileUser?.id == _user?.id) {
        _profileUser = UserProfileItem.fromCurrentUser(_user!);
      }
      if (!mounted) {
        return;
      }
      setState(() => _flash = '资料已更新');
    });
  }

  Future<void> _activatePlan(String planId) async {
    await _runBusy(() async {
      _subscription = await _api.activateSubscription(planId);
      _user = await _api.fetchMe();
      if (_profileUser?.id == _user?.id) {
        _profileUser = UserProfileItem.fromCurrentUser(_user!);
      }
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      setState(() => _flash = '外部账号已绑定');
    });
  }

  Future<void> _removeExternalAccount(String id) async {
    await _runBusy(() async {
      await _api.deleteExternalAccount(id);
      _externalAccounts = await _api.listExternalAccounts();
      if (!mounted) {
        return;
      }
      setState(() => _flash = '外部账号已移除');
    });
  }

  FriendItem? _findFriend(String id, List<FriendItem> items) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  List<FriendItem> get _acceptedFriends =>
      _friends.where((item) => item.status == 'accepted').toList();

  List<SpaceItem> get _privateSpaces =>
      _spaces.where((space) => space.type == 'private').toList();

  List<SpaceItem> get _publicSpaces =>
      _spaces.where((space) => space.type == 'public').toList();

  List<String> get _connectedChains {
    final values = <String>{};
    for (final item in _externalAccounts) {
      if (item.bindingStatus == 'active' && item.chain.isNotEmpty) {
        values.add(item.chain);
      }
    }
    return values.toList()..sort();
  }

  String get _pageTitle {
    switch (_view) {
      case AppView.dashboard:
        return '工作台';
      case AppView.privateSpace:
        return '私人空间';
      case AppView.publicSpace:
        return '公共空间';
      case AppView.profile:
        return _profileUser?.displayName.isNotEmpty == true
            ? _profileUser!.displayName
            : '个人主页';
      case AppView.postDetail:
        return _currentPost?.title.isNotEmpty == true
            ? _currentPost!.title
            : '文章详情';
      case AppView.levels:
        return '等级体系';
      case AppView.subscription:
        return '订阅计划';
      case AppView.blockchain:
        return '区块链接入';
      case AppView.friends:
        return '好友关系';
      case AppView.chat:
        return '实时聊天';
    }
  }

  String get _pageSubtitle {
    switch (_view) {
      case AppView.dashboard:
        return '汇总账号、空间、订阅、好友与实时互动状态。';
      case AppView.privateSpace:
        return '管理仅自己可见的内容、草稿和私人空间。';
      case AppView.publicSpace:
        return '发布公开内容、查看广场动态并打开作者主页。';
      case AppView.profile:
        return '查看用户资料、关系状态和历史文章。';
      case AppView.postDetail:
        return '查看完整正文、评论和互动统计。';
      case AppView.levels:
        return '等级与计划联动，决定展示身份和能力范围。';
      case AppView.subscription:
        return '管理当前会员计划和续费动作。';
      case AppView.blockchain:
        return '绑定链上账号并查看已连接链摘要。';
      case AppView.friends:
        return '搜索用户、发起好友请求并处理待接受关系。';
      case AppView.chat:
        return '查看会话摘要并发送实时消息。';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return _buildGuestLanding(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1120;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_pageTitle),
                Text(
                  _pageSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
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
          drawer: wide ? null : Drawer(child: SafeArea(child: _buildSidebar())),
          body: Row(
            children: [
              if (wide) SizedBox(width: 260, child: _buildSidebar()),
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
                          _buildTopSummaryRow(constraints.maxWidth),
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

  Widget _buildGuestLanding(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07111B), Color(0xFF13324A)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1080;
              final hero = _buildLandingHero(context);
              final auth = _buildAuthCard(context);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: hero),
                              const SizedBox(width: 20),
                              SizedBox(width: 420, child: auth),
                            ],
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [hero, const SizedBox(height: 20), auth],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLandingHero(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'iniyou',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          '先完成账号流程，再进入工作台。',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          '普通 Web 前端和 Flutter 前端现在保持同一套信息架构。未登录时先进入登录或注册，登录后再进入私人空间、公共空间、好友、聊天和区块链接入页面。',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            HeroStatCard(
              index: '01',
              label: '登录或注册',
              text: '统一入口，减少未登录状态下的分叉页面。',
            ),
            HeroStatCard(
              index: '02',
              label: '进入工作台',
              text: '登录后可查看仪表盘、空间、关系和聊天。',
            ),
            HeroStatCard(
              index: '03',
              label: '双前端并存',
              text: 'Legacy Web 与 Flutter 前端保持一致的页面结构。',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auth Flow',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF6EE7FF),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '未登录态聚焦在账号流程',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  '将账号入口、工作台预览和功能说明拆开，避免在未登录时提前暴露完整业务模块。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    FeatureChipCard(title: '私人空间', text: '沉淀草稿、笔记和仅自己可见的记录。'),
                    FeatureChipCard(title: '公共空间', text: '展示项目、发布内容并建立公开连接。'),
                    FeatureChipCard(title: '实时互动', text: '登录后进入聊天、好友和资料工作台。'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final title = _loginMode ? '回到 iniyou' : '创建你的 iniyou 账户';
    final subtitle = _loginMode ? '输入账号后直接进入工作台。' : '创建账号后自动进入你的空间。';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('账号入口', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
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
                decoration: const InputDecoration(labelText: '邮箱 / 手机号'),
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
                decoration: const InputDecoration(labelText: '密码，至少 8 位'),
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
    );
  }

  Widget _buildSidebar() {
    final items = <_NavItem>[
      _NavItem(AppView.dashboard, '工作台', Icons.dashboard_outlined),
      _NavItem(AppView.privateSpace, '私人空间', Icons.lock_outline),
      _NavItem(AppView.publicSpace, '公共空间', Icons.public),
      _NavItem(AppView.profile, '个人主页', Icons.person_outline),
      _NavItem(AppView.levels, '等级', Icons.stars_outlined),
      _NavItem(AppView.subscription, '订阅', Icons.workspace_premium_outlined),
      _NavItem(AppView.blockchain, '区块链', Icons.hub_outlined),
      _NavItem(AppView.friends, '好友', Icons.people_alt_outlined),
      _NavItem(AppView.chat, '聊天', Icons.chat_bubble_outline),
    ];

    return Container(
      color: const Color(0xFF0D1623),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'iniyou',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Private + Public Spaces',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          InfoCard(
            title: _user!.displayName.isEmpty ? _user!.id : _user!.displayName,
            lines: [
              '等级: ${_user!.level}',
              '计划: ${_subscription?.planId.isNotEmpty == true ? _subscription!.planId : 'basic'}',
              '未读会话: ${_conversations.fold<int>(0, (sum, item) => sum + item.unreadCount)}',
            ],
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            final selected =
                _view == item.view ||
                (_view == AppView.postDetail &&
                    item.view == AppView.publicSpace);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: selected
                      ? const Color(0xFF1D6F87)
                      : const Color(0xFF152131),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onPressed: () => _navigateTo(item.view),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18),
                    const SizedBox(width: 10),
                    Text(item.label),
                  ],
                ),
              ),
            );
          }),
        ],
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

  Widget _buildTopSummaryRow(double width) {
    final cards = [
      SummaryCardData(
        '空间',
        '${_spaces.length}',
        '私人 ${_privateSpaces.length} / 公共 ${_publicSpaces.length}',
      ),
      SummaryCardData(
        '好友',
        '${_acceptedFriends.length}',
        '总关系 ${_friends.length}',
      ),
      SummaryCardData(
        '订阅',
        _subscription?.planId.isNotEmpty == true
            ? _subscription!.planId
            : 'basic',
        '状态 ${_subscription?.status ?? 'inactive'}',
      ),
      SummaryCardData(
        '链上账号',
        '${_externalAccounts.length}',
        _connectedChains.isEmpty ? '尚未连接链' : _connectedChains.join(', '),
      ),
    ];
    if (width < 920) {
      return Column(
        children: [
          for (final item in cards) ...[
            SummaryCard(item: item),
            const SizedBox(height: 12),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          Expanded(child: SummaryCard(item: cards[index])),
          if (index < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildSectionBody(double width) {
    switch (_view) {
      case AppView.dashboard:
        return _buildDashboardView(width);
      case AppView.privateSpace:
        return _buildPrivateView();
      case AppView.publicSpace:
        return _buildPublicView();
      case AppView.profile:
        return _buildProfileView();
      case AppView.postDetail:
        return _buildPostDetailView();
      case AppView.levels:
        return _buildLevelsView();
      case AppView.subscription:
        return _buildSubscriptionView();
      case AppView.blockchain:
        return _buildBlockchainView();
      case AppView.friends:
        return _buildFriendsView();
      case AppView.chat:
        return _buildChatView(width);
    }
  }

  Widget _buildDashboardView(double width) {
    final compact = width < 980;
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: '账号概览',
          lines: [
            '用户 ID: ${_user!.id}',
            if (_user!.email.isNotEmpty) '邮箱: ${_user!.email}',
            if (_user!.phone.isNotEmpty) '手机号: ${_user!.phone}',
            '等级: ${_user!.level}',
            '状态: ${_user!.status}',
          ],
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '快捷入口',
          lines: const [
            '进入私人空间沉淀草稿和私人内容',
            '进入公共空间发布文章和打开作者主页',
            '好友和聊天页面保持关系与实时消息联动',
          ],
          trailing: FilledButton.tonal(
            onPressed: () => _navigateTo(AppView.publicSpace),
            child: const Text('打开公共空间'),
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: '空间摘要',
          lines: [
            for (final space in _spaces.take(4))
              '${space.type.toUpperCase()} · ${space.name}',
            if (_spaces.isEmpty) '当前还没有空间，注册后会自动创建默认空间。',
          ],
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '最近公共内容',
          lines: [
            for (final post in _publicPosts.take(3))
              '${post.authorName}: ${post.title}',
            if (_publicPosts.isEmpty) '公共空间里还没有内容。',
          ],
          trailing: FilledButton.tonal(
            onPressed: _publicPosts.isEmpty
                ? null
                : () => _openPostDetail(_publicPosts.first.id),
            child: const Text('查看详情'),
          ),
        ),
      ],
    );

    if (compact) {
      return Column(children: [left, const SizedBox(height: 16), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildPrivateView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpaceComposer(type: 'private'),
        const SizedBox(height: 16),
        _buildPostComposer(
          title: '发布私人内容',
          subtitle: '私人内容仅自己可见，适合草稿、笔记和内部记录。',
          titleController: _privatePostTitleController,
          contentController: _privatePostContentController,
          status: _privatePostStatus,
          onStatusChanged: (value) =>
              setState(() => _privatePostStatus = value),
          onSubmit: () => _publishPost(
            visibility: 'private',
            titleController: _privatePostTitleController,
            contentController: _privatePostContentController,
            status: _privatePostStatus,
          ),
        ),
        const SizedBox(height: 16),
        _buildSpaceList('私人空间列表', _privateSpaces),
        const SizedBox(height: 16),
        _buildPostStream(_privatePosts, emptyText: '还没有私人内容。'),
      ],
    );
  }

  Widget _buildPublicView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpaceComposer(type: 'public'),
        const SizedBox(height: 16),
        _buildPostComposer(
          title: '发布公共内容',
          subtitle: '公开文章会出现在公共空间和作者主页。',
          titleController: _publicPostTitleController,
          contentController: _publicPostContentController,
          status: _publicPostStatus,
          onStatusChanged: (value) => setState(() => _publicPostStatus = value),
          onSubmit: () => _publishPost(
            visibility: 'public',
            titleController: _publicPostTitleController,
            contentController: _publicPostContentController,
            status: _publicPostStatus,
          ),
        ),
        const SizedBox(height: 16),
        _buildSpaceList('公共空间列表', _publicSpaces),
        const SizedBox(height: 16),
        _buildPostStream(_publicPosts, emptyText: '公共空间里还没有内容。'),
      ],
    );
  }

  Widget _buildProfileView() {
    final profile = _profileUser;
    if (profile == null) {
      return InfoCard(title: '个人主页', lines: const ['尚未加载资料，点击左侧个人主页重新进入。']);
    }

    final isOwnProfile = _user != null && profile.id == _user!.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: profile.displayName,
          lines: [
            '用户 ID: ${profile.id}',
            if (profile.email.isNotEmpty) '邮箱: ${profile.email}',
            if (profile.phone.isNotEmpty) '手机号: ${profile.phone}',
            '状态: ${profile.status}',
            if (!isOwnProfile && profile.relationStatus.isNotEmpty)
              '关系: ${profile.relationStatus} / ${profile.direction}',
            if (isOwnProfile)
              '已连接链: ${_connectedChains.isEmpty ? '暂无' : _connectedChains.join(', ')}',
          ],
          trailing: isOwnProfile
              ? FilledButton.tonal(
                  onPressed: () => _navigateTo(AppView.blockchain),
                  child: const Text('链上账号'),
                )
              : null,
        ),
        const SizedBox(height: 16),
        if (isOwnProfile)
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
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _saveProfile,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (profile.relationStatus.isEmpty)
                FilledButton.tonal(
                  onPressed: () => _addFriend(profile.id),
                  child: const Text('添加好友'),
                ),
              if (profile.relationStatus == 'pending' &&
                  profile.direction == 'incoming')
                FilledButton.tonal(
                  onPressed: () => _acceptFriend(profile.id),
                  child: const Text('接受好友'),
                ),
              if (profile.relationStatus == 'accepted')
                FilledButton.tonal(
                  onPressed: () {
                    final friend = _findFriend(profile.id, _friends);
                    if (friend != null) {
                      _startChat(friend);
                    }
                  },
                  child: const Text('发起聊天'),
                ),
            ],
          ),
        const SizedBox(height: 16),
        _buildPostStream(
          _profilePosts,
          emptyText: isOwnProfile ? '你还没有发布内容。' : '这个用户还没有公开内容。',
        ),
      ],
    );
  }

  Widget _buildPostDetailView() {
    final post = _currentPost;
    if (post == null) {
      return InfoCard(title: '文章详情', lines: const ['先从公共空间或个人主页打开一篇文章。']);
    }

    final isOwnPost = _user != null && post.userId == _user!.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostCard(
          post: post,
          commentController: _commentControllers.putIfAbsent(
            post.id,
            TextEditingController.new,
          ),
          onLike: () => _toggleLike(post),
          onShare: () => _sharePost(post),
          onComment: () => _comment(post),
          onOpenAuthor: () => _openProfile(post.userId),
          onOpenDetail: null,
          onEdit: isOwnPost ? () {} : null,
        ),
        const SizedBox(height: 16),
        if (isOwnPost)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('编辑文章', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editPostTitleController,
                    decoration: const InputDecoration(labelText: '标题'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editPostContentController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: '内容'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _editPostVisibility,
                          decoration: const InputDecoration(labelText: '可见性'),
                          items: const [
                            DropdownMenuItem(
                              value: 'public',
                              child: Text('公开'),
                            ),
                            DropdownMenuItem(
                              value: 'private',
                              child: Text('私密'),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => _editPostVisibility =
                                value ?? _editPostVisibility,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _editPostStatus,
                          decoration: const InputDecoration(labelText: '状态'),
                          items: const [
                            DropdownMenuItem(
                              value: 'published',
                              child: Text('已发布'),
                            ),
                            DropdownMenuItem(value: 'draft', child: Text('草稿')),
                            DropdownMenuItem(
                              value: 'hidden',
                              child: Text('隐藏'),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => _editPostStatus = value ?? _editPostStatus,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: _loading ? null : _savePostEdits,
                        child: const Text('保存修改'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLevelsView() {
    final currentLevel = _user?.level ?? 'basic';
    final cards = [
      LevelCardData(
        level: 'basic',
        title: 'Basic',
        text: '默认身份，可访问工作台、公共空间和基础资料。',
      ),
      LevelCardData(
        level: 'premium',
        title: 'Premium',
        text: '解锁私密内容、好友互动和更完整的工作流。',
      ),
      LevelCardData(level: 'vip', title: 'VIP', text: '强化身份层级和长期会员展示，适合高活跃用户。'),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((item) {
        final active = currentLevel == item.level;
        return SizedBox(
          width: 320,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(item.text),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: active ? null : () => _activatePlan(item.level),
                    child: Text(active ? '当前等级' : '切换到 ${item.level}'),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionView() {
    final currentPlan = _subscription?.planId.isNotEmpty == true
        ? _subscription!.planId
        : 'basic';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
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
          children: [
            PlanCard(
              planId: 'basic',
              title: 'Basic',
              features: ['公共内容流', '基础资料', '默认空间'],
              isLoading: _loading,
              onActivate: _activatePlan,
            ),
            PlanCard(
              planId: 'premium',
              title: 'Premium',
              features: ['私密内容', '聊天能力', '扩展社交功能'],
              isLoading: _loading,
              onActivate: _activatePlan,
            ),
            PlanCard(
              planId: 'vip',
              title: 'VIP',
              features: ['高级身份层级', '长期会员', '更强展示能力'],
              isLoading: _loading,
              onActivate: _activatePlan,
            ),
          ].map((card) => SizedBox(width: 300, child: card)).toList(),
        ),
      ],
    );
  }

  Widget _buildBlockchainView() {
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
                        initialValue: _externalProvider,
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
                        initialValue: _externalChain,
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
                  child: InfoCard(
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

  Widget _buildFriendsView() {
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
                Text('搜索用户', style: Theme.of(context).textTheme.titleLarge),
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
                          width: 300,
                          child: InfoCard(
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _friends
              .map(
                (friend) => SizedBox(
                  width: 320,
                  child: InfoCard(
                    title: friend.displayName,
                    lines: [
                      friend.secondary,
                      '状态: ${friend.status}',
                      '方向: ${friend.direction}',
                    ],
                    trailing: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => _openProfile(friend.id),
                          child: const Text('主页'),
                        ),
                        if (friend.direction == 'incoming' &&
                            friend.status == 'pending')
                          FilledButton.tonal(
                            onPressed: () => _acceptFriend(friend.id),
                            child: const Text('接受'),
                          )
                        else
                          FilledButton.tonal(
                            onPressed: friend.status == 'accepted'
                                ? () => _startChat(friend)
                                : null,
                            child: const Text('聊天'),
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildChatView(double width) {
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
              final friend = _findFriend(item.peerId, _friends);
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
            ..._acceptedFriends.map(
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
              height: 460,
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

  Widget _buildSpaceComposer({required String type}) {
    final title = type == 'private' ? '创建私人空间' : '创建公共空间';
    final subtitle = type == 'private'
        ? '私人空间适合沉淀草稿和只对自己可见的内容。'
        : '公共空间适合对外展示项目和发布公开内容。';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 16),
            TextField(
              controller: _spaceNameController,
              decoration: const InputDecoration(labelText: '空间名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _spaceDescriptionController,
              decoration: const InputDecoration(labelText: '空间描述'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : () => _createSpace(type),
              child: const Text('创建空间'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostComposer({
    required String title,
    required String subtitle,
    required TextEditingController titleController,
    required TextEditingController contentController,
    required String status,
    required ValueChanged<String> onStatusChanged,
    required VoidCallback onSubmit,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: '内容'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: '状态'),
                    items: const [
                      DropdownMenuItem(value: 'published', child: Text('已发布')),
                      DropdownMenuItem(value: 'draft', child: Text('草稿')),
                      DropdownMenuItem(value: 'hidden', child: Text('隐藏')),
                    ],
                    onChanged: (value) => onStatusChanged(value ?? status),
                  ),
                ),
                FilledButton(
                  onPressed: _loading ? null : onSubmit,
                  child: const Text('提交'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceList(String title, List<SpaceItem> spaces) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: spaces
              .map(
                (space) => SizedBox(
                  width: 320,
                  child: InfoCard(
                    title: space.name,
                    lines: [space.description, '类型: ${space.type}'],
                  ),
                ),
              )
              .toList(),
        ),
        if (spaces.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('当前还没有空间。'),
          ),
      ],
    );
  }

  Widget _buildPostStream(List<PostItem> posts, {required String emptyText}) {
    if (posts.isEmpty) {
      return InfoCard(title: '内容流', lines: [emptyText]);
    }
    return Column(
      children: [
        for (var index = 0; index < posts.length; index++) ...[
          PostCard(
            post: posts[index],
            commentController: _commentControllers.putIfAbsent(
              posts[index].id,
              TextEditingController.new,
            ),
            onLike: () => _toggleLike(posts[index]),
            onShare: () => _sharePost(posts[index]),
            onComment: () => _comment(posts[index]),
            onOpenAuthor: () => _openProfile(posts[index].userId),
            onOpenDetail: () => _openPostDetail(posts[index].id),
            onEdit: _user != null && posts[index].userId == _user!.id
                ? () => _openPostDetail(posts[index].id)
                : null,
          ),
          if (index < posts.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.view, this.label, this.icon);

  final AppView view;
  final String label;
  final IconData icon;
}
