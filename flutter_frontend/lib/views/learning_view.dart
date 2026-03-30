import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/app_models.dart';
import '../widgets/bilingual_action_button.dart';
import '../widgets/post_markdown.dart';
import 'view_state_helpers.dart';

const defaultLearningCourseId = 'english-storytelling';

Widget buildLearningView({
  required String languageCode,
  required String activeCourseId,
  required ApiClient apiClient,
  required ValueChanged<String> onSelectCourse,
  required VoidCallback onBackToServices,
}) {
  return LearningView(
    languageCode: languageCode,
    activeCourseId: activeCourseId,
    apiClient: apiClient,
    onSelectCourse: onSelectCourse,
    onBackToServices: onBackToServices,
  );
}

class LearningView extends StatefulWidget {
  const LearningView({
    super.key,
    required this.languageCode,
    required this.activeCourseId,
    required this.apiClient,
    required this.onSelectCourse,
    required this.onBackToServices,
  });

  final String languageCode;
  final String activeCourseId;
  final ApiClient apiClient;
  final ValueChanged<String> onSelectCourse;
  final VoidCallback onBackToServices;

  @override
  State<LearningView> createState() => _LearningViewState();
}

class _LearningViewState extends State<LearningView> {
  final Map<String, MarkdownFileDocument> _markdownCache = {};
  bool _markdownLoading = false;
  String? _markdownError;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadActiveCourseMarkdown();
  }

  @override
  void didUpdateWidget(covariant LearningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeCourseId != widget.activeCourseId ||
        oldWidget.languageCode != widget.languageCode) {
      _loadActiveCourseMarkdown();
    }
  }

  _LearningCourse get _activeCourse => learningCourseCatalog.firstWhere(
    (course) => course.id == widget.activeCourseId,
    orElse: () => learningCourseCatalog.first,
  );

  String _courseMarkdownPath(_LearningCourse course, String languageCode) {
    // Map one course and locale to the learning-service markdown resource path.
    // 将课程与语言映射到 learning-service 的 Markdown 资源路径。
    return 'courses/${course.id}.$languageCode.md';
  }

  String _resolvedCourseMarkdown(_LearningCourse course) {
    final localePath = _courseMarkdownPath(course, widget.languageCode);
    final fallbackPath = _courseMarkdownPath(course, 'zh-CN');
    return _markdownCache[localePath]?.content ??
        _markdownCache[fallbackPath]?.content ??
        course.markdownText(widget.languageCode);
  }

  Future<CodeExecutionRunState> _runCodeSnippet(
    String language,
    String source,
  ) async {
    // Execute one runnable snippet through learning-service and map the result into UI text.
    // 通过 learning-service 执行一段可运行代码，并映射成界面展示文案。
    try {
      final result = await widget.apiClient.executeLearningCodeSnippet(
        language,
        source,
      );
      final meta = result.timedOut
          ? localizedText(
              widget.languageCode,
              '已超时 · ${result.durationMs} ms',
              'Timed out · ${result.durationMs} ms',
              '已逾時 · ${result.durationMs} ms',
            )
          : localizedText(
              widget.languageCode,
              '退出码 ${result.exitCode} · ${result.durationMs} ms',
              'Exit ${result.exitCode} · ${result.durationMs} ms',
              '退出碼 ${result.exitCode} · ${result.durationMs} ms',
            );
      return CodeExecutionRunState(
        stdout: result.stdout,
        stderr: result.stderr,
        meta: meta,
        error: '',
      );
    } catch (error) {
      final message = error is ApiException ? error.message : error.toString();
      return CodeExecutionRunState(
        stdout: '',
        stderr: '',
        meta: localizedText(
          widget.languageCode,
          '请求失败',
          'Request failed',
          '請求失敗',
        ),
        error: message,
      );
    }
  }

  Future<void> _loadActiveCourseMarkdown() async {
    // Prefer backend markdown content and keep the built-in markdown as a stable fallback.
    // 优先读取后端 Markdown 内容，并把内建 Markdown 保留为稳定兜底。
    final course = _activeCourse;
    final currentVersion = ++_loadVersion;
    final candidatePaths = <String>[
      _courseMarkdownPath(course, widget.languageCode),
      if (widget.languageCode != 'zh-CN') _courseMarkdownPath(course, 'zh-CN'),
    ];
    final nextCache = <String, MarkdownFileDocument>{};
    var loaded = false;
    if (mounted) {
      setState(() {
        _markdownLoading = true;
        _markdownError = null;
      });
    }
    for (final path in candidatePaths) {
      if (_markdownCache.containsKey(path)) {
        loaded = true;
        continue;
      }
      try {
        final document = await widget.apiClient.fetchLearningMarkdownFile(path);
        nextCache[path] = document;
        loaded = true;
      } catch (_) {
        // Ignore missing locale variants and continue to the next fallback path.
        // 忽略缺失的语言版本，并继续尝试下一条兜底路径。
      }
    }
    if (!mounted || currentVersion != _loadVersion) {
      return;
    }
    setState(() {
      _markdownCache.addAll(nextCache);
      _markdownLoading = false;
      _markdownError = loaded
          ? null
          : localizedText(
              widget.languageCode,
              '后端课程文件暂未返回，当前显示内建示例内容。',
              'The backend lesson file is not available yet, so the built-in sample is shown.',
              '後端課程檔案暫未返回，目前顯示內建示例內容。',
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCourse = _activeCourse;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final cards = <Widget>[
          for (final course in learningCourseCatalog)
            _LearningCourseCard(
              course: course,
              languageCode: widget.languageCode,
              active: course.id == activeCourse.id,
              onTap: () => widget.onSelectCourse(course.id),
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF172435), Color(0xFF0B121A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
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
                              localizedText(
                                widget.languageCode,
                                '学习服务',
                                'Learning Service',
                                '學習服務',
                              ),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              localizedText(
                                widget.languageCode,
                                '学习课程',
                                'Learning Courses',
                                '學習課程',
                              ),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              localizedText(
                                widget.languageCode,
                                '用课程卡片组织英语、编程、AI 等内容，并完整展示 Markdown、代码块、表格与 Mermaid 思维导图。',
                                'Organize English, programming, AI, and more into course cards while fully rendering Markdown, code fences, tables, and Mermaid mind maps.',
                                '用課程卡片組織英語、程式、AI 等內容，並完整顯示 Markdown、程式碼塊、表格與 Mermaid 思維導圖。',
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.55,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: widget.onBackToServices,
                        primaryLabel: localizedText(
                          widget.languageCode,
                          '返回服务导航',
                          'Back to Services',
                          '返回服務導航',
                        ),
                        secondaryLabel: localizedText(
                          widget.languageCode,
                          'Back to Services',
                          '返回服务导航',
                          'Back to Services',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final label in [
                        localizedText(
                          widget.languageCode,
                          'Markdown 正文',
                          'Markdown lessons',
                          'Markdown 正文',
                        ),
                        localizedText(
                          widget.languageCode,
                          '代码块',
                          'Code fences',
                          '程式碼塊',
                        ),
                        localizedText(
                          widget.languageCode,
                          '表格',
                          'Tables',
                          '表格',
                        ),
                        localizedText(
                          widget.languageCode,
                          'Mermaid 思维导图',
                          'Mermaid mind maps',
                          'Mermaid 思維導圖',
                        ),
                      ])
                        _LearningFeatureChip(label: label),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: Column(children: cards)),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 6,
                    child: _LearningDetailCard(
                      course: activeCourse,
                      languageCode: widget.languageCode,
                      markdownContent: _resolvedCourseMarkdown(activeCourse),
                      loading: _markdownLoading,
                      statusText: _markdownError,
                      onRunGoSnippet: _runCodeSnippet,
                    ),
                  ),
                ],
              )
            else ...[
              ...cards,
              const SizedBox(height: 18),
              _LearningDetailCard(
                course: activeCourse,
                languageCode: widget.languageCode,
                markdownContent: _resolvedCourseMarkdown(activeCourse),
                loading: _markdownLoading,
                statusText: _markdownError,
                onRunGoSnippet: _runCodeSnippet,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LearningFeatureChip extends StatelessWidget {
  const _LearningFeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LearningCourseCard extends StatelessWidget {
  const _LearningCourseCard({
    required this.course,
    required this.languageCode,
    required this.active,
    required this.onTap,
  });

  final _LearningCourse course;
  final String languageCode;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: course.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? theme.colorScheme.primary.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Text(
                      course.icon,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    course.metaText(languageCode),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                course.titleText(languageCode),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.subtitleText(languageCode),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in course.tags(languageCode))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
}

class _LearningDetailCard extends StatelessWidget {
  const _LearningDetailCard({
    required this.course,
    required this.languageCode,
    required this.markdownContent,
    required this.loading,
    required this.statusText,
    required this.onRunGoSnippet,
  });

  final _LearningCourse course;
  final String languageCode;
  final String markdownContent;
  final bool loading;
  final String? statusText;
  final CodeSnippetRunner onRunGoSnippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedText(languageCode, '当前课程', 'Current Lesson', '目前課程'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            course.titleText(languageCode),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.subtitleText(languageCode),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in course.tags(languageCode))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (loading || (statusText ?? '').isNotEmpty) ...[
            Text(
              loading ? 'Loading course markdown...' : (statusText ?? ''),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
          ],
          PostMarkdownBody(
            content: markdownContent,
            codeSnippetRunner: onRunGoSnippet,
            runCodeLabel: localizedText(
              languageCode,
              '运行代码',
              'Run code',
              '執行程式碼',
            ),
            runningGoLabel: localizedText(
              languageCode,
              '运行中...',
              'Running...',
              '執行中...',
            ),
            outputLabel: localizedText(languageCode, '输出结果', 'Output', '輸出結果'),
            stderrLabel: localizedText(languageCode, '错误输出', 'stderr', '錯誤輸出'),
            requestErrorLabel: localizedText(
              languageCode,
              '请求错误',
              'Request error',
              '請求錯誤',
            ),
            noStdoutLabel: localizedText(
              languageCode,
              '本次运行没有标准输出。',
              'This run produced no stdout output.',
              '本次執行沒有標準輸出。',
            ),
            codeCopiedLabel: localizedText(
              languageCode,
              '代码已复制到剪贴板。',
              'Code copied to clipboard.',
              '程式碼已複製到剪貼簿。',
            ),
            copyFailedLabel: localizedText(
              languageCode,
              '复制失败，请手动复制。',
              'Copy failed. Please copy it manually.',
              '複製失敗，請手動複製。',
            ),
            copyCodeLabel: localizedText(
              languageCode,
              '复制代码',
              'Copy code',
              '複製程式碼',
            ),
            resetOutputLabel: localizedText(
              languageCode,
              '重置输出',
              'Reset output',
              '重設輸出',
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningCourse {
  const _LearningCourse({
    required this.id,
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.tagMap,
    required this.markdown,
  });

  final String id;
  final String icon;
  final List<Color> colors;
  final Map<String, String> title;
  final Map<String, String> subtitle;
  final Map<String, String> meta;
  final Map<String, List<String>> tagMap;
  final Map<String, String> markdown;

  String titleText(String languageCode) =>
      title[languageCode] ?? title['zh-CN'] ?? '';

  String subtitleText(String languageCode) =>
      subtitle[languageCode] ?? subtitle['zh-CN'] ?? '';

  String metaText(String languageCode) =>
      meta[languageCode] ?? meta['zh-CN'] ?? '';

  List<String> tags(String languageCode) =>
      tagMap[languageCode] ?? tagMap['zh-CN'] ?? const [];

  String markdownText(String languageCode) =>
      markdown[languageCode] ?? markdown['zh-CN'] ?? '';
}

const learningCourseCatalog = <_LearningCourse>[
  _LearningCourse(
    id: 'english-storytelling',
    icon: 'EN',
    colors: [Color(0xFF1D3144), Color(0xFF101925)],
    title: {
      'zh-CN': '英语表达：故事化开口',
      'en-US': 'English Speaking: Story-First Flow',
      'zh-TW': '英語表達：故事化開口',
    },
    subtitle: {
      'zh-CN': '用可复述的表达模板训练英文介绍、观点和复盘。',
      'en-US':
          'Train intros, opinions, and recaps with reusable speaking templates.',
      'zh-TW': '用可複述的表達模板訓練英文介紹、觀點與復盤。',
    },
    meta: {
      'zh-CN': '6 节课 · 初中级',
      'en-US': '6 lessons · Beginner to Intermediate',
      'zh-TW': '6 堂課 · 初中階',
    },
    tagMap: {
      'zh-CN': ['开口', '复述', '表达'],
      'en-US': ['Speaking', 'Retelling', 'Framing'],
      'zh-TW': ['開口', '複述', '表達'],
    },
    markdown: {
      'zh-CN': '''# 英语表达：故事化开口

> 目标：把“我知道单词，但说不出来”拆成可练习的步骤。

## 学习路径

- 用 **场景句** 打开话题
- 用 **原因句** 补充观点
- 用 **结果句** 做收尾
- 用 `3-sentence loop` 反复训练

## 表达模板

| 场景 | 起手句 | 延展句 |
| --- | --- | --- |
| 自我介绍 | I usually work on... | The part I enjoy most is... |
| 复盘经历 | One thing I learned is... | Next time I would... |
| 观点表达 | I tend to think... | The main reason is... |

## 练习代码块

```text
Topic: Describe a skill you are learning.
1. Start with the situation.
2. Explain why it matters.
3. End with one next action.
```

---

## 思维导图

```mermaid
mindmap
  root((English speaking))
    Opening
      Scene sentence
      Role sentence
    Opinion
      Main idea
      One example
    Closing
      Next action
      Reflection
```

## 今日任务

- [x] 跟读 3 轮模板句
- [ ] 用自己的项目经历替换关键词
- [ ] 录一段 30 秒复述音频''',
      'en-US': '''# English Speaking: Story-First Flow

> Goal: turn "I know the words, but I cannot speak" into repeatable drills.

## Learning path

- Start with a **scene sentence**
- Add your view with a **reason sentence**
- Close with an **outcome sentence**
- Repeat everything with a `3-sentence loop`

## Speaking template

| Scenario | Opening | Expansion |
| --- | --- | --- |
| Intro | I usually work on... | The part I enjoy most is... |
| Reflection | One thing I learned is... | Next time I would... |
| Opinion | I tend to think... | The main reason is... |

## Drill prompt

```text
Topic: Describe a skill you are learning.
1. Start with the situation.
2. Explain why it matters.
3. End with one next action.
```

---

## Mind map

```mermaid
mindmap
  root((English speaking))
    Opening
      Scene sentence
      Role sentence
    Opinion
      Main idea
      One example
    Closing
      Next action
      Reflection
```

## Today

- [x] Shadow the template for 3 rounds
- [ ] Replace the keywords with your own project story
- [ ] Record one 30-second recap''',
      'zh-TW': '''# 英語表達：故事化開口

> 目標：把「我知道單字，但說不出來」拆成可練習的步驟。

## 學習路徑

- 用 **場景句** 打開話題
- 用 **原因句** 補充觀點
- 用 **結果句** 做收尾
- 用 `3-sentence loop` 反覆訓練

## 表達模板

| 場景 | 起手句 | 延展句 |
| --- | --- | --- |
| 自我介紹 | I usually work on... | The part I enjoy most is... |
| 復盤經歷 | One thing I learned is... | Next time I would... |
| 觀點表達 | I tend to think... | The main reason is... |

## 練習代碼塊

```text
Topic: Describe a skill you are learning.
1. Start with the situation.
2. Explain why it matters.
3. End with one next action.
```

---

## 思維導圖

```mermaid
mindmap
  root((English speaking))
    Opening
      Scene sentence
      Role sentence
    Opinion
      Main idea
      One example
    Closing
      Next action
      Reflection
```

## 今日任務

- [x] 跟讀 3 輪模板句
- [ ] 用自己的專案經歷替換關鍵詞
- [ ] 錄一段 30 秒複述音訊''',
    },
  ),
  _LearningCourse(
    id: 'programming-systems',
    icon: 'DEV',
    colors: [Color(0xFF3C261A), Color(0xFF141015)],
    title: {
      'zh-CN': '编程实战：把需求拆成系统',
      'en-US': 'Programming: Turning Features into Systems',
      'zh-TW': '程式實戰：把需求拆成系統',
    },
    subtitle: {
      'zh-CN': '从界面、状态、接口到验证，练习完整开发链路。',
      'en-US':
          'Practice the full build loop from UI and state to APIs and verification.',
      'zh-TW': '從介面、狀態、介面到驗證，練習完整開發鏈路。',
    },
    meta: {
      'zh-CN': '8 节课 · 进阶',
      'en-US': '8 lessons · Intermediate',
      'zh-TW': '8 堂課 · 進階',
    },
    tagMap: {
      'zh-CN': ['架构', '状态', '验证'],
      'en-US': ['Architecture', 'State', 'Verification'],
      'zh-TW': ['架構', '狀態', '驗證'],
    },
    markdown: {
      'zh-CN': '''# 编程实战：把需求拆成系统

## 四段式拆解

1. 先定义用户界面和关键路径
2. 再定义状态与数据结构
3. 再定义接口与错误处理
4. 最后补构建、测试和回归验证

> 你写的不是“页面”，而是一套可维护的行为系统。

## 最小实现清单

- 页面入口
- 路由状态
- 课程数据模型
- Markdown 渲染器
- 图表渲染兜底

## 示例代码

```javascript
function openLearningCourse(courseId) {
  const selected = courses.find((course) => course.id === courseId);
  if (!selected) {
    throw new Error('course not found');
  }
  return {
    ...selected,
    openedAt: new Date().toISOString(),
  };
}
```

## 设计表

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| 服务卡片 | 服务状态 | 导航入口 |
| 课程列表 | 分类筛选 | 当前课程 |
| Markdown 渲染器 | 原始正文 | 安全 HTML / Widget |
| Mermaid 渲染器 | `mermaid` 代码块 | SVG / 源码兜底 |

## 系统图

```mermaid
flowchart LR
  A[Service card] --> B[Course list]
  B --> C[Markdown renderer]
  C --> D[Code block]
  C --> E[Mermaid block]
  E --> F[Diagram output]
```''',
      'en-US': '''# Programming: Turning Features into Systems

## Four-step breakdown

1. Define the UI and the key user path
2. Define state and data structures
3. Define APIs and error handling
4. Finish with build, tests, and regression checks

> You are not shipping a page. You are shipping a maintainable behavior system.

## Minimum implementation list

- Page entry
- Route state
- Course data model
- Markdown renderer
- Diagram fallback

## Example code

```javascript
function openLearningCourse(courseId) {
  const selected = courses.find((course) => course.id === courseId);
  if (!selected) {
    throw new Error('course not found');
  }
  return {
    ...selected,
    openedAt: new Date().toISOString(),
  };
}
```

## Design table

| Module | Input | Output |
| --- | --- | --- |
| Service card | Service health | Navigation entry |
| Course list | Category filter | Active course |
| Markdown renderer | Raw body | Safe HTML / Widget |
| Mermaid renderer | `mermaid` fence | SVG / source fallback |

## System map

```mermaid
flowchart LR
  A[Service card] --> B[Course list]
  B --> C[Markdown renderer]
  C --> D[Code block]
  C --> E[Mermaid block]
  E --> F[Diagram output]
```''',
      'zh-TW': '''# 程式實戰：把需求拆成系統

## 四段式拆解

1. 先定義使用者介面和關鍵路徑
2. 再定義狀態與資料結構
3. 再定義介面與錯誤處理
4. 最後補建置、測試與回歸驗證

> 你寫的不是「頁面」，而是一套可維護的行為系統。

## 最小實作清單

- 頁面入口
- 路由狀態
- 課程資料模型
- Markdown 渲染器
- 圖表渲染兜底

## 範例程式碼

```javascript
function openLearningCourse(courseId) {
  const selected = courses.find((course) => course.id === courseId);
  if (!selected) {
    throw new Error('course not found');
  }
  return {
    ...selected,
    openedAt: new Date().toISOString(),
  };
}
```

## 設計表

| 模組 | 輸入 | 輸出 |
| --- | --- | --- |
| 服務卡片 | 服務狀態 | 導航入口 |
| 課程列表 | 分類篩選 | 目前課程 |
| Markdown 渲染器 | 原始正文 | 安全 HTML / Widget |
| Mermaid 渲染器 | `mermaid` 程式碼塊 | SVG / 原始碼兜底 |

## 系統圖

```mermaid
flowchart LR
  A[Service card] --> B[Course list]
  B --> C[Markdown renderer]
  C --> D[Code block]
  C --> E[Mermaid block]
  E --> F[Diagram output]
```''',
    },
  ),
  _LearningCourse(
    id: 'ai-workflows',
    icon: 'AI',
    colors: [Color(0xFF123246), Color(0xFF0E1520)],
    title: {
      'zh-CN': 'AI 工作流：从提示词到交付',
      'en-US': 'AI Workflows: From Prompt to Delivery',
      'zh-TW': 'AI 工作流：從提示詞到交付',
    },
    subtitle: {
      'zh-CN': '把模型调用、上下文管理和人工校验串成可靠流程。',
      'en-US':
          'Connect model calls, context management, and review into a reliable loop.',
      'zh-TW': '把模型呼叫、上下文管理與人工校驗串成可靠流程。',
    },
    meta: {
      'zh-CN': '7 节课 · 中高级',
      'en-US': '7 lessons · Intermediate to Advanced',
      'zh-TW': '7 堂課 · 中高階',
    },
    tagMap: {
      'zh-CN': ['提示词', '上下文', '校验'],
      'en-US': ['Prompting', 'Context', 'Verification'],
      'zh-TW': ['提示詞', '上下文', '校驗'],
    },
    markdown: {
      'zh-CN': '''# AI 工作流：从提示词到交付

## 核心原则

- 给模型清晰的角色、目标和输出格式
- 把不稳定信息放进显式上下文
- 让验证步骤和生成步骤分离

## 输出格式示例

```json
{
  "goal": "summarize code changes",
  "constraints": [
    "keep it concise",
    "cite modified files",
    "state verification status"
  ]
}
```

## 质量检查

| 检查项 | 说明 |
| --- | --- |
| 来源是否明确 | 输入上下文是否可追溯 |
| 结构是否稳定 | 输出字段是否固定 |
| 结果是否可验证 | 是否有测试、日志或页面回看 |

## 代理流程图

```mermaid
mindmap
  root((AI workflow))
    Prompt
      Role
      Goal
      Constraints
    Context
      Files
      Docs
      State
    Verification
      Tests
      Review
      Final answer
```

---

## 结论

> 好的 AI 页面不是“能生成内容”，而是“能稳定交付结果”。''',
      'en-US': '''# AI Workflows: From Prompt to Delivery

## Core rules

- Give the model a clear role, goal, and output shape
- Move unstable facts into explicit context
- Separate verification from generation

## Output schema example

```json
{
  "goal": "summarize code changes",
  "constraints": [
    "keep it concise",
    "cite modified files",
    "state verification status"
  ]
}
```

## Quality checks

| Check | Meaning |
| --- | --- |
| Source clarity | Can the input context be traced? |
| Structure stability | Are the output fields fixed? |
| Verifiability | Is there a test, log, or page review? |

## Agent workflow map

```mermaid
mindmap
  root((AI workflow))
    Prompt
      Role
      Goal
      Constraints
    Context
      Files
      Docs
      State
    Verification
      Tests
      Review
      Final answer
```

---

## Conclusion

> A good AI page is not "able to generate". It is "able to deliver reliably."''',
      'zh-TW': '''# AI 工作流：從提示詞到交付

## 核心原則

- 給模型清晰的角色、目標與輸出格式
- 把不穩定資訊放進顯式上下文
- 讓驗證步驟與生成步驟分離

## 輸出格式範例

```json
{
  "goal": "summarize code changes",
  "constraints": [
    "keep it concise",
    "cite modified files",
    "state verification status"
  ]
}
```

## 品質檢查

| 檢查項 | 說明 |
| --- | --- |
| 來源是否明確 | 輸入上下文是否可追溯 |
| 結構是否穩定 | 輸出欄位是否固定 |
| 結果是否可驗證 | 是否有測試、日誌或頁面回看 |

## 代理流程圖

```mermaid
mindmap
  root((AI workflow))
    Prompt
      Role
      Goal
      Constraints
    Context
      Files
      Docs
      State
    Verification
      Tests
      Review
      Final answer
```

---

## 結論

> 好的 AI 頁面不是「能生成內容」，而是「能穩定交付結果」。''',
    },
  ),
];
