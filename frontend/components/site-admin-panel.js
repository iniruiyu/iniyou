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
      userFilter: '',
      levelDrafts: {},
      statusDrafts: {},
    };
  },
  computed: {
    isAdmin() {
      return String(this.app?.user?.level || '').toLowerCase() === 'admin';
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
    offlineServices() {
      return this.serviceCards.filter((service) => !service.online);
    },
    databaseCards() {
      const database = this.overview?.database || {};
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
    draftLevel(user) {
      return this.levelDrafts[user.id] || user.level || 'basic';
    },
    draftStatus(user) {
      return this.statusDrafts[user.id] || user.status || 'active';
    },
    servicePrimaryAction(service) {
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
      } catch (error) {
        this.errorMessage = String(error?.message || error || '');
      } finally {
        this.loading = false;
      }
    },
    async saveUser(user) {
      const level = this.draftLevel(user);
      const status = this.draftStatus(user);
      if (level === user.level && status === user.status) {
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
          body: JSON.stringify({ level, status }),
        });
        const updated = await this.readPayload(response);
        const users = this.managedUsers.map((item) => (item.id === updated.id ? updated : item));
        const summary = { ...(this.overview?.summary || {}) };
        summary.admin_users = users.filter((item) => item.level === 'admin').length;
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

        <article v-if="!loading" class="service-card site-admin-section">
          <div class="service-card-head">
            <div>
              <div class="service-card-title">{{ label('待处理提醒', 'Attention queue', '待處理提醒') }}</div>
              <div class="service-card-sub">{{ label('优先显示当前离线服务和已停用用户，减少人工扫描成本。', 'Show offline services and disabled users first to reduce manual scanning.', '優先顯示目前離線服務與已停用使用者，減少人工掃描成本。') }}</div>
            </div>
          </div>
          <div class="site-admin-meta-grid">
            <div class="site-admin-meta-card">
              <div class="site-admin-meta-label">{{ label('离线服务', 'Offline services', '離線服務') }}</div>
              <div class="site-admin-meta-value">{{ offlineServices.length }}</div>
              <div class="site-admin-generated">{{ offlineServices.length ? offlineServices.map((service) => service.title).join(' · ') : label('当前没有离线服务。', 'No offline services right now.', '目前沒有離線服務。') }}</div>
              <div v-if="offlineServices.length" class="site-admin-action-chips">
                <button v-for="service in offlineServices" :key="service.key" type="button" @click="servicePrimaryAction(service)">{{ service.title }}</button>
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
        </article>

        <article v-if="!loading" class="service-card site-admin-section">
          <div class="service-card-head">
            <div>
              <div class="service-card-title">{{ label('微服务配置', 'Microservice configuration', '微服務設定') }}</div>
              <div class="service-card-sub">{{ label('查看各服务地址、健康状态、探测耗时与功能范围。', 'Review each service base URL, health, probe latency, and scope.', '查看各服務位址、健康狀態、探測耗時與功能範圍。') }}</div>
            </div>
          </div>
          <div class="site-admin-service-list">
            <div v-for="service in serviceCards" :key="service.key" class="site-admin-service-row">
              <div class="site-admin-service-copy">
                <div class="site-admin-service-headline">
                  <div class="service-card-title">{{ service.title }}</div>
                  <div class="service-status-badge" :class="{ 'service-status-badge-offline': !service.online }">{{ serviceOnlineLabel(service.online) }}</div>
                </div>
                <div class="site-admin-generated">{{ service.base_url }}</div>
                <div class="site-admin-meta-grid">
                  <div v-for="config in [{ key: label('探测耗时', 'Probe latency', '探測耗時'), value: (service.response_time_ms || 0) + 'ms' }, { key: label('必需服务', 'Required', '必要服務'), value: service.required ? 'true' : 'false' }, ...(service.config_items || []).map((item) => ({ key: item.key, value: item.value }))]" :key="service.key + '-' + config.key" class="site-admin-meta-card">
                    <div class="site-admin-meta-label">{{ config.key }}</div>
                    <div class="site-admin-meta-value">{{ config.value || '-' }}</div>
                  </div>
                </div>
              </div>
              <div class="service-card-actions">
                <bilingual-action-button
                  variant="filled"
                  compact
                  type="button"
                  :primary-label="servicePrimaryLabel(service)"
                  :secondary-label="servicePrimaryLabel(service)"
                  :disabled="service.key !== 'account' && !service.online"
                  @click="servicePrimaryAction(service)"
                ></bilingual-action-button>
              </div>
            </div>
          </div>
        </article>

        <article v-if="!loading" class="service-card site-admin-section">
          <div class="service-card-head">
            <div>
              <div class="service-card-title">{{ label('数据库配置', 'Database configuration', '資料庫設定') }}</div>
              <div class="service-card-sub">{{ label('展示当前聚合服务使用的数据库连接配置与连接池占用。', 'Show the database connection configuration and pool usage for the admin service.', '展示目前聚合服務使用的資料庫連線設定與連線池占用。') }}</div>
            </div>
          </div>
          <div class="site-admin-meta-grid">
            <div v-for="item in databaseCards" :key="item.key" class="site-admin-meta-card">
              <div class="site-admin-meta-label">{{ item.label }}</div>
              <div class="site-admin-meta-value">{{ item.value }}</div>
            </div>
          </div>
          <pre v-if="overview?.database?.masked_dsn" class="site-admin-pre">{{ overview.database.masked_dsn }}</pre>
        </article>

        <article v-if="!loading" class="service-card site-admin-section">
          <div class="service-card-head">
            <div>
              <div class="service-card-title">{{ label('运行性能', 'Runtime performance', '執行效能') }}</div>
              <div class="service-card-sub">{{ label('展示 admin-service 当前进程的运行时资源占用。', 'Show current runtime resource usage for the admin-service process.', '展示 admin-service 目前行程的執行時資源占用。') }}</div>
            </div>
          </div>
          <div class="site-admin-meta-grid">
            <div v-for="item in runtimeCards" :key="item.key" class="site-admin-meta-card">
              <div class="site-admin-meta-label">{{ item.label }}</div>
              <div class="site-admin-meta-value">{{ item.value }}</div>
            </div>
          </div>
        </article>

        <article v-if="!loading" class="service-card site-admin-section">
          <div class="service-card-head">
            <div>
              <div class="service-card-title">{{ label('用户管理', 'User management', '使用者管理') }}</div>
              <div class="service-card-sub">{{ label('直接调整最近注册用户的等级与状态，避免手工改数据库。', 'Adjust level and status for recent users directly without editing the database manually.', '直接調整最近註冊使用者的等級與狀態，避免手動修改資料庫。') }}</div>
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
                <select :value="draftLevel(user)" @change="levelDrafts[user.id] = $event.target.value">
                  <option value="basic">basic</option>
                  <option value="vip">vip</option>
                  <option value="admin">admin</option>
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
        </article>
      </template>
    </section>
  `,
};
