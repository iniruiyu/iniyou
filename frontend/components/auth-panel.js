window.AuthPanel = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  template: `
    <section class="auth-card panel">
      <div class="auth-card-head">
        <div class="auth-eyebrow">{{ app.t('landing.authEyebrow') }}</div>
        <h2>{{ app.authMode === 'login' ? app.t('auth.welcomeTitle') : app.t('auth.createTitle') }}</h2>
        <p>{{ app.authMode === 'login' ? app.t('auth.welcomeSub') : app.t('auth.createSub') }}</p>
      </div>

      <div class="auth-toggle">
        <button
          class="auth-toggle-item"
          :class="{ active: app.authMode === 'login' }"
          type="button"
          @click="app.setAuthMode('login')"
        >
          {{ app.t('auth.login') }}
        </button>
        <button
          class="auth-toggle-item"
          :class="{ active: app.authMode === 'register' }"
          type="button"
          @click="app.setAuthMode('register')"
        >
          {{ app.t('auth.register') }}
        </button>
      </div>

      <form v-if="app.authMode === 'login'" class="form auth-form">
        <input type="text" :placeholder="app.t('auth.accountPlaceholder')" v-model="app.auth.account" />
        <input type="password" :placeholder="app.t('auth.passwordPlaceholder')" v-model="app.auth.password" />
        <button class="primary" type="button" @click="app.login()">{{ app.t('auth.login') }}</button>
      </form>

      <form v-else class="form auth-form">
        <input type="text" :placeholder="app.t('auth.emailPlaceholder')" v-model="app.auth.email" />
        <input type="text" :placeholder="app.t('auth.phonePlaceholder')" v-model="app.auth.phone" />
        <input type="password" :placeholder="app.t('auth.passwordPlaceholder')" v-model="app.auth.password" />
        <button class="primary" type="button" @click="app.register()">{{ app.t('auth.register') }}</button>
      </form>

      <div class="auth-footnote">
        {{ app.authMode === 'login' ? app.t('landing.loginHint') : app.t('landing.registerHint') }}
      </div>
    </section>
  `,
};
