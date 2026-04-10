window.LandingPage = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  // Use landing shell layout for auth-only view.
  // 认证页沿用 landing-shell 布局。
  template: `
    <div class="landing-shell auth-shell">
      <div class="landing-backdrop landing-backdrop-one"></div>
      <div class="landing-backdrop landing-backdrop-two"></div>
      <div class="landing-backdrop landing-backdrop-three"></div>

      <header class="landing-topbar auth-topbar">
        <div class="brand landing-brand">
          <div class="brand-mark" aria-hidden="true">
            <span class="brand-mark-ring"></span>
            <span class="brand-mark-dot brand-mark-dot-primary"></span>
            <span class="brand-mark-dot brand-mark-dot-accent"></span>
          </div>
          <div class="landing-brand-copy">
            <div class="brand-title">iniyou</div>
          </div>
        </div>
        <settings-menu :app="app" class="landing-settings-menu"></settings-menu>
      </header>

      <main class="landing-main auth-main">
        <aside class="landing-auth-column">
          <div v-if="app.flashMessage" class="banner banner-success">{{ app.flashMessage }}</div>
          <div v-if="app.errorMessage" class="banner banner-error">{{ app.errorMessage }}</div>
          <div class="landing-auth-stack">
            <div class="landing-auth-panel-head">
              <div class="landing-auth-kicker">{{ app.t('landing.authEyebrow') }}</div>
              <div class="landing-auth-title">{{ app.authMode === 'login' ? app.t('auth.welcomeTitle') : app.t('auth.createTitle') }}</div>
              <div class="landing-auth-summary">{{ app.authMode === 'login' ? app.t('auth.welcomeSub') : app.t('auth.createSub') }}</div>
            </div>
            <auth-panel :app="app"></auth-panel>
          </div>
        </aside>
      </main>
    </div>
  `,
};
