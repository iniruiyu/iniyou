import 'package:flutter/material.dart';

import '../models/app_models.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.commentController,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    this.onOpenAuthor,
    this.onOpenDetail,
    this.onEdit,
    this.onDelete,
  });

  final PostItem post;
  final TextEditingController commentController;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback? onOpenAuthor;
  final VoidCallback? onOpenDetail;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        post.authorName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      if (post.spaceLabel.isNotEmpty)
                        Text(
                          post.spaceLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (post.spaceLabel.isNotEmpty) const SizedBox(height: 4),
                      Text(
                        '${post.visibility} · ${post.status} · ${post.createdAtLabel}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onOpenAuthor != null)
                      FilledButton.tonal(
                        onPressed: onOpenAuthor,
                        child: const Text('作者主页'),
                      ),
                    if (onOpenDetail != null)
                      FilledButton.tonal(
                        onPressed: onOpenDetail,
                        child: const Text('详情'),
                      ),
                    if (onEdit != null)
                      FilledButton.tonal(
                        onPressed: onEdit,
                        child: const Text('编辑'),
                      ),
                    if (onDelete != null)
                      TextButton(onPressed: onDelete, child: const Text('删除')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(post.content),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onLike,
                  child: Text(
                    '${post.likedByMe ? '取消点赞' : '点赞'} · ${post.likesCount}',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onShare,
                  child: Text('转发 · ${post.sharesCount}'),
                ),
                Chip(label: Text('评论 ${post.commentsCount}')),
              ],
            ),
            const SizedBox(height: 12),
            if (post.comments.isNotEmpty)
              ...post.comments.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${item.authorName}: ${item.content}'),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(labelText: '写评论'),
                    onSubmitted: (_) => onComment(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: onComment,
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

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.lines,
    this.trailing,
  });

  final String title;
  final List<String> lines;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.planId,
    required this.title,
    required this.features,
    required this.isLoading,
    required this.onActivate,
  });

  final String planId;
  final String title;
  final List<String> features;
  final bool isLoading;
  final ValueChanged<String> onActivate;

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
            const SizedBox(height: 12),
            ...features.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('- $item'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isLoading ? null : () => onActivate(planId),
              child: Text('启用 $planId'),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroStatCard extends StatelessWidget {
  const HeroStatCard({
    super.key,
    required this.index,
    required this.label,
    required this.text,
  });

  final String index;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(index, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureChipCard extends StatelessWidget {
  const FeatureChipCard({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.item});

  final SummaryCardData item;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                item.value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(item.detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class SummaryCardData {
  const SummaryCardData(this.label, this.value, this.detail);

  final String label;
  final String value;
  final String detail;
}

class LevelCardData {
  const LevelCardData({
    required this.level,
    required this.title,
    required this.text,
  });

  final String level;
  final String title;
  final String text;
}
