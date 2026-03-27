// ignore_for_file: deprecated_member_use
// Keep the Web Mermaid bridge on the current lightweight SDK path.
// 让 Web Mermaid 桥接暂时沿用当前轻依赖 SDK 调用路径。

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class MermaidDiagramBlock extends StatefulWidget {
  const MermaidDiagramBlock({super.key, required this.code});

  final String code;

  @override
  State<MermaidDiagramBlock> createState() => _MermaidDiagramBlockState();
}

class _MermaidDiagramBlockState extends State<MermaidDiagramBlock> {
  static bool _mermaidInitialized = false;

  late final String _viewType;
  late final html.DivElement _container;

  @override
  void initState() {
    super.initState();
    _viewType =
        'iniyou-mermaid-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';
    _container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.pointerEvents = 'none';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (_) => _container,
    );
    scheduleMicrotask(_renderDiagram);
  }

  @override
  void didUpdateWidget(covariant MermaidDiagramBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      scheduleMicrotask(_renderDiagram);
    }
  }

  void _ensureMermaid() {
    // Bootstrap Mermaid only once for the whole Flutter Web runtime.
    // 在整个 Flutter Web 运行期内仅初始化一次 Mermaid。
    final mermaid = js.context['mermaid'];
    if (mermaid == null || _mermaidInitialized) {
      return;
    }
    mermaid.callMethod('initialize', [
      js.JsObject.jsify({
        'startOnLoad': false,
        'securityLevel': 'strict',
        'theme': 'dark',
      }),
    ]);
    _mermaidInitialized = true;
  }

  Future<void> _renderDiagram() async {
    final pre = html.PreElement()
      ..classes.add('mermaid')
      ..text = widget.code
      ..style.margin = '0'
      ..style.padding = '18px'
      ..style.borderRadius = '16px'
      ..style.border = '1px solid rgba(255,255,255,0.08)'
      ..style.background = 'rgba(8, 14, 22, 0.96)'
      ..style.overflowX = 'auto'
      ..style.whiteSpace = 'pre-wrap'
      ..style.pointerEvents = 'none';
    _container.children
      ..clear()
      ..add(pre);

    final mermaid = js.context['mermaid'];
    if (mermaid == null) {
      return;
    }
    _ensureMermaid();
    try {
      await Future<void>.delayed(Duration.zero);
      mermaid.callMethod('run', [
        js.JsObject.jsify({
          'nodes': js.JsArray.from([pre]),
        }),
      ]);
    } catch (_) {
      // Keep the source block visible when Mermaid rendering fails.
      // Mermaid 渲染失败时保留源码块可见。
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                  'mermaid',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mind map / 思维导图',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 320, child: HtmlElementView(viewType: _viewType)),
        ],
      ),
    );
  }
}
