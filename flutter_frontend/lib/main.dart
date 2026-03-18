import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api/api_client.dart';
import 'controllers/app_actions.dart';
import 'controllers/chat_media_actions.dart';
import 'controllers/post_state_actions.dart';
import 'controllers/session_actions.dart';
import 'i18n/app_i18n.dart';
import 'models/app_models.dart';
import 'views/authenticated_home_view.dart';
import 'views/authenticated_shell_view.dart';
import 'views/guest_landing_view.dart';
import 'views/section_body_router.dart';
import 'views/shell_widgets.dart';
import 'views/view_factories.dart';
import 'views/view_state_helpers.dart';

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
  space,
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

enum ProfileTab { levels, subscription, blockchain }

class IniyouHome extends StatefulWidget {
  const IniyouHome({super.key});

  @override
  State<IniyouHome> createState() => _IniyouHomeState();
}

class _IniyouHomeState extends State<IniyouHome> {
  static const _languageKey = 'iniyou_language';
  static const _themeKey = 'iniyou_theme';
  static const _activePrivateSpaceKey = 'iniyou_active_private_space';
  static const _activePublicSpaceKey = 'iniyou_active_public_space';
  final ApiClient _api = ApiClient();

  final _loginAccountController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _domainController = TextEditingController();
  final _signatureController = TextEditingController();
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
  final _spaceSubdomainController = TextEditingController();
  final _editPostTitleController = TextEditingController();
  final _editPostContentController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};

  SharedPreferences? _prefs;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;

  bool _booting = true;
  bool _loading = false;
  bool _loginMode = true;
  String _languageCode = AppI18n.defaultLanguageCode;
  // Current theme key for skin switching.
  // 皮肤切换的当前主题键。
  String _themeKeyValue = 'midnight';
  // Sidebar collapsed state.
  // 侧边栏折叠状态。
  bool _sidebarCollapsed = false;
  // Current profile tab.
  // 当前个人主页选项卡。
  ProfileTab _profileTab = ProfileTab.levels;
  // Whether the current host route has already been applied.
  // 当前主机路由是否已经应用。
  bool _hostRouteApplied = false;
  // Active private space ID.
  // 当前私人空间 ID。
  String? _activePrivateSpaceId;
  // Active public space ID.
  // 当前公共空间 ID。
  String? _activePublicSpaceId;
  String? _error;
  String? _flash;
  String _publicPostStatus = 'published';
  String _privatePostStatus = 'draft';
  String _externalProvider = 'evm';
  String _externalChain = 'ethereum';
  String _phoneVisibility = 'private';
  String _emailVisibility = 'private';
  String _ageVisibility = 'private';
  String _genderVisibility = 'private';
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
  ChatAttachmentDraft? _chatAttachment;

  // Available theme options for the settings menu.
  // 设置菜单可选主题列表。
  static const List<ThemeOption> _themeOptions = [
    ThemeOption(key: 'midnight', labelKey: 'theme.midnight'),
    ThemeOption(key: 'dawn', labelKey: 'theme.dawn'),
    ThemeOption(key: 'ocean', labelKey: 'theme.ocean'),
  ];

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
      _usernameController,
      _domainController,
      _signatureController,
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
      _spaceSubdomainController,
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
    final savedLanguage = _prefs?.getString(_languageKey);
    if (savedLanguage != null &&
        AppI18n.supportedLanguageCodes.contains(savedLanguage)) {
      _languageCode = savedLanguage;
    }
    // Restore saved theme selection.
    // 恢复保存的皮肤主题选择。
    final savedTheme = _prefs?.getString(_themeKey);
    if (savedTheme != null &&
        _themeOptions.any((option) => option.key == savedTheme)) {
      _themeKeyValue = savedTheme;
    }
    _activePrivateSpaceId = _prefs?.getString(_activePrivateSpaceKey);
    _activePublicSpaceId = _prefs?.getString(_activePublicSpaceKey);
    final sessionRestored = SessionActions.restoreSession(_api, _prefs!);
    if (sessionRestored) {
      try {
        await _refreshAll();
        await _applyHostRouteFromCurrentHost();
        _connectSocket();
      } catch (_) {
        await _logout(clearRemote: false);
      }
    }
    if (mounted) {
      setState(() => _booting = false);
    }
  }

  String _t(String key) => AppI18n.tr(_languageCode, key);

  String _peerT(String key) {
    // Resolve the counterpart language for bilingual labels.
    // 解析双语标签的另一种语言，保持主副语言分层展示。
    final peerLanguageCode = _languageCode == 'en-US' ? 'zh-CN' : 'en-US';
    return AppI18n.tr(peerLanguageCode, key);
  }

  int get _unreadMessageCount =>
      _conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);

  int get _pendingFriendCount => _friends
      .where(
        (friend) =>
            friend.status == 'pending' && friend.direction == 'incoming',
      )
      .length;

  FriendItem? get _topPendingFriend {
    final pending =
        _friends
            .where(
              (friend) =>
                  friend.status == 'pending' && friend.direction == 'incoming',
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pending.isEmpty ? null : pending.first;
  }

  Future<void> _setLanguage(String languageCode) async {
    if (!AppI18n.supportedLanguageCodes.contains(languageCode)) {
      return;
    }
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    if (!mounted) {
      return;
    }
    setState(() => _languageCode = languageCode);
  }

  void _toggleSidebar() {
    // Toggle sidebar collapsed state.
    // 切换侧边栏折叠状态。
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  void _setProfileTab(ProfileTab tab) {
    // Switch profile tab.
    // 切换个人主页选项卡。
    setState(() => _profileTab = tab);
  }

  Future<void> _setTheme(String themeKey) async {
    // Persist and apply theme selection.
    // 保存并应用主题选择。
    if (!_themeOptions.any((option) => option.key == themeKey)) {
      return;
    }
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeKey);
    if (!mounted) {
      return;
    }
    setState(() => _themeKeyValue = themeKey);
  }

  ThemeData _themeDataFor(String themeKey) {
    // Build theme data for the selected skin.
    // 构建所选皮肤的主题数据。
    switch (themeKey) {
      case 'dawn':
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F80ED),
          brightness: Brightness.light,
        );
        return ThemeData(
          colorScheme: scheme,
          scaffoldBackgroundColor: const Color(0xFFF6F7FB),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFEEF1F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        );
      case 'ocean':
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF4DD6D3),
          brightness: Brightness.dark,
          surface: const Color(0xFF0B1E2D),
        );
        return ThemeData(
          colorScheme: scheme,
          scaffoldBackgroundColor: const Color(0xFF06131F),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            color: Color(0xFF0B1E2D),
            elevation: 0,
            margin: EdgeInsets.zero,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF10283B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        );
      case 'midnight':
      default:
        const seed = Color(0xFF6EE7FF);
        final scheme = ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          surface: const Color(0xFF101925),
        );
        return ThemeData(
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
        );
    }
  }

  List<Color> _backgroundGradientFor(String themeKey) {
    // Return background gradient colors per theme.
    // 返回各主题的背景渐变色。
    switch (themeKey) {
      case 'dawn':
        return const [Color(0xFFEEF1FF), Color(0xFFF6F7FB)];
      case 'ocean':
        return const [Color(0xFF12334F), Color(0xFF06131F)];
      case 'midnight':
      default:
        return const [Color(0xFF08111D), Color(0xFF0E1A2A)];
    }
  }

  SpaceItem? _selectedSpaceForVisibility(String visibility) {
    // Resolve the current space for a content visibility scope.
    // 为内容可见范围解析当前空间。
    final activeSpaceId = visibility == 'private'
        ? _activePrivateSpaceId
        : _activePublicSpaceId;
    final activeSpace = findSpaceById(_spaces, activeSpaceId);
    if (activeSpace != null && activeSpace.type == visibility) {
      return activeSpace;
    }
    final hostSpace = _spaceFromCurrentHost();
    if (hostSpace != null && hostSpace.type == visibility) {
      return hostSpace;
    }
    return firstSpaceOfType(_spaces, visibility);
  }

  String? _currentHostLabel() {
    // Extract the leading host label used for subdomain routing.
    // 提取用于子域名路由的首个主机标识。
    final host = Uri.base.host.toLowerCase();
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return null;
    }
    final parts = host
        .split('.')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (parts.length < 3 && !host.endsWith('.localhost')) {
      return null;
    }
    final label = parts.first;
    if (label.isEmpty || label == 'www') {
      return null;
    }
    return label;
  }

  SpaceItem? _spaceFromCurrentHost() {
    // Try to map the current host subdomain to a known space.
    // 尝试把当前主机的子域名映射到已知空间。
    final label = _currentHostLabel();
    if (label == null) {
      return null;
    }
    for (final space in _spaces) {
      if (space.subdomain.toLowerCase() == label) {
        return space;
      }
    }
    return null;
  }

  Future<bool> _applyHostRouteFromCurrentHost() async {
    // Route the current host label to a profile once per session.
    // 将当前主机标识在每个会话中仅路由一次到对应个人主页。
    if (_hostRouteApplied || _user == null) {
      return false;
    }
    final label = _currentHostLabel();
    if (label == null) {
      _hostRouteApplied = true;
      return false;
    }
    if (_spaceFromCurrentHost() != null) {
      _hostRouteApplied = true;
      return false;
    }
    try {
      await _loadProfileByDomain(label, quiet: true);
      _hostRouteApplied = true;
      return true;
    } catch (_) {
      try {
        await _loadProfileByUsername(label, quiet: true);
        _hostRouteApplied = true;
        return true;
      } catch (_) {
        _hostRouteApplied = true;
        return false;
      }
    }
  }

  String _suggestSpaceSubdomain(String name, String type) {
    // Build a simple subdomain suggestion from a human-readable name.
    // 根据可读名称构建一个简单的二级域名建议值。
    return _normalizeSpaceSlug(name);
  }

  String _normalizeSpaceSlug(String value) {
    // Keep only lowercase letters and digits for a space subdomain.
    // 仅保留小写英文字母和数字作为空间二级域名。
    final lower = value.trim().toLowerCase();
    if (lower.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final isLetter = rune >= 0x61 && rune <= 0x7a;
      final isDigit = rune >= 0x30 && rune <= 0x39;
      if (isLetter || isDigit) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  bool _isValidSpaceSubdomain(String value) {
    // Validate that the subdomain contains only letters, digits, and stays within 63 characters.
    // 校验二级域名只包含英文字母和数字，并限制在 63 个字符以内。
    return RegExp(r'^[a-z0-9]{1,63}$').hasMatch(value);
  }

  Future<void> _syncActiveSpaces() async {
    // Keep the selected spaces aligned with the current account data.
    // 让已选空间与当前账号数据保持同步。
    final privateSpace = _selectedSpaceForVisibility('private');
    final publicSpace = _selectedSpaceForVisibility('public');
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await _persistSpaceSelection(
      prefs,
      _activePrivateSpaceKey,
      privateSpace?.id,
    );
    await _persistSpaceSelection(prefs, _activePublicSpaceKey, publicSpace?.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _activePrivateSpaceId = privateSpace?.id;
      _activePublicSpaceId = publicSpace?.id;
    });
  }

  Future<void> _persistSpaceSelection(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    // Persist or clear a selected space ID.
    // 持久化或清除已选空间 ID。
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value);
  }

  Future<void> _setActiveSpace(SpaceItem space) async {
    // Store the selected space without changing the current page.
    // 仅保存当前空间选择，不直接切换页面。
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    if (space.type == 'private') {
      await _persistSpaceSelection(prefs, _activePrivateSpaceKey, space.id);
    } else {
      await _persistSpaceSelection(prefs, _activePublicSpaceKey, space.id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (space.type == 'private') {
        _activePrivateSpaceId = space.id;
      } else {
        _activePublicSpaceId = space.id;
      }
    });
  }

  Future<void> _setActiveSpaceById(String? spaceId, String visibility) async {
    // Store a selected space from its ID and visibility scope.
    // 根据空间 ID 和可见性范围保存已选空间。
    final candidate = findSpaceById(_spaces, spaceId);
    if (candidate != null) {
      await _setActiveSpace(candidate);
      return;
    }
    final fallback = _selectedSpaceForVisibility(visibility);
    if (fallback != null) {
      await _setActiveSpace(fallback);
    }
  }

  Future<void> _openSpaceComposer({
    required String defaultType,
    SpaceItem? space,
  }) async {
    // Open the space creation/edit dialog.
    // 打开空间创建/编辑弹窗。
    final isEditing = space != null;
    var selectedType = isEditing
        ? space.type
        : defaultType == 'private'
        ? 'private'
        : 'public';
    _spaceNameController.text = isEditing ? space.name : '';
    _spaceDescriptionController.text = isEditing ? space.description : '';
    _spaceSubdomainController.text = isEditing ? space.subdomain : '';
    if (!isEditing && _spaceSubdomainController.text.trim().isEmpty) {
      final suggestion = _suggestSpaceSubdomain(
        _spaceNameController.text,
        selectedType,
      );
      if (suggestion.isNotEmpty) {
        _spaceSubdomainController.text = suggestion;
      }
    }

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEditing ? '编辑空间' : '创建空间',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditing
                              ? '名称和二级域名可以独立修改，二级域名只能包含英文字母和数字，且最长 63 个字符。'
                              : '选择私人或公共空间，然后补充名称、描述和二级域名。名称和二级域名互不关联，二级域名最长 63 个字符。',
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          key: ValueKey('space-type-$selectedType'),
                          initialValue: selectedType,
                          decoration: const InputDecoration(labelText: '空间类型'),
                          items: const [
                            DropdownMenuItem(
                              value: 'private',
                              child: Text('私人空间'),
                            ),
                            DropdownMenuItem(
                              value: 'public',
                              child: Text('公共空间'),
                            ),
                          ],
                          onChanged: isEditing
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedType = value ?? selectedType;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _spaceNameController,
                          decoration: const InputDecoration(labelText: '空间名称'),
                          onChanged: isEditing
                              ? null
                              : (value) {
                                  if (_spaceSubdomainController.text
                                      .trim()
                                      .isEmpty) {
                                    final suggestion = _suggestSpaceSubdomain(
                                      value,
                                      selectedType,
                                    );
                                    if (suggestion.isNotEmpty) {
                                      setDialogState(() {
                                        _spaceSubdomainController.text =
                                            suggestion;
                                      });
                                    }
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _spaceSubdomainController,
                          maxLength: 63,
                          decoration: InputDecoration(
                            labelText: '二级域名（可选）',
                            helperText: isEditing
                                ? '仅允许英文字母和数字，且最长 63 个字符。'
                                : '仅允许英文字母和数字，最长 63 个字符，留空时后端会自动生成。',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _spaceDescriptionController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: '空间描述'),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.tonal(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      final name = _spaceNameController.text
                                          .trim();
                                      final description =
                                          _spaceDescriptionController.text
                                              .trim();
                                      final subdomain =
                                          _spaceSubdomainController.text
                                              .trim()
                                              .toLowerCase();
                                      if (name.isEmpty) {
                                        setState(() => _error = '空间名称不能为空');
                                        return;
                                      }
                                      if (subdomain.isNotEmpty &&
                                          !_isValidSpaceSubdomain(subdomain)) {
                                        setState(
                                          () => _error =
                                              '二级域名只能包含英文字母和数字，且最长 63 个字符',
                                        );
                                        return;
                                      }
                                      Navigator.of(dialogContext).pop();
                                      await _saveSpace(
                                        space: space,
                                        type: selectedType,
                                        name: name,
                                        description: description,
                                        subdomain: subdomain,
                                      );
                                    },
                              child: Text(isEditing ? '保存修改' : '创建空间'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    } finally {
      _spaceNameController.clear();
      _spaceDescriptionController.clear();
      _spaceSubdomainController.clear();
    }
  }

  Future<void> _openPostComposer({
    required String visibility,
    required SpaceItem? activeSpace,
  }) async {
    // Open the post publishing dialog.
    // 打开内容发布弹窗。
    final isPrivate = visibility == 'private';
    final titleController = isPrivate
        ? _privatePostTitleController
        : _publicPostTitleController;
    final contentController = isPrivate
        ? _privatePostContentController
        : _publicPostContentController;
    final spaces = isPrivate ? privateSpaces(_spaces) : publicSpaces(_spaces);
    if (spaces.isEmpty) {
      setState(() => _error = '请先创建对应空间');
      return;
    }
    var selectedSpaceId =
        activeSpace?.id ??
        _selectedSpaceForVisibility(visibility)?.id ??
        spaces.first.id;
    var selectedStatus = isPrivate ? _privatePostStatus : _publicPostStatus;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? dialogError;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final selectedSpace = findSpaceById(_spaces, selectedSpaceId);
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPrivate ? '发布私人内容' : '发布公共内容',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedSpace == null
                            ? '先选择一个空间，再填写标题和内容。'
                            : '当前空间：${selectedSpace.name} · @${selectedSpace.subdomain}',
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        key: ValueKey('space-select-$selectedSpaceId'),
                        initialValue: selectedSpaceId,
                        decoration: const InputDecoration(labelText: '发布空间'),
                        items: [
                          for (final space in spaces)
                            DropdownMenuItem(
                              value: space.id,
                              child: Text(
                                '${space.name} · @${space.subdomain}',
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedSpaceId = value ?? selectedSpaceId;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
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
                      DropdownButtonFormField<String>(
                        key: ValueKey('status-$selectedStatus'),
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(labelText: '状态'),
                        items: const [
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('已发布'),
                          ),
                          DropdownMenuItem(value: 'draft', child: Text('草稿')),
                          DropdownMenuItem(value: 'hidden', child: Text('隐藏')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedStatus = value ?? selectedStatus;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: _loading
                                ? null
                                : () async {
                                    final title = titleController.text.trim();
                                    final content = contentController.text
                                        .trim();
                                    if (title.isEmpty || content.isEmpty) {
                                      setDialogState(() {
                                        dialogError = '标题和内容不能为空';
                                      });
                                      return;
                                    }
                                    Navigator.of(dialogContext).pop();
                                    if (isPrivate) {
                                      setState(
                                        () =>
                                            _privatePostStatus = selectedStatus,
                                      );
                                    } else {
                                      setState(
                                        () =>
                                            _publicPostStatus = selectedStatus,
                                      );
                                    }
                                    await _publishPost(
                                      visibility: visibility,
                                      spaceId: selectedSpaceId,
                                      titleController: titleController,
                                      contentController: contentController,
                                      status: selectedStatus,
                                    );
                                  },
                            child: Text(isPrivate ? '保存到私人空间' : '发布到公共空间'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _enterSpace(SpaceItem space) async {
    // Enter a space and switch to the matching page.
    // 进入空间并切换到对应页面。
    await _setActiveSpace(space);
    if (!mounted) {
      return;
    }
    setState(() {
      _view = AppView.space;
      _flash = '已进入空间 · @${space.subdomain}';
      _error = null;
    });
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
    _usernameController.text = dashboard.user.username;
    _domainController.text = dashboard.user.domain;
    _signatureController.text = dashboard.user.signature;
    _phoneVisibility = dashboard.user.phoneVisibility;
    _emailVisibility = dashboard.user.emailVisibility;
    _ageVisibility = dashboard.user.ageVisibility;
    _genderVisibility = dashboard.user.genderVisibility;

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

    await _syncActiveSpaces();

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
      await _applyHostRouteFromCurrentHost();
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
      await _applyHostRouteFromCurrentHost();
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
      _chatAttachment = null;
      _hostRouteApplied = false;
      _activePrivateSpaceId = null;
      _activePublicSpaceId = null;
      _view = AppView.dashboard;
      _flash = null;
      _error = null;
      _displayNameController.clear();
      _usernameController.clear();
      _domainController.clear();
      _signatureController.clear();
      _phoneVisibility = 'private';
      _emailVisibility = 'private';
      _ageVisibility = 'private';
      _genderVisibility = 'private';
    });
    await prefs.remove(_activePrivateSpaceKey);
    await prefs.remove(_activePublicSpaceKey);
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
    // Redirect settings views into profile tabs.
    // 将设置类视图重定向到个人主页标签。
    if (view == AppView.levels) {
      _openProfileTab(ProfileTab.levels);
      return;
    }
    if (view == AppView.subscription) {
      _openProfileTab(ProfileTab.subscription);
      return;
    }
    if (view == AppView.blockchain) {
      _openProfileTab(ProfileTab.blockchain);
      return;
    }
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

  void _openProfileTab(ProfileTab tab) {
    // Open profile view with a selected tab.
    // 打开个人主页并定位到指定选项卡。
    if (mounted) {
      setState(() {
        _view = AppView.profile;
        _profileTab = tab;
        _error = null;
        _flash = null;
      });
    }
  }

  Future<bool> _confirmDangerousAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    // Confirm destructive actions with a dialog.
    // 通过弹窗确认破坏性操作。
    if (!mounted) {
      return false;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _removeCommentController(String postId) {
    // Dispose a cached comment editor for a post that no longer exists.
    // 释放已不存在文章对应的评论输入框缓存。
    final controller = _commentControllers.remove(postId);
    controller?.dispose();
  }

  Future<void> _saveSpace({
    SpaceItem? space,
    required String type,
    required String name,
    required String description,
    required String subdomain,
  }) async {
    // Create or update a space from the modal draft.
    // 根据弹窗草稿创建或更新空间。
    final normalizedSubdomain = subdomain.toLowerCase().trim();
    if (name.trim().isEmpty) {
      setState(() => _error = '空间名称不能为空');
      return;
    }
    if (space == null &&
        normalizedSubdomain.isNotEmpty &&
        !_isValidSpaceSubdomain(normalizedSubdomain)) {
      setState(() => _error = '二级域名只能包含英文字母和数字，且最长 63 个字符');
      return;
    }
    if (space != null && normalizedSubdomain.isEmpty) {
      setState(() => _error = '二级域名不能为空');
      return;
    }
    if (space != null && !_isValidSpaceSubdomain(normalizedSubdomain)) {
      setState(() => _error = '二级域名只能包含英文字母和数字，且最长 63 个字符');
      return;
    }

    await _runBusy(() async {
      if (space == null) {
        final result = await AppActions.createSpaceAndReload(
          _api,
          type: type,
          name: name.trim(),
          description: description.trim(),
          subdomain: normalizedSubdomain.isEmpty ? null : normalizedSubdomain,
        );
        _spaces = result.spaces;
        await _setActiveSpace(result.space);
        if (!mounted) {
          return;
        }
        setState(() {
          _view = AppView.space;
          _flash = '已创建空间 · @${result.space.subdomain}';
        });
        return;
      }

      final updated = await _api.updateSpace(
        id: space.id,
        name: name.trim(),
        description: description.trim(),
        subdomain: normalizedSubdomain,
      );
      _spaces = _spaces
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      await _setActiveSpace(updated);
      await _refreshAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _view = AppView.space;
        _flash = '空间已更新 · @${updated.subdomain}';
      });
    });
  }

  Future<void> _deleteSpace(SpaceItem space) async {
    // Delete a managed space and all of its content.
    // 删除可管理空间及其全部内容。
    final confirmed = await _confirmDangerousAction(
      title: '删除空间',
      message: '删除空间后，该空间下的文章、评论、点赞和转发记录都会一并删除，是否继续？',
      confirmLabel: '删除',
    );
    if (!confirmed) {
      return;
    }
    await _runBusy(() async {
      final currentPostBelongsToSpace = _currentPost?.spaceId == space.id;
      final relatedPostIds = <String>{
        if (_currentPost?.spaceId == space.id && _currentPost != null)
          _currentPost!.id,
        for (final post in _publicPosts)
          if (post.spaceId == space.id) post.id,
        for (final post in _privatePosts)
          if (post.spaceId == space.id) post.id,
        for (final post in _profilePosts)
          if (post.spaceId == space.id) post.id,
      };
      await _api.deleteSpace(space.id);
      for (final postId in relatedPostIds) {
        _removeCommentController(postId);
      }
      if (currentPostBelongsToSpace) {
        _currentPost = null;
        _editPostTitleController.clear();
        _editPostContentController.clear();
        _editPostVisibility = 'public';
        _editPostStatus = 'published';
        if (_view == AppView.postDetail) {
          _view = AppView.space;
        }
      }
      await _refreshAll();
      if (!mounted) {
        return;
      }
      setState(() => _flash = '空间已删除');
    });
  }

  Future<void> _deletePost(PostItem post) async {
    // Delete a managed post and all of its interactions.
    // 删除可管理文章及其所有互动记录。
    final confirmed = await _confirmDangerousAction(
      title: '删除文章',
      message: '删除文章后，关联的评论、点赞和转发记录都会一并删除，是否继续？',
      confirmLabel: '删除',
    );
    if (!confirmed) {
      return;
    }
    await _runBusy(() async {
      final currentPost = _currentPost;
      await _api.deletePost(post.id);
      _removeCommentController(post.id);
      if (currentPost?.id == post.id) {
        _currentPost = null;
        _editPostTitleController.clear();
        _editPostContentController.clear();
        _editPostVisibility = 'public';
        _editPostStatus = 'published';
        if (_view == AppView.postDetail) {
          _view = AppView.space;
        }
      }
      await _refreshAll();
      if (!mounted) {
        return;
      }
      setState(() => _flash = '文章已删除');
    });
  }

  Future<void> _publishPost({
    required String visibility,
    required String spaceId,
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
        spaceId: spaceId,
      );
      titleController.clear();
      contentController.clear();
      _applyPostUpdate(result.post);
      await _setActiveSpaceById(spaceId, visibility);
      if (visibility == 'public') {
        _publicPosts = result.posts;
      } else {
        _privatePosts = result.posts;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _view = AppView.space;
        _flash = visibility == 'public' ? '公共内容已发布' : '私人内容已保存';
      });
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
    // Reset profile tab when opening profile.
    // 打开个人主页时重置选项卡。
    _profileTab = ProfileTab.levels;
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

  Future<void> _loadProfileByUsername(
    String username, {
    bool quiet = false,
  }) async {
    Future<void> action() async {
      final profile = await _api.fetchUserProfileByUsername(username);
      final ownProfile = _user?.id == profile.id;
      final posts = await _api.listUserPosts(
        profile.id,
        visibility: ownProfile ? 'all' : 'public',
        limit: 50,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profileUser = profile;
        _profilePosts = posts;
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

  Future<void> _loadProfileByDomain(
    String domain, {
    bool quiet = false,
  }) async {
    Future<void> action() async {
      final profile = await _api.fetchUserProfileByDomain(domain);
      final ownProfile = _user?.id == profile.id;
      final posts = await _api.listUserPosts(
        profile.id,
        visibility: ownProfile ? 'all' : 'public',
        limit: 50,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profileUser = profile;
        _profilePosts = posts;
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
        spaceId: post.spaceId,
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
      _chatAttachment = null;
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

  Future<void> _pickChatAttachment(String messageType) async {
    // Pick and compress a media attachment for the current chat draft.
    // 为当前聊天草稿选择并压缩媒体附件。
    if (_activeChat == null) {
      setState(() => _error = '请先选择聊天对象');
      return;
    }
    final attachment = await pickChatAttachment(messageType);
    if (!mounted || attachment == null) {
      return;
    }
    setState(() {
      _chatAttachment = attachment;
      _view = AppView.chat;
      _error = null;
      _flash = null;
    });
  }

  void _clearChatAttachment() {
    // Clear the current chat attachment draft.
    // 清空当前聊天附件草稿。
    setState(() => _chatAttachment = null);
  }

  Future<void> _sendMessage() async {
    final peer = _activeChat;
    if (peer == null) {
      setState(() => _error = '请先选择聊天对象');
      return;
    }
    final content = _chatComposerController.text.trim();
    final attachment = _chatAttachment;
    if (content.isEmpty && attachment == null) {
      return;
    }
    await _runBusy(() async {
      final chat = await AppActions.sendMessageAndReload(
        _api,
        peerId: peer.id,
        content: content,
        messageType: attachment?.messageType ?? 'text',
        mediaName: attachment?.mediaName ?? '',
        mediaMime: attachment?.mediaMime ?? '',
        mediaData: attachment?.mediaData ?? '',
        expiresInMinutes: attachment == null ? 0 : 7 * 24 * 60,
      );
      _chatComposerController.clear();
      _chatAttachment = null;
      _messages = chat.messages;
      _conversations = chat.conversations;
    });
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final domain = _domainController.text.trim().toLowerCase();
    final signature = _signatureController.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = '昵称不能为空');
      return;
    }
    if (domain.isEmpty) {
      setState(() => _error = '域名不能为空');
      return;
    }
    if (username.isNotEmpty && !_isValidSpaceSubdomain(username)) {
      setState(() => _error = '用户名只能包含英文字母和数字，且最长 63 个字符');
      return;
    }
    if (!_isValidSpaceSubdomain(domain)) {
      setState(() => _error = '域名只能包含英文字母和数字，且最长 63 个字符');
      return;
    }
    await _runBusy(() async {
      _user = await _api.updateProfile(
        displayName: displayName,
        username: username,
        domain: domain,
        signature: signature,
        phoneVisibility: _phoneVisibility,
        emailVisibility: _emailVisibility,
        ageVisibility: _ageVisibility,
        genderVisibility: _genderVisibility,
      );
      _displayNameController.text = _user?.displayName ?? displayName;
      _usernameController.text = _user?.username ?? username;
      _domainController.text = _user?.domain ?? domain;
      _signatureController.text = _user?.signature ?? signature;
      _phoneVisibility = _user?.phoneVisibility ?? _phoneVisibility;
      _emailVisibility = _user?.emailVisibility ?? _emailVisibility;
      _ageVisibility = _user?.ageVisibility ?? _ageVisibility;
      _genderVisibility = _user?.genderVisibility ?? _genderVisibility;
      if (_profileUser?.id == _user?.id) {
        _profileUser = UserProfileItem.fromCurrentUser(_user!);
      }
      if (!mounted) {
        return;
      }
      setState(() => _flash = '身份卡已更新');
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
    final textDirection = AppI18n.isRtl(_languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
    Widget content;
    if (_booting) {
      content = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_user == null) {
      content = GuestLandingView(
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
        currentLanguageCode: _languageCode,
        onLanguageChanged: _setLanguage,
        currentThemeKey: _themeKeyValue,
        onThemeChanged: _setTheme,
        themeOptions: _themeOptions,
        t: _t,
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1120;
          final activePrivateSpace = _selectedSpaceForVisibility('private');
          final activePublicSpace = _selectedSpaceForVisibility('public');
          final dashboardPublicPosts = postsForSpace(
            _publicPosts,
            activePublicSpace?.id,
          );
          final filteredPrivatePosts = postsForSpace(
            _privatePosts,
            activePrivateSpace?.id,
          );
          final filteredPublicPosts = postsForSpace(
            _publicPosts,
            activePublicSpace?.id,
          );
          final identityHandle = _user!.domain.isNotEmpty
              ? _user!.domain
              : _user!.username;
          return AuthenticatedShellView(
            userLabel: _user!.displayName.isEmpty
                ? (identityHandle.isEmpty ? _user!.id : '@$identityHandle')
                : (identityHandle.isEmpty
                      ? _user!.displayName
                      : '${_user!.displayName} · @$identityHandle'),
            pageTitle: pageTitleForView(
              _view,
              profileUser: _profileUser,
              currentPost: _currentPost,
              activePrivateSpace: activePrivateSpace,
              activePublicSpace: activePublicSpace,
              t: _t,
            ),
            pageSubtitle: pageSubtitleForView(
              _view,
              activePrivateSpace: activePrivateSpace,
              activePublicSpace: activePublicSpace,
              t: _t,
            ),
            loading: _loading,
            wide: wide,
            sidebarCollapsed: _sidebarCollapsed,
            sidebar: _buildSidebar(),
            onRefresh: () => _runBusy(_refreshAll),
            onLogout: _logout,
            onToggleSidebar: _toggleSidebar,
            currentLanguageCode: _languageCode,
            onLanguageChanged: _setLanguage,
            currentThemeKey: _themeKeyValue,
            onThemeChanged: _setTheme,
            themeOptions: _themeOptions,
            backgroundGradient: _backgroundGradientFor(_themeKeyValue),
            topNav: _buildTopNavBar(),
            // Show nav buttons only when sidebar is collapsed on wide layouts.
            // 仅在宽屏且侧边栏折叠时显示导航按钮。
            showTopNav: wide && _sidebarCollapsed,
            floatingNotice: _buildSocialReminderBanner(),
            t: _t,
            body: AuthenticatedHomeView(
              width: constraints.maxWidth,
              error: _error,
              flash: _flash,
              stretchBody: _view == AppView.chat,
              sectionBody: _buildSectionBody(
                constraints.maxWidth,
                activePrivateSpace: activePrivateSpace,
                activePublicSpace: activePublicSpace,
                dashboardPublicPosts: dashboardPublicPosts,
                filteredPrivatePosts: filteredPrivatePosts,
                filteredPublicPosts: filteredPublicPosts,
              ),
            ),
          );
        },
      );
    }
    return Directionality(
      textDirection: textDirection,
      child: Theme(data: _themeDataFor(_themeKeyValue), child: content),
    );
  }

  Widget _buildSidebar() {
    return ShellSidebar(
      user: _user!,
      subscription: _subscription,
      conversations: _conversations,
      pendingFriendCount: _pendingFriendCount,
      selectedViewKey: sidebarViewKey(_view),
      items: buildShellSidebarItems(_t),
      onNavigate: (viewKey) => _navigateTo(appViewFromKey(viewKey)),
      t: _t,
    );
  }

  PreferredSizeWidget _buildTopNavBar() {
    // Top navigation for quick switching.
    // 顶部导航用于快速切换视图。
    final items = [
      (AppView.dashboard, _t('sidebar.dashboard')),
      (AppView.space, _t('sidebar.space')),
      (AppView.friends, _t('sidebar.friends')),
      (AppView.profile, _t('sidebar.profile')),
      (AppView.chat, _t('sidebar.chat')),
    ];
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Keep navigation buttons in a single row.
          // 保持导航按钮单行展示。
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Badge(
                    isLabelVisible: item.$1 == AppView.chat
                        ? _unreadMessageCount > 0
                        : item.$1 == AppView.friends
                        ? _pendingFriendCount > 0
                        : false,
                    label: Text(
                      item.$1 == AppView.chat
                          ? (_unreadMessageCount > 99
                                ? '99+'
                                : '$_unreadMessageCount')
                          : (_pendingFriendCount > 99
                                ? '99+'
                                : '$_pendingFriendCount'),
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: FilledButton.tonal(
                      onPressed: () => _navigateTo(item.$1),
                      style: FilledButton.styleFrom(
                        backgroundColor: _view == item.$1
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      ),
                      child: Text(item.$2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildSocialReminderBanner() {
    // Show a floating reminder when there are pending friends or unread chats.
    // 当存在待处理好友请求或未读聊天时展示浮动提醒。
    final pendingFriend = _topPendingFriend;
    final unreadCount = _unreadMessageCount;
    if (pendingFriend == null && unreadCount == 0) {
      return null;
    }

    final lines = <String>[
      if (pendingFriend != null)
        '${pendingFriend.displayName.isNotEmpty ? pendingFriend.displayName : pendingFriend.id} ${_t('friends.title')}',
      if (unreadCount > 0) '$_unreadMessageCount ${_t('ws.unreadLabel')}',
    ];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  pendingFriend != null
                      ? Icons.person_add_alt_1_outlined
                      : Icons.mark_chat_unread_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  pendingFriend != null ? '新好友提醒' : '新消息提醒',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (pendingFriend != null)
                  FilledButton.tonal(
                    onPressed: () => _navigateTo(AppView.friends),
                    child: const Text('查看好友'),
                  ),
                if (unreadCount > 0)
                  FilledButton.tonal(
                    onPressed: () => _navigateTo(AppView.chat),
                    child: const Text('查看聊天'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionBody(
    double width, {
    required SpaceItem? activePrivateSpace,
    required SpaceItem? activePublicSpace,
    required List<PostItem> dashboardPublicPosts,
    required List<PostItem> filteredPrivatePosts,
    required List<PostItem> filteredPublicPosts,
  }) {
    _externalChain = normalizeBlockchainChain(
      _externalProvider,
      _externalChain,
    );
    return sectionBodyForView(
      _view,
      dashboard: buildDashboardView(
        width: width,
        user: _user!,
        spaces: _spaces,
        publicPosts: dashboardPublicPosts,
        activePrivateSpace: activePrivateSpace,
        activePublicSpace: activePublicSpace,
        onOpenPublicSpace: () => _navigateTo(AppView.space),
        onOpenPostDetail: _openPostDetail,
      ),
      space: buildSpaceView(
        loading: _loading,
        spaces: _spaces,
        privatePosts: filteredPrivatePosts,
        publicPosts: filteredPublicPosts,
        user: _user,
        commentControllerFor: (postId) =>
            _commentControllers.putIfAbsent(postId, TextEditingController.new),
        onOpenPrivateSpaceComposer: () =>
            _openSpaceComposer(defaultType: 'private'),
        onOpenPublicSpaceComposer: () =>
            _openSpaceComposer(defaultType: 'public'),
        onOpenPrivatePostComposer: () => _openPostComposer(
          visibility: 'private',
          activeSpace: activePrivateSpace,
        ),
        onOpenPublicPostComposer: () => _openPostComposer(
          visibility: 'public',
          activeSpace: activePublicSpace,
        ),
        onEnterSpace: _enterSpace,
        onEditSpace: (space) =>
            _openSpaceComposer(defaultType: space.type, space: space),
        onDeleteSpace: _deleteSpace,
        onToggleLike: _toggleLike,
        onSharePost: _sharePost,
        onCommentPost: _comment,
        onDeletePost: _deletePost,
        onOpenProfile: _openProfile,
        onOpenPostDetail: _openPostDetail,
      ),
      privateSpace: buildPrivateView(
        loading: _loading,
        activeSpace: activePrivateSpace,
        spaces: _spaces,
        privatePosts: filteredPrivatePosts,
        user: _user,
        commentControllerFor: (postId) =>
            _commentControllers.putIfAbsent(postId, TextEditingController.new),
        onOpenSpaceComposer: () => _openSpaceComposer(defaultType: 'private'),
        onOpenPostComposer: () => _openPostComposer(
          visibility: 'private',
          activeSpace: activePrivateSpace,
        ),
        onEnterSpace: _enterSpace,
        onEditSpace: (space) =>
            _openSpaceComposer(defaultType: space.type, space: space),
        onDeleteSpace: _deleteSpace,
        onToggleLike: _toggleLike,
        onSharePost: _sharePost,
        onCommentPost: _comment,
        onDeletePost: _deletePost,
        onOpenProfile: _openProfile,
        onOpenPostDetail: _openPostDetail,
      ),
      publicSpace: buildPublicView(
        loading: _loading,
        activeSpace: activePublicSpace,
        spaces: _spaces,
        publicPosts: filteredPublicPosts,
        user: _user,
        commentControllerFor: (postId) =>
            _commentControllers.putIfAbsent(postId, TextEditingController.new),
        onOpenSpaceComposer: () => _openSpaceComposer(defaultType: 'public'),
        onOpenPostComposer: () => _openPostComposer(
          visibility: 'public',
          activeSpace: activePublicSpace,
        ),
        onEnterSpace: _enterSpace,
        onEditSpace: (space) =>
            _openSpaceComposer(defaultType: space.type, space: space),
        onDeleteSpace: _deleteSpace,
        onToggleLike: _toggleLike,
        onSharePost: _sharePost,
        onCommentPost: _comment,
        onDeletePost: _deletePost,
        onOpenProfile: _openProfile,
        onOpenPostDetail: _openPostDetail,
      ),
      profile: buildProfileView(
        user: _user,
        profileUser: _profileUser,
        profilePosts: _profilePosts,
        subscription: _subscription,
        externalAccounts: _externalAccounts,
        friends: _friends,
        currentLevel: _user?.level ?? 'basic',
        onActivateLevel: _activatePlan,
        onActivatePlan: _activatePlan,
        displayNameController: _displayNameController,
        usernameController: _usernameController,
        domainController: _domainController,
        signatureController: _signatureController,
        phoneVisibility: _phoneVisibility,
        emailVisibility: _emailVisibility,
        ageVisibility: _ageVisibility,
        genderVisibility: _genderVisibility,
        loading: _loading,
        commentControllerFor: (postId) =>
            _commentControllers.putIfAbsent(postId, TextEditingController.new),
        profileTab: _profileTab,
        onProfileTabChanged: _setProfileTab,
        onSaveProfile: _saveProfile,
        onPhoneVisibilityChanged: (value) =>
            setState(() => _phoneVisibility = value),
        onEmailVisibilityChanged: (value) =>
            setState(() => _emailVisibility = value),
        onAgeVisibilityChanged: (value) =>
            setState(() => _ageVisibility = value),
        onGenderVisibilityChanged: (value) =>
            setState(() => _genderVisibility = value),
        onAddFriend: _addFriend,
        onAcceptFriend: _acceptFriend,
        onStartChat: _startChat,
        onToggleLike: _toggleLike,
        onSharePost: _sharePost,
        onCommentPost: _comment,
        onDeletePost: _deletePost,
        onOpenProfile: _openProfile,
        onOpenPostDetail: _openPostDetail,
        t: _t,
        peerT: _peerT,
      ),
      postDetail: buildPostDetailView(
        user: _user,
        currentPost: _currentPost,
        loading: _loading,
        commentControllerFor: (postId) =>
            _commentControllers.putIfAbsent(postId, TextEditingController.new),
        editTitleController: _editPostTitleController,
        editContentController: _editPostContentController,
        editVisibility: _editPostVisibility,
        editStatus: _editPostStatus,
        onEditVisibilityChanged: (value) =>
            setState(() => _editPostVisibility = value),
        onEditStatusChanged: (value) => setState(() => _editPostStatus = value),
        onToggleLike: _toggleLike,
        onSharePost: _sharePost,
        onCommentPost: _comment,
        onOpenProfile: _openProfile,
        onSaveEdits: _savePostEdits,
        onDeletePost: _currentPost == null
            ? null
            : () => _deletePost(_currentPost!),
      ),
      levels: buildLevelsView(
        currentLevel: _user?.level ?? 'basic',
        onActivateLevel: _activatePlan,
      ),
      subscription: buildSubscriptionView(
        subscription: _subscription,
        loading: _loading,
        onActivatePlan: _activatePlan,
      ),
      blockchain: buildBlockchainView(
        loading: _loading,
        externalProvider: _externalProvider,
        externalChain: _externalChain,
        externalAccounts: _externalAccounts,
        addressController: _externalAddressController,
        signatureController: _externalSignatureController,
        onProviderChanged: (value) => setState(() {
          _externalProvider = value;
          _externalChain = normalizeBlockchainChain(value, _externalChain);
        }),
        onChainChanged: (value) => setState(() => _externalChain = value),
        onBind: _bindExternalAccount,
        onRemove: _removeExternalAccount,
      ),
      friends: buildFriendsView(
        loading: _loading,
        searchController: _friendSearchController,
        searchResults: _searchResults,
        friends: _friends,
        onSearch: _searchUsers,
        onAddFriend: _addFriend,
        onAcceptFriend: _acceptFriend,
        onOpenProfile: _openProfile,
        onStartChat: _startChat,
      ),
      chat: buildChatView(
        width: width,
        user: _user!,
        activeChat: _activeChat,
        friends: _friends,
        conversations: _conversations,
        messages: _messages,
        pendingFriendCount: _pendingFriendCount,
        chatAttachment: _chatAttachment,
        chatComposerController: _chatComposerController,
        loading: _loading,
        onStartChat: _startChat,
        onSendMessage: _sendMessage,
        onPickAttachment: _pickChatAttachment,
        onClearAttachment: _clearChatAttachment,
      ),
    );
  }
}
