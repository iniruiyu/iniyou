function buildServiceSections(app) {
  // Build the service directory from the current microservice state.
  // 根据当前微服务状态构建服务目录。
  return [
    {
      key: 'account',
      online: true,
      title: app.t('services.accountTitle'),
      sub: app.t('services.accountSub'),
      actionKey: 'profile',
      actionLabel: app.t('services.open'),
      modules: [
        app.t('profile.identity.personalTitle'),
        app.t('profile.identity.contactTitle'),
        app.t('profile.identity.privacyTitle'),
        app.t('profile.membership.title'),
        app.t('profile.blockchain.title'),
      ],
    },
    {
      key: 'space',
      online: app.isServiceOnline('space'),
      title: app.t('services.spaceTitle'),
      sub: app.t('services.spaceSub'),
      actionKey: 'space',
      actionLabel: app.t('services.open'),
      modules: [
        app.t('spaces.workspaceTitle'),
        app.t('spaces.ownedTab'),
        app.t('spaces.createTab'),
        app.t('posts.publishAction'),
        app.t('posts.openDetail'),
      ],
    },
    {
      key: 'message',
      online: app.isServiceOnline('message'),
      title: app.t('services.messageTitle'),
      sub: app.t('services.messageSub'),
      actionKey: 'chat',
      actionLabel: app.t('services.open'),
      modules: [
        app.t('nav.friends'),
        app.t('nav.chat'),
        app.t('ws.unreadLabel'),
        app.t('chat.title'),
      ],
    },
  ];
}

window.ServiceNavigation = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  computed: {
    serviceSections() {
      return buildServiceSections(this.app);
    },
    visibleServiceSections() {
      return this.serviceSections.filter((section) => section.online);
    },
  },
  methods: {
    openServiceSection(serviceKey) {
      // Delegate navigation back to the root app so routing stays centralized.
      // 将跳转交回根应用，保证路由切换仍然集中收口。
      this.app.openServiceSection(serviceKey);
    },
    refreshServiceStatus() {
      // Refresh availability in the root app, then let the page rerender itself.
      // 刷新根应用中的可用性状态，再由页面自行重绘。
      this.app.refreshServiceStatus();
    },
  },
  // Standalone service directory page so the root app template stays slimmer.
  // 独立的服务目录页，让根应用模板更轻。
  template: `
    <section class="panel services-page">
      <div class="space-page-hero services-page-hero">
        <div>
          <div class="space-shell-kicker">{{ app.t('nav.services') }}</div>
          <div class="space-page-title">{{ app.t('services.title') }}</div>
          <div class="space-page-sub">{{ app.t('services.sub') }}</div>
        </div>
        <bilingual-action-button
          variant="tonal"
          compact
          type="button"
          :primary-label="app.t('services.refresh')"
          :secondary-label="app.peerLocaleText('services.refresh')"
          @click="refreshServiceStatus"
        ></bilingual-action-button>
      </div>
      <div class="services-grid">
        <article v-for="service in visibleServiceSections" :key="service.key" class="service-card">
          <div class="service-card-head">
            <div>
              <div class="service-card-title">{{ service.title }}</div>
              <div class="service-card-sub">{{ service.sub }}</div>
            </div>
            <div class="service-status-badge">{{ app.t('services.online') }}</div>
          </div>
          <div class="service-chip-list">
            <span v-for="module in service.modules" :key="service.key + '-' + module" class="service-chip">{{ module }}</span>
          </div>
          <div class="service-card-actions">
            <bilingual-action-button
              variant="filled"
              compact
              type="button"
              :primary-label="service.actionLabel"
              :secondary-label="app.peerLocaleText('services.open')"
              @click="openServiceSection(service.actionKey)"
            ></bilingual-action-button>
          </div>
        </article>
      </div>
    </section>
  `,
};
