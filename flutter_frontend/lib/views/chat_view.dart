import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

import '../controllers/chat_media_actions.dart';
import '../models/app_models.dart';

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
    required this.onSendMessage,
    required this.onPickAttachment,
    required this.onClearAttachment,
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
  final VoidCallback onSendMessage;
  final Future<void> Function(String messageType) onPickAttachment;
  final VoidCallback onClearAttachment;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _messageScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottom(immediate: true);
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeChatChanged = oldWidget.activeChat?.id != widget.activeChat?.id;
    final messageChanged = oldWidget.messages.length != widget.messages.length ||
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
    final hasSelection = selection.isValid &&
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = widget.width < 1100;
        final listPane = _buildListPane(context);
        final chatPane = _buildChatPane(context, constraints.maxWidth);

        if (compact) {
          final listHeight = constraints.hasBoundedHeight
              ? (constraints.maxHeight * 0.34).clamp(240.0, 320.0).toDouble()
              : 300.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: listHeight, child: listPane),
              const SizedBox(height: 16),
              Expanded(child: chatPane),
            ],
          );
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
                    '最近会话',
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
                child: Text('有 ${widget.pendingFriendCount} 个好友请求待处理。'),
              ),
            if (widget.pendingFriendCount > 0) const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (widget.conversations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('还没有会话记录。'),
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
                  Text('好友', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (widget.acceptedFriends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('还没有可聊天的好友。'),
                    ),
                  ...widget.acceptedFriends.map(
                    (friend) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(friend.displayName),
                      subtitle: Text(friend.secondary),
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

  Widget _buildChatPane(BuildContext context, double width) {
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
                        widget.activeChat?.displayName ?? '选择一个好友开始聊天',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.activeChat?.secondary ?? '选择左侧好友后会加载历史消息。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (widget.activeChat != null)
                  FilledButton.tonal(
                    onPressed: () => widget.onStartChat(widget.activeChat!),
                    child: const Text('刷新会话'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (attachment != null) ...[
              _buildAttachmentDraft(context, attachment),
              const SizedBox(height: 12),
            ],
            Expanded(child: _buildHistory(context, width)),
            const SizedBox(height: 12),
            _buildComposer(context, attachment),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(BuildContext context, double width) {
    final activeChat = widget.activeChat;
    if (activeChat == null) {
      return const Center(
        child: Text('选择左侧好友后会加载历史消息并接入 WebSocket。'),
      );
    }
    if (widget.messages.isEmpty) {
      return const Center(child: Text('当前会话还没有消息。'));
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  if (item.expiresAt != null)
                    Text(
                      '临时消息 · ${formatDateTime(item.expiresAt!)} 自动删除',
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
          const Text(
            '表情包',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            sticker,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    ChatAttachmentDraft? attachment,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '常用表情 / 贴纸',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final emoji in _emojiQuickItems)
                    ActionChip(
                      label: Text(emoji, style: const TextStyle(fontSize: 18)),
                      onPressed: _canCompose
                          ? () => _insertComposerText(emoji)
                          : null,
                    ),
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _canCompose ? () => widget.onPickAttachment('image') : null,
              icon: const Icon(Icons.image_outlined),
              label: const Text('图片'),
            ),
            FilledButton.tonalIcon(
              onPressed: _canCompose ? () => widget.onPickAttachment('video') : null,
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('视频'),
            ),
            FilledButton.tonalIcon(
              onPressed: _canCompose ? () => widget.onPickAttachment('audio') : null,
              icon: const Icon(Icons.mic_none_outlined),
              label: const Text('语音'),
            ),
            if (attachment != null)
              FilledButton.tonal(
                onPressed: _canCompose ? widget.onClearAttachment : null,
                child: const Text('清除附件'),
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
                  labelText: _canCompose ? '输入消息或附件说明' : '先选择好友后再输入消息',
                ),
                onSubmitted: _canCompose ? (_) => widget.onSendMessage() : null,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _canCompose ? widget.onSendMessage : null,
              child: const Text('发送'),
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
                  '${attachment.messageType} · ${attachment.sizeLabel} · 7天后自动删除',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: widget.loading ? null : widget.onClearAttachment,
            child: const Text('移除'),
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
          TextButton(
            onPressed: () => openChatAttachment(
              mediaMime: message.mediaMime,
              mediaData: message.mediaData,
            ),
            child: const Text('打开'),
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
