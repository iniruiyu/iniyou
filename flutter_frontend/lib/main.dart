import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api/api_client.dart';
import 'models/app_models.dart';
import 'views/authenticated_shell_view.dart';
import 'views/content_sections.dart';
import 'views/guest_landing_view.dart';
import 'views/settings_views.dart';
import 'views/shell_widgets.dart';
import 'views/social_views.dart';
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
      return GuestLandingView(
        loginMode: _loginMode,
        loading: _loading,
        error: _error,
        loginAccountController: _loginAccountController,
        loginPasswordController: _loginPasswordController,
        registerEmailController: _registerEmailController,
        registerPhoneController: _registerPhoneController,
        registerPasswordController: _registerPasswordController,
        onToggleMode: (value) => setState(() => _loginMode = value),
        onLogin: _login,
        onRegister: _register,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1120;
        return AuthenticatedShellView(
          userLabel: _user!.displayName.isEmpty
              ? _user!.id
              : _user!.displayName,
          pageTitle: _pageTitle,
          pageSubtitle: _pageSubtitle,
          loading: _loading,
          wide: wide,
          sidebar: _buildSidebar(),
          onRefresh: () => _runBusy(_refreshAll),
          onLogout: _logout,
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildBanner(),
              const SizedBox(height: 16),
              TopSummaryRow(
                width: constraints.maxWidth,
                cards: [
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
                    _connectedChains.isEmpty
                        ? '尚未连接链'
                        : _connectedChains.join(', '),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionBody(constraints.maxWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return ShellSidebar(
      user: _user!,
      subscription: _subscription,
      conversations: _conversations,
      selectedViewKey: _sidebarViewKey(_view),
      items: const [
        ShellSidebarItem(
          viewKey: 'dashboard',
          label: '工作台',
          icon: Icons.dashboard_outlined,
        ),
        ShellSidebarItem(
          viewKey: 'private',
          label: '私人空间',
          icon: Icons.lock_outline,
        ),
        ShellSidebarItem(viewKey: 'public', label: '公共空间', icon: Icons.public),
        ShellSidebarItem(
          viewKey: 'profile',
          label: '个人主页',
          icon: Icons.person_outline,
        ),
        ShellSidebarItem(
          viewKey: 'levels',
          label: '等级',
          icon: Icons.stars_outlined,
        ),
        ShellSidebarItem(
          viewKey: 'subscription',
          label: '订阅',
          icon: Icons.workspace_premium_outlined,
        ),
        ShellSidebarItem(
          viewKey: 'blockchain',
          label: '区块链',
          icon: Icons.hub_outlined,
        ),
        ShellSidebarItem(
          viewKey: 'friends',
          label: '好友',
          icon: Icons.people_alt_outlined,
        ),
        ShellSidebarItem(
          viewKey: 'chat',
          label: '聊天',
          icon: Icons.chat_bubble_outline,
        ),
      ],
      onNavigate: (viewKey) => _navigateTo(_appViewFromKey(viewKey)),
    );
  }

  Widget _buildBanner() {
    return BannerCard(error: _error, flash: _flash);
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
    return DashboardOverviewView(
      width: width,
      user: _user!,
      spaces: _spaces,
      publicPosts: _publicPosts,
      onOpenPublicSpace: () => _navigateTo(AppView.publicSpace),
      onOpenPostDetail: _openPostDetail,
    );
  }

  Widget _buildPrivateView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpaceComposerCard(
          type: 'private',
          loading: _loading,
          nameController: _spaceNameController,
          descriptionController: _spaceDescriptionController,
          onSubmit: () => _createSpace('private'),
        ),
        const SizedBox(height: 16),
        PostComposerCard(
          loading: _loading,
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
        SpaceListSection(title: '私人空间列表', spaces: _privateSpaces),
        const SizedBox(height: 16),
        PostStreamSection(
          posts: _privatePosts,
          emptyText: '还没有私人内容。',
          commentControllerFor: (postId) => _commentControllers.putIfAbsent(
            postId,
            TextEditingController.new,
          ),
          onLike: _toggleLike,
          onShare: _sharePost,
          onComment: _comment,
          onOpenAuthor: _openProfile,
          onOpenDetail: _openPostDetail,
          canEditPost: (post) => _user != null && post.userId == _user!.id,
        ),
      ],
    );
  }

  Widget _buildPublicView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpaceComposerCard(
          type: 'public',
          loading: _loading,
          nameController: _spaceNameController,
          descriptionController: _spaceDescriptionController,
          onSubmit: () => _createSpace('public'),
        ),
        const SizedBox(height: 16),
        PostComposerCard(
          loading: _loading,
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
        SpaceListSection(title: '公共空间列表', spaces: _publicSpaces),
        const SizedBox(height: 16),
        PostStreamSection(
          posts: _publicPosts,
          emptyText: '公共空间里还没有内容。',
          commentControllerFor: (postId) => _commentControllers.putIfAbsent(
            postId,
            TextEditingController.new,
          ),
          onLike: _toggleLike,
          onShare: _sharePost,
          onComment: _comment,
          onOpenAuthor: _openProfile,
          onOpenDetail: _openPostDetail,
          canEditPost: (post) => _user != null && post.userId == _user!.id,
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    return ProfileView(
      user: _user,
      profileUser: _profileUser,
      profilePosts: _profilePosts,
      connectedChains: _connectedChains,
      displayNameController: _displayNameController,
      loading: _loading,
      commentControllerFor: (postId) =>
          _commentControllers.putIfAbsent(postId, TextEditingController.new),
      onSaveProfile: _saveProfile,
      onAddFriend: _addFriend,
      onAcceptFriend: _acceptFriend,
      onStartChat: () {
        final profile = _profileUser;
        if (profile == null) {
          return;
        }
        final friend = _findFriend(profile.id, _friends);
        if (friend != null) {
          _startChat(friend);
        }
      },
      onToggleLike: _toggleLike,
      onSharePost: _sharePost,
      onCommentPost: _comment,
      onOpenProfile: _openProfile,
      onOpenPostDetail: _openPostDetail,
    );
  }

  Widget _buildPostDetailView() {
    final post = _currentPost;
    return PostDetailView(
      user: _user,
      currentPost: post,
      loading: _loading,
      commentController: _commentControllers.putIfAbsent(
        post?.id ?? '__missing__',
        TextEditingController.new,
      ),
      editTitleController: _editPostTitleController,
      editContentController: _editPostContentController,
      editVisibility: _editPostVisibility,
      editStatus: _editPostStatus,
      onEditVisibilityChanged: (value) =>
          setState(() => _editPostVisibility = value),
      onEditStatusChanged: (value) => setState(() => _editPostStatus = value),
      onLike: () {
        final current = _currentPost;
        if (current != null) {
          _toggleLike(current);
        }
      },
      onShare: () {
        final current = _currentPost;
        if (current != null) {
          _sharePost(current);
        }
      },
      onComment: () {
        final current = _currentPost;
        if (current != null) {
          _comment(current);
        }
      },
      onOpenAuthor: () {
        final current = _currentPost;
        if (current != null) {
          _openProfile(current.userId);
        }
      },
      onSaveEdits: _savePostEdits,
    );
  }

  Widget _buildLevelsView() {
    return LevelsView(
      currentLevel: _user?.level ?? 'basic',
      onActivateLevel: _activatePlan,
    );
  }

  Widget _buildSubscriptionView() {
    return SubscriptionView(
      subscription: _subscription,
      loading: _loading,
      onActivatePlan: _activatePlan,
    );
  }

  Widget _buildBlockchainView() {
    final chainsByProvider = const {
      'evm': ['ethereum', 'base', 'bsc', 'polygon'],
      'solana': ['solana'],
      'tron': ['tron'],
    };
    if (!chainsByProvider[_externalProvider]!.contains(_externalChain)) {
      _externalChain = chainsByProvider[_externalProvider]!.first;
    }
    return BlockchainView(
      loading: _loading,
      externalProvider: _externalProvider,
      externalChain: _externalChain,
      externalAccounts: _externalAccounts,
      addressController: _externalAddressController,
      signatureController: _externalSignatureController,
      onProviderChanged: (value) => setState(() {
        _externalProvider = value;
        _externalChain = chainsByProvider[value]!.first;
      }),
      onChainChanged: (value) => setState(() => _externalChain = value),
      onBind: _bindExternalAccount,
      onRemove: _removeExternalAccount,
    );
  }

  Widget _buildFriendsView() {
    return FriendsView(
      loading: _loading,
      searchController: _friendSearchController,
      searchResults: _searchResults,
      friends: _friends,
      onSearch: _searchUsers,
      onAddFriend: _addFriend,
      onAcceptFriend: _acceptFriend,
      onOpenProfile: _openProfile,
      onStartChat: _startChat,
    );
  }

  Widget _buildChatView(double width) {
    return ChatView(
      width: width,
      user: _user!,
      activeChat: _activeChat,
      acceptedFriends: _acceptedFriends,
      conversations: _conversations,
      messages: _messages,
      chatComposerController: _chatComposerController,
      loading: _loading,
      findFriend: (id) => _findFriend(id, _friends),
      onStartChat: _startChat,
      onSendMessage: _sendMessage,
    );
  }

  String _sidebarViewKey(AppView view) {
    if (view == AppView.postDetail) {
      return 'public';
    }
    switch (view) {
      case AppView.dashboard:
        return 'dashboard';
      case AppView.privateSpace:
        return 'private';
      case AppView.publicSpace:
        return 'public';
      case AppView.profile:
        return 'profile';
      case AppView.postDetail:
        return 'public';
      case AppView.levels:
        return 'levels';
      case AppView.subscription:
        return 'subscription';
      case AppView.blockchain:
        return 'blockchain';
      case AppView.friends:
        return 'friends';
      case AppView.chat:
        return 'chat';
    }
  }

  AppView _appViewFromKey(String key) {
    switch (key) {
      case 'dashboard':
        return AppView.dashboard;
      case 'private':
        return AppView.privateSpace;
      case 'public':
        return AppView.publicSpace;
      case 'profile':
        return AppView.profile;
      case 'levels':
        return AppView.levels;
      case 'subscription':
        return AppView.subscription;
      case 'blockchain':
        return AppView.blockchain;
      case 'friends':
        return AppView.friends;
      case 'chat':
        return AppView.chat;
      default:
        return AppView.dashboard;
    }
  }
}
