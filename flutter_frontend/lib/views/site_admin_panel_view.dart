import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/app_models.dart';
import '../widgets/bilingual_action_button.dart';
import 'view_state_helpers.dart';

class SiteAdminWorkspaceView extends StatefulWidget {
  const SiteAdminWorkspaceView({
    super.key,
    required this.apiClient,
    required this.onOpenServices,
    required this.onOpenProfile,
    required this.onOpenSpace,
    required this.onOpenChat,
    required this.onOpenLearning,
    required this.onRefresh,
    required this.languageCode,
  });

  final ApiClient apiClient;
  final VoidCallback onOpenServices;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSpace;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenLearning;
  final VoidCallback onRefresh;
  final String languageCode;

  @override
  State<SiteAdminWorkspaceView> createState() => _SiteAdminWorkspaceViewState();
}

class _SiteAdminWorkspaceViewState extends State<SiteAdminWorkspaceView> {
  AdminOverview? _overview;
  bool _loading = true;
  bool _saving = false;
  String _error = '';
  String _flash = '';
  String _userFilter = '';
  final Map<String, String> _levelDrafts = {};
  final Map<String, String> _statusDrafts = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadOverview(refreshWorkspace: false));
  }

  Future<void> _loadOverview({required bool refreshWorkspace}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    if (refreshWorkspace) {
      widget.onRefresh();
    }
    try {
      final overview = await widget.apiClient.fetchAdminOverview();
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = overview;
        _loading = false;
        _error = '';
        _flash = '';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  String _draftLevel(AdminUserItem user) => _levelDrafts[user.id] ?? user.level;

  String _draftStatus(AdminUserItem user) =>
      _statusDrafts[user.id] ?? user.status;

  List<AdminServiceStatus> _offlineServices(AdminOverview overview) =>
      overview.services.where((service) => !service.online).toList();

  List<AdminUserItem> _disabledUsers(AdminOverview overview) => overview
      .users
      .items
      .where((user) => user.status.toLowerCase() != 'active')
      .toList();

  List<AdminUserItem> _filteredUsers(AdminOverview overview) {
    final query = _userFilter.trim().toLowerCase();
    if (query.isEmpty) {
      return overview.users.items;
    }
    return overview.users.items.where((user) {
      final haystack = [
        user.displayName,
        user.email,
        user.username,
        user.domain,
        user.id,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _focusDisabledUser(AdminUserItem user) {
    setState(() {
      _userFilter = user.displayName.isNotEmpty
          ? user.displayName
          : (user.email.isNotEmpty ? user.email : user.id);
      _flash = localizedText(
        widget.languageCode,
        '已筛选停用用户: ${user.displayName.isEmpty ? user.id : user.displayName}',
        'Filtered disabled user: ${user.displayName.isEmpty ? user.id : user.displayName}',
        '已篩選停用使用者: ${user.displayName.isEmpty ? user.id : user.displayName}',
      );
    });
  }

  Future<void> _saveUser(AdminUserItem user) async {
    final nextLevel = _draftLevel(user);
    final nextStatus = _draftStatus(user);
    if (nextLevel == user.level && nextStatus == user.status) {
      setState(() {
        _flash = localizedText(
          widget.languageCode,
          '当前用户没有需要保存的变更。',
          'No user changes to save.',
          '目前使用者沒有需要儲存的變更。',
        );
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
      _flash = '';
    });
    try {
      final updated = await widget.apiClient.updateAdminUser(
        userId: user.id,
        level: nextLevel,
        status: nextStatus,
      );
      final current = _overview;
      if (!mounted || current == null) {
        return;
      }
      final updatedItems = current.users.items
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      final activeUsers = updatedItems
          .where((item) => item.status == 'active')
          .length;
      final adminUsers = updatedItems
          .where((item) => item.level == 'admin')
          .length;
      final users = AdminUserSummary(
        totalUsers: current.users.totalUsers,
        adminUsers: adminUsers,
        activeUsers: activeUsers,
        inactiveUsers: updatedItems.length - activeUsers,
        items: updatedItems,
      );
      setState(() {
        _overview = AdminOverview(
          generatedAt: current.generatedAt,
          summary: AdminSummary(
            totalServices: current.summary.totalServices,
            onlineServices: current.summary.onlineServices,
            offlineServices: current.summary.offlineServices,
            totalUsers: users.totalUsers,
            adminUsers: adminUsers,
            activeUsers: activeUsers,
            disabledUsers: users.inactiveUsers,
          ),
          totalServices: current.totalServices,
          onlineServices: current.onlineServices,
          offlineServices: current.offlineServices,
          adminWorkspaces: current.adminWorkspaces,
          degraded: current.degraded,
          checkedAt: current.checkedAt,
          services: current.services,
          workspaces: current.workspaces,
          database: current.database,
          runtime: current.runtime,
          users: users,
        );
        _saving = false;
        _flash = localizedText(
          widget.languageCode,
          '用户权限已更新。',
          'User permissions updated.',
          '使用者權限已更新。',
        );
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  VoidCallback? _primaryAction(AdminServiceStatus service) {
    switch (service.key) {
      case 'account':
        return widget.onOpenProfile;
      case 'space':
        return service.online ? widget.onOpenSpace : null;
      case 'message':
        return service.online ? widget.onOpenChat : null;
      case 'learning':
        return service.online ? widget.onOpenLearning : null;
      case 'admin':
        return () => _loadOverview(refreshWorkspace: true);
      default:
        return null;
    }
  }

  String _primaryLabel(AdminServiceStatus service) {
    switch (service.key) {
      case 'account':
        return localizedText(
          widget.languageCode,
          '进入个人主页',
          'Open profile',
          '進入個人主頁',
        );
      case 'space':
        return localizedText(widget.languageCode, '打开空间', 'Open space', '打開空間');
      case 'message':
        return localizedText(widget.languageCode, '打开聊天', 'Open chat', '打開聊天');
      case 'learning':
        return localizedText(
          widget.languageCode,
          '打开学习页',
          'Open learning',
          '打開學習頁',
        );
      default:
        return localizedText(
          widget.languageCode,
          '刷新数据',
          'Refresh data',
          '重新整理資料',
        );
    }
  }

  VoidCallback _attentionServiceAction(AdminServiceStatus service) {
    final action = _primaryAction(service);
    if (action != null) {
      return action;
    }
    return () {
      setState(() {
        _flash = localizedText(
          widget.languageCode,
          '服务当前离线: ${service.title}',
          'Service is offline: ${service.title}',
          '服務目前離線: ${service.title}',
        );
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final generatedAt = overview?.generatedAt;
    final filteredUsers = overview == null
        ? const <AdminUserItem>[]
        : _filteredUsers(overview);
    final offlineServices = overview == null
        ? const <AdminServiceStatus>[]
        : _offlineServices(overview);
    final disabledUsers = overview == null
        ? const <AdminUserItem>[]
        : _disabledUsers(overview);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminSectionCard(
            title: localizedText(
              widget.languageCode,
              '网站总管理面板',
              'Site-wide admin panel',
              '網站總管理面板',
            ),
            subtitle: localizedText(
              widget.languageCode,
              '统一查看微服务配置、数据库配置、用户管理和运行性能。',
              'Review microservice config, database config, user management, and runtime performance in one place.',
              '統一查看微服務設定、資料庫設定、使用者管理與執行效能。',
            ),
            headerActions: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BilingualActionButton(
                  variant: BilingualButtonVariant.tonal,
                  compact: true,
                  onPressed: widget.onOpenServices,
                  primaryLabel: localizedText(
                    widget.languageCode,
                    '服务导航',
                    'Service navigation',
                    '服務導航',
                  ),
                  secondaryLabel: 'Service navigation',
                ),
                BilingualActionButton(
                  variant: BilingualButtonVariant.filled,
                  compact: true,
                  onPressed: _loading
                      ? null
                      : () => _loadOverview(refreshWorkspace: true),
                  primaryLabel: localizedText(
                    widget.languageCode,
                    '刷新面板',
                    'Refresh panel',
                    '重新整理面板',
                  ),
                  secondaryLabel: 'Refresh panel',
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error.isNotEmpty)
                  Text(
                    _error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_flash.isNotEmpty)
                  Text(
                    _flash,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (generatedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    localizedText(
                      widget.languageCode,
                      '最近生成: ${formatDateTime(generatedAt)}',
                      'Generated: ${formatDateTime(generatedAt)}',
                      '最近產生: ${formatDateTime(generatedAt)}',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                if (_loading)
                  const LinearProgressIndicator()
                else if (overview != null)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AdminSummaryCard(
                        label: localizedText(
                          widget.languageCode,
                          '总服务数',
                          'Total services',
                          '總服務數',
                        ),
                        value: '${overview.summary.totalServices}',
                      ),
                      _AdminSummaryCard(
                        label: localizedText(
                          widget.languageCode,
                          '在线服务',
                          'Online services',
                          '在線服務',
                        ),
                        value: '${overview.summary.onlineServices}',
                      ),
                      _AdminSummaryCard(
                        label: localizedText(
                          widget.languageCode,
                          '总用户数',
                          'Total users',
                          '總使用者數',
                        ),
                        value: '${overview.summary.totalUsers}',
                      ),
                      _AdminSummaryCard(
                        label: localizedText(
                          widget.languageCode,
                          '管理员',
                          'Admins',
                          '管理員',
                        ),
                        value: '${overview.summary.adminUsers}',
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_loading && overview != null) ...[
            _AdminSectionCard(
              title: localizedText(
                widget.languageCode,
                '待处理提醒',
                'Attention queue',
                '待處理提醒',
              ),
              subtitle: localizedText(
                widget.languageCode,
                '优先显示当前离线服务和已停用用户，减少人工扫描成本。',
                'Show offline services and disabled users first to reduce manual scanning.',
                '優先顯示目前離線服務與已停用使用者，減少人工掃描成本。',
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _AdminAttentionCard(
                    title: localizedText(
                      widget.languageCode,
                      '离线服务',
                      'Offline services',
                      '離線服務',
                    ),
                    value: '${offlineServices.length}',
                    lines: offlineServices.isEmpty
                        ? [
                            localizedText(
                              widget.languageCode,
                              '当前没有离线服务。',
                              'No offline services right now.',
                              '目前沒有離線服務。',
                            ),
                          ]
                        : offlineServices
                              .map((service) => service.title)
                              .toList(),
                    actions: offlineServices
                        .map(
                          (service) => _AdminAttentionAction(
                            label: service.title,
                            onTap: _attentionServiceAction(service),
                          ),
                        )
                        .toList(),
                  ),
                  _AdminAttentionCard(
                    title: localizedText(
                      widget.languageCode,
                      '停用用户',
                      'Disabled users',
                      '停用使用者',
                    ),
                    value: '${disabledUsers.length}',
                    lines: disabledUsers.isEmpty
                        ? [
                            localizedText(
                              widget.languageCode,
                              '当前没有停用用户。',
                              'No disabled users right now.',
                              '目前沒有停用使用者。',
                            ),
                          ]
                        : disabledUsers
                              .take(4)
                              .map(
                                (user) => user.displayName.isEmpty
                                    ? user.id
                                    : user.displayName,
                              )
                              .toList(),
                    actions: disabledUsers
                        .take(4)
                        .map(
                          (user) => _AdminAttentionAction(
                            label: user.displayName.isEmpty
                                ? user.id
                                : user.displayName,
                            onTap: () => _focusDisabledUser(user),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: localizedText(
                widget.languageCode,
                '微服务配置',
                'Microservice configuration',
                '微服務設定',
              ),
              subtitle: localizedText(
                widget.languageCode,
                '查看各服务地址、健康状态、探测耗时与功能范围。',
                'Review each service base URL, health, probe latency, and scope.',
                '查看各服務位址、健康狀態、探測耗時與功能範圍。',
              ),
              child: Column(
                children: [
                  for (final service in overview.services) ...[
                    _AdminServiceConfigTile(
                      service: service,
                      languageCode: widget.languageCode,
                      primaryLabel: _primaryLabel(service),
                      onPrimary: _primaryAction(service),
                    ),
                    if (service != overview.services.last)
                      const Divider(height: 24),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: localizedText(
                widget.languageCode,
                '数据库配置',
                'Database configuration',
                '資料庫設定',
              ),
              subtitle: localizedText(
                widget.languageCode,
                '展示当前聚合服务使用的数据库连接配置与连接池占用。',
                'Show the database connection configuration and pool usage for the admin service.',
                '展示目前聚合服務使用的資料庫連線設定與連線池占用。',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AdminInfoChip(
                        label: 'Driver',
                        value: overview.database.driver,
                      ),
                      _AdminInfoChip(
                        label: 'Host',
                        value: overview.database.host,
                      ),
                      _AdminInfoChip(
                        label: 'Port',
                        value: overview.database.port,
                      ),
                      _AdminInfoChip(
                        label: 'Database',
                        value: overview.database.database,
                      ),
                      _AdminInfoChip(
                        label: 'User',
                        value: overview.database.user,
                      ),
                      _AdminInfoChip(
                        label: 'SSL',
                        value: overview.database.sslMode,
                      ),
                      _AdminInfoChip(
                        label: localizedText(
                          widget.languageCode,
                          '打开连接',
                          'Open connections',
                          '打開連線',
                        ),
                        value: '${overview.database.openConnections}',
                      ),
                      _AdminInfoChip(
                        label: localizedText(
                          widget.languageCode,
                          '使用中',
                          'In use',
                          '使用中',
                        ),
                        value: '${overview.database.inUseConnections}',
                      ),
                      _AdminInfoChip(
                        label: localizedText(
                          widget.languageCode,
                          '空闲连接',
                          'Idle connections',
                          '閒置連線',
                        ),
                        value: '${overview.database.idleConnections}',
                      ),
                      _AdminInfoChip(
                        label: localizedText(
                          widget.languageCode,
                          '最大连接',
                          'Max open',
                          '最大連線',
                        ),
                        value: '${overview.database.maxOpenConnections}',
                      ),
                    ],
                  ),
                  if (overview.database.maskedDsn.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SelectableText(overview.database.maskedDsn),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: localizedText(
                widget.languageCode,
                '运行性能',
                'Runtime performance',
                '執行效能',
              ),
              subtitle: localizedText(
                widget.languageCode,
                '展示 admin-service 当前进程的运行时资源占用。',
                'Show current runtime resource usage for the admin-service process.',
                '展示 admin-service 目前行程的執行時資源占用。',
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _AdminInfoChip(
                    label: 'Go',
                    value: overview.runtime.goVersion,
                  ),
                  _AdminInfoChip(
                    label: 'Platform',
                    value:
                        '${overview.runtime.goOs}/${overview.runtime.goArch}',
                  ),
                  _AdminInfoChip(
                    label: localizedText(
                      widget.languageCode,
                      '协程数',
                      'Goroutines',
                      '協程數',
                    ),
                    value: '${overview.runtime.goroutines}',
                  ),
                  _AdminInfoChip(
                    label: localizedText(
                      widget.languageCode,
                      '已分配内存',
                      'Allocated memory',
                      '已分配記憶體',
                    ),
                    value: '${overview.runtime.memoryAllocMb}MB',
                  ),
                  _AdminInfoChip(
                    label: localizedText(
                      widget.languageCode,
                      '系统内存',
                      'System memory',
                      '系統記憶體',
                    ),
                    value: '${overview.runtime.memorySysMb}MB',
                  ),
                  _AdminInfoChip(
                    label: localizedText(
                      widget.languageCode,
                      '堆对象',
                      'Heap objects',
                      '堆物件',
                    ),
                    value: '${overview.runtime.heapObjects}',
                  ),
                  _AdminInfoChip(
                    label: localizedText(
                      widget.languageCode,
                      'GC 次数',
                      'GC count',
                      'GC 次數',
                    ),
                    value: '${overview.runtime.gcCount}',
                  ),
                  _AdminInfoChip(
                    label: localizedText(
                      widget.languageCode,
                      '运行时长',
                      'Uptime',
                      '執行時長',
                    ),
                    value: '${overview.runtime.uptimeSec}s',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: localizedText(
                widget.languageCode,
                '用户管理',
                'User management',
                '使用者管理',
              ),
              subtitle: localizedText(
                widget.languageCode,
                '直接调整最近注册用户的等级与状态，避免手工改数据库。',
                'Adjust level and status for recent users directly without editing the database manually.',
                '直接調整最近註冊使用者的等級與狀態，避免手動修改資料庫。',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AdminInfoChip(
                        label: localizedText(
                          widget.languageCode,
                          '活跃用户',
                          'Active users',
                          '活躍使用者',
                        ),
                        value: '${overview.users.activeUsers}',
                      ),
                      _AdminInfoChip(
                        label: localizedText(
                          widget.languageCode,
                          '停用用户',
                          'Disabled users',
                          '停用使用者',
                        ),
                        value: '${overview.users.inactiveUsers}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: ValueKey('admin-user-filter-$_userFilter'),
                    initialValue: _userFilter,
                    onChanged: (value) {
                      setState(() {
                        _userFilter = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: localizedText(
                        widget.languageCode,
                        '筛选用户',
                        'Filter users',
                        '篩選使用者',
                      ),
                      hintText: localizedText(
                        widget.languageCode,
                        '输入昵称、邮箱、用户名或域名',
                        'Search by name, email, username, or domain',
                        '輸入暱稱、郵箱、用戶名或網域',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredUsers.isEmpty)
                    Text(
                      localizedText(
                        widget.languageCode,
                        '没有匹配的用户。',
                        'No matching users.',
                        '沒有符合的使用者。',
                      ),
                    ),
                  for (final user in filteredUsers) ...[
                    _AdminUserTile(
                      user: user,
                      saving: _saving,
                      languageCode: widget.languageCode,
                      levelValue: _draftLevel(user),
                      statusValue: _draftStatus(user),
                      onLevelChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _levelDrafts[user.id] = value;
                        });
                      },
                      onStatusChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _statusDrafts[user.id] = value;
                        });
                      },
                      onSave: () => _saveUser(user),
                    ),
                    if (user != filteredUsers.last) const Divider(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerActions,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? headerActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(subtitle),
                    ],
                  ),
                ),
                if (headerActions != null) headerActions!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _AdminServiceConfigTile extends StatelessWidget {
  const _AdminServiceConfigTile({
    required this.service,
    required this.languageCode,
    required this.primaryLabel,
    this.onPrimary,
  });

  final AdminServiceStatus service;
  final String languageCode;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    service.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(service.baseUrl),
                ],
              ),
            ),
            Chip(
              label: Text(
                service.online
                    ? localizedText(languageCode, '在线', 'Online', '線上')
                    : localizedText(languageCode, '离线', 'Offline', '離線'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AdminInfoChip(
              label: localizedText(
                languageCode,
                '探测耗时',
                'Probe latency',
                '探測耗時',
              ),
              value: '${service.responseTimeMs}ms',
            ),
            _AdminInfoChip(
              label: localizedText(languageCode, '必需服务', 'Required', '必要服務'),
              value: service.required ? 'true' : 'false',
            ),
            for (final config in service.configItems)
              _AdminInfoChip(label: config.key, value: config.value),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            BilingualActionButton(
              variant: service.online
                  ? BilingualButtonVariant.filled
                  : BilingualButtonVariant.tonal,
              compact: true,
              onPressed: onPrimary,
              primaryLabel: primaryLabel,
              secondaryLabel: primaryLabel,
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminInfoChip extends StatelessWidget {
  const _AdminInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AdminAttentionCard extends StatelessWidget {
  const _AdminAttentionCard({
    required this.title,
    required this.value,
    required this.lines,
    this.actions = const [],
  });

  final String title;
  final String value;
  final List<String> lines;
  final List<_AdminAttentionAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: Theme.of(context).textTheme.bodySmall),
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions)
                  ActionChip(
                    label: Text(action.label),
                    onPressed: action.onTap,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminAttentionAction {
  const _AdminAttentionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class _AdminUserTile extends StatelessWidget {
  const _AdminUserTile({
    required this.user,
    required this.levelValue,
    required this.statusValue,
    required this.onLevelChanged,
    required this.onStatusChanged,
    required this.onSave,
    required this.languageCode,
    required this.saving,
  });

  final AdminUserItem user;
  final String levelValue;
  final String statusValue;
  final ValueChanged<String?> onLevelChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onSave;
  final String languageCode;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName.isEmpty ? user.id : user.displayName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          user.secondary.isEmpty ? user.id : user.secondary,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: levelValue,
                decoration: InputDecoration(
                  labelText: localizedText(languageCode, '等级', 'Level', '等級'),
                ),
                items: const [
                  DropdownMenuItem(value: 'basic', child: Text('basic')),
                  DropdownMenuItem(value: 'vip', child: Text('vip')),
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                ],
                onChanged: onLevelChanged,
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: statusValue,
                decoration: InputDecoration(
                  labelText: localizedText(languageCode, '状态', 'Status', '狀態'),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('active')),
                  DropdownMenuItem(value: 'disabled', child: Text('disabled')),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            BilingualActionButton(
              variant: BilingualButtonVariant.filled,
              compact: true,
              onPressed: saving ? null : onSave,
              primaryLabel: localizedText(
                languageCode,
                '保存用户',
                'Save user',
                '儲存使用者',
              ),
              secondaryLabel: 'Save user',
            ),
          ],
        ),
      ],
    );
  }
}
