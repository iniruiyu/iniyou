import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api/api_client.dart';
import 'controllers/app_actions.dart';
import 'controllers/post_state_actions.dart';
import 'controllers/session_actions.dart';
import 'models/app_models.dart';
import 'views/authenticated_shell_view.dart';
import 'views/content_sections.dart';
import 'views/guest_landing_view.dart';
import 'views/section_body_router.dart';
import 'views/settings_views.dart';
import 'views/shell_widgets.dart';
import 'views/social_views.dart';
import 'views/view_state_helpers.dart';
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
    final sessionRestored = SessionActions.restoreSession(_api, _prefs!);
    if (sessionRestored) {
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
    final dashboard = await AppActions.loadDashboard(_api);
    _displayNameController.text = dashboard.user.displayName;

    if (!mounted) {
      return;
    }

    setState(() {
      _user = dashboard.user;
      _spaces = dashboard.spaces;
      _publicPosts = dashboard.publicPosts;
      _privatePosts = dashboard.privatePosts;
      _friends = dashboard.friends;
      _conversations = dashboard.conversations;
      _subscription = dashboard.subscription;
      _externalAccounts = dashboard.externalAccounts;
      if (_activeChat != null) {
        _activeChat = findFriendById(_activeChat!.id, dashboard.friends);
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
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await SessionActions.login(
        _api,
        prefs,
        account: _loginAccountController.text.trim(),
        password: _loginPasswordController.text,
      );
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
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await SessionActions.register(
        _api,
        prefs,
        email: _registerEmailController.text.trim(),
        phone: _registerPhoneController.text.trim(),
        password: _registerPasswordController.text,
      );
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
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await SessionActions.logout(_api, prefs, clearRemote: clearRemote);
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
    final channel = SessionActions.connectSocket(_api);
    if (channel == null) {
      _channel = null;
      return;
    }
    _channel = channel;
    _socketSubscription = _channel!.stream.listen((event) async {
      if (_user == null) {
        return;
      }
      final peerId = SessionActions.extractPeerIdFromSocketEvent(
        event,
        _user!.id,
      );
      if (peerId == null) {
        return;
      }
      final conversations = await _api.listConversations();
      if (!mounted) {
        return;
      }
      setState(() => _conversations = conversations);
      if (_activeChat?.id == peerId) {
        final friend = findFriendById(peerId, _friends);
        if (friend != null) {
          await _loadMessages(friend, quiet: true);
        }
      }
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
      _spaces = await AppActions.createSpaceAndReload(
        _api,
        type: type,
        name: name,
        description: description,
      );
      _spaceNameController.clear();
      _spaceDescriptionController.clear();
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
      final result = await AppActions.createPostAndReload(
        _api,
        title: title,
        content: content,
        visibility: visibility,
        status: status,
      );
      titleController.clear();
      contentController.clear();
      _applyPostUpdate(result.post);
      if (visibility == 'public') {
        _publicPosts = result.posts;
      } else {
        _privatePosts = result.posts;
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
    final next = PostStateActions.applyPostUpdate(
      updated: updated,
      publicPosts: _publicPosts,
      privatePosts: _privatePosts,
      profilePosts: _profilePosts,
      currentPost: _currentPost,
    );
    setState(() {
      _publicPosts = next.publicPosts;
      _privatePosts = next.privatePosts;
      _profilePosts = next.profilePosts;
      _currentPost = next.currentPost;
    });
  }

  Future<void> _openProfile(String userId) async {
    await _runBusy(() => _loadProfile(userId));
  }

  Future<void> _loadProfile(String userId, {bool quiet = false}) async {
    Future<void> action() async {
      final profile = await AppActions.loadProfile(
        _api,
        userId: userId,
        ownProfile: _user != null && userId == _user!.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profileUser = profile.profileUser;
        _profilePosts = profile.posts;
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
      final detail = await AppActions.loadPostDetail(_api, postId);
      final post = detail.post;
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
      final result = await AppActions.addFriendAndReload(
        _api,
        friendId: friendId,
        query: _friendSearchController.text.trim(),
      );
      _friends = result.friends;
      _searchResults = result.searchResults;
      if (!mounted) {
        return;
      }
      setState(() => _flash = '好友请求已发送');
    });
  }

  Future<void> _acceptFriend(String friendId) async {
    await _runBusy(() async {
      final result = await AppActions.acceptFriendAndReload(_api, friendId);
      _friends = result.friends;
      _conversations = result.conversations;
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
      final items = await AppActions.loadMessages(_api, friend.id);
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
      final chat = await AppActions.sendMessageAndReload(
        _api,
        peerId: peer.id,
        content: content,
      );
      _chatComposerController.clear();
      _messages = chat.messages;
      _conversations = chat.conversations;
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
      final result = await AppActions.activatePlan(_api, planId);
      _subscription = result.subscription;
      _user = result.user;
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
      _externalAccounts = await AppActions.bindExternalAccountAndReload(
        _api,
        provider: _externalProvider,
        chain: _externalChain,
        address: _externalAddressController.text.trim(),
        signature: _externalSignatureController.text.trim(),
      );
      _externalAddressController.clear();
      _externalSignatureController.clear();
      if (!mounted) {
        return;
      }
      setState(() => _flash = '外部账号已绑定');
    });
  }

  Future<void> _removeExternalAccount(String id) async {
    await _runBusy(() async {
      _externalAccounts = await AppActions.removeExternalAccountAndReload(
        _api,
        id,
      );
      if (!mounted) {
        return;
      }
      setState(() => _flash = '外部账号已移除');
    });
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
          pageTitle: pageTitleForView(
            _view,
            profileUser: _profileUser,
            currentPost: _currentPost,
          ),
          pageSubtitle: pageSubtitleForView(_view),
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
                    '私人 ${privateSpaces(_spaces).length} / 公共 ${publicSpaces(_spaces).length}',
                  ),
                  SummaryCardData(
                    '好友',
                    '${acceptedFriends(_friends).length}',
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
                    connectedChains(_externalAccounts).isEmpty
                        ? '尚未连接链'
                        : connectedChains(_externalAccounts).join(', '),
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
      selectedViewKey: sidebarViewKey(_view),
      items: defaultShellSidebarItems,
      onNavigate: (viewKey) => _navigateTo(appViewFromKey(viewKey)),
    );
  }

  Widget _buildBanner() {
    return BannerCard(error: _error, flash: _flash);
  }

  Widget _buildSectionBody(double width) {
    return sectionBodyForView(
      _view,
      dashboard: _buildDashboardView(width),
      privateSpace: _buildPrivateView(),
      publicSpace: _buildPublicView(),
      profile: _buildProfileView(),
      postDetail: _buildPostDetailView(),
      levels: _buildLevelsView(),
      subscription: _buildSubscriptionView(),
      blockchain: _buildBlockchainView(),
      friends: _buildFriendsView(),
      chat: _buildChatView(width),
    );
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
        SpaceListSection(title: '私人空间列表', spaces: privateSpaces(_spaces)),
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
        SpaceListSection(title: '公共空间列表', spaces: publicSpaces(_spaces)),
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
      connectedChains: connectedChains(_externalAccounts),
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
        final friend = findFriendById(profile.id, _friends);
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
      acceptedFriends: acceptedFriends(_friends),
      conversations: _conversations,
      messages: _messages,
      chatComposerController: _chatComposerController,
      loading: _loading,
      findFriend: (id) => findFriendById(id, _friends),
      onStartChat: _startChat,
      onSendMessage: _sendMessage,
    );
  }
}
