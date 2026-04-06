const MICROserviceAdminConsoleCopy = {
  'zh-CN': {
    back: '返回总控',
    openService: '打开服务页',
    refresh: '刷新状态',
    healthy: '在线',
    offline: '离线',
    required: '必需服务',
    unavailable: '当前微服务离线，管理控制入口已暂时停用。',
    sectionsTitle: '管理控制项',
    detailsTitle: '服务状态',
  },
  'en-US': {
    back: 'Back to admin',
    openService: 'Open service',
    refresh: 'Refresh status',
    healthy: 'Online',
    offline: 'Offline',
    required: 'Required service',
    unavailable: 'This microservice is currently offline, so its management console is temporarily unavailable.',
    sectionsTitle: 'Management modules',
    detailsTitle: 'Service status',
  },
  'zh-TW': {
    back: '返回總控',
    openService: '打開服務頁',
    refresh: '重新整理狀態',
    healthy: '線上',
    offline: '離線',
    required: '必需服務',
    unavailable: '目前微服務離線，管理控制入口已暫時停用。',
    sectionsTitle: '管理控制項',
    detailsTitle: '服務狀態',
  },
};

const MICROSERVICE_ADMIN_METADATA = {
  'account-admin': {
    serviceKey: 'account',
    serviceOpenKey: 'profile',
    title: {
      'zh-CN': '账号服务管理控制页',
      'en-US': 'Account service admin console',
      'zh-TW': '帳號服務管理控制頁',
    },
    sub: {
      'zh-CN': '集中查看身份资料、隐私字段、会员等级与链上绑定的管理入口。',
      'en-US': 'Review the shared management entry points for identity data, privacy fields, membership, and chain bindings.',
      'zh-TW': '集中查看身份資料、隱私欄位、會員等級與鏈上綁定的管理入口。',
    },
    modules: {
      'zh-CN': ['身份资料', '联系信息', '隐私可见性', '会员等级', '链上绑定'],
      'en-US': ['Identity profile', 'Contact details', 'Privacy visibility', 'Membership levels', 'Chain bindings'],
      'zh-TW': ['身份資料', '聯絡資訊', '隱私可見性', '會員等級', '鏈上綁定'],
    },
  },
  'space-admin': {
    serviceKey: 'space',
    serviceOpenKey: 'space',
    title: {
      'zh-CN': '空间服务管理控制页',
      'en-US': 'Space service admin console',
      'zh-TW': '空間服務管理控制頁',
    },
    sub: {
      'zh-CN': '统一进入空间工作台、内容发布链路和帖子上下文的运维入口。',
      'en-US': 'Open the shared operations entry for the workspace, publishing flow, and post context.',
      'zh-TW': '統一進入空間工作台、內容發布鏈路與貼文上下文的運維入口。',
    },
    modules: {
      'zh-CN': ['空间工作台', '空间列表', '帖子发布', '帖子详情', '媒体内容'],
      'en-US': ['Workspace', 'Space list', 'Post publishing', 'Post detail', 'Media content'],
      'zh-TW': ['空間工作台', '空間列表', '貼文發布', '貼文詳情', '媒體內容'],
    },
  },
  'message-admin': {
    serviceKey: 'message',
    serviceOpenKey: 'chat',
    title: {
      'zh-CN': '消息服务管理控制页',
      'en-US': 'Message service admin console',
      'zh-TW': '訊息服務管理控制頁',
    },
    sub: {
      'zh-CN': '集中查看好友关系、会话摘要、未读消息和实时通信入口。',
      'en-US': 'Review the management entry points for friendships, conversation summaries, unread status, and realtime messaging.',
      'zh-TW': '集中查看好友關係、會話摘要、未讀訊息與即時通信入口。',
    },
    modules: {
      'zh-CN': ['好友关系', '会话摘要', '未读计数', '聊天面板', '实时连接'],
      'en-US': ['Friendships', 'Conversation summaries', 'Unread counts', 'Chat panel', 'Realtime connection'],
      'zh-TW': ['好友關係', '會話摘要', '未讀計數', '聊天面板', '即時連線'],
    },
  },
};

function localizedAdminConsoleText(app, key) {
  const locale = app?.locale || 'zh-CN';
  return MICROserviceAdminConsoleCopy[locale]?.[key] || MICROserviceAdminConsoleCopy['zh-CN'][key] || '';
}

window.MicroserviceAdminConsole = {
  props: {
    app: { type: Object, required: true },
    workspaceKey: { type: String, required: true },
  },
  computed: {
    metadata() {
      return MICROSERVICE_ADMIN_METADATA[this.workspaceKey] || null;
    },
    serviceStatus() {
      const items = Array.isArray(this.app?.adminOverview?.services) ? this.app.adminOverview.services : [];
      return items.find((item) => item?.workspace_key === this.workspaceKey || item?.workspaceKey === this.workspaceKey || item?.key === this.metadata?.serviceKey) || null;
    },
    title() {
      return this.metadata?.title?.[this.app.locale] || this.metadata?.title?.['zh-CN'] || '';
    },
    sub() {
      return this.metadata?.sub?.[this.app.locale] || this.metadata?.sub?.['zh-CN'] || '';
    },
    modules() {
      return this.metadata?.modules?.[this.app.locale] || this.metadata?.modules?.['zh-CN'] || [];
    },
    online() {
      return this.serviceStatus?.online === true || this.app.isServiceOnline(this.metadata?.serviceKey);
    },
    metaParts() {
      const parts = [];
      parts.push(this.online ? localizedAdminConsoleText(this.app, 'healthy') : localizedAdminConsoleText(this.app, 'offline'));
      if (this.serviceStatus?.required === true) {
        parts.push(localizedAdminConsoleText(this.app, 'required'));
      }
      const latency = Number(this.serviceStatus?.latency_ms ?? this.serviceStatus?.latencyMs ?? 0);
      if (latency > 0) {
        parts.push(`${latency} ms`);
      }
      const baseUrl = String(this.serviceStatus?.base_url ?? this.serviceStatus?.baseUrl ?? '').trim();
      if (baseUrl) {
        parts.push(baseUrl);
      }
      return parts;
    },
  },
  methods: {
    text(key) {
      return localizedAdminConsoleText(this.app, key);
    },
    openService() {
      if (this.metadata?.serviceOpenKey) {
        this.app.openServiceSection(this.metadata.serviceOpenKey);
      }
    },
    backToAdmin() {
      this.app.openServiceSection('admin-panel');
    },
  },
  template: `
    <section class="panel services-page site-admin-page" v-if="metadata">
      <div class="space-page-hero services-page-hero">
        <div>
          <div class="space-shell-kicker">{{ app.t('nav.admin-panel') }}</div>
          <div class="space-page-title">{{ title }}</div>
          <div class="space-page-sub">{{ sub }}</div>
        </div>
        <div class="site-admin-actions">
          <bilingual-action-button
            variant="tonal"
            compact
            type="button"
            :primary-label="text('back')"
            :secondary-label="text('back')"
            @click="backToAdmin"
          ></bilingual-action-button>
          <bilingual-action-button
            variant="filled"
            compact
            type="button"
            :primary-label="text('openService')"
            :secondary-label="text('openService')"
            :disabled="!online"
            @click="openService"
          ></bilingual-action-button>
        </div>
      </div>

      <div class="site-admin-summary">
        <article class="site-admin-stat">
          <div class="site-admin-stat-label">{{ text('detailsTitle') }}</div>
          <div class="site-admin-stat-value">{{ online ? text('healthy') : text('offline') }}</div>
        </article>
      </div>

      <div class="learning-admin-files">
        <div class="learning-admin-files-head">
          <div class="service-card-title">{{ text('sectionsTitle') }}</div>
          <div class="service-card-sub">{{ metaParts.join(' · ') }}</div>
        </div>
        <div v-if="!online" class="service-card-sub">{{ text('unavailable') }}</div>
        <div v-else class="service-chip-list">
          <span v-for="module in modules" :key="workspaceKey + '-' + module" class="service-chip">{{ module }}</span>
        </div>
      </div>
    </section>
  `,
};
