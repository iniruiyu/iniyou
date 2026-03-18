import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_cards.dart';

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
  });

  final double width;
  final CurrentUser user;
  final List<SpaceItem> spaces;
  final List<PostItem> publicPosts;
  final SpaceItem? activePrivateSpace;
  final SpaceItem? activePublicSpace;
  final VoidCallback onOpenPublicSpace;
  final ValueChanged<String> onOpenPostDetail;

  @override
  Widget build(BuildContext context) {
    final compact = width < 980;
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: '账号概览',
          lines: [
            '用户 ID: ${user.id}',
            if (user.email.isNotEmpty) '邮箱: ${user.email}',
            if (user.phone.isNotEmpty) '手机号: ${user.phone}',
            '等级: ${user.level}',
            '状态: ${user.status}',
          ],
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '快捷入口',
          lines: const [
            '进入空间管理草稿、公开内容和空间入口',
            '公开内容会出现在公共空间，也能打开作者主页',
            '好友和聊天页面保持关系与实时消息联动',
          ],
          trailing: FilledButton.tonal(
            onPressed: onOpenPublicSpace,
            child: const Text('打开空间'),
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
            if (activePrivateSpace != null)
              '当前私人：${activePrivateSpace!.name} · @${activePrivateSpace!.subdomain}',
            if (activePublicSpace != null)
              '当前公共：${activePublicSpace!.name} · @${activePublicSpace!.subdomain}',
            for (final space in spaces.take(4))
              '${space.type.toUpperCase()} · ${space.name} · @${space.subdomain}',
            if (spaces.isEmpty) '当前还没有空间，先创建一个空间。',
          ],
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: '最近公共内容',
          lines: [
            for (final post in publicPosts.take(3))
              '${post.authorName}: ${post.title}',
            if (publicPosts.isEmpty) '公共空间里还没有内容。',
          ],
          trailing: FilledButton.tonal(
            onPressed: publicPosts.isEmpty
                ? null
                : () => onOpenPostDetail(publicPosts.first.id),
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
}

class SpaceComposerCard extends StatelessWidget {
  const SpaceComposerCard({
    super.key,
    required this.loading,
    required this.title,
    required this.subtitle,
    required this.detailLines,
    required this.buttonLabel,
    required this.onSubmit,
  });

  final bool loading;
  final String title;
  final String subtitle;
  final List<String> detailLines;
  final String buttonLabel;
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
            FilledButton(
              onPressed: loading ? null : onSubmit,
              child: Text(buttonLabel),
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
    required this.buttonLabel,
    required this.onSubmit,
  });

  final bool loading;
  final String title;
  final String subtitle;
  final List<String> detailLines;
  final String buttonLabel;
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
            FilledButton(
              onPressed: loading ? null : onSubmit,
              child: Text(buttonLabel),
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
    required this.onEnterSpace,
    this.onEditSpace,
    this.onDeleteSpace,
  });

  final String title;
  final List<SpaceItem> spaces;
  final String? activeSpaceId;
  final ValueChanged<SpaceItem> onEnterSpace;
  final ValueChanged<SpaceItem>? onEditSpace;
  final ValueChanged<SpaceItem>? onDeleteSpace;

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
                                const Chip(label: Text('当前')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(space.description),
                          const SizedBox(height: 8),
                          Text('类型: ${space.type}'),
                          const SizedBox(height: 4),
                          Text('二级域名: @${space.subdomain}'),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => onEnterSpace(space),
                                child: const Text('进入空间'),
                              ),
                              if (onEditSpace != null)
                                FilledButton.tonal(
                                  onPressed: () => onEditSpace!(space),
                                  child: const Text('编辑'),
                                ),
                              if (onDeleteSpace != null)
                                TextButton(
                                  onPressed: () => onDeleteSpace!(space),
                                  child: const Text('删除'),
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
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('当前还没有空间。'),
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

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return InfoCard(title: '内容流', lines: [emptyText]);
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
