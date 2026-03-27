import 'package:flutter/material.dart';

import 'mermaid_diagram.dart';

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
        children.add(const SizedBox(height: 12));
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

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildBlock({
    required BuildContext context,
    required _MarkdownBlock block,
    required TextStyle baseStyle,
    required TextStyle codeStyle,
    required TextStyle linkStyle,
  }) {
    final theme = Theme.of(context);
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
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 4),
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
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.info.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    block.info,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SelectableText(
                block.text,
                style: codeStyle.copyWith(height: 1.5),
              ),
            ],
          ),
        );
      case _MarkdownBlockType.mermaid:
        return MermaidDiagramBlock(code: block.text);
      case _MarkdownBlockType.unorderedList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < block.listItems.length; index += 1) ...[
              if (index > 0) const SizedBox(height: 6),
              _buildListItem(
                marker: block.listItems[index].checked == null
                    ? const _ListMarkerData.text('•')
                    : _ListMarkerData.task(block.listItems[index].checked!),
                text: block.listItems[index].text,
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
              if (index > 0) const SizedBox(height: 6),
              _buildListItem(
                marker: _ListMarkerData.text('${index + 1}.'),
                text: block.items[index],
                baseStyle: baseStyle,
                codeStyle: codeStyle,
                linkStyle: linkStyle,
              ),
            ],
          ],
        );
      case _MarkdownBlockType.table:
        return _MarkdownTable(
          header: block.header,
          rows: block.rows,
          baseStyle: baseStyle,
          codeStyle: codeStyle,
          linkStyle: linkStyle,
        );
      case _MarkdownBlockType.thematicBreak:
        return Divider(color: theme.colorScheme.outlineVariant, height: 12);
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
    required _ListMarkerData marker,
    required String text,
    required TextStyle baseStyle,
    required TextStyle codeStyle,
    required TextStyle linkStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (marker.taskChecked == null)
          Text(
            '${marker.text} ',
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          )
        else
          Container(
            margin: const EdgeInsets.only(top: 2, right: 8),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: marker.taskChecked!
                  ? Colors.teal.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                marker.taskChecked! ? '✓' : '○',
                style: baseStyle.copyWith(
                  fontSize: (baseStyle.fontSize ?? 15) - 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
  _CodeFenceState? fence;
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

    if (fence != null) {
      if (trimmed.startsWith(fence.delimiter)) {
        blocks.add(
          fence.info == 'mermaid'
              ? _MarkdownBlock.mermaid(codeLines.join('\n'))
              : _MarkdownBlock.code(codeLines.join('\n'), fence.info),
        );
        fence = null;
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

    final fenceMatch = RegExp(
      r'^(```|~~~)\s*([\w-]+)?\s*$',
    ).firstMatch(trimmed);
    if (fenceMatch != null) {
      flushParagraph();
      fence = _CodeFenceState(
        delimiter: fenceMatch.group(1)!,
        info: (fenceMatch.group(2) ?? '').toLowerCase(),
      );
      codeLines = <String>[];
      index += 1;
      continue;
    }

    if (RegExp(r'^([-*_])(?:\s*\1){2,}\s*$').hasMatch(trimmed)) {
      flushParagraph();
      blocks.add(_MarkdownBlock.thematicBreak());
      index += 1;
      continue;
    }

    if (index + 1 < lines.length &&
        line.contains('|') &&
        lines[index + 1].contains('|') &&
        _isTableSeparator(lines[index + 1])) {
      flushParagraph();
      final header = _splitTableRow(line);
      final rows = <List<String>>[];
      index += 2;
      while (index < lines.length) {
        final current = lines[index];
        if (current.trim().isEmpty || !current.contains('|')) {
          break;
        }
        rows.add(_splitTableRow(current));
        index += 1;
      }
      blocks.add(_MarkdownBlock.table(header, rows));
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
      final items = <_MarkdownListItem>[];
      while (index < lines.length) {
        final current = RegExp(
          r'^[-*+]\s+(.+)$',
        ).firstMatch(lines[index].trim());
        if (current == null) {
          break;
        }
        final itemText = current.group(1) ?? '';
        final taskMatch = RegExp(r'^\[( |x|X)\]\s+(.+)$').firstMatch(itemText);
        items.add(
          _MarkdownListItem(
            text: taskMatch?.group(2) ?? itemText,
            checked: taskMatch == null
                ? null
                : (taskMatch.group(1)?.toLowerCase() == 'x'),
          ),
        );
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
  if (fence != null) {
    blocks.add(
      fence.info == 'mermaid'
          ? _MarkdownBlock.mermaid(codeLines.join('\n'))
          : _MarkdownBlock.code(codeLines.join('\n'), fence.info),
    );
  }

  return blocks;
}

List<String> _splitTableRow(String line) {
  // Split one markdown table row into trimmed cells.
  // 将一行 Markdown 表格拆分成去空白后的单元格。
  return line
      .trim()
      .replaceFirst(RegExp(r'^\|'), '')
      .replaceFirst(RegExp(r'\|$'), '')
      .split('|')
      .map((cell) => cell.trim())
      .toList();
}

bool _isTableSeparator(String line) {
  // Detect the separator row between table head and body.
  // 识别表头和表体之间的分隔线。
  final cells = _splitTableRow(line);
  if (cells.isEmpty) {
    return false;
  }
  return cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell));
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
  mermaid,
  unorderedList,
  orderedList,
  table,
  thematicBreak,
}

class _MarkdownBlock {
  const _MarkdownBlock._({
    required this.type,
    required this.text,
    required this.items,
    required this.listItems,
    required this.level,
    required this.info,
    required this.header,
    required this.rows,
  });

  factory _MarkdownBlock.paragraph(String text) => _MarkdownBlock._(
    type: _MarkdownBlockType.paragraph,
    text: text,
    items: const [],
    listItems: const [],
    level: 0,
    info: '',
    header: const [],
    rows: const [],
  );

  factory _MarkdownBlock.heading(int level, String text) => _MarkdownBlock._(
    type: _MarkdownBlockType.heading,
    text: text,
    items: const [],
    listItems: const [],
    level: level,
    info: '',
    header: const [],
    rows: const [],
  );

  factory _MarkdownBlock.quote(String text) => _MarkdownBlock._(
    type: _MarkdownBlockType.quote,
    text: text,
    items: const [],
    listItems: const [],
    level: 0,
    info: '',
    header: const [],
    rows: const [],
  );

  factory _MarkdownBlock.code(String text, String info) => _MarkdownBlock._(
    type: _MarkdownBlockType.code,
    text: text,
    items: const [],
    listItems: const [],
    level: 0,
    info: info,
    header: const [],
    rows: const [],
  );

  factory _MarkdownBlock.mermaid(String text) => _MarkdownBlock._(
    type: _MarkdownBlockType.mermaid,
    text: text,
    items: const [],
    listItems: const [],
    level: 0,
    info: 'mermaid',
    header: const [],
    rows: const [],
  );

  factory _MarkdownBlock.unorderedList(List<_MarkdownListItem> items) =>
      _MarkdownBlock._(
        type: _MarkdownBlockType.unorderedList,
        text: '',
        items: items,
        listItems: items,
        level: 0,
        info: '',
        header: const [],
        rows: const [],
      );

  factory _MarkdownBlock.orderedList(List<String> items) => _MarkdownBlock._(
    type: _MarkdownBlockType.orderedList,
    text: '',
    items: items,
    listItems: const [],
    level: 0,
    info: '',
    header: const [],
    rows: const [],
  );

  factory _MarkdownBlock.table(List<String> header, List<List<String>> rows) =>
      _MarkdownBlock._(
        type: _MarkdownBlockType.table,
        text: '',
        items: const [],
        listItems: const [],
        level: 0,
        info: '',
        header: header,
        rows: rows,
      );

  factory _MarkdownBlock.thematicBreak() => _MarkdownBlock._(
    type: _MarkdownBlockType.thematicBreak,
    text: '',
    items: const [],
    listItems: const [],
    level: 0,
    info: '',
    header: const [],
    rows: const [],
  );

  final _MarkdownBlockType type;
  final String text;
  final List<dynamic> items;
  final List<_MarkdownListItem> listItems;
  final int level;
  final String info;
  final List<String> header;
  final List<List<String>> rows;
}

class _MarkdownListItem {
  const _MarkdownListItem({required this.text, required this.checked});

  final String text;
  final bool? checked;
}

class _CodeFenceState {
  const _CodeFenceState({required this.delimiter, required this.info});

  final String delimiter;
  final String info;
}

class _ListMarkerData {
  const _ListMarkerData._({required this.text, required this.taskChecked});

  const _ListMarkerData.text(String text)
    : this._(text: text, taskChecked: null);

  const _ListMarkerData.task(bool checked)
    : this._(text: '', taskChecked: checked);

  final String text;
  final bool? taskChecked;
}

class _MarkdownTable extends StatelessWidget {
  const _MarkdownTable({
    required this.header,
    required this.rows,
    required this.baseStyle,
    required this.codeStyle,
    required this.linkStyle,
  });

  final List<String> header;
  final List<List<String>> rows;
  final TextStyle baseStyle;
  final TextStyle codeStyle;
  final TextStyle linkStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        children: [
          for (final cell in header)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text.rich(
                TextSpan(
                  style: baseStyle.copyWith(fontWeight: FontWeight.w800),
                  children: _buildInlineSpans(
                    cell,
                    baseStyle.copyWith(fontWeight: FontWeight.w800),
                    codeStyle,
                    linkStyle,
                  ),
                ),
              ),
            ),
        ],
      ),
      for (final row in rows)
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.2),
          ),
          children: [
            for (final cell in row)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text.rich(
                  TextSpan(
                    style: baseStyle,
                    children: _buildInlineSpans(
                      cell,
                      baseStyle,
                      codeStyle,
                      linkStyle,
                    ),
                  ),
                ),
              ),
          ],
        ),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.symmetric(
              inside: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            children: effectiveRows,
          ),
        ),
      ),
    );
  }
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
