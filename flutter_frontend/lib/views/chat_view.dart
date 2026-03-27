import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

import '../controllers/chat_media_actions.dart';
import '../models/app_models.dart';
import 'view_state_helpers.dart';
import '../widgets/bilingual_action_button.dart';

class _StickerQuickItem {
  const _StickerQuickItem({required this.token, required this.label});

  final String token;
  final String label;
}

// Keep common quick inserts together so the chat composer stays one-tap friendly.
// 将常用快捷插入集中维护，保持聊天输入区可一键触达。
const List<String> _emojiQuickItems = [
  '😀',
  '😂',
  '🥳',
  '👍',
  '❤️',
  '🔥',
  '🙏',
  '✨',
  '🎉',
];

const List<_StickerQuickItem> _stickerQuickItems = [
  _StickerQuickItem(token: '【开心】', label: '开心'),
  _StickerQuickItem(token: '【加油】', label: '加油'),
  _StickerQuickItem(token: '【收到】', label: '收到'),
  _StickerQuickItem(token: '【抱抱】', label: '抱抱'),
  _StickerQuickItem(token: '【赞】', label: '点赞'),
  _StickerQuickItem(token: '【感谢】', label: '感谢'),
];

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.width,
    required this.user,
    required this.activeChat,
    required this.acceptedFriends,
    required this.conversations,
    required this.messages,
    required this.pendingFriendCount,
    required this.chatAttachment,
    required this.chatComposerController,
    required this.loading,
    required this.findFriend,
    required this.onStartChat,
    required this.onOpenProfile,
    required this.onSendMessage,
    required this.onPickAttachment,
    required this.onClearAttachment,
    required this.languageCode,
  });

  final double width;
  final CurrentUser user;
  final FriendItem? activeChat;
  final List<FriendItem> acceptedFriends;
  final List<ConversationItem> conversations;
  final List<ChatMessage> messages;
  final int pendingFriendCount;
  final ChatAttachmentDraft? chatAttachment;
  final TextEditingController chatComposerController;
  final bool loading;
  final FriendItem? Function(String id) findFriend;
  final ValueChanged<FriendItem> onStartChat;
  final ValueChanged<String> onOpenProfile;
  final VoidCallback onSendMessage;
  final Future<void> Function(String messageType) onPickAttachment;
  final VoidCallback onClearAttachment;
  final String languageCode;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _messageScrollController = ScrollController();
  bool _showQuickInsertPanel = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom(immediate: true);
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeChatChanged = oldWidget.activeChat?.id != widget.activeChat?.id;
    final messageChanged =
        oldWidget.messages.length != widget.messages.length ||
        (oldWidget.messages.isNotEmpty &&
            widget.messages.isNotEmpty &&
            oldWidget.messages.last.id != widget.messages.last.id);
    if (activeChatChanged || messageChanged) {
      // Keep the newest message in view after switching chat or receiving updates.
      // 切换会话或收到更新后，保持最新消息始终可见。
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageScrollController.dispose();
    super.dispose();
  }

  bool get _canCompose => widget.activeChat != null && !widget.loading;

  String _l(String zh, String en, [String? tw]) {
    return localizedText(widget.languageCode, zh, en, tw);
  }

  void _openQuickInsertPanel() {
    if (_showQuickInsertPanel) {
      return;
    }
    // Open the quick insert panel for emojis and text stickers.
    // 打开表情与文字表情的快捷面板。
    setState(() => _showQuickInsertPanel = true);
  }

  void _closeQuickInsertPanel() {
    if (!_showQuickInsertPanel) {
      return;
    }
    // Close the quick insert panel with a visible red close affordance.
    // 使用醒目的红色关闭入口收起快捷面板。
    setState(() => _showQuickInsertPanel = false);
  }

  void _openChatFromMenu(String friendId) {
    // Jump to the selected friend from the right-side chat menu.
    // 通过右侧聊天菜单切换到选中的好友会话。
    final friend = widget.findFriend(friendId);
    if (friend != null) {
      widget.onStartChat(friend);
    }
  }

  List<PopupMenuEntry<String>> _buildChatMenuEntries() {
    // Keep recent conversations and quick friend switches inside one menu so compact layouts stay clean.
    // 将最近会话与好友快捷切换统一收纳到一个菜单里，保持紧凑布局更干净。
    final entries = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        enabled: false,
        child: Text(
          _l('最近会话', 'Recent conversations', '最近會話'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    ];

    if (widget.conversations.isEmpty) {
      entries.add(
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            _l('还没有会话记录。', 'No conversation history yet.', '還沒有會話記錄。'),
          ),
        ),
      );
    } else {
      for (final item in widget.conversations) {
        final friend = widget.findFriend(item.peerId);
        if (friend == null) {
          continue;
        }
        entries.add(
          PopupMenuItem<String>(
            value: friend.id,
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    friend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.hasUnread)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Badge(
                      isLabelVisible: true,
                      label: Text(
                        item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                      ),
                      child: const Icon(
                        Icons.mark_chat_unread_outlined,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    entries.add(const PopupMenuDivider());
    entries.add(
      PopupMenuItem<String>(
        enabled: false,
        child: Text(
          _l('好友', 'Friends', '好友'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
    final recentPeerIds = widget.conversations
        .map((item) => item.peerId)
        .toSet();
    final friends = widget.acceptedFriends.where(
      (friend) => !recentPeerIds.contains(friend.id),
    );
    if (friends.isEmpty) {
      entries.add(
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            _l(
              '还没有可聊天的好友。',
              'No friends available for chat yet.',
              '還沒有可聊天的好友。',
            ),
          ),
        ),
      );
    } else {
      for (final friend in friends) {
        entries.add(
          PopupMenuItem<String>(
            value: friend.id,
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    friend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return entries;
  }

  Widget _buildChatMenuButton() {
    // Put the menu entry on the right so the chat pane keeps its main actions aligned away from the left edge.
    // 将菜单入口放到右侧，让聊天主操作远离左边缘并保持右对齐。
    return PopupMenuButton<String>(
      tooltip: _l('最近会话', 'Recent conversations', '最近會話'),
      icon: const Icon(Icons.more_vert),
      onSelected: _openChatFromMenu,
      itemBuilder: (_) => _buildChatMenuEntries(),
    );
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_messageScrollController.hasClients) {
        return;
      }
      final target = _messageScrollController.position.maxScrollExtent;
      if (immediate) {
        _messageScrollController.jumpTo(target);
        return;
      }
      final distance = target - _messageScrollController.position.pixels;
      if (distance > 120) {
        _messageScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _insertComposerText(String snippet) {
    if (snippet.isEmpty) {
      return;
    }
    final controller = widget.chatComposerController;
    final value = controller.value;
    final text = value.text;
    final selection = value.selection;
    final hasSelection =
        selection.isValid &&
        selection.start >= 0 &&
        selection.end >= 0 &&
        selection.start <= text.length &&
        selection.end <= text.length;
    final start = hasSelection ? selection.start : text.length;
    final end = hasSelection ? selection.end : text.length;
    controller.value = value.copyWith(
      text: text.replaceRange(start, end, snippet),
      selection: TextSelection.collapsed(offset: start + snippet.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _openFriendProfile(
    BuildContext context,
    FriendItem friend,
  ) async {
    if (!mounted) {
      return;
    }
    // Keep the chat preview lightweight so opening it on web does not trigger a heavy space-list rebuild.
    // 将聊天里的好友预览保持为轻量级，避免在 Web 端打开时触发沉重的空间列表重绘。
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: Text(_l('好友资料', 'Friend profile', '好友資料')),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        '${_l('状态', 'Status', '狀態')}: ${friend.status}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${_l('方向', 'Direction', '方向')}: ${friend.direction}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_l('用户名', 'Username', '使用者名稱')}: ${friend.username.isNotEmpty ? friend.username : _l('暂无', 'N/A', '暫無')}',
                ),
                const SizedBox(height: 6),
                Text('${_l('联系方式', 'Contact', '聯絡方式')}: ${friend.secondary}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_l('关闭', 'Close', '關閉')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onOpenProfile(friend.id);
              },
              child: Text(_l('查看主页', 'Open profile', '查看主頁')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = widget.width < 1100;
        final listPane = _buildListPane(context);
        final chatPane = _buildChatPane(
          context,
          constraints.maxWidth,
          compactLayout: compact,
        );

        if (compact) {
          return chatPane;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 380, child: listPane),
            const SizedBox(width: 16),
            Expanded(child: chatPane),
          ],
        );
      },
    );
  }

  Widget _buildListPane(BuildContext context) {
    final totalUnread = widget.conversations.fold<int>(
      0,
      (sum, item) => sum + item.unreadCount,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _l('最近会话', 'Recent conversations', '最近會話'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (totalUnread > 0)
                  Badge(
                    isLabelVisible: true,
                    label: Text(totalUnread > 99 ? '99+' : '$totalUnread'),
                    child: const Icon(Icons.mark_chat_unread_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.pendingFriendCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _l(
                    '有 ${widget.pendingFriendCount} 个好友请求待处理。',
                    '${widget.pendingFriendCount} friend requests are waiting.',
                    '有 ${widget.pendingFriendCount} 個好友請求待處理。',
                  ),
                ),
              ),
            if (widget.pendingFriendCount > 0) const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (widget.conversations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _l(
                          '还没有会话记录。',
                          'No conversation history yet.',
                          '還沒有會話記錄。',
                        ),
                      ),
                    ),
                  ...widget.conversations.map((item) {
                    final friend = widget.findFriend(item.peerId);
                    if (friend == null) {
                      return const SizedBox.shrink();
                    }
                    final selected = widget.activeChat?.id == friend.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        title: Text(friend.displayName),
                        subtitle: Text(
                          item.lastMessagePreview.isNotEmpty
                              ? item.lastMessagePreview
                              : item.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: item.hasUnread
                            ? CircleAvatar(
                                radius: 12,
                                child: Text('${item.unreadCount}'),
                              )
                            : null,
                        selected: selected,
                        onTap: () => widget.onStartChat(friend),
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  Text(
                    _l('好友', 'Friends', '好友'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (widget.acceptedFriends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _l(
                          '还没有可聊天的好友。',
                          'No friends available for chat yet.',
                          '還沒有可聊天的好友。',
                        ),
                      ),
                    ),
                  ...widget.acceptedFriends.map(
                    (friend) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(friend.displayName),
                      subtitle: Text(friend.secondary),
                      trailing: IconButton(
                        tooltip: _l('查看资料', 'View profile', '查看資料'),
                        onPressed: () => _openFriendProfile(context, friend),
                        icon: const Icon(Icons.person_outline),
                      ),
                      selected: widget.activeChat?.id == friend.id,
                      onTap: () => widget.onStartChat(friend),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPane(
    BuildContext context,
    double width, {
    required bool compactLayout,
  }) {
    final attachment = widget.chatAttachment;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.activeChat?.displayName ??
                            _l(
                              '选择一个好友开始聊天',
                              'Select a friend to start chatting',
                              '選擇一個好友開始聊天',
                            ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.activeChat?.secondary ??
                            (compactLayout
                                ? _l(
                                    '从右上角菜单选择好友后会加载历史消息。',
                                    'Pick a friend from the upper-right menu to load conversation history.',
                                    '從右上角選單選擇好友後會載入歷史訊息。',
                                  )
                                : _l(
                                    '从左侧会话列表选择好友后会加载历史消息。',
                                    'Pick a friend from the left conversation list to load history.',
                                    '從左側會話列表選擇好友後會載入歷史訊息。',
                                  )),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    _buildChatMenuButton(),
                    if (widget.activeChat != null)
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        onPressed: () => widget.onStartChat(widget.activeChat!),
                        primaryLabel: _l('刷新会话', 'Refresh chat', '重新整理會話'),
                        secondaryLabel: 'Refresh chat',
                      ),
                    if (widget.activeChat != null)
                      BilingualActionButton(
                        variant: BilingualButtonVariant.outlined,
                        onPressed: () =>
                            _openFriendProfile(context, widget.activeChat!),
                        primaryLabel: _l('查看资料', 'View profile', '查看資料'),
                        secondaryLabel: 'View profile',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (attachment != null) ...[
              _buildAttachmentDraft(context, attachment),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: _buildHistory(
                context,
                width,
                compactLayout: compactLayout,
              ),
            ),
            const SizedBox(height: 12),
            _buildComposer(context, attachment),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(
    BuildContext context,
    double width, {
    required bool compactLayout,
  }) {
    final activeChat = widget.activeChat;
    if (activeChat == null) {
      return Center(
        child: Text(
          compactLayout
              ? _l(
                  '从右上角菜单选择好友后会加载历史消息并接入 WebSocket。',
                  'Choose a friend from the upper-right menu to load history and connect the WebSocket.',
                  '從右上角選單選擇好友後會載入歷史訊息並接入 WebSocket。',
                )
              : _l(
                  '从左侧会话列表选择好友后会加载历史消息并接入 WebSocket。',
                  'Choose a friend from the left conversation list to load history and connect the WebSocket.',
                  '從左側會話列表選擇好友後會載入歷史訊息並接入 WebSocket。',
                ),
        ),
      );
    }
    if (widget.messages.isEmpty) {
      return Center(
        child: Text(
          _l(
            '当前会话还没有消息。',
            'No messages in this conversation yet.',
            '目前會話還沒有訊息。',
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _messageScrollController,
      thumbVisibility: width >= 1100,
      child: ListView.separated(
        controller: _messageScrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(right: 4),
        itemCount: widget.messages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = widget.messages[index];
          final mine = item.from == widget.user.id;
          return _buildMessageBubble(context, item, mine, width);
        },
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage item,
    bool mine,
    double width,
  ) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width < 1100 ? width * 0.82 : 460,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFF1D6F87) : const Color(0xFF192535),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: mine
                  ? const Color(0xFF2FD0FF).withValues(alpha: 0.4)
                  : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.hasMedia) ...[
                _buildMediaMessage(context, item),
                if (item.content.isNotEmpty && !item.isSticker)
                  const SizedBox(height: 10),
              ],
              if (item.isSticker)
                _buildStickerMessage(context, item.content.trim())
              else if (item.content.isNotEmpty)
                Text(
                  item.content,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    item.createdAtLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (item.expiresAt != null)
                    Text(
                      '${_l('临时消息', 'Temporary message', '臨時訊息')} · ${formatDateTime(item.expiresAt!)} ${_l('自动删除', 'auto-delete', '自動刪除')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickerMessage(BuildContext context, String sticker) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Sticker card label / 文字表情卡片标题：仅显示当前语言。
            _l('表情包', 'Sticker', '貼圖'),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            sticker,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsertPanel(
    BuildContext context,
    ChatAttachmentDraft? attachment,
  ) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: !_showQuickInsertPanel
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.96,
                    ),
                    theme.colorScheme.surfaceContainerLow.withValues(
                      alpha: 0.94,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_emotions_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _l('表情包面板', 'Sticker panel', '貼圖面板'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Red close button to dismiss the emoji panel.
                      // 红色关闭按钮用于收起表情包面板。
                      IconButton(
                        tooltip: _l('关闭表情包面板', 'Close sticker panel', '關閉貼圖面板'),
                        onPressed: _closeQuickInsertPanel,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: Colors.redAccent,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _l('常用表情', 'Emoji', '常用表情'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emoji in _emojiQuickItems)
                        ActionChip(
                          label: Text(
                            emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          onPressed: _canCompose
                              ? () => _insertComposerText(emoji)
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _l('文字表情', 'Text stickers', '文字表情'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sticker in _stickerQuickItems)
                        Tooltip(
                          message: sticker.label,
                          child: ActionChip(
                            label: Text(sticker.token),
                            onPressed: _canCompose
                                ? () => _insertComposerText(sticker.token)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  if (attachment != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _l('当前附件', 'Active attachment', '目前附件'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      attachment.mediaName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildComposer(BuildContext context, ChatAttachmentDraft? attachment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickInsertPanel(context, attachment),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Emoji panel toggle goes before media actions for faster access.
            // 表情面板入口放在媒体按钮之前，方便先打开再发送内容。
            FilledButton.tonalIcon(
              onPressed: _canCompose ? _openQuickInsertPanel : null,
              icon: const Icon(Icons.emoji_emotions_outlined),
              label: Text(_l('表情', 'Emoji', '表情')),
            ),
            FilledButton.tonalIcon(
              onPressed: _canCompose
                  ? () => widget.onPickAttachment('image')
                  : null,
              icon: const Icon(Icons.image_outlined),
              label: Text(_l('图片', 'Image', '圖片')),
            ),
            FilledButton.tonalIcon(
              onPressed: _canCompose
                  ? () => widget.onPickAttachment('video')
                  : null,
              icon: const Icon(Icons.video_library_outlined),
              label: Text(_l('视频', 'Video', '影片')),
            ),
            FilledButton.tonalIcon(
              onPressed: _canCompose
                  ? () => widget.onPickAttachment('audio')
                  : null,
              icon: const Icon(Icons.mic_none_outlined),
              label: Text(_l('语音', 'Voice', '語音')),
            ),
            if (attachment != null)
              FilledButton.tonal(
                onPressed: _canCompose ? widget.onClearAttachment : null,
                child: Text(_l('清除附件', 'Clear attachment', '清除附件')),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.chatComposerController,
                enabled: _canCompose,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _canCompose
                      ? _l(
                          '输入消息或附件说明',
                          'Type a message or attachment note',
                          '輸入訊息或附件說明',
                        )
                      : _l(
                          '先选择好友后再输入消息',
                          'Select a friend before typing',
                          '先選擇好友後再輸入訊息',
                        ),
                ),
                onSubmitted: _canCompose ? (_) => widget.onSendMessage() : null,
              ),
            ),
            const SizedBox(width: 12),
            BilingualActionButton(
              onPressed: _canCompose ? widget.onSendMessage : null,
              primaryLabel: _l('发送', 'Send', '送出'),
              secondaryLabel: 'Send',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentDraft(
    BuildContext context,
    ChatAttachmentDraft attachment,
  ) {
    final icon = switch (attachment.messageType) {
      'image' => Icons.image_outlined,
      'video' => Icons.video_library_outlined,
      'audio' => Icons.mic_none_outlined,
      _ => Icons.attach_file,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.mediaName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${attachment.messageType} · ${attachment.sizeLabel} · ${_l('7天后自动删除', 'Deleted after 7 days', '7天後自動刪除')}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BilingualActionButton(
            variant: BilingualButtonVariant.tonal,
            onPressed: widget.loading ? null : widget.onClearAttachment,
            primaryLabel: _l('移除', 'Remove', '移除'),
            secondaryLabel: 'Remove',
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMessage(BuildContext context, ChatMessage message) {
    final bytes = _decodeMediaBytes(message.mediaData);
    if (message.isImage && bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: 220,
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            message.isVideo
                ? Icons.video_library_outlined
                : message.isAudio
                ? Icons.mic_none_outlined
                : Icons.image_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.mediaLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  message.mediaMime.isNotEmpty
                      ? message.mediaMime
                      : message.messageType,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          BilingualActionButton(
            variant: BilingualButtonVariant.text,
            compact: true,
            onPressed: () => openChatAttachment(
              mediaMime: message.mediaMime,
              mediaData: message.mediaData,
            ),
            primaryLabel: _l('打开', 'Open', '開啟'),
            secondaryLabel: 'Open',
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeMediaBytes(String mediaData) {
    if (mediaData.isEmpty) {
      return null;
    }
    try {
      // Decode and inflate the compressed attachment payload.
      // 解码并展开已压缩的附件载荷。
      final rawBytes = Uint8List.fromList(base64Decode(mediaData));
      try {
        return Uint8List.fromList(GZipDecoder().decodeBytes(rawBytes));
      } catch (_) {
        return rawBytes;
      }
    } catch (_) {
      return null;
    }
  }
}
