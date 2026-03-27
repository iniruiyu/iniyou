window.SettingsMenu = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      // Keep the floating panel hidden until we can measure the viewport and trigger.
      // 在完成视口与触发器测量前先隐藏浮层，避免弹层闪到错误位置。
      dropdownStyle: {
        top: '0px',
        left: '0px',
        right: 'auto',
        bottom: 'auto',
        visibility: 'hidden',
      },
      dropdownPlacement: 'down',
      viewportListenersBound: false,
    };
  },
  created() {
    // Bind stable handlers once so viewport listeners can be added and removed safely.
    // 先绑定稳定处理器，方便视口监听按需挂载和移除。
    this.boundViewportReposition = () => {
      if (!this.app.settingsOpen) {
        return;
      }
      this.positionDropdown();
    };
    this.boundEscapeKey = (event) => {
      if (event.key === 'Escape' && this.app.settingsOpen) {
        this.app.closeSettingsMenu();
      }
    };
  },
  mounted() {
    if (this.app.settingsOpen) {
      this.$nextTick(() => {
        if (!this.app.settingsOpen) {
          return;
        }
        this.positionDropdown();
        this.bindViewportListeners();
      });
    }
  },
  beforeUnmount() {
    this.unbindViewportListeners();
  },
  watch: {
    'app.settingsOpen'(open) {
      if (open) {
        this.$nextTick(() => {
          if (!this.app.settingsOpen) {
            return;
          }
          this.positionDropdown();
          this.bindViewportListeners();
        });
        return;
      }
      this.unbindViewportListeners();
      this.dropdownStyle = {
        top: '0px',
        left: '0px',
        right: 'auto',
        bottom: 'auto',
        visibility: 'hidden',
      };
      this.dropdownPlacement = 'down';
    },
    'app.locale'() {
      if (this.app.settingsOpen) {
        this.$nextTick(() => {
          if (this.app.settingsOpen) {
            this.positionDropdown();
          }
        });
      }
    },
    'app.theme'() {
      if (this.app.settingsOpen) {
        this.$nextTick(() => {
          if (this.app.settingsOpen) {
            this.positionDropdown();
          }
        });
      }
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
    toggleSettingsMenu() {
      this.app.toggleSettingsMenu();
    },
    bindViewportListeners() {
      if (this.viewportListenersBound || typeof window === 'undefined') {
        return;
      }
      window.addEventListener('resize', this.boundViewportReposition, { passive: true });
      window.addEventListener('scroll', this.boundViewportReposition, true);
      if (typeof document !== 'undefined') {
        document.addEventListener('keydown', this.boundEscapeKey);
      }
      this.viewportListenersBound = true;
    },
    unbindViewportListeners() {
      if (!this.viewportListenersBound) {
        return;
      }
      window.removeEventListener('resize', this.boundViewportReposition);
      window.removeEventListener('scroll', this.boundViewportReposition, true);
      if (typeof document !== 'undefined') {
        document.removeEventListener('keydown', this.boundEscapeKey);
      }
      this.viewportListenersBound = false;
    },
    positionDropdown() {
      const trigger = this.$refs.triggerButton;
      const panel = this.$refs.dropdownPanel;
      if (!trigger || !panel || typeof window === 'undefined') {
        return;
      }
      const viewportPadding = 12;
      const gap = 10;
      const triggerRect = trigger.getBoundingClientRect();
      const panelHeight = panel.scrollHeight || panel.offsetHeight || 0;
      const viewportWidth = window.innerWidth || document.documentElement.clientWidth || 0;
      const viewportHeight = window.innerHeight || document.documentElement.clientHeight || 0;
      const widthLimit = Math.max(0, viewportWidth - viewportPadding * 2);
      const width = Math.min(360, widthLimit);
      const maxLeft = Math.max(viewportPadding, viewportWidth - width - viewportPadding);
      const left = Math.min(Math.max(triggerRect.left, viewportPadding), maxLeft);
      const spaceBelow = viewportHeight - triggerRect.bottom - gap - viewportPadding;
      const spaceAbove = triggerRect.top - gap - viewportPadding;
      const openUpward = spaceBelow < panelHeight && spaceAbove > spaceBelow;
      const availableHeight = Math.max(0, openUpward ? spaceAbove : spaceBelow);
      const height = panelHeight > 0 ? Math.min(panelHeight, availableHeight) : availableHeight;
      const top = openUpward
        ? Math.max(viewportPadding, triggerRect.top - gap - height)
        : Math.min(triggerRect.bottom + gap, Math.max(viewportPadding, viewportHeight - viewportPadding - height));
      this.dropdownPlacement = openUpward ? 'up' : 'down';
      this.dropdownStyle = {
        position: 'fixed',
        top: `${Math.round(top)}px`,
        left: `${Math.round(left)}px`,
        right: 'auto',
        bottom: 'auto',
        width: `${Math.round(width)}px`,
        maxHeight: `${Math.round(availableHeight)}px`,
        visibility: 'visible',
      };
    },
  },
  // Viewport-aware settings menu for the main shell.
  // 视口感知的主壳层设置菜单。
  template: `
    <div class="settings-menu" @click.stop>
      <button
        ref="triggerButton"
        class="settings-trigger ghost"
        type="button"
        :aria-expanded="app.settingsOpen ? 'true' : 'false'"
        @click="toggleSettingsMenu"
      >
        <!-- Settings icon / 设置图标 -->
        <span class="settings-trigger-icon">SET</span>
        <span class="settings-trigger-text">
          <span class="settings-trigger-label">{{ app.t('settings.menu') }}</span>
          <span class="settings-trigger-meta">{{ app.getLanguageMeta(app.locale).name }}</span>
        </span>
      </button>
      <teleport to="body">
        <!-- Render the panel outside the sidebar so overflow cannot clip it. -->
        <!-- 将面板渲染到侧栏外部，避免被 overflow 裁切。 -->
        <div
          v-if="app.settingsOpen"
          ref="dropdownPanel"
          class="settings-dropdown settings-dropdown--floating"
          :class="{ 'settings-dropdown--up': dropdownPlacement === 'up' }"
          :style="dropdownStyle"
          @click.stop
        >
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
      </teleport>
    </div>
  `,
};
