window.SiteAdminPanel = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      saving: false,
      errorMessage: '',
      flashMessage: '',
      overview: null,
      databaseConfig: null,
      databaseConfigDraft: '',
      databaseConfigLoading: false,
      databaseConfigSaving: false,
      userFilter: '',
      roleDrafts: {},
      levelDrafts: {},
      statusDrafts: {},
      microservicesExpanded: false,
      serviceSettingsOpen: false,
      activeServiceKey: '',
    };
  },
  computed: {
    isAdmin() {
      return this.app?.isCurrentUserAdmin?.() === true;
    },
    summaryCards() {
      const summary = this.overview?.summary || {};
      return [
        {
          key: 'total-services',
          label: this.label('总服务数', 'Total services', '總服務數'),
          value: String(summary.total_services || 0),
        },
        {
          key: 'online-services',
          label: this.label('在线服务', 'Online services', '在線服務'),
          value: String(summary.online_services || 0),
        },
        {
          key: 'total-users',
          label: this.label('总用户数', 'Total users', '總使用者數'),
          value: String(summary.total_users || 0),
        },
        {
          key: 'admin-users',
          label: this.label('管理员', 'Admins', '管理員'),
          value: String(summary.admin_users || 0),
        },
      ];
    },
    serviceCards() {
      return Array.isArray(this.overview?.services) ? this.overview.services : [];
    },
    onlineServices() {
      return this.serviceCards.filter((service) => service.online);
    },
    offlineServices() {
      return this.serviceCards.filter((service) => !service.online);
    },
    selectedService() {
      return this.serviceCards.find((service) => service.key === this.activeServiceKey) || null;
    },
    selectedServiceCards() {
      const service = this.selectedService;
      if (!service) {
        return [];
      }
      return [
        {
          key: 'latency',
          label: this.label('探测耗时', 'Probe latency', '探測耗時'),
          value: `${service.response_time_ms || 0}ms`,
        },
        {
          key: 'required',
          label: this.label('必需服务', 'Required service', '必要服務'),
          value: service.required ? 'true' : 'false',
        },
        ...((service.config_items || []).map((item) => ({
          key: item.key,
          label: item.key,
          value: item.value || '-',
        }))),
      ];
    },
    servicePanelSummaryCards() {
      return [
        {
          key: 'online',
          label: this.label('在线服务', 'Online services', '在線服務'),
          value: String(this.onlineServices.length),
        },
        {
          key: 'offline',
          label: this.label('离线服务', 'Offline services', '離線服務'),
          value: String(this.offlineServices.length),
        },
        {
          key: 'total',
          label: this.label('总服务数', 'Total services', '總服務數'),
          value: String(this.serviceCards.length),
        },
      ];
    },
    databaseCards() {
      const database = this.databaseConfig || this.overview?.database || {};
      return [
        { key: 'driver', label: 'Driver', value: database.driver || '-' },
        { key: 'host', label: 'Host', value: database.host || '-' },
        { key: 'port', label: 'Port', value: database.port || '-' },
        { key: 'database', label: 'Database', value: database.database || '-' },
        { key: 'user', label: 'User', value: database.user || '-' },
        { key: 'ssl', label: 'SSL', value: database.ssl_mode || '-' },
        {
          key: 'open',
          label: this.label('打开连接', 'Open connections', '打開連線'),
          value: String(database.open_connections ?? 0),
        },
        {
          key: 'inuse',
          label: this.label('使用中', 'In use', '使用中'),
          value: String(database.in_use_connections ?? 0),
        },
        {
          key: 'idle',
          label: this.label('空闲连接', 'Idle connections', '閒置連線'),
          value: String(database.idle_connections ?? 0),
        },
        {
          key: 'max',
          label: this.label('最大连接', 'Max open', '最大連線'),
          value: String(database.max_open_connections ?? 0),
        },
      ];
    },
    runtimeCards() {
      const runtime = this.overview?.runtime || {};
      return [
        { key: 'go', label: 'Go', value: runtime.go_version || '-' },
        {
          key: 'platform',
          label: 'Platform',
          value: `${runtime.go_os || '-'} / ${runtime.go_arch || '-'}`,
        },
        {
          key: 'goroutines',
          label: this.label('协程数', 'Goroutines', '協程數'),
          value: String(runtime.goroutines ?? 0),
        },
        {
          key: 'alloc',
          label: this.label('已分配内存', 'Allocated memory', '已分配記憶體'),
          value: `${runtime.memory_alloc_mb ?? 0}MB`,
        },
        {
          key: 'sys',
          label: this.label('系统内存', 'System memory', '系統記憶體'),
          value: `${runtime.memory_sys_mb ?? 0}MB`,
        },
        {
          key: 'heap',
          label: this.label('堆对象', 'Heap objects', '堆物件'),
          value: String(runtime.heap_objects ?? 0),
        },
        {
          key: 'gc',
          label: this.label('GC 次数', 'GC count', 'GC 次數'),
          value: String(runtime.gc_count ?? 0),
        },
        {
          key: 'uptime',
          label: this.label('运行时长', 'Uptime', '執行時長'),
          value: `${runtime.uptime_sec ?? 0}s`,
        },
      ];
    },
    managedUsers() {
      return Array.isArray(this.overview?.users?.items) ? this.overview.users.items : [];
    },
    disabledUsers() {
      return this.managedUsers.filter((user) => String(user.status || '').toLowerCase() !== 'active');
    },
    filteredUsers() {
      const query = String(this.userFilter || '').trim().toLowerCase();
      if (!query) {
        return this.managedUsers;
      }
      return this.managedUsers.filter((user) => {
        const haystack = [
          user.display_name || '',
          user.email || '',
          user.username || '',
          user.domain || '',
          user.id || '',
        ].join(' ').toLowerCase();
        return haystack.includes(query);
      });
    },
  },
  methods: {
    label(zh, en, tw) {
      switch (this.app?.locale) {
        case 'en-US':
          return en;
        case 'zh-TW':
          return tw;
        case 'zh-CN':
        default:
          return zh;
      }
    },
    userSecondary(user) {
      return [
        user.domain ? `@${user.domain}` : '',
        user.username ? `@${user.username}` : '',
        user.email || '',
      ].filter(Boolean).join(' · ');
    },
    serviceOnlineLabel(online) {
      return online
        ? this.label('在线', 'Online', '線上')
        : this.label('离线', 'Offline', '離線');
    },
    serviceStatusTone(service) {
      return service?.online ? 'online' : 'offline';
    },
    serviceDescription(service) {
      switch (service?.key) {
        case 'account':
          return this.label('账号资料、角色与身份体系。', 'Accounts, roles, and identity data.', '帳號資料、角色與身分體系。');
        case 'space':
          return this.label('空间内容、发布流与子域名入口。', 'Space content, publishing flow, and subdomain entry.', '空間內容、發布流與子網域入口。');
        case 'message':
          return this.label('会话、消息流与未读提醒。', 'Conversations, message flow, and unread alerts.', '會話、訊息流與未讀提醒。');
        case 'learning':
          return this.label('课程浏览、内容发布与课程后台。', 'Course browsing, publishing, and course console.', '課程瀏覽、內容發布與課程後台。');
        case 'admin':
          return this.label('站点级聚合总控与全局观察。', 'Site-wide control and global observability.', '站點級聚合總控與全域觀察。');
        default:
          return this.label('查看当前服务配置与操作入口。', 'Review current service configuration and actions.', '查看目前服務設定與操作入口。');
      }
    },
    draftRole(user) {
      return this.roleDrafts[user.id] || user.role || 'member';
    },
    draftLevel(user) {
      return this.levelDrafts[user.id] || user.level || 'basic';
    },
    draftStatus(user) {
      return this.statusDrafts[user.id] || user.status || 'active';
    },
    servicePrimaryAction(service) {
      this.closeServiceSettings();
      switch (service.key) {
        case 'account':
          this.app.openMyProfile();
          break;
        case 'space':
          if (service.online) {
            this.app.openServiceSection('space');
          } else {
            this.flashMessage = this.label('服务当前离线: ', 'Service is offline: ', '服務目前離線: ') + service.title;
          }
          break;
        case 'message':
          if (service.online) {
            this.app.openServiceSection('chat');
          } else {
            this.flashMessage = this.label('服务当前离线: ', 'Service is offline: ', '服務目前離線: ') + service.title;
          }
          break;
        case 'learning':
          if (service.online) {
            this.app.openServiceSection('learning');
          } else {
            this.flashMessage = this.label('服务当前离线: ', 'Service is offline: ', '服務目前離線: ') + service.title;
          }
          break;
        default:
          this.refreshOverview(true);
          break;
      }
    },
    serviceSecondaryAction(service) {
      this.closeServiceSettings();
      switch (service.key) {
        case 'account':
          this.app.openServiceSection('account-admin');
          break;
        case 'space':
          if (service.online) {
            this.app.openServiceSection('space-admin');
          }
          break;
        case 'message':
          if (service.online) {
            this.app.openServiceSection('message-admin');
          }
          break;
        case 'learning':
          if (service.online) {
            this.app.openServiceSection('learning-admin');
          }
          break;
        default:
          break;
      }
    },
    focusDisabledUser(user) {
      this.userFilter = user.display_name || user.email || user.id || '';
      this.flashMessage = this.label('已筛选停用用户: ', 'Filtered disabled user: ', '已篩選停用使用者: ')
        + (user.display_name || user.id || '');
    },
    servicePrimaryLabel(service) {
      switch (service.key) {
        case 'account':
          return this.label('进入个人主页', 'Open profile', '進入個人主頁');
        case 'space':
          return this.label('打开空间', 'Open space', '打開空間');
        case 'message':
          return this.label('打开聊天', 'Open chat', '打開聊天');
        case 'learning':
          return this.label('打开学习页', 'Open learning', '打開學習頁');
        default:
          return this.label('刷新数据', 'Refresh data', '重新整理資料');
      }
    },
    serviceSecondaryLabel(service) {
      switch (service.key) {
        case 'account':
        case 'space':
        case 'message':
          return this.label('管理控制页', 'Admin console', '管理控制頁');
        case 'learning':
          return this.label('课程后台', 'Course console', '課程後台');
        default:
          return '';
      }
    },
    showSecondaryAction(service) {
      return ['account', 'space', 'message', 'learning'].includes(service.key);
    },
    toggleMicroservicesExpanded() {
      // Keep the microservice workbench collapsed by default so site-level controls stay primary.
      // 默认收起微服务工作台，让站点级控制保持第一层级。
      this.microservicesExpanded = !this.microservicesExpanded;
    },
    openServiceSettings(service) {
      if (!service || !service.key) {
        return;
      }
      this.activeServiceKey = service.key;
      this.microservicesExpanded = true;
      this.serviceSettingsOpen = true;
    },
    closeServiceSettings() {
      this.serviceSettingsOpen = false;
    },
    async readPayload(response) {
      const payload = await this.app.readApiPayload(response);
      if (!response.ok) {
        throw new Error(payload.error || payload.message || `request failed: ${response.status}`);
      }
      return payload;
    },
    async refreshOverview(refreshWorkspace = false) {
      if (!this.isAdmin) {
        return;
      }
      this.loading = true;
      this.errorMessage = '';
      this.flashMessage = '';
      if (refreshWorkspace) {
        await this.app.refreshServiceStatus();
      }
      try {
        const response = await fetch(`${this.app.adminApiBase}/overview`, {
          headers: {
            Authorization: `Bearer ${this.app.token}`,
          },
        });
        this.overview = await this.readPayload(response);
        if (this.activeServiceKey && !this.serviceCards.some((service) => service.key === this.activeServiceKey)) {
          this.activeServiceKey = '';
          this.serviceSettingsOpen = false;
        }
        await this.refreshDatabaseConfig();
      } catch (error) {
        this.errorMessage = String(error?.message || error || '');
      } finally {
        this.loading = false;
      }
    },
    async refreshDatabaseConfig() {
      if (!this.isAdmin) {
        return;
      }
      this.databaseConfigLoading = true;
      try {
        const response = await fetch(`${this.app.adminApiBase}/config/database`, {
          headers: {
            Authorization: `Bearer ${this.app.token}`,
          },
        });
        const item = await this.readPayload(response);
        this.databaseConfig = item;
        this.databaseConfigDraft = item?.dsn || '';
      } catch (error) {
        this.errorMessage = String(error?.message || error || '');
      } finally {
        this.databaseConfigLoading = false;
      }
    },
    async saveDatabaseConfig() {
      const dsn = String(this.databaseConfigDraft || '').trim();
      if (!dsn) {
        this.errorMessage = this.label(
          '数据库连接不能为空。',
          'Database DSN is required.',
          '資料庫連線不能為空。',
        );
        return;
      }
      this.databaseConfigSaving = true;
      this.errorMessage = '';
      this.flashMessage = '';
      try {
        const response = await fetch(`${this.app.adminApiBase}/config/database`, {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${this.app.token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ dsn }),
        });
        const item = await this.readPayload(response);
        this.databaseConfig = item;
        this.databaseConfigDraft = item?.dsn || dsn;
        this.flashMessage = this.label(
          '数据库连接已写入本地配置文件，重启后端服务后生效。',
          'Database DSN was saved to the local config file. Restart backend services to apply it.',
          '資料庫連線已寫入本地設定檔，重啟後端服務後生效。',
        );
      } catch (error) {
        this.errorMessage = String(error?.message || error || '');
      } finally {
        this.databaseConfigSaving = false;
      }
    },
    async saveUser(user) {
      const role = this.draftRole(user);
      const level = this.draftLevel(user);
      const status = this.draftStatus(user);
      if (role === user.role && level === user.level && status === user.status) {
        this.flashMessage = this.label(
          '当前用户没有需要保存的变更。',
          'No user changes to save.',
          '目前使用者沒有需要儲存的變更。',
        );
        return;
      }
      this.saving = true;
      this.errorMessage = '';
      this.flashMessage = '';
      try {
        const response = await fetch(`${this.app.adminApiBase}/users/${encodeURIComponent(user.id)}`, {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${this.app.token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ role, level, status }),
        });
        const updated = await this.readPayload(response);
        const users = this.managedUsers.map((item) => (item.id === updated.id ? updated : item));
        const summary = { ...(this.overview?.summary || {}) };
        summary.admin_users = users.filter((item) => item.role === 'admin').length;
        summary.active_users = users.filter((item) => item.status === 'active').length;
        summary.disabled_users = users.filter((item) => item.status !== 'active').length;
        this.overview = {
          ...this.overview,
          summary,
          users: {
            ...(this.overview?.users || {}),
            admin_users: summary.admin_users,
            active_users: summary.active_users,
            inactive_users: summary.disabled_users,
            items: users,
          },
        };
        this.flashMessage = this.label('用户权限已更新。', 'User permissions updated.', '使用者權限已更新。');
      } catch (error) {
        this.errorMessage = String(error?.message || error || '');
      } finally {
        this.saving = false;
      }
    },
  },
  async mounted() {
    await this.refreshOverview(false);
  },
  template: `
    <section class="panel services-page site-admin-page">
      <div class="space-page-hero services-page-hero">
        <div>
          <div class="space-shell-kicker">{{ app.t('nav.admin-panel') }}</div>
          <div class="space-page-title">{{ label('网站总管理面板', 'Site-wide admin panel', '網站總管理面板') }}</div>
          <div class="space-page-sub">{{ label('统一查看微服务配置、数据库配置、用户管理和运行性能。', 'Review microservice config, database config, user management, and runtime performance in one place.', '統一查看微服務設定、資料庫設定、使用者管理與執行效能。') }}</div>
        </div>
        <div class="site-admin-actions">
          <bilingual-action-button
            variant="tonal"
            compact
            type="button"
            :primary-label="label('服务导航', 'Service navigation', '服務導航')"
            :secondary-label="'Service navigation'"
            @click="app.openServiceSection('services')"
          ></bilingual-action-button>
          <bilingual-action-button
            variant="filled"
            compact
            type="button"
            :primary-label="label('刷新面板', 'Refresh panel', '重新整理面板')"
            :secondary-label="'Refresh panel'"
            :disabled="loading"
            @click="refreshOverview(true)"
          ></bilingual-action-button>
        </div>
      </div>

      <div v-if="!isAdmin" class="learning-admin-files">
        <div class="learning-admin-files-head">
          <div>
            <div class="service-card-title">{{ label('管理员权限', 'Admin access', '管理員權限') }}</div>
            <div class="service-card-sub">{{ label('只有管理员账号可以进入总管理面板。', 'Only administrator accounts can enter this panel.', '只有管理員帳號可以進入總管理面板。') }}</div>
          </div>
        </div>
      </div>

      <template v-else>
        <div v-if="errorMessage" class="site-admin-banner site-admin-banner-error">{{ errorMessage }}</div>
        <div v-if="flashMessage" class="site-admin-banner">{{ flashMessage }}</div>
        <div v-if="overview?.generated_at" class="site-admin-generated">
          {{ label('最近生成', 'Generated', '最近產生') }}: {{ app.formatDateTime(overview.generated_at) }}
        </div>
        <div v-if="loading" class="site-admin-loading">
          <div class="site-admin-loading-bar"></div>
        </div>

        <div v-if="!loading" class="site-admin-summary">
          <article v-for="card in summaryCards" :key="card.key" class="site-admin-stat">
            <div class="site-admin-stat-label">{{ card.label }}</div>
            <div class="site-admin-stat-value">{{ card.value }}</div>
          </article>
        </div>

        <div v-if="!loading" class="site-admin-layout">
          <article class="service-card site-admin-section site-admin-cluster">
            <div class="service-card-head">
              <div>
                <div class="service-card-title">{{ label('站点控制', 'Site controls', '站點控制') }}</div>
                <div class="service-card-sub">{{ label('把需要直接操作的站点级配置放在一起，减少在总控里来回切换。', 'Keep actionable site-wide controls together so the admin panel reads like one control room.', '把需要直接操作的站點級設定放在一起，減少在總控裡來回切換。') }}</div>
              </div>
            </div>

            <div class="site-admin-cluster-grid">
              <section class="site-admin-subsection">
                <div class="site-admin-subsection-head">
                  <div>
                    <div class="site-admin-kicker">{{ label('优先处理', 'First look', '優先處理') }}</div>
                    <div class="service-card-title">{{ label('待处理提醒', 'Attention queue', '待處理提醒') }}</div>
                  </div>
                </div>
                <div class="site-admin-meta-grid">
                  <div class="site-admin-meta-card">
                    <div class="site-admin-meta-label">{{ label('离线服务', 'Offline services', '離線服務') }}</div>
                    <div class="site-admin-meta-value">{{ offlineServices.length }}</div>
                    <div class="site-admin-generated">{{ offlineServices.length ? offlineServices.map((service) => service.title).join(' · ') : label('当前没有离线服务。', 'No offline services right now.', '目前沒有離線服務。') }}</div>
                    <div v-if="offlineServices.length" class="site-admin-action-chips">
                      <button v-for="service in offlineServices" :key="service.key" type="button" @click="openServiceSettings(service)">{{ service.title }}</button>
                    </div>
                  </div>
                  <div class="site-admin-meta-card">
                    <div class="site-admin-meta-label">{{ label('停用用户', 'Disabled users', '停用使用者') }}</div>
                    <div class="site-admin-meta-value">{{ disabledUsers.length }}</div>
                    <div class="site-admin-generated">{{ disabledUsers.length ? disabledUsers.slice(0, 4).map((user) => user.display_name || user.id).join(' · ') : label('当前没有停用用户。', 'No disabled users right now.', '目前沒有停用使用者。') }}</div>
                    <div v-if="disabledUsers.length" class="site-admin-action-chips">
                      <button v-for="user in disabledUsers.slice(0, 4)" :key="user.id" type="button" @click="focusDisabledUser(user)">{{ user.display_name || user.id }}</button>
                    </div>
                  </div>
                </div>
              </section>

              <section class="site-admin-subsection">
                <div class="site-admin-subsection-head">
                  <div>
                    <div class="site-admin-kicker">{{ label('连接配置', 'Connection config', '連線設定') }}</div>
                    <div class="service-card-title">{{ label('数据库配置', 'Database configuration', '資料庫設定') }}</div>
                  </div>
                  <div class="service-card-actions">
                    <bilingual-action-button
                      variant="tonal"
                      compact
                      type="button"
                      :primary-label="label('重新读取配置', 'Reload config', '重新讀取設定')"
                      :secondary-label="'Reload config'"
                      :disabled="databaseConfigLoading || databaseConfigSaving"
                      @click="refreshDatabaseConfig"
                    ></bilingual-action-button>
                    <bilingual-action-button
                      variant="filled"
                      compact
                      type="button"
                      :primary-label="label('保存数据库连接', 'Save database DSN', '儲存資料庫連線')"
                      :secondary-label="'Save database DSN'"
                      :disabled="databaseConfigLoading || databaseConfigSaving"
                      @click="saveDatabaseConfig"
                    ></bilingual-action-button>
                  </div>
                </div>
                <div class="site-admin-meta-grid">
                  <div v-for="item in databaseCards" :key="item.key" class="site-admin-meta-card">
                    <div class="site-admin-meta-label">{{ item.label }}</div>
                    <div class="site-admin-meta-value">{{ item.value }}</div>
                  </div>
                </div>
                <pre v-if="databaseConfig?.masked_dsn || overview?.database?.masked_dsn" class="site-admin-pre">{{ databaseConfig?.masked_dsn || overview.database.masked_dsn }}</pre>
                <div class="site-admin-user-filter site-admin-user-filter-compact">
                  <textarea
                    v-model.trim="databaseConfigDraft"
                    class="post-textarea"
                    :placeholder="label('输入完整 DB_DSN，例如 host=localhost user=postgres password=postgres dbname=account_service port=5432 sslmode=disable', 'Enter the full DB_DSN, for example host=localhost user=postgres password=postgres dbname=account_service port=5432 sslmode=disable', '輸入完整 DB_DSN，例如 host=localhost user=postgres password=postgres dbname=account_service port=5432 sslmode=disable')"
                    :disabled="databaseConfigLoading || databaseConfigSaving"
                  ></textarea>
                </div>
                <div class="site-admin-generated">
                  {{ label('配置文件', 'Config file', '設定檔') }}: {{ databaseConfig?.source_path || '-' }}
                </div>
                <div class="site-admin-generated">
                  {{ label('保存后需要重启 account/admin/space/message/learning 服务，新连接才会被全部服务使用。', 'Restart account/admin/space/message/learning after saving so every service picks up the new connection.', '儲存後需要重啟 account/admin/space/message/learning 服務，新連線才會被全部服務使用。') }}
                </div>
              </section>

              <section class="site-admin-subsection">
                <div class="site-admin-subsection-head">
                  <div>
                    <div class="site-admin-kicker">{{ label('权限与状态', 'Access and status', '權限與狀態') }}</div>
                    <div class="service-card-title">{{ label('用户管理', 'User management', '使用者管理') }}</div>
                  </div>
                </div>
                <div class="site-admin-meta-grid">
                  <div class="site-admin-meta-card">
                    <div class="site-admin-meta-label">{{ label('活跃用户', 'Active users', '活躍使用者') }}</div>
                    <div class="site-admin-meta-value">{{ overview?.users?.active_users || 0 }}</div>
                  </div>
                  <div class="site-admin-meta-card">
                    <div class="site-admin-meta-label">{{ label('停用用户', 'Disabled users', '停用使用者') }}</div>
                    <div class="site-admin-meta-value">{{ overview?.users?.inactive_users || 0 }}</div>
                  </div>
                </div>
                <div class="site-admin-user-filter">
                  <input
                    v-model.trim="userFilter"
                    type="search"
                    :placeholder="label('输入昵称、邮箱、用户名或域名', 'Search by name, email, username, or domain', '輸入暱稱、郵箱、用戶名或網域')"
                  />
                </div>
                <div class="site-admin-user-list">
                  <div v-if="filteredUsers.length === 0" class="site-admin-generated">
                    {{ label('没有匹配的用户。', 'No matching users.', '沒有符合的使用者。') }}
                  </div>
                  <div v-for="user in filteredUsers" :key="user.id" class="site-admin-user-row">
                    <div class="site-admin-user-copy">
                      <div class="service-card-title">{{ user.display_name || user.id }}</div>
                      <div class="service-card-sub">{{ userSecondary(user) || user.id }}</div>
                    </div>
                    <div class="site-admin-user-controls">
                      <select :value="draftRole(user)" @change="roleDrafts[user.id] = $event.target.value">
                        <option value="member">member</option>
                        <option value="admin">admin</option>
                      </select>
                      <select :value="draftLevel(user)" @change="levelDrafts[user.id] = $event.target.value">
                        <option value="basic">basic</option>
                        <option value="premium">premium</option>
                        <option value="vip">vip</option>
                      </select>
                      <select :value="draftStatus(user)" @change="statusDrafts[user.id] = $event.target.value">
                        <option value="active">active</option>
                        <option value="disabled">disabled</option>
                      </select>
                      <bilingual-action-button
                        variant="filled"
                        compact
                        type="button"
                        :primary-label="label('保存用户', 'Save user', '儲存使用者')"
                        :secondary-label="'Save user'"
                        :disabled="saving"
                        @click="saveUser(user)"
                      ></bilingual-action-button>
                    </div>
                  </div>
                </div>
              </section>
            </div>
          </article>

          <article class="service-card site-admin-section site-admin-cluster">
            <div class="service-card-head">
              <div>
                <div class="service-card-title">{{ label('微服务工作台', 'Microservice workbench', '微服務工作台') }}</div>
                <div class="service-card-sub">{{ label('把所有微服务收成一组，先看整体状态，再按服务项展开设置弹层。', 'Keep microservices inside one grouped workbench: review the whole estate first, then open a settings sheet per service.', '把所有微服務收成一組，先看整體狀態，再按服務項展開設定彈層。') }}</div>
              </div>
            </div>

            <button type="button" class="site-admin-accordion" @click="toggleMicroservicesExpanded">
              <div class="site-admin-accordion-copy">
                <div class="site-admin-kicker">{{ label('分组折叠', 'Grouped fold', '分組折疊') }}</div>
                <div class="service-card-title">{{ label('微服务设置入口', 'Microservice settings', '微服務設定入口') }}</div>
                <div class="service-card-sub">{{ microservicesExpanded ? label('当前已展开，点击收起服务列表。', 'Expanded now. Click to collapse the service list.', '目前已展開，點擊收起服務列表。') : label('默认折叠，避免总控首页被服务细节淹没。', 'Collapsed by default so the main control page stays focused.', '預設折疊，避免總控首頁被服務細節淹沒。') }}</div>
              </div>
              <div class="site-admin-accordion-side">
                <div class="site-admin-summary-inline">
                  <div v-for="card in servicePanelSummaryCards" :key="card.key" class="site-admin-summary-pill">
                    <span>{{ card.label }}</span>
                    <strong>{{ card.value }}</strong>
                  </div>
                </div>
                <div class="site-admin-accordion-indicator" :class="{ 'site-admin-accordion-indicator-open': microservicesExpanded }">+</div>
              </div>
            </button>

            <div v-if="microservicesExpanded" class="site-admin-service-list site-admin-service-list-collapsed">
              <button v-for="service in serviceCards" :key="service.key" type="button" class="site-admin-service-row site-admin-service-row-button" @click="openServiceSettings(service)">
                <div class="site-admin-service-copy">
                  <div class="site-admin-service-headline">
                    <div class="service-card-title">{{ service.title }}</div>
                    <div class="service-status-badge" :class="{ 'service-status-badge-offline': !service.online }">{{ serviceOnlineLabel(service.online) }}</div>
                  </div>
                  <div class="service-card-sub">{{ serviceDescription(service) }}</div>
                  <div class="site-admin-generated">{{ service.base_url }}</div>
                </div>
                <div class="site-admin-service-tail">
                  <div class="site-admin-summary-pill">
                    <span>{{ label('探测耗时', 'Probe latency', '探測耗時') }}</span>
                    <strong>{{ (service.response_time_ms || 0) + 'ms' }}</strong>
                  </div>
                  <div class="site-admin-service-open">{{ label('打开设置', 'Open settings', '打開設定') }}</div>
                </div>
              </button>
            </div>
          </article>

          <article class="service-card site-admin-section site-admin-cluster">
            <div class="service-card-head">
              <div>
                <div class="service-card-title">{{ label('运行观察', 'Operations and runtime', '執行觀察') }}</div>
                <div class="service-card-sub">{{ label('把当前总控服务的运行态、生成时间和基础运行指标放到一组，便于巡检。', 'Keep runtime health, generation time, and system indicators together for quick operator review.', '把目前總控服務的執行態、產生時間與基礎指標放到一組，便於巡檢。') }}</div>
              </div>
            </div>
            <div class="site-admin-cluster-grid site-admin-cluster-grid-compact">
              <section class="site-admin-subsection">
                <div class="site-admin-subsection-head">
                  <div>
                    <div class="site-admin-kicker">{{ label('生成状态', 'Generated state', '產生狀態') }}</div>
                    <div class="service-card-title">{{ label('当前快照', 'Current snapshot', '目前快照') }}</div>
                  </div>
                </div>
                <div class="site-admin-generated">
                  {{ label('最近生成', 'Generated', '最近產生') }}: {{ overview?.generated_at ? app.formatDateTime(overview.generated_at) : '-' }}
                </div>
                <div class="site-admin-generated">
                  {{ label('在线服务摘要', 'Online service summary', '線上服務摘要') }}:
                  {{ onlineServices.length ? onlineServices.map((service) => service.title).join(' · ') : label('当前没有在线服务。', 'No online services right now.', '目前沒有線上服務。') }}
                </div>
              </section>

              <section class="site-admin-subsection">
                <div class="site-admin-subsection-head">
                  <div>
                    <div class="site-admin-kicker">{{ label('进程指标', 'Process metrics', '行程指標') }}</div>
                    <div class="service-card-title">{{ label('运行性能', 'Runtime performance', '執行效能') }}</div>
                  </div>
                </div>
                <div class="site-admin-meta-grid">
                  <div v-for="item in runtimeCards" :key="item.key" class="site-admin-meta-card">
                    <div class="site-admin-meta-label">{{ item.label }}</div>
                    <div class="site-admin-meta-value">{{ item.value }}</div>
                  </div>
                </div>
              </section>
            </div>
          </article>
        </div>

        <div v-if="serviceSettingsOpen && selectedService" class="modal-backdrop" @click.self="closeServiceSettings">
          <div class="modal site-admin-service-modal">
            <div class="modal-header">
              <div>
                <div class="space-toolbar-kicker">{{ label('微服务设置', 'Microservice settings', '微服務設定') }}</div>
                <div class="modal-title">{{ selectedService.title }}</div>
                <div class="site-admin-generated">{{ serviceDescription(selectedService) }}</div>
              </div>
              <button class="ghost compact" type="button" @click="closeServiceSettings">×</button>
            </div>

            <div class="site-admin-service-modal-summary">
              <div class="service-status-badge" :class="{ 'service-status-badge-offline': !selectedService.online }">{{ serviceOnlineLabel(selectedService.online) }}</div>
              <div class="site-admin-generated">{{ selectedService.base_url || '-' }}</div>
            </div>

            <div class="site-admin-meta-grid">
              <div v-for="item in selectedServiceCards" :key="selectedService.key + '-modal-' + item.key" class="site-admin-meta-card">
                <div class="site-admin-meta-label">{{ item.label }}</div>
                <div class="site-admin-meta-value">{{ item.value }}</div>
              </div>
            </div>

            <div class="modal-actions">
              <bilingual-action-button
                variant="tonal"
                compact
                type="button"
                :primary-label="label('刷新面板', 'Refresh panel', '重新整理面板')"
                :secondary-label="'Refresh panel'"
                :disabled="loading"
                @click="refreshOverview(true)"
              ></bilingual-action-button>
              <bilingual-action-button
                v-if="showSecondaryAction(selectedService)"
                variant="tonal"
                compact
                type="button"
                :primary-label="serviceSecondaryLabel(selectedService)"
                :secondary-label="serviceSecondaryLabel(selectedService)"
                :disabled="selectedService.key !== 'account' && !selectedService.online"
                @click="serviceSecondaryAction(selectedService)"
              ></bilingual-action-button>
              <bilingual-action-button
                variant="filled"
                compact
                type="button"
                :primary-label="servicePrimaryLabel(selectedService)"
                :secondary-label="servicePrimaryLabel(selectedService)"
                :disabled="selectedService.key !== 'account' && !selectedService.online"
                @click="servicePrimaryAction(selectedService)"
              ></bilingual-action-button>
            </div>
          </div>
        </div>
      </template>
    </section>
  `,
};
