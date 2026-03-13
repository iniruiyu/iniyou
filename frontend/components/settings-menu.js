window.SettingsMenu = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  template: `
    <div class="settings-menu" @click.stop>
      <button class="settings-trigger ghost" type="button" @click="app.toggleSettingsMenu()">
        <span class="settings-trigger-label">{{ app.t('settings.menu') }}</span>
        <span class="settings-trigger-meta">{{ app.getLanguageMeta(app.locale).name }}</span>
      </button>
      <div v-if="app.settingsOpen" class="settings-dropdown">
        <div class="settings-header">
          <div class="settings-eyebrow">{{ app.t('settings.customize') }}</div>
          <div class="settings-title">{{ app.t('i18n.title') }}</div>
        </div>
        <label class="lang-label">{{ app.t('i18n.choose') }}</label>
        <select class="lang-select" v-model="app.locale">
          <option v-for="option in app.languageOptions" :key="option.code" :value="option.code">
            {{ option.name }} ({{ option.code }})
          </option>
        </select>
        <div class="lang-add-title">{{ app.t('i18n.addTitle') }}</div>
        <input class="lang-input" type="text" :placeholder="app.t('i18n.codePlaceholder')" v-model="app.newLanguage.code" />
        <input class="lang-input" type="text" :placeholder="app.t('i18n.namePlaceholder')" v-model="app.newLanguage.name" />
        <label class="lang-label">{{ app.t('i18n.dirLabel') }}</label>
        <select class="lang-select" v-model="app.newLanguage.dir">
          <option value="ltr">{{ app.t('i18n.dirLtr') }}</option>
          <option value="rtl">{{ app.t('i18n.dirRtl') }}</option>
        </select>
        <textarea class="lang-textarea" :placeholder="app.t('i18n.jsonPlaceholder')" v-model="app.newLanguage.json"></textarea>
        <button class="primary settings-action" type="button" @click="app.addLanguage()">{{ app.t('i18n.addButton') }}</button>
      </div>
    </div>
  `,
};
