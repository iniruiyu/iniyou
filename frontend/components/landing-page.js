window.LandingPage = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  template: `
    <div class="auth-shell">
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
        <section class="landing-hero auth-hero">
          <div class="landing-copy auth-copy">
            <div class="hero-pill">{{ app.t('landing.heroPill') }}</div>
            <h1>{{ app.t('landing.heroTitle') }}</h1>
            <p class="landing-subtitle">{{ app.t('landing.heroSub') }}</p>

            <div class="landing-stats auth-stats">
              <div class="landing-stat">
                <strong>01</strong>
                <span>{{ app.t('landing.statStepOne') }}</span>
              </div>
              <div class="landing-stat">
                <strong>02</strong>
                <span>{{ app.t('landing.statStepTwo') }}</span>
              </div>
              <div class="landing-stat">
                <strong>03</strong>
                <span>{{ app.t('landing.statStepThree') }}</span>
              </div>
            </div>
          </div>

          <div class="landing-showcase auth-showcase">
            <article class="showcase-card showcase-card-main">
              <div class="showcase-label">{{ app.t('landing.previewLabel') }}</div>
              <h3>{{ app.t('landing.previewTitle') }}</h3>
              <p>{{ app.t('landing.previewSub') }}</p>
              <div class="feature-strip compact">
                <article class="feature-card">
                  <div class="feature-index">01</div>
                  <h3>{{ app.t('landing.featurePrivateTitle') }}</h3>
                  <p>{{ app.t('landing.featurePrivateSub') }}</p>
                </article>
                <article class="feature-card">
                  <div class="feature-index">02</div>
                  <h3>{{ app.t('landing.featurePublicTitle') }}</h3>
                  <p>{{ app.t('landing.featurePublicSub') }}</p>
                </article>
                <article class="feature-card">
                  <div class="feature-index">03</div>
                  <h3>{{ app.t('landing.featureLiveTitle') }}</h3>
                  <p>{{ app.t('landing.featureLiveSub') }}</p>
                </article>
              </div>
            </article>
          </div>
        </section>

        <div class="landing-auth-column">
          <div v-if="app.flashMessage" class="banner banner-success">{{ app.flashMessage }}</div>
          <div v-if="app.errorMessage" class="banner banner-error">{{ app.errorMessage }}</div>
          <auth-panel :app="app"></auth-panel>
        </div>
      </main>
    </div>
  `,
};
