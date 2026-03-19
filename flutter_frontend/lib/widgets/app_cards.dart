import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../controllers/post_media_actions.dart';
import '../models/app_models.dart';
import 'bilingual_action_button.dart';

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
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: onOpenAuthor,
                        primaryLabel: '作者主页',
                        secondaryLabel: 'Author profile',
                      ),
                    if (onOpenDetail != null)
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: onOpenDetail,
                        primaryLabel: '详情',
                        secondaryLabel: 'Details',
                      ),
                    if (onEdit != null)
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: onEdit,
                        primaryLabel: '编辑',
                        secondaryLabel: 'Edit',
                      ),
                    if (onDelete != null)
                      BilingualActionButton(
                        variant: BilingualButtonVariant.text,
                        compact: true,
                        onPressed: onDelete,
                        primaryLabel: '删除',
                        secondaryLabel: 'Delete',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (post.hasMedia) ...[
              _buildMediaPreview(context),
              const SizedBox(height: 12),
            ],
            if (post.content.isNotEmpty) Text(post.content),
            if (post.content.isEmpty && !post.hasMedia)
              const SizedBox.shrink(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  compact: true,
                  onPressed: onLike,
                  primaryLabel: '${post.likedByMe ? '取消点赞' : '点赞'} · ${post.likesCount}',
                  secondaryLabel: '${post.likedByMe ? 'Unlike' : 'Like'} · ${post.likesCount}',
                ),
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  compact: true,
                  onPressed: onShare,
                  primaryLabel: '转发 · ${post.sharesCount}',
                  secondaryLabel: 'Share · ${post.sharesCount}',
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
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  compact: true,
                  onPressed: onComment,
                  primaryLabel: '提交',
                  secondaryLabel: 'Submit',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    // Render image and short-video attachments with a clear bilingual action.
    // 将图文和小视频附件分别渲染，并提供清晰的双语操作入口。
    if (post.isImage) {
      final bytes = _decodeMediaBytes(post.mediaData);
      if (bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => openPostAttachment(
              mediaMime: post.mediaMime,
              mediaData: post.mediaData,
            ),
            child: Image.memory(
              bytes,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            post.isVideo ? Icons.video_library_outlined : Icons.image_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.mediaName.isNotEmpty ? post.mediaName : '媒体附件',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  post.mediaMime.isNotEmpty
                      ? '${post.mediaMime} · ${post.mediaType}'
                      : post.mediaType,
                ),
                const SizedBox(height: 8),
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  compact: true,
                  onPressed: () => openPostAttachment(
                    mediaMime: post.mediaMime,
                    mediaData: post.mediaData,
                  ),
                  primaryLabel: '打开附件',
                  secondaryLabel: 'Open attachment',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeMediaBytes(String data) {
    try {
      return Uint8List.fromList(base64Decode(data));
    } catch (_) {
      return null;
    }
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
            BilingualActionButton(
              variant: BilingualButtonVariant.filled,
              compact: false,
              onPressed: isLoading ? null : () => onActivate(planId),
              primaryLabel: '启用 $planId',
              secondaryLabel: 'Activate $planId',
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
