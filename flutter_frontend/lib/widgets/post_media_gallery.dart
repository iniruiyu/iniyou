import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/app_models.dart';

class PostMediaGallery extends StatelessWidget {
  const PostMediaGallery({
    super.key,
    required this.items,
    this.onOpenAttachment,
    this.onRemoveAttachment,
    this.maxWidth = 720,
    this.singleMaxHeight = 405,
    this.singleAspectRatio = 16 / 9,
    this.gridMinTileWidth = 180,
    this.gridAspectRatio = 4 / 3,
  });

  final List<PostAttachmentDraft> items;
  final ValueChanged<PostAttachmentDraft>? onOpenAttachment;
  final ValueChanged<int>? onRemoveAttachment;
  final double maxWidth;
  final double singleMaxHeight;
  final double singleAspectRatio;
  final double gridMinTileWidth;
  final double gridAspectRatio;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (items.length == 1) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: singleMaxHeight,
          ),
          child: _PostMediaTile(
            item: items.first,
            index: 0,
            aspectRatio: singleAspectRatio,
            onOpenAttachment: onOpenAttachment,
            onRemoveAttachment: onRemoveAttachment,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Let the gallery keep every tile visible while adapting the column count to width.
        // 让画廊根据宽度自适应列数，同时保证每个媒体项都完整可见。
        final availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : maxWidth;
        final tentativeColumns = (availableWidth / gridMinTileWidth).floor();
        final crossAxisCount = tentativeColumns < 1
            ? 1
            : tentativeColumns > 3
            ? 3
            : tentativeColumns;
        final effectiveColumns = items.length < crossAxisCount
            ? items.length
            : crossAxisCount;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveColumns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: gridAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _PostMediaTile(
              item: items[index],
              index: index,
              aspectRatio: gridAspectRatio,
              onOpenAttachment: onOpenAttachment,
              onRemoveAttachment: onRemoveAttachment,
            );
          },
        );
      },
    );
  }
}

class _PostMediaTile extends StatelessWidget {
  const _PostMediaTile({
    required this.item,
    required this.index,
    required this.aspectRatio,
    this.onOpenAttachment,
    this.onRemoveAttachment,
  });

  final PostAttachmentDraft item;
  final int index;
  final double aspectRatio;
  final ValueChanged<PostAttachmentDraft>? onOpenAttachment;
  final ValueChanged<int>? onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildBody(context),
        ),
      ),
    );

    if (onOpenAttachment == null && onRemoveAttachment == null) {
      return card;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            onTap: onOpenAttachment == null
                ? null
                : () => onOpenAttachment!.call(item),
            child: card,
          ),
        ),
        if (onRemoveAttachment != null)
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkResponse(
                onTap: () => onRemoveAttachment!.call(index),
                radius: 18,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xDD111827),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (item.isImage) {
      final bytes = _decodeMediaBytes(item.mediaData);
      if (bytes != null) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Image.memory(
            bytes,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
          ),
        );
      }
    }

    final icon = item.isVideo
        ? Icons.video_library_outlined
        : item.isImage
        ? Icons.image_outlined
        : Icons.attachment_outlined;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.mediaName.isNotEmpty ? item.mediaName : '媒体附件',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  item.mediaMime.isNotEmpty
                      ? '${item.mediaMime} · ${item.sizeLabel}'
                      : item.sizeLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeMediaBytes(String data) {
    // Decode the gallery payload for inline image previews.
    // 解码画廊载荷，以便直接预览图片内容。
    if (data.isEmpty) {
      return null;
    }
    try {
      return Uint8List.fromList(base64Decode(data));
    } catch (_) {
      return null;
    }
  }
}
