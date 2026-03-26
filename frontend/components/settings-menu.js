window.SettingsMenu = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  methods: {
    // Build bilingual option models for the compact settings menu.
    // 为紧凑设置菜单构建双语选项模型。
    languageSelectOptions() {
      return this.app.languageOptions.map((option) => ({
        value: option.code,
        label: `${option.name} (${option.code})`,
      }));
    },
    themeSelectOptions() {
      return this.app.themeOptions.map((theme) => ({
        value: theme.value,
        label: this.app.t(theme.labelKey),
      }));
    },
    directionSelectOptions() {
      return [
        {
          value: 'ltr',
          label: this.app.t('i18n.dirLtr'),
        },
        {
          value: 'rtl',
          label: this.app.t('i18n.dirRtl'),
        },
      ];
    },
  },
  // Compact layout for sidebar navigation.
  // 侧边栏导航的紧凑布局。
  template: `
    <div class="settings-menu" @click.stop>
      <button class="settings-trigger ghost" type="button" @click="app.toggleSettingsMenu()">
        <!-- Settings icon / 设置图标 -->
        <span class="settings-trigger-icon">SET</span>
        <span class="settings-trigger-text">
          <span class="settings-trigger-label">{{ app.t('settings.menu') }}</span>
          <span class="settings-trigger-meta">{{ app.getLanguageMeta(app.locale).name }}</span>
        </span>
      </button>
      <div v-if="app.settingsOpen" class="settings-dropdown">
        <div class="settings-header">
          <div class="settings-eyebrow">{{ app.t('settings.customize') }}</div>
          <div class="settings-title">{{ app.t('i18n.title') }}</div>
        </div>
        <!-- Split the panel into calm card-like sections / 将面板拆成更安静的卡片分区。 -->
        <section class="settings-section">
          <div class="settings-section-head">
            <div class="settings-section-title">{{ app.t('i18n.choose') }}</div>
          </div>
          <bilingual-select-field
            :primary-label="app.t('i18n.choose')"
            :secondary-label="app.peerLocaleText('i18n.choose')"
            v-model="app.locale"
            :options="languageSelectOptions()"
          ></bilingual-select-field>
        </section>
        <section class="settings-section">
          <div class="settings-section-head">
            <div class="settings-section-title">{{ app.t('theme.title') }}</div>
          </div>
          <bilingual-select-field
            :primary-label="app.t('theme.label')"
            :secondary-label="app.peerLocaleText('theme.label')"
            v-model="app.theme"
            :options="themeSelectOptions()"
            @change="app.applyTheme()"
          ></bilingual-select-field>
        </section>
        <!-- Keep the language creation form collapsed by default so the panel stays compact. -->
        <!-- 新增语言表单默认折叠，避免设置面板过长。 -->
        <details class="settings-section settings-section-collapsible">
          <summary class="settings-section-summary">
            <div class="settings-section-summary-copy">
              <div class="settings-section-title">{{ app.t('i18n.addTitle') }}</div>
              <div class="settings-section-note">{{ app.peerLocaleText('i18n.addTitle') }}</div>
            </div>
            <span class="settings-section-toggle" aria-hidden="true">+</span>
          </summary>
          <div class="settings-section-body">
            <div class="settings-form-grid">
              <input class="lang-input" type="text" :placeholder="app.t('i18n.codePlaceholder')" v-model="app.newLanguage.code" />
              <input class="lang-input" type="text" :placeholder="app.t('i18n.namePlaceholder')" v-model="app.newLanguage.name" />
              <bilingual-select-field
                :primary-label="app.t('i18n.dirLabel')"
                :secondary-label="app.peerLocaleText('i18n.dirLabel')"
                v-model="app.newLanguage.dir"
                :options="directionSelectOptions()"
              ></bilingual-select-field>
              <textarea class="lang-textarea" :placeholder="app.t('i18n.jsonPlaceholder')" v-model="app.newLanguage.json"></textarea>
            </div>
            <bilingual-action-button
              variant="primary"
              type="button"
              class="settings-action"
              :primary-label="app.t('i18n.addButton')"
              :secondary-label="app.peerLocaleText('i18n.addButton')"
              @click="app.addLanguage()"
            ></bilingual-action-button>
          </div>
        </details>
        <button class="settings-logout ghost danger" type="button" @click="app.closeSettingsMenu(); app.logout()">
          <span class="settings-logout-label">{{ app.t('auth.logout') }}</span>
          <span class="settings-logout-meta">{{ app.peerLocaleText('auth.logout') }}</span>
        </button>
      </div>
    </div>
  `,
};
