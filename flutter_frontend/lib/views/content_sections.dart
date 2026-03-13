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
    required this.onOpenPublicSpace,
    required this.onOpenPostDetail,
  });

  final double width;
  final CurrentUser user;
  final List<SpaceItem> spaces;
  final List<PostItem> publicPosts;
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
            '进入私人空间沉淀草稿和私人内容',
            '进入公共空间发布文章和打开作者主页',
            '好友和聊天页面保持关系与实时消息联动',
          ],
          trailing: FilledButton.tonal(
            onPressed: onOpenPublicSpace,
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
            for (final space in spaces.take(4))
              '${space.type.toUpperCase()} · ${space.name}',
            if (spaces.isEmpty) '当前还没有空间，注册后会自动创建默认空间。',
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
    required this.type,
    required this.loading,
    required this.nameController,
    required this.descriptionController,
    required this.onSubmit,
  });

  final String type;
  final bool loading;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
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
              controller: nameController,
              decoration: const InputDecoration(labelText: '空间名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: '空间描述'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : onSubmit,
              child: const Text('创建空间'),
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
    required this.titleController,
    required this.contentController,
    required this.status,
    required this.onStatusChanged,
    required this.onSubmit,
  });

  final bool loading;
  final String title;
  final String subtitle;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String status;
  final ValueChanged<String> onStatusChanged;
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
                  onPressed: loading ? null : onSubmit,
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

class SpaceListSection extends StatelessWidget {
  const SpaceListSection({
    super.key,
    required this.title,
    required this.spaces,
  });

  final String title;
  final List<SpaceItem> spaces;

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
          ),
          if (index < posts.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
