import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/app_models.dart';
import '../widgets/bilingual_action_button.dart';
import '../widgets/post_markdown.dart';
import 'view_state_helpers.dart';

const defaultLearningCourseId = 'english-storytelling';
const List<String> learningCourseLocaleOptions = <String>[
  'zh-CN',
  'en-US',
  'zh-TW',
];

Widget buildLearningView({
  required String languageCode,
  required String activeCourseId,
  required bool isAdmin,
  bool adminWorkspaceOnly = false,
  required ApiClient apiClient,
  required ValueChanged<String> onSelectCourse,
  required VoidCallback onBackToServices,
}) {
  return LearningView(
    languageCode: languageCode,
    activeCourseId: activeCourseId,
    isAdmin: isAdmin,
    adminWorkspaceOnly: adminWorkspaceOnly,
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
    required this.isAdmin,
    required this.adminWorkspaceOnly,
    required this.apiClient,
    required this.onSelectCourse,
    required this.onBackToServices,
  });

  final String languageCode;
  final String activeCourseId;
  final bool isAdmin;
  final bool adminWorkspaceOnly;
  final ApiClient apiClient;
  final ValueChanged<String> onSelectCourse;
  final VoidCallback onBackToServices;

  @override
  State<LearningView> createState() => _LearningViewState();
}

class _LearningViewState extends State<LearningView> {
  final Map<String, MarkdownFileDocument> _markdownCache = {};
  final TextEditingController _markdownEditorController =
      TextEditingController();
  List<MarkdownFileSummary> _catalogItems = const [];
  List<_LearningCourse> _backendCourseCatalog = const [];
  bool _catalogLoading = false;
  String? _catalogError;
  bool _markdownLoading = false;
  String? _markdownError;
  bool _adminConsoleMode = false;
  bool _editorMode = false;
  bool _markdownSaving = false;
  String _adminOverviewFilter = 'all';
  String? _saveStatus;
  String _editorBaseline = '';
  int _loadVersion = 0;
  int _catalogLoadVersion = 0;

  @override
  void initState() {
    super.initState();
    _adminConsoleMode = widget.adminWorkspaceOnly;
    _markdownEditorController.addListener(_handleMarkdownEditorChanged);
    _loadCourseCatalog();
    _loadActiveCourseMarkdown();
  }

  @override
  void dispose() {
    _markdownEditorController.removeListener(_handleMarkdownEditorChanged);
    _markdownEditorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LearningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeCourseId != widget.activeCourseId ||
        oldWidget.languageCode != widget.languageCode) {
      _editorMode = false;
      _adminConsoleMode = widget.adminWorkspaceOnly;
      _saveStatus = null;
      _syncEditorWithActiveCourse(force: true);
      _loadActiveCourseMarkdown();
    }
    if (oldWidget.adminWorkspaceOnly != widget.adminWorkspaceOnly &&
        widget.adminWorkspaceOnly) {
      _adminConsoleMode = true;
    }
  }

  List<_LearningCourse> get _courseCatalog {
    final merged = <String, _LearningCourse>{};
    for (final course in learningCourseCatalog) {
      merged[course.id] = course;
    }
    for (final course in _backendCourseCatalog) {
      merged[course.id] = course;
    }
    return merged.values.toList();
  }

  _LearningCourse get _activeCourse => _courseCatalog.firstWhere(
    (course) => course.id == widget.activeCourseId,
    orElse: () => _courseCatalog.isNotEmpty
        ? _courseCatalog.first
        : learningCourseCatalog.first,
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

  String get _activeCourseMarkdownPath =>
      _courseMarkdownPath(_activeCourse, widget.languageCode);

  bool get _hasUnsavedEditorChanges =>
      _markdownEditorController.text != _editorBaseline;

  List<MarkdownFileSummary> get _activeCourseFiles {
    final prefix = 'courses/${_activeCourse.id}.';
    return _catalogItems.where((item) => item.path.startsWith(prefix)).toList()
      ..sort((left, right) => left.path.compareTo(right.path));
  }

  List<_LearningAdminCourseSummary> get _adminCourseSummaries {
    final summariesByCourseId = <String, _LearningAdminCourseSummaryBuilder>{};
    for (final course in _courseCatalog) {
      summariesByCourseId[course.id] = _LearningAdminCourseSummaryBuilder(
        courseId: course.id,
        title: course.titleText(widget.languageCode),
      );
    }
    for (final item in _catalogItems) {
      final descriptor = _parseLearningCourseFilePath(item.path);
      if (descriptor == null) {
        continue;
      }
      final builder = summariesByCourseId.putIfAbsent(
        descriptor.courseId,
        () => _LearningAdminCourseSummaryBuilder(
          courseId: descriptor.courseId,
          title: descriptor.courseId,
        ),
      );
      builder.totalFiles += 1;
      switch (item.status.trim().toLowerCase()) {
        case 'draft':
          builder.draftFiles += 1;
          break;
        case 'archived':
          builder.archivedFiles += 1;
          break;
        default:
          builder.publishedFiles += 1;
          break;
      }
    }
    final summaries = summariesByCourseId.values
        .map((builder) => builder.build())
        .toList();
    summaries.sort((left, right) {
      if (left.adminPriority != right.adminPriority) {
        return left.adminPriority.compareTo(right.adminPriority);
      }
      if (left.draftFiles != right.draftFiles) {
        return right.draftFiles.compareTo(left.draftFiles);
      }
      if (left.totalFiles != right.totalFiles) {
        return right.totalFiles.compareTo(left.totalFiles);
      }
      return left.courseId.compareTo(right.courseId);
    });
    return summaries;
  }

  List<_LearningAdminCourseSummary> get _filteredAdminCourseSummaries {
    switch (_adminOverviewFilter) {
      case 'pending':
        return _adminCourseSummaries
            .where((summary) => summary.hasDrafts)
            .toList();
      case 'draft':
        return _adminCourseSummaries
            .where((summary) => summary.draftFiles > 0)
            .toList();
      case 'published':
        return _adminCourseSummaries
            .where((summary) => summary.publishedFiles > 0)
            .toList();
      case 'archived':
        return _adminCourseSummaries
            .where((summary) => summary.archivedFiles > 0)
            .toList();
      default:
        return _adminCourseSummaries;
    }
  }

  String? get _nextPendingCourseId {
    for (final summary in _adminCourseSummaries) {
      if (summary.hasDrafts) {
        return summary.courseId;
      }
    }
    return null;
  }

  void _handleMarkdownEditorChanged() {
    // Rebuild editor actions when the draft changes so save/reset availability stays current.
    // 当草稿发生变化时重建编辑器操作区，保持保存/重置按钮状态及时更新。
    if (!mounted) {
      return;
    }
    setState(() {});
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
    _syncEditorWithActiveCourse();
  }

  Future<void> _loadCourseCatalog() async {
    // Discover backend lesson files so the learning page can surface new courses without a frontend release.
    // 发现后端课程文件，让学习页无需等待前端发版也能展示新课程。
    final currentVersion = ++_catalogLoadVersion;
    if (mounted) {
      setState(() {
        _catalogLoading = true;
        _catalogError = null;
      });
    }
    try {
      final items = await widget.apiClient.listLearningMarkdownFiles();
      final backendCourses = _buildBackendCourseCatalog(items);
      if (!mounted || currentVersion != _catalogLoadVersion) {
        return;
      }
      setState(() {
        _catalogItems = items;
        _backendCourseCatalog = backendCourses;
        _catalogLoading = false;
        _catalogError = null;
      });
      await _loadActiveCourseMarkdown();
    } catch (_) {
      if (!mounted || currentVersion != _catalogLoadVersion) {
        return;
      }
      setState(() {
        _catalogLoading = false;
        _catalogError = localizedText(
          widget.languageCode,
          '后端课程索引暂不可用，当前继续显示内建课程目录。',
          'The backend lesson index is unavailable, so the built-in catalog is still shown.',
          '後端課程索引暫不可用，目前繼續顯示內建課程目錄。',
        );
      });
    }
  }

  void _syncEditorWithActiveCourse({bool force = false}) {
    // Keep the markdown editor aligned with the active course unless the user is mid-edit.
    // 让 Markdown 编辑器与当前课程保持一致，但避免覆盖用户正在编辑的内容。
    if (!force && _editorMode && _hasUnsavedEditorChanges) {
      return;
    }
    final nextContent = _resolvedCourseMarkdown(_activeCourse);
    _markdownEditorController.value = TextEditingValue(
      text: nextContent,
      selection: TextSelection.collapsed(offset: nextContent.length),
    );
    _editorBaseline = nextContent;
  }

  void _toggleEditorMode() {
    // Switch between lesson preview and source editing while preserving unsaved text.
    // 在课程预览和源码编辑之间切换，同时保留未保存的草稿。
    setState(() {
      if (!_editorMode) {
        _syncEditorWithActiveCourse(force: true);
      }
      _editorMode = !_editorMode;
      _saveStatus = null;
    });
  }

  void _toggleAdminConsoleMode() {
    // Switch between the learner-facing preview and the administrator console workspace.
    // 在学习者预览模式与管理员后台工作区之间切换。
    if (widget.adminWorkspaceOnly) {
      return;
    }
    setState(() {
      _adminConsoleMode = !_adminConsoleMode;
      if (!_adminConsoleMode) {
        _editorMode = false;
      } else {
        _syncEditorWithActiveCourse(force: true);
      }
      _saveStatus = null;
    });
  }

  void _resetMarkdownDraft() {
    // Reset the editor back to the latest loaded markdown snapshot for the active course.
    // 将编辑器重置为当前课程最近一次加载到的 Markdown 快照。
    final nextContent = _resolvedCourseMarkdown(_activeCourse);
    setState(() {
      _markdownEditorController.value = TextEditingValue(
        text: nextContent,
        selection: TextSelection.collapsed(offset: nextContent.length),
      );
      _editorBaseline = nextContent;
      _saveStatus = localizedText(
        widget.languageCode,
        '已重置为当前已加载内容。',
        'Reset to the currently loaded lesson content.',
        '已重設為目前已載入內容。',
      );
    });
  }

  Future<void> _reloadActiveCourseMarkdown() async {
    // Drop the cached active locale file so the next load re-reads it from the backend.
    // 丢弃当前语言课程缓存，让下一次加载重新从后端读取。
    final activePath = _activeCourseMarkdownPath;
    final fallbackPath = _courseMarkdownPath(_activeCourse, 'zh-CN');
    setState(() {
      _markdownCache.remove(activePath);
      if (fallbackPath != activePath) {
        _markdownCache.remove(fallbackPath);
      }
      _saveStatus = null;
    });
    await _loadActiveCourseMarkdown();
  }

  Future<void> _saveActiveCourseMarkdown() async {
    // Save the active lesson markdown through learning-service and refresh the local preview cache.
    // 通过 learning-service 保存当前课程 Markdown，并刷新本地预览缓存。
    final relativePath = _activeCourseMarkdownPath;
    final nextContent = _markdownEditorController.text;
    setState(() {
      _markdownSaving = true;
      _saveStatus = null;
    });
    try {
      final document = await widget.apiClient.saveLearningMarkdownFile(
        relativePath,
        nextContent,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _markdownCache[relativePath] = document;
        _editorBaseline = document.content;
        _markdownEditorController.value = TextEditingValue(
          text: document.content,
          selection: TextSelection.collapsed(offset: document.content.length),
        );
        _markdownSaving = false;
        _markdownError = null;
        _saveStatus = localizedText(
          widget.languageCode,
          '课程内容已保存到 learning-service。',
          'Lesson content saved to learning-service.',
          '課程內容已儲存到 learning-service。',
        );
      });
      await _loadCourseCatalog();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _markdownSaving = false;
        _saveStatus = error is ApiException ? error.message : error.toString();
      });
    }
  }

  String _normalizeCourseIdInput(String value) {
    // Normalize one course id input into a safe slug that matches backend path rules.
    // 将课程 ID 输入规范化为匹配后端路径规则的安全 slug。
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _showCreateLessonDialog() async {
    // Create one new backend lesson file from the learning page so users can start a course without manual filesystem edits.
    // 在学习页内创建新的后端课程文件，避免用户还要手动改文件系统。
    final idController = TextEditingController();
    final contentController = TextEditingController(
      text: '# New Lesson\n\nWrite your course content here.',
    );
    var locale = widget.languageCode;
    if (!learningCourseLocaleOptions.contains(locale)) {
      locale = 'zh-CN';
    }
    var inlineError = '';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              title: Text(
                localizedText(
                  widget.languageCode,
                  '新建课程文件',
                  'Create lesson file',
                  '新建課程檔案',
                ),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: idController,
                        decoration: InputDecoration(
                          labelText: localizedText(
                            widget.languageCode,
                            '课程 ID',
                            'Course ID',
                            '課程 ID',
                          ),
                          hintText: 'my-new-course',
                          helperText: localizedText(
                            widget.languageCode,
                            '仅支持小写字母、数字、-、_。',
                            'Use lowercase letters, numbers, hyphens, and underscores.',
                            '僅支援小寫字母、數字、-、_。',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: locale,
                        items: learningCourseLocaleOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() => locale = value);
                        },
                        decoration: InputDecoration(
                          labelText: localizedText(
                            widget.languageCode,
                            '语言版本',
                            'Locale',
                            '語言版本',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        minLines: 12,
                        maxLines: 18,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText: localizedText(
                            widget.languageCode,
                            'Markdown 内容',
                            'Markdown content',
                            'Markdown 內容',
                          ),
                        ),
                      ),
                      if (inlineError.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          inlineError,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    localizedText(widget.languageCode, '取消', 'Cancel', '取消'),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final normalizedCourseId = _normalizeCourseIdInput(
                      idController.text,
                    );
                    if (normalizedCourseId.isEmpty) {
                      setDialogState(() {
                        inlineError = localizedText(
                          widget.languageCode,
                          '请先填写有效的课程 ID。',
                          'Enter a valid course ID first.',
                          '請先填寫有效的課程 ID。',
                        );
                      });
                      return;
                    }
                    final relativePath =
                        'courses/$normalizedCourseId.$locale.md';
                    try {
                      await widget.apiClient.saveLearningMarkdownFile(
                        relativePath,
                        contentController.text,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop(true);
                      setState(() {
                        _markdownCache[relativePath] = MarkdownFileDocument(
                          path: relativePath,
                          content: contentController.text,
                          size: contentController.text.length,
                          updatedAt: DateTime.now(),
                          status: 'draft',
                        );
                        _saveStatus = localizedText(
                          widget.languageCode,
                          '新课程文件已创建为草稿并保存。',
                          'The new lesson file was created as a draft and saved.',
                          '新課程檔案已建立為草稿並儲存。',
                        );
                      });
                      await _loadCourseCatalog();
                      widget.onSelectCourse(normalizedCourseId);
                    } catch (error) {
                      setDialogState(() {
                        inlineError = error is ApiException
                            ? error.message
                            : error.toString();
                      });
                    }
                  },
                  child: Text(
                    localizedText(widget.languageCode, '创建', 'Create', '建立'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    idController.dispose();
    contentController.dispose();
    if (created == true && mounted) {
      setState(() {
        _editorMode = false;
      });
    }
  }

  Future<void> _deleteLessonFile(String relativePath) async {
    // Delete one lesson file so administrators can take a specific locale variant offline quickly.
    // 删除单个课程文件，让管理员可以快速下架指定语言版本。
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            localizedText(
              widget.languageCode,
              '删除课程文件',
              'Delete lesson file',
              '刪除課程檔案',
            ),
          ),
          content: Text(
            localizedText(
              widget.languageCode,
              '确认删除当前语言版本的课程文件吗？此操作会立即让该文件从管理员后台与课程目录中移除。',
              'Delete the current locale lesson file? This removes it from the admin console and lesson catalog immediately.',
              '確認刪除目前語言版本的課程檔案嗎？此操作會立即讓該檔案從管理員後台與課程目錄中移除。',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                localizedText(widget.languageCode, '取消', 'Cancel', '取消'),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                localizedText(widget.languageCode, '删除', 'Delete', '刪除'),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _markdownSaving = true;
      _saveStatus = null;
    });
    try {
      await widget.apiClient.deleteLearningMarkdownFile(relativePath);
      if (!mounted) {
        return;
      }
      setState(() {
        _markdownCache.remove(relativePath);
        _markdownSaving = false;
        _editorMode = false;
        _saveStatus = localizedText(
          widget.languageCode,
          '课程文件已删除。',
          'The lesson file was deleted.',
          '課程檔案已刪除。',
        );
      });
      await _loadCourseCatalog();
      await _loadActiveCourseMarkdown();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _markdownSaving = false;
        _saveStatus = error is ApiException ? error.message : error.toString();
      });
    }
  }

  Future<void> _deleteActiveLessonFile() async {
    await _deleteLessonFile(_activeCourseMarkdownPath);
  }

  Future<void> _updateLessonFileStatus(
    String relativePath,
    String status,
  ) async {
    // Update one lesson file status so administrators can publish or archive a locale variant directly.
    // 更新单个课程文件状态，让管理员可以直接发布或归档指定语言版本。
    setState(() {
      _markdownSaving = true;
      _saveStatus = null;
    });
    try {
      await widget.apiClient.updateLearningMarkdownFileStatus(
        relativePath,
        status,
      );
      if (!mounted) {
        return;
      }
      final cachedDocument = _markdownCache[relativePath];
      setState(() {
        _markdownSaving = false;
        if (cachedDocument != null) {
          _markdownCache[relativePath] = MarkdownFileDocument(
            path: cachedDocument.path,
            content: cachedDocument.content,
            size: cachedDocument.size,
            updatedAt: cachedDocument.updatedAt,
            status: status,
          );
        }
        _saveStatus = localizedText(
          widget.languageCode,
          status == 'published' ? '课程文件已发布，学员端现可见。' : '课程文件已归档，学员端现已隐藏。',
          status == 'published'
              ? 'The lesson file is now published and visible to learners.'
              : 'The lesson file is now archived and hidden from learners.',
          status == 'published' ? '課程檔案已發布，學員端現在可見。' : '課程檔案已歸檔，學員端現在已隱藏。',
        );
      });
      await _loadCourseCatalog();
      if (relativePath == _activeCourseMarkdownPath) {
        await _loadActiveCourseMarkdown();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _markdownSaving = false;
        _saveStatus = error is ApiException ? error.message : error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCourse = _activeCourse;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final cards = <Widget>[
          for (final course in _courseCatalog)
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
                  if (_catalogLoading || (_catalogError ?? '').isNotEmpty) ...[
                    Text(
                      _catalogLoading
                          ? localizedText(
                              widget.languageCode,
                              '正在同步后端课程目录...',
                              'Syncing backend lesson catalog...',
                              '正在同步後端課程目錄...',
                            )
                          : (_catalogError ?? ''),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                      editorMode: _editorMode,
                      adminConsoleMode: _adminConsoleMode,
                      adminWorkspaceOnly: widget.adminWorkspaceOnly,
                      markdownSaving: _markdownSaving,
                      saveStatus: _saveStatus,
                      markdownEditorController: _markdownEditorController,
                      hasUnsavedChanges: _hasUnsavedEditorChanges,
                      isAdmin: widget.isAdmin,
                      onToggleAdminConsoleMode: _toggleAdminConsoleMode,
                      onToggleEditorMode: _toggleEditorMode,
                      onResetDraft: _resetMarkdownDraft,
                      onReloadMarkdown: _reloadActiveCourseMarkdown,
                      onSaveMarkdown: _saveActiveCourseMarkdown,
                      onCreateLesson: _showCreateLessonDialog,
                      onDeleteLesson: _deleteActiveLessonFile,
                      courseFiles: _activeCourseFiles,
                      courseSummaries: _filteredAdminCourseSummaries,
                      adminOverviewFilter: _adminOverviewFilter,
                      nextPendingCourseId: _nextPendingCourseId,
                      onDeleteSpecificLesson: _deleteLessonFile,
                      onUpdateLessonStatus: _updateLessonFileStatus,
                      onAdminOverviewFilterChanged: (value) {
                        setState(() => _adminOverviewFilter = value);
                      },
                      onOpenNextPendingCourse: () {
                        final nextPendingCourseId = _nextPendingCourseId;
                        if (nextPendingCourseId != null) {
                          widget.onSelectCourse(nextPendingCourseId);
                        }
                      },
                      onOpenCourse: widget.onSelectCourse,
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
                editorMode: _editorMode,
                adminConsoleMode: _adminConsoleMode,
                adminWorkspaceOnly: widget.adminWorkspaceOnly,
                markdownSaving: _markdownSaving,
                saveStatus: _saveStatus,
                markdownEditorController: _markdownEditorController,
                hasUnsavedChanges: _hasUnsavedEditorChanges,
                isAdmin: widget.isAdmin,
                onToggleAdminConsoleMode: _toggleAdminConsoleMode,
                onToggleEditorMode: _toggleEditorMode,
                onResetDraft: _resetMarkdownDraft,
                onReloadMarkdown: _reloadActiveCourseMarkdown,
                onSaveMarkdown: _saveActiveCourseMarkdown,
                onCreateLesson: _showCreateLessonDialog,
                onDeleteLesson: _deleteActiveLessonFile,
                courseFiles: _activeCourseFiles,
                courseSummaries: _filteredAdminCourseSummaries,
                adminOverviewFilter: _adminOverviewFilter,
                nextPendingCourseId: _nextPendingCourseId,
                onDeleteSpecificLesson: _deleteLessonFile,
                onUpdateLessonStatus: _updateLessonFileStatus,
                onAdminOverviewFilterChanged: (value) {
                  setState(() => _adminOverviewFilter = value);
                },
                onOpenNextPendingCourse: () {
                  final nextPendingCourseId = _nextPendingCourseId;
                  if (nextPendingCourseId != null) {
                    widget.onSelectCourse(nextPendingCourseId);
                  }
                },
                onOpenCourse: widget.onSelectCourse,
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
    required this.editorMode,
    required this.adminConsoleMode,
    required this.adminWorkspaceOnly,
    required this.markdownSaving,
    required this.saveStatus,
    required this.markdownEditorController,
    required this.hasUnsavedChanges,
    required this.isAdmin,
    required this.onToggleAdminConsoleMode,
    required this.onToggleEditorMode,
    required this.onResetDraft,
    required this.onReloadMarkdown,
    required this.onSaveMarkdown,
    required this.onCreateLesson,
    required this.onDeleteLesson,
    required this.courseFiles,
    required this.courseSummaries,
    required this.adminOverviewFilter,
    required this.nextPendingCourseId,
    required this.onDeleteSpecificLesson,
    required this.onUpdateLessonStatus,
    required this.onAdminOverviewFilterChanged,
    required this.onOpenNextPendingCourse,
    required this.onOpenCourse,
    required this.onRunGoSnippet,
  });

  final _LearningCourse course;
  final String languageCode;
  final String markdownContent;
  final bool loading;
  final String? statusText;
  final bool editorMode;
  final bool adminConsoleMode;
  final bool adminWorkspaceOnly;
  final bool markdownSaving;
  final String? saveStatus;
  final TextEditingController markdownEditorController;
  final bool hasUnsavedChanges;
  final bool isAdmin;
  final VoidCallback onToggleAdminConsoleMode;
  final VoidCallback onToggleEditorMode;
  final VoidCallback onResetDraft;
  final Future<void> Function() onReloadMarkdown;
  final Future<void> Function() onSaveMarkdown;
  final Future<void> Function() onCreateLesson;
  final Future<void> Function() onDeleteLesson;
  final List<MarkdownFileSummary> courseFiles;
  final List<_LearningAdminCourseSummary> courseSummaries;
  final String adminOverviewFilter;
  final String? nextPendingCourseId;
  final Future<void> Function(String path) onDeleteSpecificLesson;
  final Future<void> Function(String path, String status) onUpdateLessonStatus;
  final ValueChanged<String> onAdminOverviewFilterChanged;
  final VoidCallback onOpenNextPendingCourse;
  final ValueChanged<String> onOpenCourse;
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
            localizedText(
              languageCode,
              adminWorkspaceOnly ? '管理员课程后台' : '当前课程',
              adminWorkspaceOnly
                  ? 'Administrator Course Console'
                  : 'Current Lesson',
              adminWorkspaceOnly ? '管理員課程後台' : '目前課程',
            ),
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
            adminWorkspaceOnly
                ? localizedText(
                    languageCode,
                    '在这里维护课程文件、语言版本和上架状态。学员可见内容以发布状态为准。',
                    'Maintain lesson files, locale variants, and publishing states here. Learner visibility follows the published state.',
                    '在這裡維護課程檔案、語言版本與上架狀態。學員可見內容以發布狀態為準。',
                  )
                : course.subtitleText(languageCode),
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
          if (isAdmin) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!adminWorkspaceOnly)
                  BilingualActionButton(
                    variant: adminConsoleMode
                        ? BilingualButtonVariant.filled
                        : BilingualButtonVariant.tonal,
                    compact: true,
                    onPressed: onToggleAdminConsoleMode,
                    primaryLabel: localizedText(
                      languageCode,
                      adminConsoleMode ? '返回课程预览' : '管理员后台',
                      adminConsoleMode
                          ? 'Back to lesson preview'
                          : 'Admin console',
                      adminConsoleMode ? '返回課程預覽' : '管理員後台',
                    ),
                    secondaryLabel: '',
                  ),
                if (adminConsoleMode) ...[
                  BilingualActionButton(
                    variant: editorMode
                        ? BilingualButtonVariant.filled
                        : BilingualButtonVariant.tonal,
                    compact: true,
                    onPressed: onToggleEditorMode,
                    primaryLabel: localizedText(
                      languageCode,
                      editorMode ? '切换到预览' : '编辑 Markdown',
                      editorMode ? 'Back to preview' : 'Edit markdown',
                      editorMode ? '切換到預覽' : '編輯 Markdown',
                    ),
                    secondaryLabel: '',
                  ),
                  BilingualActionButton(
                    variant: BilingualButtonVariant.tonal,
                    compact: true,
                    onPressed: () => onCreateLesson(),
                    primaryLabel: localizedText(
                      languageCode,
                      '新建课程',
                      'New lesson',
                      '新建課程',
                    ),
                    secondaryLabel: '',
                  ),
                  BilingualActionButton(
                    variant: BilingualButtonVariant.outlined,
                    compact: true,
                    onPressed: loading ? null : () => onReloadMarkdown(),
                    primaryLabel: localizedText(
                      languageCode,
                      '重新加载',
                      'Reload',
                      '重新載入',
                    ),
                    secondaryLabel: '',
                  ),
                  BilingualActionButton(
                    variant: BilingualButtonVariant.outlined,
                    compact: true,
                    onPressed: markdownSaving ? null : () => onDeleteLesson(),
                    primaryLabel: localizedText(
                      languageCode,
                      '删除当前版本',
                      'Delete locale file',
                      '刪除目前版本',
                    ),
                    secondaryLabel: '',
                  ),
                  if (editorMode) ...[
                    BilingualActionButton(
                      variant: BilingualButtonVariant.outlined,
                      compact: true,
                      onPressed: markdownSaving ? null : onResetDraft,
                      primaryLabel: localizedText(
                        languageCode,
                        '重置草稿',
                        'Reset draft',
                        '重設草稿',
                      ),
                      secondaryLabel: '',
                    ),
                    BilingualActionButton(
                      variant: BilingualButtonVariant.filled,
                      compact: true,
                      onPressed: markdownSaving || !hasUnsavedChanges
                          ? null
                          : () => onSaveMarkdown(),
                      primaryLabel: localizedText(
                        languageCode,
                        markdownSaving ? '保存中...' : '保存到服务',
                        markdownSaving ? 'Saving...' : 'Save to service',
                        markdownSaving ? '儲存中...' : '儲存到服務',
                      ),
                      secondaryLabel: '',
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 14),
          ] else ...[
            Text(
              localizedText(
                languageCode,
                '课程上架与内容维护需管理员权限。',
                'Publishing and course maintenance require administrator access.',
                '課程上架與內容維護需管理員權限。',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if ((saveStatus ?? '').isNotEmpty) ...[
            Text(
              saveStatus ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (isAdmin && adminConsoleMode && courseFiles.isNotEmpty) ...[
            _LearningCourseFilesPanel(
              languageCode: languageCode,
              activePath: 'courses/${course.id}.$languageCode.md',
              files: courseFiles,
              onDeleteFile: onDeleteSpecificLesson,
              onUpdateStatus: onUpdateLessonStatus,
              saving: markdownSaving,
            ),
            const SizedBox(height: 18),
          ],
          if (loading || (statusText ?? '').isNotEmpty) ...[
            Text(
              loading ? 'Loading course markdown...' : (statusText ?? ''),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (adminConsoleMode && editorMode)
            _LearningMarkdownEditor(
              languageCode: languageCode,
              controller: markdownEditorController,
            )
          else if (adminConsoleMode)
            _LearningAdminConsoleSummary(
              languageCode: languageCode,
              courseFilesCount: courseFiles.length,
              hasUnsavedChanges: hasUnsavedChanges,
              draftCount: courseFiles
                  .where((item) => item.status == 'draft')
                  .length,
              publishedCount: courseFiles
                  .where((item) => item.status == 'published')
                  .length,
              archivedCount: courseFiles
                  .where((item) => item.status == 'archived')
                  .length,
              activeCourseId: course.id,
              courseSummaries: courseSummaries,
              adminOverviewFilter: adminOverviewFilter,
              nextPendingCourseId: nextPendingCourseId,
              onAdminOverviewFilterChanged: onAdminOverviewFilterChanged,
              onOpenNextPendingCourse: onOpenNextPendingCourse,
              onOpenCourse: onOpenCourse,
            )
          else
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
              outputLabel: localizedText(
                languageCode,
                '输出结果',
                'Output',
                '輸出結果',
              ),
              stderrLabel: localizedText(
                languageCode,
                '错误输出',
                'stderr',
                '錯誤輸出',
              ),
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

class _LearningMarkdownEditor extends StatelessWidget {
  const _LearningMarkdownEditor({
    required this.languageCode,
    required this.controller,
  });

  final String languageCode;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedText(
              languageCode,
              '在这里直接编辑课程 Markdown，保存后会写回 learning-service。',
              'Edit the lesson markdown here and save it back to learning-service.',
              '在這裡直接編輯課程 Markdown，儲存後會寫回 learning-service。',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 20,
            maxLines: 28,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: localizedText(
                languageCode,
                'Markdown 源码',
                'Markdown source',
                'Markdown 原始碼',
              ),
              hintText: localizedText(
                languageCode,
                '支持标题、表格、代码块和 Mermaid 语法。',
                'Supports headings, tables, code fences, and Mermaid syntax.',
                '支援標題、表格、程式碼塊與 Mermaid 語法。',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningCourseFilesPanel extends StatelessWidget {
  const _LearningCourseFilesPanel({
    required this.languageCode,
    required this.activePath,
    required this.files,
    required this.onDeleteFile,
    required this.onUpdateStatus,
    required this.saving,
  });

  final String languageCode;
  final String activePath;
  final List<MarkdownFileSummary> files;
  final Future<void> Function(String path) onDeleteFile;
  final Future<void> Function(String path, String status) onUpdateStatus;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.22,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedText(languageCode, '课程版本文件', 'Lesson files', '課程版本檔案'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizedText(
              languageCode,
              '管理员可直接查看当前课程已存在的语言版本文件，并逐个发布、归档或删除。',
              'Administrators can inspect every locale file for this lesson and publish, archive, or delete them one by one.',
              '管理員可直接查看目前課程已存在的語言版本檔案，並逐一發布、歸檔或刪除。',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in files)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.path,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatByteSize(item.size)} · ${item.updatedAt != null ? formatDateTime(item.updatedAt!) : '--'}${item.path == activePath ? ' · ${localizedText(languageCode, '当前界面版本', 'Active in this view', '目前介面版本')}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _LearningLessonStatusBadge(
                          languageCode: languageCode,
                          status: item.status,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      BilingualActionButton(
                        variant: BilingualButtonVariant.tonal,
                        compact: true,
                        onPressed: saving || item.status == 'published'
                            ? null
                            : () => onUpdateStatus(item.path, 'published'),
                        primaryLabel: localizedText(
                          languageCode,
                          '发布',
                          'Publish',
                          '發布',
                        ),
                        secondaryLabel: '',
                      ),
                      BilingualActionButton(
                        variant: BilingualButtonVariant.outlined,
                        compact: true,
                        onPressed: saving || item.status == 'archived'
                            ? null
                            : () => onUpdateStatus(item.path, 'archived'),
                        primaryLabel: localizedText(
                          languageCode,
                          '归档',
                          'Archive',
                          '歸檔',
                        ),
                        secondaryLabel: '',
                      ),
                      BilingualActionButton(
                        variant: BilingualButtonVariant.outlined,
                        compact: true,
                        onPressed: saving
                            ? null
                            : () => onDeleteFile(item.path),
                        primaryLabel: localizedText(
                          languageCode,
                          '删除',
                          'Delete',
                          '刪除',
                        ),
                        secondaryLabel: '',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LearningAdminConsoleSummary extends StatelessWidget {
  const _LearningAdminConsoleSummary({
    required this.languageCode,
    required this.courseFilesCount,
    required this.hasUnsavedChanges,
    required this.draftCount,
    required this.publishedCount,
    required this.archivedCount,
    required this.activeCourseId,
    required this.courseSummaries,
    required this.adminOverviewFilter,
    required this.nextPendingCourseId,
    required this.onAdminOverviewFilterChanged,
    required this.onOpenNextPendingCourse,
    required this.onOpenCourse,
  });

  final String languageCode;
  final int courseFilesCount;
  final bool hasUnsavedChanges;
  final int draftCount;
  final int publishedCount;
  final int archivedCount;
  final String activeCourseId;
  final List<_LearningAdminCourseSummary> courseSummaries;
  final String adminOverviewFilter;
  final String? nextPendingCourseId;
  final ValueChanged<String> onAdminOverviewFilterChanged;
  final VoidCallback onOpenNextPendingCourse;
  final ValueChanged<String> onOpenCourse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.22,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedText(
              languageCode,
              '管理员后台工作区',
              'Administrator workspace',
              '管理員後台工作區',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizedText(
              languageCode,
              '这里会集中放置课程创建、版本管理、上架与下架动作。当前版本已支持新建、编辑、发布、归档、删除和文件清单管理。',
              'This workspace centralizes lesson creation, version management, and publishing actions. The current build already supports create, edit, publish, archive, delete, and file-list management.',
              '這裡會集中放置課程建立、版本管理、上架與下架動作。目前版本已支援新建、編輯、發布、歸檔、刪除與檔案清單管理。',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (nextPendingCourseId != null) ...[
            BilingualActionButton(
              variant: BilingualButtonVariant.filled,
              compact: true,
              onPressed: onOpenNextPendingCourse,
              primaryLabel: localizedText(
                languageCode,
                '打开待处理课程',
                'Open next pending lesson',
                '打開待處理課程',
              ),
              secondaryLabel: '',
            ),
            const SizedBox(height: 12),
          ],
          Text(
            localizedText(
              languageCode,
              '当前课程文件数：$courseFilesCount；${hasUnsavedChanges ? '存在未保存草稿' : '当前无未保存草稿'}',
              'Current lesson file count: $courseFilesCount; ${hasUnsavedChanges ? 'unsaved draft present' : 'no unsaved draft'}',
              '目前課程檔案數：$courseFilesCount；${hasUnsavedChanges ? '存在未儲存草稿' : '目前沒有未儲存草稿'}',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LearningMetricChip(
                label: localizedText(
                  languageCode,
                  '草稿 $draftCount',
                  'Draft $draftCount',
                  '草稿 $draftCount',
                ),
              ),
              _LearningMetricChip(
                label: localizedText(
                  languageCode,
                  '已发布 $publishedCount',
                  'Published $publishedCount',
                  '已發布 $publishedCount',
                ),
              ),
              _LearningMetricChip(
                label: localizedText(
                  languageCode,
                  '已归档 $archivedCount',
                  'Archived $archivedCount',
                  '已歸檔 $archivedCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            localizedText(languageCode, '课程总览', 'Course overview', '課程總覽'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizedText(
              languageCode,
              '先看全局课程状态，再切到具体课程继续维护语言版本和上架动作。',
              'Scan global course status first, then jump into a specific lesson to manage locale variants and publishing.',
              '先看全域課程狀態，再切到具體課程繼續維護語言版本與上架動作。',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in const [
                ('all', '全部', 'All', '全部'),
                ('pending', '待处理', 'Pending', '待處理'),
                ('draft', '草稿', 'Draft', '草稿'),
                ('published', '已发布', 'Published', '已發布'),
                ('archived', '已归档', 'Archived', '已歸檔'),
              ])
                BilingualActionButton(
                  variant: adminOverviewFilter == filter.$1
                      ? BilingualButtonVariant.filled
                      : BilingualButtonVariant.tonal,
                  compact: true,
                  onPressed: () => onAdminOverviewFilterChanged(filter.$1),
                  primaryLabel: localizedText(
                    languageCode,
                    filter.$2,
                    filter.$3,
                    filter.$4,
                  ),
                  secondaryLabel: '',
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (courseSummaries.isEmpty)
            Text(
              localizedText(
                languageCode,
                '当前筛选条件下暂无课程。',
                'No lessons match the current filter.',
                '目前篩選條件下沒有課程。',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          for (final summary in courseSummaries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.colorScheme.surface,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.courseId,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (summary.needsInitialPublish)
                                _LearningMetricChip(
                                  label: localizedText(
                                    languageCode,
                                    '待上架',
                                    'Needs publish',
                                    '待上架',
                                  ),
                                ),
                              if (summary.needsUpdatePublish)
                                _LearningMetricChip(
                                  label: localizedText(
                                    languageCode,
                                    '待更新',
                                    'Needs update',
                                    '待更新',
                                  ),
                                ),
                              _LearningMetricChip(
                                label: localizedText(
                                  languageCode,
                                  '文件 ${summary.totalFiles}',
                                  'Files ${summary.totalFiles}',
                                  '檔案 ${summary.totalFiles}',
                                ),
                              ),
                              _LearningMetricChip(
                                label: localizedText(
                                  languageCode,
                                  '草稿 ${summary.draftFiles}',
                                  'Draft ${summary.draftFiles}',
                                  '草稿 ${summary.draftFiles}',
                                ),
                              ),
                              _LearningMetricChip(
                                label: localizedText(
                                  languageCode,
                                  '已发布 ${summary.publishedFiles}',
                                  'Published ${summary.publishedFiles}',
                                  '已發布 ${summary.publishedFiles}',
                                ),
                              ),
                              _LearningMetricChip(
                                label: localizedText(
                                  languageCode,
                                  '已归档 ${summary.archivedFiles}',
                                  'Archived ${summary.archivedFiles}',
                                  '已歸檔 ${summary.archivedFiles}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    BilingualActionButton(
                      variant: summary.courseId == activeCourseId
                          ? BilingualButtonVariant.filled
                          : BilingualButtonVariant.tonal,
                      compact: true,
                      onPressed: () => onOpenCourse(summary.courseId),
                      primaryLabel: localizedText(
                        languageCode,
                        summary.courseId == activeCourseId ? '当前课程' : '打开课程',
                        summary.courseId == activeCourseId
                            ? 'Current lesson'
                            : 'Open lesson',
                        summary.courseId == activeCourseId ? '目前課程' : '打開課程',
                      ),
                      secondaryLabel: '',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LearningLessonStatusBadge extends StatelessWidget {
  const _LearningLessonStatusBadge({
    required this.languageCode,
    required this.status,
  });

  final String languageCode;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedStatus = status.trim().isEmpty
        ? 'published'
        : status.trim();
    final Color foregroundColor;
    final Color backgroundColor;
    final String label;
    switch (normalizedStatus) {
      case 'draft':
        foregroundColor = const Color(0xFF8A5A00);
        backgroundColor = const Color(0xFFFFE7BA);
        label = localizedText(languageCode, '草稿', 'Draft', '草稿');
        break;
      case 'archived':
        foregroundColor = const Color(0xFF5E6472);
        backgroundColor = const Color(0xFFE5E7EB);
        label = localizedText(languageCode, '已归档', 'Archived', '已歸檔');
        break;
      default:
        foregroundColor = const Color(0xFF0B6B45);
        backgroundColor = const Color(0xFFCFEEDB);
        label = localizedText(languageCode, '已发布', 'Published', '已發布');
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: backgroundColor,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LearningMetricChip extends StatelessWidget {
  const _LearningMetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LearningAdminCourseSummary {
  const _LearningAdminCourseSummary({
    required this.courseId,
    required this.title,
    required this.totalFiles,
    required this.draftFiles,
    required this.publishedFiles,
    required this.archivedFiles,
  });

  final String courseId;
  final String title;
  final int totalFiles;
  final int draftFiles;
  final int publishedFiles;
  final int archivedFiles;

  bool get hasDrafts => draftFiles > 0;
  bool get needsInitialPublish => draftFiles > 0 && publishedFiles == 0;
  bool get needsUpdatePublish => draftFiles > 0 && publishedFiles > 0;
  int get adminPriority {
    if (needsInitialPublish) {
      return 0;
    }
    if (needsUpdatePublish) {
      return 1;
    }
    if (publishedFiles > 0) {
      return 2;
    }
    if (archivedFiles > 0) {
      return 3;
    }
    return 4;
  }
}

class _LearningAdminCourseSummaryBuilder {
  _LearningAdminCourseSummaryBuilder({
    required this.courseId,
    required this.title,
  });

  final String courseId;
  final String title;
  int totalFiles = 0;
  int draftFiles = 0;
  int publishedFiles = 0;
  int archivedFiles = 0;

  _LearningAdminCourseSummary build() {
    return _LearningAdminCourseSummary(
      courseId: courseId,
      title: title,
      totalFiles: totalFiles,
      draftFiles: draftFiles,
      publishedFiles: publishedFiles,
      archivedFiles: archivedFiles,
    );
  }
}

class _LearningCourseFileDescriptor {
  const _LearningCourseFileDescriptor({
    required this.courseId,
    required this.languageCode,
  });

  final String courseId;
  final String languageCode;
}

_LearningCourseFileDescriptor? _parseLearningCourseFilePath(String path) {
  final normalized = path.trim();
  if (!normalized.startsWith('courses/') || !normalized.endsWith('.md')) {
    return null;
  }
  final fileName = normalized.substring('courses/'.length);
  final lastDot = fileName.lastIndexOf('.');
  if (lastDot <= 0) {
    return null;
  }
  final localeDot = fileName.substring(0, lastDot).lastIndexOf('.');
  if (localeDot <= 0) {
    return null;
  }
  return _LearningCourseFileDescriptor(
    courseId: fileName.substring(0, localeDot),
    languageCode: fileName.substring(localeDot + 1, lastDot),
  );
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

List<_LearningCourse> _buildBackendCourseCatalog(
  List<MarkdownFileSummary> items,
) {
  // Group backend markdown files by course id so one course card can represent multiple locale variants.
  // 按课程 ID 聚合后端 Markdown 文件，让一张课程卡片可以表示多个语言版本。
  final grouped = <String, List<MarkdownFileSummary>>{};
  for (final item in items) {
    final descriptor = _tryParseLearningCourseFile(item.path);
    if (descriptor == null) {
      continue;
    }
    grouped
        .putIfAbsent(descriptor.courseId, () => <MarkdownFileSummary>[])
        .add(item);
  }

  final courses = <_LearningCourse>[];
  for (final entry in grouped.entries) {
    final sortedItems = List<MarkdownFileSummary>.from(entry.value)
      ..sort((left, right) => left.path.compareTo(right.path));
    courses.add(_buildBackendCourse(entry.key, sortedItems));
  }
  courses.sort((left, right) => left.id.compareTo(right.id));
  return courses;
}

_LearningCourse _buildBackendCourse(
  String courseId,
  List<MarkdownFileSummary> items,
) {
  // Convert one discovered backend course into a UI card while keeping frontend fallback text lightweight.
  // 将发现到的单个后端课程转换成界面卡片，同时保持前端兜底文案足够轻量。
  final languageCodes =
      items
          .map(
            (item) =>
                _tryParseLearningCourseFile(item.path)?.languageCode ?? '',
          )
          .where((languageCode) => languageCode.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  final latestUpdatedAt = items
      .map((item) => item.updatedAt)
      .whereType<DateTime>()
      .fold<DateTime?>(null, (latest, current) {
        if (latest == null || current.isAfter(latest)) {
          return current;
        }
        return latest;
      });
  final accent = _learningCourseAccentColor(courseId);
  final fallbackTitle = _humanizeCourseId(courseId);
  final updateLabel = latestUpdatedAt == null
      ? 'Backend'
      : '${latestUpdatedAt.year}-${latestUpdatedAt.month.toString().padLeft(2, '0')}-${latestUpdatedAt.day.toString().padLeft(2, '0')}';

  return _LearningCourse(
    id: courseId,
    icon: courseId.length >= 3
        ? courseId.substring(0, 3).toUpperCase()
        : courseId.toUpperCase(),
    colors: [
      accent.withValues(alpha: 0.92),
      Color.alphaBlend(accent.withValues(alpha: 0.18), const Color(0xFF0F1720)),
    ],
    title: {
      'zh-CN': fallbackTitle,
      'en-US': fallbackTitle,
      'zh-TW': fallbackTitle,
    },
    subtitle: {
      'zh-CN': '来自 learning-service 的动态课程文件，可随内容仓库持续扩展。',
      'en-US':
          'A backend-driven lesson discovered from learning-service and ready to grow with the content repository.',
      'zh-TW': '來自 learning-service 的動態課程檔案，可隨內容倉庫持續擴展。',
    },
    meta: {
      'zh-CN': '${languageCodes.length} 个语言版本 · 更新 $updateLabel',
      'en-US': '${languageCodes.length} locale variants · Updated $updateLabel',
      'zh-TW': '${languageCodes.length} 個語言版本 · 更新 $updateLabel',
    },
    tagMap: {
      'zh-CN': ['后端同步', ...languageCodes],
      'en-US': ['Backend sync', ...languageCodes],
      'zh-TW': ['後端同步', ...languageCodes],
    },
    markdown: const {},
  );
}

_LearningCourseFileDescriptor? _tryParseLearningCourseFile(String path) {
  // Accept only backend lesson files under `courses/` that follow the `{courseId}.{locale}.md` naming convention.
  // 仅接受 `courses/` 目录下遵循 `{courseId}.{locale}.md` 命名规则的后端课程文件。
  final normalized = path.trim();
  if (!normalized.startsWith('courses/') || !normalized.endsWith('.md')) {
    return null;
  }
  final fileName = normalized.substring('courses/'.length);
  final lastDot = fileName.lastIndexOf('.');
  if (lastDot <= 0) {
    return null;
  }
  final localeDot = fileName.lastIndexOf('.', lastDot - 1);
  if (localeDot <= 0) {
    return null;
  }
  final courseId = fileName.substring(0, localeDot);
  final languageCode = fileName.substring(localeDot + 1, lastDot);
  if (courseId.isEmpty || languageCode.isEmpty) {
    return null;
  }
  return _LearningCourseFileDescriptor(
    courseId: courseId,
    languageCode: languageCode,
  );
}

String _humanizeCourseId(String courseId) {
  // Turn one slug-like course id into a readable fallback title for backend-discovered lessons.
  // 将 slug 风格课程 ID 转成可读的后端课程兜底标题。
  final words = courseId
      .split(RegExp(r'[-_]+'))
      .where((word) => word.trim().isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .toList();
  if (words.isEmpty) {
    return courseId;
  }
  return words.join(' ');
}

Color _learningCourseAccentColor(String courseId) {
  // Keep backend-generated course cards visually distinct yet deterministic for the same id.
  // 让后端生成的课程卡片既有区分度，又能对同一 ID 保持稳定配色。
  final palette = <Color>[
    const Color(0xFF2F5D7C),
    const Color(0xFF6A3F2A),
    const Color(0xFF1D5B4F),
    const Color(0xFF5F3B73),
    const Color(0xFF7A5C1B),
  ];
  final hash = courseId.codeUnits.fold<int>(0, (value, code) => value + code);
  return palette[hash % palette.length];
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
