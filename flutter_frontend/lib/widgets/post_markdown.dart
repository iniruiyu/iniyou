import 'package:flutter/material.dart';

class PostMarkdownBody extends StatelessWidget {
  const PostMarkdownBody({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = _parseMarkdownBlocks(content);
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    final baseStyle =
        theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: theme.colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: 15,
          height: 1.6,
          color: theme.colorScheme.onSurface,
        );
    final codeStyle = baseStyle.copyWith(
      fontFamily: 'monospace',
      fontSize: (baseStyle.fontSize ?? 15) - 0.5,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      color: theme.colorScheme.onSurface,
    );
    final linkStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    final children = <Widget>[];
    for (var index = 0; index < blocks.length; index += 1) {
      if (index > 0) {
        children.add(const SizedBox(height: 10));
      }
      children.add(
        _buildBlock(
          context: context,
          block: blocks[index],
          baseStyle: baseStyle,
          codeStyle: codeStyle,
          linkStyle: linkStyle,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildBlock({
    required BuildContext context,
    required _MarkdownBlock block,
    required TextStyle baseStyle,
    required TextStyle codeStyle,
    required TextStyle linkStyle,
  }) {
    switch (block.type) {
      case _MarkdownBlockType.heading:
        final headingStyle = _headingStyle(context, block.level, baseStyle);
        return Text.rich(
          TextSpan(
            style: headingStyle,
            children: _buildInlineSpans(
              block.text,
              headingStyle,
              codeStyle,
              linkStyle,
            ),
          ),
        );
      case _MarkdownBlockType.quote:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 4,
              ),
            ),
          ),
          child: Text.rich(
            TextSpan(
              style: baseStyle,
              children: _buildInlineSpans(
                block.text,
                baseStyle,
                codeStyle,
                linkStyle,
              ),
            ),
          ),
        );
      case _MarkdownBlockType.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: SelectableText(
            block.text,
            style: codeStyle.copyWith(height: 1.5),
          ),
        );
      case _MarkdownBlockType.unorderedList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < block.items.length; index += 1) ...[
              if (index > 0) const SizedBox(height: 4),
              _buildListItem(
                prefix: '•',
                text: block.items[index],
                baseStyle: baseStyle,
                codeStyle: codeStyle,
                linkStyle: linkStyle,
              ),
            ],
          ],
        );
      case _MarkdownBlockType.orderedList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < block.items.length; index += 1) ...[
              if (index > 0) const SizedBox(height: 4),
              _buildListItem(
                prefix: '${index + 1}.',
                text: block.items[index],
                baseStyle: baseStyle,
                codeStyle: codeStyle,
                linkStyle: linkStyle,
              ),
            ],
          ],
        );
      case _MarkdownBlockType.paragraph:
        return Text.rich(
          TextSpan(
            style: baseStyle,
            children: _buildInlineSpans(
              block.text,
              baseStyle,
              codeStyle,
              linkStyle,
            ),
          ),
        );
    }
  }

  Widget _buildListItem({
    required String prefix,
    required String text,
    required TextStyle baseStyle,
    required TextStyle codeStyle,
    required TextStyle linkStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$prefix ',
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: baseStyle,
              children: _buildInlineSpans(
                text,
                baseStyle,
                codeStyle,
                linkStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

TextStyle _headingStyle(BuildContext context, int level, TextStyle baseStyle) {
  // Scale heading text without losing the app theme's overall typography tone.
  // 在不破坏应用整体字体系的前提下，按层级放大标题文本。
  final theme = Theme.of(context);
  final baseSize =
      theme.textTheme.titleLarge?.fontSize ?? (baseStyle.fontSize ?? 15) + 5;
  final levelOffset = switch (level) {
    1 => 10.0,
    2 => 8.0,
    3 => 6.0,
    4 => 4.0,
    5 => 2.0,
    _ => 0.0,
  };
  return baseStyle.copyWith(
    fontSize: baseSize + levelOffset,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
}

List<_MarkdownBlock> _parseMarkdownBlocks(String content) {
  // Parse the article body into block-level markdown sections.
  // 将文章正文解析为块级 Markdown 结构。
  final lines = content
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  final blocks = <_MarkdownBlock>[];
  final paragraphLines = <String>[];
  var fence = '';
  var codeLines = <String>[];

  void flushParagraph() {
    if (paragraphLines.isEmpty) {
      return;
    }
    blocks.add(_MarkdownBlock.paragraph(paragraphLines.join('\n')));
    paragraphLines.clear();
  }

  for (var index = 0; index < lines.length;) {
    final line = lines[index];
    final trimmed = line.trim();

    if (fence.isNotEmpty) {
      if (trimmed.startsWith(fence)) {
        blocks.add(_MarkdownBlock.code(codeLines.join('\n')));
        fence = '';
        codeLines = <String>[];
      } else {
        codeLines.add(line);
      }
      index += 1;
      continue;
    }

    if (trimmed.isEmpty) {
      flushParagraph();
      index += 1;
      continue;
    }

    final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
    if (headingMatch != null) {
      flushParagraph();
      blocks.add(
        _MarkdownBlock.heading(
          headingMatch.group(1)!.length,
          headingMatch.group(2) ?? '',
        ),
      );
      index += 1;
      continue;
    }

    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      flushParagraph();
      fence = trimmed.substring(0, 3);
      codeLines = <String>[];
      index += 1;
      continue;
    }

    if (trimmed.startsWith('>')) {
      flushParagraph();
      final quoteLines = <String>[];
      while (index < lines.length) {
        final quoteTrimmed = lines[index].trim();
        if (!quoteTrimmed.startsWith('>')) {
          break;
        }
        quoteLines.add(quoteTrimmed.replaceFirst(RegExp(r'^>\s?'), ''));
        index += 1;
      }
      blocks.add(_MarkdownBlock.quote(quoteLines.join('\n')));
      continue;
    }

    final unorderedMatch = RegExp(r'^[-*+]\s+(.+)$').firstMatch(trimmed);
    if (unorderedMatch != null) {
      flushParagraph();
      final items = <String>[];
      while (index < lines.length) {
        final current = RegExp(
          r'^[-*+]\s+(.+)$',
        ).firstMatch(lines[index].trim());
        if (current == null) {
          break;
        }
        items.add(current.group(1) ?? '');
        index += 1;
      }
      blocks.add(_MarkdownBlock.unorderedList(items));
      continue;
    }

    final orderedMatch = RegExp(r'^\d+\.\s+(.+)$').firstMatch(trimmed);
    if (orderedMatch != null) {
      flushParagraph();
      final items = <String>[];
      while (index < lines.length) {
        final current = RegExp(
          r'^\d+\.\s+(.+)$',
        ).firstMatch(lines[index].trim());
        if (current == null) {
          break;
        }
        items.add(current.group(1) ?? '');
        index += 1;
      }
      blocks.add(_MarkdownBlock.orderedList(items));
      continue;
    }

    paragraphLines.add(line);
    index += 1;
  }

  flushParagraph();
  if (fence.isNotEmpty) {
    blocks.add(_MarkdownBlock.code(codeLines.join('\n')));
  }

  return blocks;
}

List<InlineSpan> _buildInlineSpans(
  String text,
  TextStyle baseStyle,
  TextStyle codeStyle,
  TextStyle linkStyle,
) {
  // Keep a small inline parser so markdown can be rendered without extra packages.
  // 通过一个轻量级行内解析器渲染 Markdown，避免额外引入依赖。
  final spans = <InlineSpan>[];
  var index = 0;

  while (index < text.length) {
    final match = _findNextInlineMatch(text, index);
    if (match == null) {
      spans.add(TextSpan(text: text.substring(index), style: baseStyle));
      break;
    }

    if (match.start > index) {
      spans.add(
        TextSpan(text: text.substring(index, match.start), style: baseStyle),
      );
    }

    switch (match.type) {
      case _InlineType.code:
        spans.add(TextSpan(text: match.content, style: codeStyle));
        break;
      case _InlineType.link:
        spans.add(
          TextSpan(
            style: linkStyle,
            children: _buildInlineSpans(
              match.content,
              linkStyle,
              codeStyle,
              linkStyle,
            ),
          ),
        );
        break;
      case _InlineType.bold:
        final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w800);
        spans.add(
          TextSpan(
            style: boldStyle,
            children: _buildInlineSpans(
              match.content,
              boldStyle,
              codeStyle,
              linkStyle,
            ),
          ),
        );
        break;
      case _InlineType.italic:
        final italicStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
        spans.add(
          TextSpan(
            style: italicStyle,
            children: _buildInlineSpans(
              match.content,
              italicStyle,
              codeStyle,
              linkStyle,
            ),
          ),
        );
        break;
    }

    index = match.end;
  }

  return spans;
}

_InlineMatch? _findNextInlineMatch(String text, int fromIndex) {
  // Resolve the earliest inline markdown token so formatting stays stable.
  // 找出最早出现的行内 Markdown 标记，保持格式解析稳定。
  final candidates = <_InlineMatch?>[
    _findCodeMatch(text, fromIndex),
    _findLinkMatch(text, fromIndex),
    _findDelimitedMatch(text, fromIndex, '**', _InlineType.bold),
    _findDelimitedMatch(text, fromIndex, '__', _InlineType.bold),
    _findDelimitedMatch(text, fromIndex, '*', _InlineType.italic),
  ].whereType<_InlineMatch>().toList();
  if (candidates.isEmpty) {
    return null;
  }
  candidates.sort((a, b) {
    final startCompare = a.start.compareTo(b.start);
    if (startCompare != 0) {
      return startCompare;
    }
    return a.priority.compareTo(b.priority);
  });
  return candidates.first;
}

_InlineMatch? _findCodeMatch(String text, int fromIndex) {
  final open = text.indexOf('`', fromIndex);
  if (open < 0) {
    return null;
  }
  final close = text.indexOf('`', open + 1);
  if (close <= open + 1) {
    return null;
  }
  return _InlineMatch(
    start: open,
    end: close + 1,
    content: text.substring(open + 1, close),
    type: _InlineType.code,
    priority: 0,
  );
}

_InlineMatch? _findLinkMatch(String text, int fromIndex) {
  final open = text.indexOf('[', fromIndex);
  if (open < 0) {
    return null;
  }
  final closeLabel = text.indexOf('](', open + 1);
  if (closeLabel < 0) {
    return null;
  }
  final closeUrl = text.indexOf(')', closeLabel + 2);
  if (closeUrl < 0) {
    return null;
  }
  final label = text.substring(open + 1, closeLabel);
  final url = text.substring(closeLabel + 2, closeUrl).trim();
  if (label.isEmpty || url.isEmpty) {
    return null;
  }
  return _InlineMatch(
    start: open,
    end: closeUrl + 1,
    content: label,
    type: _InlineType.link,
    priority: 1,
  );
}

_InlineMatch? _findDelimitedMatch(
  String text,
  int fromIndex,
  String delimiter,
  _InlineType type,
) {
  var open = text.indexOf(delimiter, fromIndex);
  while (open >= 0) {
    final close = text.indexOf(delimiter, open + delimiter.length);
    if (close > open + delimiter.length) {
      return _InlineMatch(
        start: open,
        end: close + delimiter.length,
        content: text.substring(open + delimiter.length, close),
        type: type,
        priority: type == _InlineType.bold ? 2 : 3,
      );
    }
    open = text.indexOf(delimiter, open + delimiter.length);
  }
  return null;
}

enum _MarkdownBlockType {
  paragraph,
  heading,
  quote,
  code,
  unorderedList,
  orderedList,
}

class _MarkdownBlock {
  const _MarkdownBlock._({
    required this.type,
    required this.text,
    required this.items,
    required this.level,
  });

  factory _MarkdownBlock.paragraph(String text) => _MarkdownBlock._(
    type: _MarkdownBlockType.paragraph,
    text: text,
    items: const [],
    level: 0,
  );

  factory _MarkdownBlock.heading(int level, String text) => _MarkdownBlock._(
    type: _MarkdownBlockType.heading,
    text: text,
    items: const [],
    level: level,
  );

  factory _MarkdownBlock.quote(String text) => _MarkdownBlock._(
    type: _MarkdownBlockType.quote,
    text: text,
    items: const [],
    level: 0,
  );

  factory _MarkdownBlock.code(String text) => _MarkdownBlock._(
    type: _MarkdownBlockType.code,
    text: text,
    items: const [],
    level: 0,
  );

  factory _MarkdownBlock.unorderedList(List<String> items) => _MarkdownBlock._(
    type: _MarkdownBlockType.unorderedList,
    text: '',
    items: items,
    level: 0,
  );

  factory _MarkdownBlock.orderedList(List<String> items) => _MarkdownBlock._(
    type: _MarkdownBlockType.orderedList,
    text: '',
    items: items,
    level: 0,
  );

  final _MarkdownBlockType type;
  final String text;
  final List<String> items;
  final int level;
}

enum _InlineType { code, link, bold, italic }

class _InlineMatch {
  const _InlineMatch({
    required this.start,
    required this.end,
    required this.content,
    required this.type,
    required this.priority,
  });

  final int start;
  final int end;
  final String content;
  final _InlineType type;
  final int priority;
}
