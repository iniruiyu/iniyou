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
    totalServices() {
      return 5;
    },
    onlineServices() {
      return 1 + (this.app.isServiceOnline('admin') ? 1 : 0) + (this.app.isServiceOnline('space') ? 1 : 0) + (this.app.isServiceOnline('message') ? 1 : 0) + (this.app.isServiceOnline('learning') ? 1 : 0);
    },
    offlineServices() {
      return this.totalServices - this.onlineServices;
    },
    adminWorkspaces() {
      return 1 + (this.app.isServiceOnline('learning') ? 1 : 0);
    },
    serviceCards() {
      return [
        {
          key: 'admin',
          title: this.app.t('services.adminPanelTitle'),
          sub: this.app.t('adminPanel.adminSub'),
          online: this.app.isServiceOnline('admin'),
          actionKey: 'admin-panel',
          actionLabel: this.app.t('services.open'),
        },
        {
          key: 'account',
          title: this.app.t('services.accountTitle'),
          sub: this.app.t('adminPanel.accountSub'),
          online: true,
          actionKey: 'profile',
          actionLabel: this.app.t('adminPanel.openProfile'),
        },
        {
          key: 'space',
          title: this.app.t('services.spaceTitle'),
          sub: this.app.t('adminPanel.spaceSub'),
          online: this.app.isServiceOnline('space'),
          actionKey: 'space',
          actionLabel: this.app.t('adminPanel.openSpace'),
        },
        {
          key: 'message',
          title: this.app.t('services.messageTitle'),
          sub: this.app.t('adminPanel.messageSub'),
          online: this.app.isServiceOnline('message'),
          actionKey: 'chat',
          actionLabel: this.app.t('adminPanel.openChat'),
        },
        {
          key: 'learning',
          title: this.app.t('services.learningTitle'),
          sub: this.app.t('adminPanel.learningSub'),
          online: this.app.isServiceOnline('learning'),
          actionKey: 'learning',
          actionLabel: this.app.t('adminPanel.openLearning'),
          secondaryActionKey: 'learning-admin',
          secondaryActionLabel: this.app.t('services.learningAdminTitle'),
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
              {{ service.online ? app.t('adminPanel.statusHealthy') : app.t('adminPanel.statusOffline') }}
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
