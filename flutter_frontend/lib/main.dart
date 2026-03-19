import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api/api_client.dart';
import 'controllers/app_actions.dart';
import 'controllers/chat_media_actions.dart';
import 'controllers/post_media_actions.dart';
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
import 'widgets/bilingual_action_button.dart';
import 'widgets/bilingual_dropdown_field.dart';
import 'widgets/bilingual_dropdown_options.dart';

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
      theme: _buildAppTheme(
        scheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF08111D),
        cardColor: const Color(0xFF101925),
        fillColor: const Color(0xFF152131),
      ),
      home: const IniyouHome(),
    );
  }
}

ThemeData _buildAppTheme({
  required ColorScheme scheme,
  required Color scaffoldBackgroundColor,
  required Color cardColor,
  required Color fillColor,
}) {
  // Build a polished app theme with softer surfaces and stronger depth cues.
  // 构建更有层次感的应用主题，强化表面层级与视觉深度。
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.primary.withValues(alpha: 0.8),
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      labelStyle: TextStyle(color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(color: scheme.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.45),
      thickness: 1,
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: scheme.onSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
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
  // Currently entered space.
  // 当前进入的空间。
  SpaceItem? _currentSpace;
  String? _error;
  String? _flash;
  String _publicPostStatus = 'published';
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
  List<PostItem> _spacePosts = const [];
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

  String _l(String zh, String en, [String? tw]) {
    // Resolve short UI strings for the active language only.
    // 仅为当前语言解析短句式界面文案。
    switch (_languageCode) {
      case 'en-US':
        return en;
      case 'zh-TW':
        return tw ?? zh;
      default:
        return zh;
    }
  }

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
        return _buildAppTheme(
          scheme: scheme,
          scaffoldBackgroundColor: const Color(0xFFF4F6FB),
          cardColor: const Color(0xFFFFFEFF),
          fillColor: const Color(0xFFEAF0F7),
        );
      case 'ocean':
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF4DD6D3),
          brightness: Brightness.dark,
          surface: const Color(0xFF0B1E2D),
        );
        return _buildAppTheme(
          scheme: scheme,
          scaffoldBackgroundColor: const Color(0xFF06131F),
          cardColor: const Color(0xFF0B1E2D),
          fillColor: const Color(0xFF10283B),
        );
      case 'midnight':
      default:
        const seed = Color(0xFF6EE7FF);
        final scheme = ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          surface: const Color(0xFF101925),
        );
        return _buildAppTheme(
          scheme: scheme,
          scaffoldBackgroundColor: const Color(0xFF08111D),
          cardColor: const Color(0xFF101925),
          fillColor: const Color(0xFF152131),
        );
    }
  }

  List<Color> _backgroundGradientFor(String themeKey) {
    // Return background gradient colors per theme.
    // 返回各主题的背景渐变色。
    switch (themeKey) {
      case 'dawn':
        return const [Color(0xFFF4F6FB), Color(0xFFE8EDF8), Color(0xFFF8FAFD)];
      case 'ocean':
        return const [Color(0xFF12334F), Color(0xFF0A1E2F), Color(0xFF06131F)];
      case 'midnight':
      default:
        return const [Color(0xFF08111D), Color(0xFF0D1A2A), Color(0xFF111F35)];
    }
  }

  SpaceItem? _selectedSpaceForVisibility(String visibility) {
    // Resolve the current space for a content visibility scope.
    // 为内容可见范围解析当前空间。
    final resolvedCurrentSpace = _resolvedCurrentSpace();
    if (resolvedCurrentSpace != null) {
      return resolvedCurrentSpace;
    }
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

  SpaceItem? _resolvedCurrentSpace() {
    // Keep the selected space only when it still exists in the loaded list.
    // 仅当当前空间仍存在于已加载列表时保留该选择。
    final currentSpace = _currentSpace;
    if (currentSpace == null) {
      return null;
    }
    return findSpaceById(_spaces, currentSpace.id);
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
    final activeSpace = _resolvedCurrentSpace();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await _persistSpaceSelection(
      prefs,
      _activePrivateSpaceKey,
      activeSpace?.id,
    );
    await _persistSpaceSelection(prefs, _activePublicSpaceKey, activeSpace?.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _currentSpace = activeSpace;
      _activePrivateSpaceId = activeSpace?.id;
      _activePublicSpaceId = activeSpace?.id;
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
    await _persistSpaceSelection(prefs, _activePrivateSpaceKey, space.id);
    await _persistSpaceSelection(prefs, _activePublicSpaceKey, space.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _currentSpace = space;
      _activePrivateSpaceId = space.id;
      _activePublicSpaceId = space.id;
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
    var selectedVisibility = isEditing
        ? space.visibility
        : selectedType == 'private'
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
                          isEditing ? _l('编辑空间', 'Edit space', '編輯空間') : _l('创建空间', 'Create space', '建立空間'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditing
                              ? _l('名称和二级域名可以独立修改，二级域名只能包含英文字母和数字，且最长 63 个字符。', 'The name and subdomain can be edited independently; the subdomain must use letters and numbers only, up to 63 characters.', '名稱和二級網域可以獨立修改，二級網域只能包含英文字母和數字，且最長 63 個字元。')
                              : _l('选择空间类型并设置可见范围，然后补充名称、描述和二级域名。名称和二级域名互不关联，二级域名最长 63 个字符。', 'Choose the space type and visibility, then fill in the name, description, and subdomain. The name and subdomain are independent, and the subdomain can be up to 63 characters.', '選擇空間類型並設定可見範圍，然後補充名稱、描述和二級網域。名稱和二級網域互不關聯，二級網域最長 63 個字元。'),
                        ),
                        const SizedBox(height: 20),
                        BilingualDropdownField<String>(
                          primaryLabel: _l('空间类型', 'Space type', '空間類型'),
                          secondaryLabel: 'Space type',
                          value: selectedType,
                          items: buildSpaceTypeItems(_languageCode),
                          onChanged: isEditing
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedType = value ?? selectedType;
                                    if (selectedType == 'private') {
                                      selectedVisibility = 'private';
                                    } else if (selectedVisibility == 'private') {
                                      selectedVisibility = 'public';
                                    }
                                    if (_spaceSubdomainController.text
                                        .trim()
                                        .isEmpty) {
                                      final suggestion = _suggestSpaceSubdomain(
                                        _spaceNameController.text,
                                        selectedType,
                                      );
                                      if (suggestion.isNotEmpty) {
                                        _spaceSubdomainController.text = suggestion;
                                      }
                                    }
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        BilingualDropdownField<String>(
                          primaryLabel: _l('可见范围', 'Visibility', '可見範圍'),
                          secondaryLabel: 'Visibility',
                          value: selectedVisibility,
                          items: buildSpaceVisibilityItems(_languageCode),
                          onChanged: selectedType == 'private'
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedVisibility = value ?? selectedVisibility;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _spaceNameController,
                          decoration: InputDecoration(labelText: _l('空间名称', 'Space name', '空間名稱')),
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
                            labelText: _l('二级域名（可选）', 'Subdomain (optional)', '二級網域（可選）'),
                            helperText: isEditing
                                ? _l('仅允许英文字母和数字，且最长 63 个字符。', 'Letters and numbers only, up to 63 characters.', '僅允許英文字母和數字，且最長 63 個字元。')
                                : _l('仅允许英文字母和数字，最长 63 个字符，留空时后端会自动生成。', 'Letters and numbers only, up to 63 characters. Leave it blank to auto-generate.', '僅允許英文字母和數字，最長 63 個字元，留空時後端會自動生成。'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _spaceDescriptionController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(labelText: _l('空间描述', 'Space description', '空間描述')),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // Dialog footer buttons use the shared bilingual button.
                            // 弹窗底部按钮统一使用双语按钮组件。
                            BilingualActionButton(
                              variant: BilingualButtonVariant.tonal,
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              primaryLabel: _l('取消', 'Cancel', '取消'),
                              secondaryLabel: 'Cancel',
                            ),
                            BilingualActionButton(
                              variant: BilingualButtonVariant.filled,
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
                                        setState(() => _error = _l('空间名称不能为空', 'Space name cannot be empty', '空間名稱不能為空'));
                                        return;
                                      }
                                      if (subdomain.isNotEmpty &&
                                          !_isValidSpaceSubdomain(subdomain)) {
                                        setState(
                                          () => _error =
                                              _l('二级域名只能包含英文字母和数字，且最长 63 个字符', 'The subdomain can contain letters and numbers only, up to 63 characters.', '二級網域只能包含英文字母和數字，且最長 63 個字元'),
                                        );
                                        return;
                                      }
                                      Navigator.of(dialogContext).pop();
                                      await _saveSpace(
                                        space: space,
                                        type: selectedType,
                                        visibility: selectedVisibility,
                                        name: name,
                                        description: description,
                                        subdomain: subdomain,
                                      );
                                    },
                              primaryLabel: isEditing ? _l('保存修改', 'Save changes', '儲存修改') : _l('创建空间', 'Create space', '建立空間'),
                              secondaryLabel:
                                  isEditing ? 'Save changes' : 'Create space',
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
    SpaceItem? activeSpace,
  }) async {
    // Open the unified space post composer dialog.
    // 打开统一的空间发帖弹窗。
    final ownedSpaces = uniqueSpacesById(
      _spaces.where((space) => space.userId == _user?.id).toList(),
    );
    if (ownedSpaces.isEmpty) {
      setState(() => _error = _l('请先创建空间', 'Create a space first', '請先建立空間'));
      return;
    }
    final selectedTargetSpace = activeSpace ?? _resolvedCurrentSpace();
    final targetSpace = selectedTargetSpace == null
        ? null
        : findSpaceById(ownedSpaces, selectedTargetSpace.id);
    final effectiveTargetSpace = targetSpace ?? ownedSpaces.first;
    if (effectiveTargetSpace.userId != _user?.id) {
      setState(() => _error = _l('只有空间创建者可以发帖', 'Only the space creator can publish posts', '只有空間建立者可以發帖'));
      return;
    }

    final titleController = _publicPostTitleController;
    final contentController = _publicPostContentController;
    var selectedSpaceId = effectiveTargetSpace.id;
    var selectedVisibility = 'public';
    var selectedStatus = _publicPostStatus;
    PostAttachmentDraft? selectedAttachment;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? dialogError;
        Widget buildAttachmentPreview(PostAttachmentDraft attachment) {
          // Preview the selected post media in the composer dialog.
          // 在发帖弹窗中预览已选媒体。
          if (attachment.isImage) {
            final bytes = Uint8List.fromList(base64Decode(attachment.mediaData));
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                bytes,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            );
          }
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_library_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(attachment.mediaName),
                      const SizedBox(height: 4),
                      Text('${attachment.mediaMime} · ${attachment.sizeLabel}'),
                    ],
                  ),
                ),
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  compact: true,
                  onPressed: () => openPostAttachment(
                    mediaMime: attachment.mediaMime,
                    mediaData: attachment.mediaData,
                  ),
                  primaryLabel: _l('打开', 'Open', '開啟'),
                  secondaryLabel: 'Open',
                ),
              ],
            ),
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final selectedSpace = findSpaceById(ownedSpaces, selectedSpaceId);
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _l('发布空间内容', 'Publish space content', '發布空間內容'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedSpace == null
                            ? _l('先选择一个空间，再填写标题、内容或媒体。', 'Select a space first, then fill in the title, content, or media.', '先選擇一個空間，再填寫標題、內容或媒體。')
                            : '${_l('当前空间', 'Current space', '目前空間')}: ${selectedSpace.name} · @${selectedSpace.subdomain}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _l('其他人会按照帖子可见性看到内容，你也可以附加图片或小视频。', 'Others will see the post according to its visibility, and you can attach images or short videos.', '其他人會依照貼文可見性看到內容，你也可以附加圖片或小影片。'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 20),
                      BilingualDropdownField<String>(
                        primaryLabel: _l('发布空间', 'Publish space', '發布空間'),
                        secondaryLabel: 'Publish space',
                        value: selectedSpaceId,
                        items: buildSpaceItems(ownedSpaces),
                        onChanged: (value) {
                          setDialogState(() {
                            final nextValue = value == null ? null : findSpaceById(ownedSpaces, value);
                            if (nextValue != null) {
                              selectedSpaceId = nextValue.id;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      BilingualDropdownField<String>(
                        primaryLabel: _l('帖子可见性', 'Post visibility', '貼文可見性'),
                        secondaryLabel: 'Post visibility',
                        value: selectedVisibility,
                        items: buildPostVisibilityItems(_languageCode),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedVisibility = value ?? selectedVisibility;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(labelText: _l('标题', 'Title', '標題')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        minLines: 4,
                        maxLines: 8,
                        decoration: InputDecoration(labelText: _l('内容', 'Content', '內容')),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          BilingualActionButton(
                            variant: BilingualButtonVariant.tonal,
                            compact: true,
                            onPressed: _loading
                                ? null
                                : () async {
                                    final attachment = await pickPostAttachment('image');
                                    if (attachment == null) {
                                      return;
                                    }
                                    if (!mounted) {
                                      return;
                                    }
                                    setDialogState(() {
                                      selectedAttachment = attachment;
                                    });
                                  },
                            primaryLabel: _l('添加图片', 'Add image', '新增圖片'),
                            secondaryLabel: 'Add image',
                          ),
                          BilingualActionButton(
                            variant: BilingualButtonVariant.tonal,
                            compact: true,
                            onPressed: _loading
                                ? null
                                : () async {
                                    final attachment = await pickPostAttachment('video');
                                    if (attachment == null) {
                                      return;
                                    }
                                    if (!mounted) {
                                      return;
                                    }
                                    setDialogState(() {
                                      selectedAttachment = attachment;
                                    });
                                  },
                            primaryLabel: _l('添加小视频', 'Add short video', '新增小影片'),
                            secondaryLabel: 'Add short video',
                          ),
                          if (selectedAttachment != null)
                            BilingualActionButton(
                              variant: BilingualButtonVariant.text,
                              compact: true,
                              onPressed: () {
                                setDialogState(() {
                                  selectedAttachment = null;
                                });
                              },
                              primaryLabel: _l('清除媒体', 'Clear media', '清除媒體'),
                              secondaryLabel: 'Clear media',
                            ),
                        ],
                      ),
                      if (selectedAttachment != null) ...[
                        const SizedBox(height: 12),
                        buildAttachmentPreview(selectedAttachment!),
                      ],
                      const SizedBox(height: 12),
                      BilingualDropdownField<String>(
                        primaryLabel: _l('状态', 'Status', '狀態'),
                        secondaryLabel: 'Status',
                        value: selectedStatus,
                        items: buildPostStatusItems(_languageCode),
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
                          BilingualActionButton(
                            variant: BilingualButtonVariant.tonal,
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            primaryLabel: _l('取消', 'Cancel', '取消'),
                            secondaryLabel: 'Cancel',
                          ),
                          BilingualActionButton(
                            variant: BilingualButtonVariant.filled,
                            onPressed: _loading
                                ? null
                                : () async {
                                    final title = titleController.text.trim();
                                    final content = contentController.text.trim();
                                    if (title.isEmpty ||
                                        (content.isEmpty &&
                                            selectedAttachment == null)) {
                                        setDialogState(() {
                                          dialogError =
                                            _l('标题不能为空，内容或媒体至少保留一项', 'Title cannot be empty; keep at least content or media.', '標題不能為空，內容或媒體至少保留一項');
                                      });
                                      return;
                                    }
                                    Navigator.of(dialogContext).pop();
                                    await _publishPost(
                                      visibility: selectedVisibility,
                                      spaceId: selectedSpaceId,
                                      titleController: titleController,
                                      contentController: contentController,
                                      status: selectedStatus,
                                      attachment: selectedAttachment,
                                    );
                                  },
                            primaryLabel: _l('发布内容', 'Publish content', '發布內容'),
                            secondaryLabel: 'Publish content',
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
    await _loadSpacePosts(space.id, quiet: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPost = null;
      _editPostTitleController.clear();
      _editPostContentController.clear();
      _editPostVisibility = 'public';
      _editPostStatus = 'published';
      _view = AppView.space;
      _flash = '${_l('已进入空间', 'Entered space', '已進入空間')} · @${space.subdomain}';
      _error = null;
    });
  }

  void _openSpaceWorkspace() {
    // Open the space workspace without binding a specific space.
    // 打开空间工作台，但不绑定具体空间。
    if (!mounted) {
      return;
    }
    setState(() {
      _currentSpace = null;
      _spacePosts = const [];
      _currentPost = null;
      _editPostTitleController.clear();
      _editPostContentController.clear();
      _editPostVisibility = 'public';
      _editPostStatus = 'published';
      _activePrivateSpaceId = null;
      _activePublicSpaceId = null;
      _view = AppView.space;
      _flash = null;
      _error = null;
    });
    SharedPreferences.getInstance().then((prefs) {
      // Clear the stored space selection so deleted or exited spaces do not reappear.
      // 清空已保存的空间选择，避免删除或退出后旧空间再次回显。
      _persistSpaceSelection(prefs, _activePrivateSpaceKey, null);
      _persistSpaceSelection(prefs, _activePublicSpaceKey, null);
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
      _currentSpace = _resolvedCurrentSpace();
      if (_currentSpace == null) {
        _spacePosts = const [];
      }
      if (_activeChat != null) {
        _activeChat = findFriendById(_activeChat!.id, dashboard.friends);
      }
    });

    await _syncActiveSpaces();
    final activeSpace = _resolvedCurrentSpace();
    if (activeSpace != null) {
      await _loadSpacePosts(activeSpace.id, quiet: true);
    }

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
      _spacePosts = const [];
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
      _currentSpace = null;
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
    if (view == AppView.space) {
      _openSpaceWorkspace();
      return;
    }
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
    String confirmSecondaryLabel = 'Confirm',
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
            // Confirm dialog actions use the shared bilingual button.
            // 确认弹窗动作统一使用双语按钮组件。
            BilingualActionButton(
              variant: BilingualButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              primaryLabel: _l('取消', 'Cancel', '取消'),
              secondaryLabel: 'Cancel',
            ),
            BilingualActionButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              primaryLabel: confirmLabel,
              secondaryLabel: confirmSecondaryLabel,
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
    required String visibility,
    required String name,
    required String description,
    required String subdomain,
  }) async {
    // Create or update a space from the modal draft.
    // 根据弹窗草稿创建或更新空间。
    final normalizedSubdomain = subdomain.toLowerCase().trim();
    if (name.trim().isEmpty) {
      setState(() => _error = _l('空间名称不能为空', 'Space name cannot be empty', '空間名稱不能為空'));
      return;
    }
    if (space == null &&
        normalizedSubdomain.isNotEmpty &&
        !_isValidSpaceSubdomain(normalizedSubdomain)) {
      setState(() => _error = _l('二级域名只能包含英文字母和数字，且最长 63 个字符', 'The subdomain can contain letters and numbers only, up to 63 characters.', '二級網域只能包含英文字母和數字，且最長 63 個字元'));
      return;
    }
    if (space != null && normalizedSubdomain.isEmpty) {
      setState(() => _error = _l('二级域名不能为空', 'The subdomain cannot be empty', '二級網域不能為空'));
      return;
    }
    if (space != null && !_isValidSpaceSubdomain(normalizedSubdomain)) {
      setState(() => _error = _l('二级域名只能包含英文字母和数字，且最长 63 个字符', 'The subdomain can contain letters and numbers only, up to 63 characters.', '二級網域只能包含英文字母和數字，且最長 63 個字元'));
      return;
    }

    await _runBusy(() async {
      if (space == null) {
        final result = await AppActions.createSpaceAndReload(
          _api,
          type: type,
          visibility: visibility,
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
          _currentPost = null;
          _editPostTitleController.clear();
          _editPostContentController.clear();
          _editPostVisibility = 'public';
          _editPostStatus = 'published';
          _view = AppView.space;
          _flash = '${_l('已创建空间', 'Space created', '空間已建立')} · @${result.space.subdomain}';
        });
        return;
      }

      final updated = await _api.updateSpace(
        id: space.id,
        name: name.trim(),
        description: description.trim(),
        subdomain: normalizedSubdomain,
        visibility: visibility,
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
          _currentPost = null;
          _editPostTitleController.clear();
          _editPostContentController.clear();
          _editPostVisibility = 'public';
          _editPostStatus = 'published';
          _view = AppView.space;
          _flash = '${_l('空间已更新', 'Space updated', '空間已更新')} · @${updated.subdomain}';
        });
      });
  }

  Future<void> _deleteSpace(SpaceItem space) async {
    // Delete a managed space and all of its content.
    // 删除可管理空间及其全部内容。
    final confirmed = await _confirmDangerousAction(
      title: _l('删除空间', 'Delete space', '刪除空間'),
      message: _l('删除空间后，该空间下的文章、评论、点赞和转发记录都会一并删除，是否继续？', 'Deleting the space will remove its posts, comments, likes, and shares. Continue?', '刪除空間後，該空間下的文章、評論、按讚和轉發記錄都會一併刪除，是否繼續？'),
      confirmLabel: _l('删除', 'Delete', '刪除'),
      confirmSecondaryLabel: 'Delete',
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
      if (!mounted) {
        return;
      }
      setState(() {
        _spaces = _spaces.where((item) => item.id != space.id).toList();
        _publicPosts = _publicPosts.where((post) => post.spaceId != space.id).toList();
        _privatePosts = _privatePosts.where((post) => post.spaceId != space.id).toList();
        _profilePosts = _profilePosts.where((post) => post.spaceId != space.id).toList();
        _spacePosts = _spacePosts.where((post) => post.spaceId != space.id).toList();
        _currentSpace = _resolvedCurrentSpace();
        if (_activePrivateSpaceId == space.id) {
          _activePrivateSpaceId = null;
        }
        if (_activePublicSpaceId == space.id) {
          _activePublicSpaceId = null;
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
      });
        final prefs = _prefs ??= await SharedPreferences.getInstance();
        await _persistSpaceSelection(prefs, _activePrivateSpaceKey, _activePrivateSpaceId);
        await _persistSpaceSelection(prefs, _activePublicSpaceKey, _activePublicSpaceId);
        await _refreshAll();
        if (!mounted) {
          return;
        }
        _openSpaceWorkspace();
        setState(() => _flash = _l('空间已删除', 'Space deleted', '空間已刪除'));
      });
    }

  Future<void> _deletePost(PostItem post) async {
    // Delete a managed post and all of its interactions.
    // 删除可管理文章及其所有互动记录。
    final confirmed = await _confirmDangerousAction(
      title: _l('删除文章', 'Delete post', '刪除文章'),
      message: _l('删除文章后，关联的评论、点赞和转发记录都会一并删除，是否继续？', 'Deleting the post will also remove its comments, likes, and shares. Continue?', '刪除文章後，關聯的評論、按讚和轉發記錄都會一併刪除，是否繼續？'),
      confirmLabel: _l('删除', 'Delete', '刪除'),
      confirmSecondaryLabel: 'Delete',
    );
    if (!confirmed) {
      return;
    }
    await _runBusy(() async {
      final currentPost = _currentPost;
      await _api.deletePost(post.id);
      _removeCommentController(post.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _publicPosts = _publicPosts.where((item) => item.id != post.id).toList();
        _privatePosts = _privatePosts.where((item) => item.id != post.id).toList();
        _spacePosts = _spacePosts.where((item) => item.id != post.id).toList();
        _profilePosts = _profilePosts.where((item) => item.id != post.id).toList();
        _currentSpace = _resolvedCurrentSpace();
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
      });
      await _refreshAll();
      if (!mounted) {
        return;
      }
      setState(() => _flash = _l('文章已删除', 'Post deleted', '文章已刪除'));
    });
  }

  Future<void> _publishPost({
    required String visibility,
    required String spaceId,
    required TextEditingController titleController,
    required TextEditingController contentController,
    required String status,
    PostAttachmentDraft? attachment,
  }) async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final hasMedia = attachment?.isMedia == true;
    if (title.isEmpty || (content.isEmpty && !hasMedia)) {
      setState(() => _error = _l('标题不能为空，内容或媒体至少保留一项', 'Title cannot be empty; keep at least content or media.', '標題不能為空，內容或媒體至少保留一項'));
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
        mediaType: attachment?.mediaType ?? '',
        mediaName: attachment?.mediaName ?? '',
        mediaMime: attachment?.mediaMime ?? '',
        mediaData: attachment?.mediaData ?? '',
      );
      titleController.clear();
      contentController.clear();
      _applyPostUpdate(result.post);
      await _setActiveSpaceById(spaceId, visibility);
      await _loadSpacePosts(spaceId, quiet: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _view = AppView.space;
        _flash = '内容已发布';
      });
    });
  }

  Future<void> _loadSpacePosts(String spaceId, {bool quiet = false}) async {
    Future<void> action() async {
      if (!mounted) {
        return;
      }
      if (_api.token == null || spaceId.isEmpty) {
        setState(() => _spacePosts = const []);
        return;
      }
      final posts = await _api.listSpacePosts(spaceId, visibility: 'all', limit: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _spacePosts = posts;
        _currentSpace = findSpaceById(_spaces, spaceId);
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
      spacePosts: _spacePosts,
      profilePosts: _profilePosts,
      currentPost: _currentPost,
    );
    setState(() {
      _publicPosts = next.publicPosts;
      _privatePosts = next.privatePosts;
      _spacePosts = next.spacePosts;
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
        _currentSpace = findSpaceById(_spaces, post.spaceId);
        _editPostVisibility = post.visibility;
        _editPostStatus = post.status;
        _view = AppView.postDetail;
      });
      if (post.spaceId.isNotEmpty) {
        await _loadSpacePosts(post.spaceId, quiet: true);
      }
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
        mediaType: post.mediaType,
        mediaName: post.mediaName,
        mediaMime: post.mediaMime,
        mediaData: post.mediaData,
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
      if (!mounted) {
        return;
      }
      setState(() {
        _subscription = result.subscription;
        _user = result.user;
        if (_profileUser?.id == _user?.id) {
          _profileUser = UserProfileItem.fromCurrentUser(_user!);
        }
        _flash = '订阅已更新';
      });
    });
  }

  Future<void> _bindExternalAccount() async {
    await _runBusy(() async {
      final nextAccounts = await AppActions.bindExternalAccountAndReload(
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
      setState(() {
        _externalAccounts = nextAccounts;
        _flash = '外部账号已绑定';
      });
    });
  }

  Future<void> _removeExternalAccount(String id) async {
    await _runBusy(() async {
      final nextAccounts = await AppActions.removeExternalAccountAndReload(
        _api,
        id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _externalAccounts = nextAccounts;
        _flash = '外部账号已移除';
      });
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
        peerT: _peerT,
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
          final spaceShell = _view == AppView.space;
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
            // Space view uses a compact shell so it behaves like a dedicated page.
            // 空间视图使用紧凑壳层，表现为独立页面。
            compactMode: spaceShell,
            loading: _loading,
            wide: wide,
            sidebarCollapsed: _sidebarCollapsed,
            sidebar: _buildSidebar(),
            onRefresh: () => _runBusy(_refreshAll),
            onLogout: _logout,
            onToggleSidebar: _toggleSidebar,
            onCompactBack: () => _navigateTo(AppView.dashboard),
            currentLanguageCode: _languageCode,
            onLanguageChanged: _setLanguage,
            currentThemeKey: _themeKeyValue,
            onThemeChanged: _setTheme,
            themeOptions: _themeOptions,
            backgroundGradient: _backgroundGradientFor(_themeKeyValue),
            topNav: _buildTopNavBar(),
            // Keep the main navigation hidden on the dedicated space page.
            // 空间独立页面中保持主导航隐藏。
            showTopNav: !spaceShell && wide && _sidebarCollapsed,
            floatingNotice: spaceShell ? null : _buildSocialReminderBanner(),
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
    final accentColor = pendingFriend != null
        ? const Color(0xFFFFB86B)
        : const Color(0xFF6EE7FF);
    final title = pendingFriend != null ? '好友提醒' : '新消息提醒';
    final subtitle = pendingFriend != null
        ? '有新的好友请求正在等待处理。'
        : '有未读消息正在等待你查看。';

    return Card(
      elevation: 16,
      shadowColor: accentColor.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: accentColor.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.24),
              Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.96),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: IgnorePointer(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pendingFriend != null
                              ? Icons.person_add_alt_1_outlined
                              : Icons.mark_chat_unread_outlined,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          pendingFriend != null
                              ? '$_pendingFriendCount 个'
                              : '$_unreadMessageCount 条',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in lines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(line),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (pendingFriend != null)
                        BilingualActionButton(
                          variant: BilingualButtonVariant.filled,
                          onPressed: () => _navigateTo(AppView.friends),
                          primaryLabel: '查看好友',
                          secondaryLabel: 'View friends',
                        ),
                      if (unreadCount > 0)
                        BilingualActionButton(
                          variant: BilingualButtonVariant.tonal,
                          onPressed: () => _navigateTo(AppView.chat),
                          primaryLabel: '查看聊天',
                          secondaryLabel: 'View chat',
                        ),
                    ],
                  ),
                ],
              ),
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
        publicPosts: dashboardPublicPosts,
        onOpenPublicSpace: () => _navigateTo(AppView.space),
        onOpenPostDetail: _openPostDetail,
        languageCode: _languageCode,
      ),
              space: buildSpaceView(
                  context: context,
                  loading: _loading,
                  spaces: _spaces,
                  activeSpace: _resolvedCurrentSpace(),
                spacePosts: _spacePosts,
                user: _user,
                commentControllerFor: (postId) =>
                    _commentControllers.putIfAbsent(postId, TextEditingController.new),
                  onOpenSpaceComposer: () =>
                      _openSpaceComposer(defaultType: 'public'),
                  onOpenPostComposer: () => _openPostComposer(activeSpace: _resolvedCurrentSpace()),
                  onLeaveSpace: _openSpaceWorkspace,
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
        languageCode: _languageCode,
      ),
              privateSpace: buildPrivateView(
                loading: _loading,
                activeSpace: _resolvedCurrentSpace() ?? activePrivateSpace,
                spaces: _spaces,
                privatePosts: filteredPrivatePosts,
                user: _user,
        commentControllerFor: (postId) =>
            _commentControllers.putIfAbsent(postId, TextEditingController.new),
                onOpenSpaceComposer: () => _openSpaceComposer(defaultType: 'private'),
                onOpenPostComposer: () => _openPostComposer(
          activeSpace: _resolvedCurrentSpace() ?? activePrivateSpace,
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
        languageCode: _languageCode,
      ),
              publicSpace: buildPublicView(
                loading: _loading,
                activeSpace: _resolvedCurrentSpace() ?? activePublicSpace,
                spaces: _spaces,
                publicPosts: filteredPublicPosts,
                user: _user,
        commentControllerFor: (postId) =>
            _commentControllers.putIfAbsent(postId, TextEditingController.new),
                onOpenSpaceComposer: () => _openSpaceComposer(defaultType: 'public'),
                onOpenPostComposer: () => _openPostComposer(
          activeSpace: _resolvedCurrentSpace() ?? activePublicSpace,
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
        languageCode: _languageCode,
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
        onEnterSpace: _enterSpace,
        languageCode: _languageCode,
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
        languageCode: _languageCode,
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
        languageCode: _languageCode,
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
        onOpenProfile: _openProfile,
        onEnterSpace: _enterSpace,
        loadFriendSpaces: _api.listUserSpaces,
        onSendMessage: _sendMessage,
        onPickAttachment: _pickChatAttachment,
        onClearAttachment: _clearChatAttachment,
        languageCode: _languageCode,
      ),
    );
  }
}
