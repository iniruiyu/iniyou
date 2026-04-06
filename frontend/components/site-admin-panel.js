window.SiteAdminPanel = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isAdmin() {
      return String(this.app?.user?.level || '').toLowerCase() === 'admin';
    },
    overview() {
      return this.app?.adminOverview && typeof this.app.adminOverview === 'object'
        ? this.app.adminOverview
        : null;
    },
    totalServices() {
      return Number(this.overview?.total_services ?? this.overview?.totalServices ?? 5);
    },
    onlineServices() {
      return Number(
        this.overview?.online_services ??
          this.overview?.onlineServices ??
          (1 +
            (this.app.isServiceOnline('admin') ? 1 : 0) +
            (this.app.isServiceOnline('space') ? 1 : 0) +
            (this.app.isServiceOnline('message') ? 1 : 0) +
            (this.app.isServiceOnline('learning') ? 1 : 0)),
      );
    },
    offlineServices() {
      return Number(
        this.overview?.offline_services ??
          this.overview?.offlineServices ??
          (this.totalServices - this.onlineServices),
      );
    },
    adminWorkspaces() {
      return Number(
        this.overview?.admin_workspaces ??
          this.overview?.adminWorkspaces ??
          (1 + (this.app.isServiceOnline('learning') ? 1 : 0)),
      );
    },
    checkedAtText() {
      const raw = String(this.overview?.checked_at ?? this.overview?.checkedAt ?? '').trim();
      if (!raw) {
        return '';
      }
      const parsed = new Date(raw);
      if (Number.isNaN(parsed.getTime())) {
        return raw;
      }
      return parsed.toLocaleString();
    },
    isDegraded() {
      return this.overview?.degraded === true;
    },
    serviceCards() {
      const managementLabel = this.app?.locale === 'en-US'
        ? 'Admin console'
        : this.app?.locale === 'zh-TW'
          ? '管理控制頁'
          : '管理控制页';
      const metadata = {
        admin: {
          title: this.app.t('services.adminPanelTitle'),
          sub: this.app.t('adminPanel.adminSub'),
          actionKey: 'admin-panel',
          actionLabel: this.app.t('services.open'),
        },
        account: {
          title: this.app.t('services.accountTitle'),
          sub: this.app.t('adminPanel.accountSub'),
          actionKey: 'profile',
          actionLabel: this.app.t('adminPanel.openProfile'),
          secondaryActionKey: 'account-admin',
          secondaryActionLabel: managementLabel,
        },
        space: {
          title: this.app.t('services.spaceTitle'),
          sub: this.app.t('adminPanel.spaceSub'),
          actionKey: 'space',
          actionLabel: this.app.t('adminPanel.openSpace'),
          secondaryActionKey: 'space-admin',
          secondaryActionLabel: managementLabel,
        },
        message: {
          title: this.app.t('services.messageTitle'),
          sub: this.app.t('adminPanel.messageSub'),
          actionKey: 'chat',
          actionLabel: this.app.t('adminPanel.openChat'),
          secondaryActionKey: 'message-admin',
          secondaryActionLabel: managementLabel,
        },
        learning: {
          title: this.app.t('services.learningTitle'),
          sub: this.app.t('adminPanel.learningSub'),
          actionKey: 'learning',
          actionLabel: this.app.t('adminPanel.openLearning'),
          secondaryActionKey: 'learning-admin',
          secondaryActionLabel: this.app.t('services.learningAdminTitle'),
        },
      };
      const overviewServices = Array.isArray(this.overview?.services) ? this.overview.services : [];
      if (overviewServices.length) {
        return overviewServices.map((service) => {
          const key = String(service?.key || '').trim();
          const meta = metadata[key] || {};
          const workspaceKey = String(service?.workspace_key ?? service?.workspaceKey ?? '').trim();
          return {
            key,
            title: meta.title || service?.title || key,
            sub: meta.sub || service?.title || '',
            online: service?.online === true,
            required: service?.required === true,
            actionKey: meta.actionKey || '',
            actionLabel: meta.actionLabel || this.app.t('services.open'),
            secondaryActionKey: key === 'admin'
              ? ''
              : String(meta.secondaryActionKey ?? workspaceKey).trim(),
            secondaryActionLabel: meta.secondaryActionLabel || '',
            baseUrl: String(service?.base_url ?? service?.baseUrl ?? '').trim(),
            latencyMs: Number(service?.latency_ms ?? service?.latencyMs ?? 0),
          };
        });
      }
      return [
        {
          key: 'admin',
          title: metadata.admin.title,
          sub: metadata.admin.sub,
          online: this.app.isServiceOnline('admin'),
          required: true,
          actionKey: metadata.admin.actionKey,
          actionLabel: metadata.admin.actionLabel,
          baseUrl: this.app.adminApiBase,
          latencyMs: 0,
        },
        {
          key: 'account',
          title: metadata.account.title,
          sub: metadata.account.sub,
          online: true,
          required: true,
          actionKey: metadata.account.actionKey,
          actionLabel: metadata.account.actionLabel,
          secondaryActionKey: metadata.account.secondaryActionKey,
          secondaryActionLabel: metadata.account.secondaryActionLabel,
          baseUrl: this.app.apiBase,
          latencyMs: 0,
        },
        {
          key: 'space',
          title: metadata.space.title,
          sub: metadata.space.sub,
          online: this.app.isServiceOnline('space'),
          required: false,
          actionKey: metadata.space.actionKey,
          actionLabel: metadata.space.actionLabel,
          secondaryActionKey: metadata.space.secondaryActionKey,
          secondaryActionLabel: metadata.space.secondaryActionLabel,
          baseUrl: this.app.spaceApiBase,
          latencyMs: 0,
        },
        {
          key: 'message',
          title: metadata.message.title,
          sub: metadata.message.sub,
          online: this.app.isServiceOnline('message'),
          required: false,
          actionKey: metadata.message.actionKey,
          actionLabel: metadata.message.actionLabel,
          secondaryActionKey: metadata.message.secondaryActionKey,
          secondaryActionLabel: metadata.message.secondaryActionLabel,
          baseUrl: this.app.messageApiBase,
          latencyMs: 0,
        },
        {
          key: 'learning',
          title: metadata.learning.title,
          sub: metadata.learning.sub,
          online: this.app.isServiceOnline('learning'),
          required: false,
          actionKey: metadata.learning.actionKey,
          actionLabel: metadata.learning.actionLabel,
          secondaryActionKey: metadata.learning.secondaryActionKey,
          secondaryActionLabel: metadata.learning.secondaryActionLabel,
          baseUrl: this.app.learningApiBase,
          latencyMs: 0,
        },
      ];
    },
  },
  methods: {
    openServiceSection(serviceKey) {
      this.app.openServiceSection(serviceKey);
    },
    refreshServiceStatus() {
      this.app.refreshServiceStatus();
    },
    serviceMetaText(service) {
      const parts = [
        service.online ? this.app.t('adminPanel.statusHealthy') : this.app.t('adminPanel.statusOffline'),
      ];
      if (service.required) {
        parts.push('Required');
      }
      if (service.latencyMs > 0) {
        parts.push(`${service.latencyMs} ms`);
      }
      if (service.baseUrl) {
        parts.push(service.baseUrl);
      }
      return parts.join(' · ');
    },
  },
  template: `
    <section class="panel services-page site-admin-page">
      <div class="space-page-hero services-page-hero">
        <div>
          <div class="space-shell-kicker">{{ app.t('nav.admin-panel') }}</div>
          <div class="space-page-title">{{ app.t('adminPanel.title') }}</div>
          <div class="space-page-sub">{{ app.t('adminPanel.sub') }}</div>
        </div>
        <div class="site-admin-actions">
          <bilingual-action-button
            variant="tonal"
            compact
            type="button"
            :primary-label="app.t('nav.services')"
            :secondary-label="app.peerLocaleText('nav.services')"
            @click="openServiceSection('services')"
          ></bilingual-action-button>
          <bilingual-action-button
            variant="filled"
            compact
            type="button"
            :primary-label="app.t('services.refresh')"
            :secondary-label="app.peerLocaleText('services.refresh')"
            @click="refreshServiceStatus"
          ></bilingual-action-button>
        </div>
      </div>

      <div v-if="!isAdmin" class="learning-admin-files">
        <div class="learning-admin-files-head">
          <div>
            <div class="service-card-title">{{ app.t('adminPanel.accessTitle') }}</div>
            <div class="service-card-sub">{{ app.t('adminPanel.accessSub') }}</div>
          </div>
        </div>
      </div>

      <template v-else>
        <div class="site-admin-summary">
          <article class="site-admin-stat">
            <div class="site-admin-stat-label">{{ app.t('adminPanel.totalServices') }}</div>
            <div class="site-admin-stat-value">{{ totalServices }}</div>
          </article>
          <article class="site-admin-stat">
            <div class="site-admin-stat-label">{{ app.t('adminPanel.onlineServices') }}</div>
            <div class="site-admin-stat-value">{{ onlineServices }}</div>
          </article>
          <article class="site-admin-stat">
            <div class="site-admin-stat-label">{{ app.t('adminPanel.offlineServices') }}</div>
            <div class="site-admin-stat-value">{{ offlineServices }}</div>
          </article>
          <article class="site-admin-stat">
            <div class="site-admin-stat-label">{{ app.t('adminPanel.adminWorkspaces') }}</div>
            <div class="site-admin-stat-value">{{ adminWorkspaces }}</div>
          </article>
        </div>

        <div v-if="app.adminOverviewLoading || app.adminOverviewError || checkedAtText" class="learning-admin-files">
          <div class="learning-admin-files-head">
            <div class="service-card-title">{{ app.t('services.adminPanelTitle') }}</div>
            <div class="service-card-sub">
              <span v-if="app.adminOverviewLoading">Loading live overview...</span>
              <span v-else-if="app.adminOverviewError">{{ app.adminOverviewError }}</span>
              <span v-else-if="checkedAtText">
                {{ checkedAtText }}<span v-if="isDegraded"> · degraded</span>
              </span>
            </div>
          </div>
        </div>

        <div class="site-admin-grid">
          <article v-for="service in serviceCards" :key="service.key" class="service-card site-admin-card">
            <div class="service-card-head">
              <div>
                <div class="service-card-title">{{ service.title }}</div>
                <div class="service-card-sub">{{ service.sub }}</div>
              </div>
              <div class="service-status-badge" :class="{ 'service-status-badge-offline': !service.online }">
                {{ service.online ? app.t('services.online') : app.t('services.offline') }}
              </div>
            </div>
            <div class="site-admin-meta">
              {{ serviceMetaText(service) }}
            </div>
            <div class="service-card-actions">
              <bilingual-action-button
                v-if="service.secondaryActionKey && service.online"
                variant="tonal"
                compact
                type="button"
                :primary-label="service.secondaryActionLabel"
                :secondary-label="service.secondaryActionLabel"
                @click="openServiceSection(service.secondaryActionKey)"
              ></bilingual-action-button>
              <bilingual-action-button
                variant="filled"
                compact
                type="button"
                :primary-label="service.actionLabel"
                :secondary-label="service.actionLabel"
                :disabled="!service.online"
                @click="openServiceSection(service.actionKey)"
              ></bilingual-action-button>
            </div>
          </article>
        </div>
      </template>
    </section>
  `,
};
