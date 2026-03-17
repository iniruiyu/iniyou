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

      <header class="landing-topbar auth-topbar">
        <div class="brand landing-brand">
          <div class="brand-mark">AS</div>
          <div>
            <div class="brand-title">Account Space</div>
            <div class="brand-sub">{{ app.t('brandSub') }}</div>
          </div>
        </div>
        <settings-menu :app="app"></settings-menu>
      </header>

      <main class="landing-main auth-main">
        <div class="landing-auth-column landing-auth-only">
          <div v-if="app.flashMessage" class="banner banner-success">{{ app.flashMessage }}</div>
          <div v-if="app.errorMessage" class="banner banner-error">{{ app.errorMessage }}</div>
          <auth-panel :app="app"></auth-panel>
          <p class="landing-auth-note">Auth Flow 已保留。首页暂时仅提供登录与注册入口，其他主页展示内容后续补充。</p>
        </div>
      </main>
    </div>
  `,
};
