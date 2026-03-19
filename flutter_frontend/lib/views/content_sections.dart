import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_cards.dart';
import '../widgets/bilingual_action_button.dart';
import 'view_state_helpers.dart';

class TopSummaryRow extends StatelessWidget {
  const TopSummaryRow({super.key, required this.width, required this.cards});

  final double width;
  final List<SummaryCardData> cards;

  @override
  Widget build(BuildContext context) {
    final columns = width >= 1320 ? 4 : (width >= 920 ? 2 : 1);
    const spacing = 12.0;
    final itemWidth = (width - spacing * (columns - 1)) / columns;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final item in cards)
          SizedBox(
            width: itemWidth,
            child: SummaryCard(item: item),
          ),
      ],
    );
  }
}

class DashboardOverviewView extends StatelessWidget {
  const DashboardOverviewView({
    super.key,
    required this.width,
    required this.user,
    required this.spaces,
    required this.publicPosts,
    required this.activePrivateSpace,
    required this.activePublicSpace,
    required this.onOpenPublicSpace,
    required this.onOpenPostDetail,
    required this.languageCode,
  });

  final double width;
  final CurrentUser user;
  final List<SpaceItem> spaces;
  final List<PostItem> publicPosts;
  final SpaceItem? activePrivateSpace;
  final SpaceItem? activePublicSpace;
  final VoidCallback onOpenPublicSpace;
  final ValueChanged<String> onOpenPostDetail;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final compact = width < 980;
    // Show only public-type spaces in the dashboard summary.
    // 仪表盘摘要只展示公共类型空间，隐藏旧的私人空间入口。
    final visibleSpaces = publicSpaces(spaces);
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: localizedText(languageCode, '账号概览', 'Account overview', '帳號概覽'),
          lines: [
            '${localizedText(languageCode, '用户 ID', 'User ID', '使用者 ID')}: ${user.id}',
            if (user.email.isNotEmpty)
              '${localizedText(languageCode, '邮箱', 'Email', '信箱')}: ${user.email}',
            if (user.phone.isNotEmpty)
              '${localizedText(languageCode, '手机号', 'Phone', '手機號')}: ${user.phone}',
            '${localizedText(languageCode, '等级', 'Level', '等級')}: ${user.level}',
            '${localizedText(languageCode, '状态', 'Status', '狀態')}: ${user.status}',
          ],
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: localizedText(languageCode, '快捷入口', 'Quick entry', '快捷入口'),
          lines: [
            localizedText(languageCode, '进入空间管理草稿、可见空间和空间入口', 'Use spaces to manage drafts, visible spaces, and entry points.', '進入空間可管理草稿、可見空間和入口。'),
            localizedText(languageCode, '空间内容会出现在空间页，也能打开作者主页', 'Space content appears on the space page and can also open the author profile.', '空間內容會出現在空間頁，也能打開作者主頁。'),
            localizedText(languageCode, '好友和聊天页面保持关系与实时消息联动', 'Friends and chat stay linked for relations and live messages.', '好友與聊天頁保持關係與即時訊息聯動。'),
          ],
          trailing: BilingualActionButton(
            variant: BilingualButtonVariant.tonal,
            compact: true,
            onPressed: onOpenPublicSpace,
            primaryLabel: localizedText(languageCode, '打开空间', 'Open space', '打開空間'),
            secondaryLabel: 'Open space',
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: localizedText(languageCode, '空间摘要', 'Space summary', '空間摘要'),
          lines: [
            if (activePublicSpace != null)
              '${localizedText(languageCode, '当前空间', 'Current space', '目前空間')}: ${activePublicSpace!.name} · @${activePublicSpace!.subdomain}',
            for (final space in visibleSpaces.take(4))
              '${spaceVisibilityLabel(space.visibility, languageCode)} · ${space.name} · @${space.subdomain}',
            if (visibleSpaces.isEmpty)
              localizedText(languageCode, '当前还没有可见空间，先创建一个空间。', 'No visible spaces yet. Create one first.', '目前還沒有可見空間，先建立一個空間。'),
          ],
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: localizedText(languageCode, '最近空间内容', 'Recent space content', '最近空間內容'),
          lines: [
            for (final post in publicPosts.take(3))
              '${post.authorName}: ${post.title}',
            if (publicPosts.isEmpty)
              localizedText(languageCode, '空间里还没有内容。', 'No content in this space yet.', '空間裡還沒有內容。'),
          ],
          trailing: BilingualActionButton(
            variant: BilingualButtonVariant.tonal,
            compact: true,
            onPressed: publicPosts.isEmpty
                ? null
                : () => onOpenPostDetail(publicPosts.first.id),
            primaryLabel: localizedText(languageCode, '查看详情', 'View details', '查看詳情'),
            secondaryLabel: 'View details',
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
}

class SpaceComposerCard extends StatelessWidget {
  const SpaceComposerCard({
    super.key,
    required this.loading,
    required this.title,
    required this.subtitle,
    required this.detailLines,
    required this.buttonPrimaryLabel,
    required this.buttonSecondaryLabel,
    required this.buttonVariant,
    required this.onSubmit,
  });

  final bool loading;
  final String title;
  final String subtitle;
  final List<String> detailLines;
  final String buttonPrimaryLabel;
  final String buttonSecondaryLabel;
  final BilingualButtonVariant buttonVariant;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
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
            if (detailLines.isNotEmpty)
              ...detailLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line),
                ),
              ),
            if (detailLines.isNotEmpty) const SizedBox(height: 8),
            BilingualActionButton(
              variant: buttonVariant,
              onPressed: loading ? null : onSubmit,
              primaryLabel: buttonPrimaryLabel,
              secondaryLabel: buttonSecondaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class PostComposerCard extends StatelessWidget {
  const PostComposerCard({
    super.key,
    required this.loading,
    required this.title,
    required this.subtitle,
    required this.detailLines,
    required this.buttonPrimaryLabel,
    required this.buttonSecondaryLabel,
    required this.buttonVariant,
    required this.onSubmit,
  });

  final bool loading;
  final String title;
  final String subtitle;
  final List<String> detailLines;
  final String buttonPrimaryLabel;
  final String buttonSecondaryLabel;
  final BilingualButtonVariant buttonVariant;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
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
            if (detailLines.isNotEmpty)
              ...detailLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line),
                ),
              ),
            if (detailLines.isNotEmpty) const SizedBox(height: 8),
            BilingualActionButton(
              variant: buttonVariant,
              onPressed: loading ? null : onSubmit,
              primaryLabel: buttonPrimaryLabel,
              secondaryLabel: buttonSecondaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class SpaceListSection extends StatelessWidget {
  const SpaceListSection({
    super.key,
    required this.title,
    required this.spaces,
    required this.activeSpaceId,
    required this.currentUserId,
    required this.onEnterSpace,
    this.onEditSpace,
    this.onDeleteSpace,
    required this.languageCode,
  });

  final String title;
  final List<SpaceItem> spaces;
  final String? activeSpaceId;
  final String? currentUserId;
  final ValueChanged<SpaceItem> onEnterSpace;
  final ValueChanged<SpaceItem>? onEditSpace;
  final ValueChanged<SpaceItem>? onDeleteSpace;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
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
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
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
                                  space.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              if (space.id == activeSpaceId)
                                Chip(label: Text(localizedText(languageCode, '当前', 'Current', '目前'))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(space.description),
                          const SizedBox(height: 8),
                          Text(
                            '${localizedText(languageCode, '类型', 'Type', '類型')}: ${spaceTypeLabel(space.type, languageCode)}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${localizedText(languageCode, '可见性', 'Visibility', '可見性')}: ${spaceVisibilityLabel(space.visibility, languageCode)}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${localizedText(languageCode, '二级域名', 'Subdomain', '二級網域')}: @${space.subdomain}',
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              BilingualActionButton(
                                variant: BilingualButtonVariant.tonal,
                                compact: true,
                                onPressed: () => onEnterSpace(space),
                                primaryLabel: localizedText(languageCode, '进入空间', 'Enter space', '進入空間'),
                                secondaryLabel: 'Enter space',
                              ),
                              if (onEditSpace != null && currentUserId != null && space.userId == currentUserId)
                                BilingualActionButton(
                                  variant: BilingualButtonVariant.tonal,
                                  compact: true,
                                  onPressed: () => onEditSpace!(space),
                                  primaryLabel: localizedText(languageCode, '编辑', 'Edit', '編輯'),
                                  secondaryLabel: 'Edit',
                                ),
                              if (onDeleteSpace != null && currentUserId != null && space.userId == currentUserId)
                                BilingualActionButton(
                                  variant: BilingualButtonVariant.text,
                                  compact: true,
                                  onPressed: () => onDeleteSpace!(space),
                                  primaryLabel: localizedText(languageCode, '删除', 'Delete', '刪除'),
                                  secondaryLabel: 'Delete',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        if (spaces.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              localizedText(languageCode, '当前还没有空间。', 'No spaces yet.', '目前還沒有空間。'),
            ),
          ),
      ],
    );
  }
}

class PostStreamSection extends StatelessWidget {
  const PostStreamSection({
    super.key,
    required this.posts,
    required this.emptyText,
    required this.commentControllerFor,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.onOpenAuthor,
    required this.onOpenDetail,
    required this.canEditPost,
    this.onDeletePost,
    required this.languageCode,
  });

  final List<PostItem> posts;
  final String emptyText;
  final TextEditingController Function(String postId) commentControllerFor;
  final ValueChanged<PostItem> onLike;
  final ValueChanged<PostItem> onShare;
  final ValueChanged<PostItem> onComment;
  final ValueChanged<String> onOpenAuthor;
  final ValueChanged<String> onOpenDetail;
  final bool Function(PostItem post) canEditPost;
  final ValueChanged<PostItem>? onDeletePost;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return InfoCard(
        title: localizedText(languageCode, '内容流', 'Feed', '內容流'),
        lines: [emptyText],
      );
    }
    return Column(
      children: [
        for (var index = 0; index < posts.length; index++) ...[
          PostCard(
            post: posts[index],
            commentController: commentControllerFor(posts[index].id),
            onLike: () => onLike(posts[index]),
            onShare: () => onShare(posts[index]),
            onComment: () => onComment(posts[index]),
            onOpenAuthor: () => onOpenAuthor(posts[index].userId),
            onOpenDetail: () => onOpenDetail(posts[index].id),
            onEdit: canEditPost(posts[index])
                ? () => onOpenDetail(posts[index].id)
                : null,
            onDelete: canEditPost(posts[index]) && onDeletePost != null
                ? () => onDeletePost!(posts[index])
                : null,
          ),
          if (index < posts.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
