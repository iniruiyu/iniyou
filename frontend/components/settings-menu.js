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
      // Track scroll progress so the panel can show a small progress bar.
      // 记录面板滚动进度，便于显示更明确的进度条反馈。
      panelScrollProgress: 0,
      viewportListenersBound: false,
      themeWorkbenchOpen: false,
      customThemeOpen: false,
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
        if (this.app.theme === 'custom') {
          this.themeWorkbenchOpen = true;
          this.customThemeOpen = true;
        }
        this.$nextTick(() => {
          if (!this.app.settingsOpen) {
            return;
          }
          this.positionDropdown();
          this.updatePanelScrollProgress();
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
      this.panelScrollProgress = 0;
      this.themeWorkbenchOpen = false;
      this.customThemeOpen = false;
    },
    'app.locale'() {
      if (this.app.settingsOpen) {
        this.$nextTick(() => {
          if (this.app.settingsOpen) {
            this.positionDropdown();
            this.updatePanelScrollProgress();
          }
        });
      }
    },
    'app.theme'() {
      if (this.app.theme === 'custom') {
        this.themeWorkbenchOpen = true;
        this.customThemeOpen = true;
      }
      if (this.app.settingsOpen) {
        this.$nextTick(() => {
          if (this.app.settingsOpen) {
            this.positionDropdown();
            this.updatePanelScrollProgress();
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
    themeCards() {
      // Build a visual theme card list with bilingual labels and preview colors.
      // 构建带双语名称和预览色块的主题卡列表。
      return this.app.themeOptions.map((theme) => ({
        ...theme,
        previewColors: this.app.themePreviewColors(theme.value),
        primaryLabel: this.app.t(theme.labelKey),
        secondaryLabel: this.app.peerLocaleText(theme.labelKey),
      }));
    },
    currentThemeCard() {
      // Resolve the active theme card for the trigger badge preview.
      // 解析当前主题卡，用于触发器上的预览徽章。
      return this.themeCards().find((theme) => theme.value === this.app.theme) || this.themeCards()[0] || null;
    },
    themePreviewStyle(theme) {
      // Convert theme preview colors into a compact gradient swatch.
      // 将主题预览色转换为紧凑渐变色块。
      const preview = Array.isArray(theme?.previewColors)
        ? theme.previewColors
        : Array.isArray(theme?.preview)
          ? theme.preview
          : [];
      const primary = preview[0] || 'var(--primary)';
      const accent = preview[1] || 'var(--accent)';
      const surface = preview[2] || 'var(--surface)';
      return {
        '--theme-preview-primary': primary,
        '--theme-preview-accent': accent,
        '--theme-preview-surface': surface,
      };
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
    toggleThemeWorkbench() {
      this.themeWorkbenchOpen = !this.themeWorkbenchOpen;
      if (!this.themeWorkbenchOpen) {
        this.customThemeOpen = false;
      }
      this.$nextTick(() => {
        if (this.app.settingsOpen) {
          this.positionDropdown();
          this.updatePanelScrollProgress();
        }
      });
    },
    toggleCustomThemeWorkbench() {
      if (!this.themeWorkbenchOpen) {
        this.themeWorkbenchOpen = true;
      }
      this.customThemeOpen = !this.customThemeOpen;
      this.$nextTick(() => {
        if (this.app.settingsOpen) {
          this.positionDropdown();
          this.updatePanelScrollProgress();
        }
      });
    },
    customThemeFields() {
      // Split custom-theme tokens into a stable edit list for the workbench.
      // 将自定义主题变量拆成稳定的编辑列表，供主题工作台使用。
      return [
        { key: 'bg', labelKey: 'theme.fields.bg' },
        { key: 'surface', labelKey: 'theme.fields.surface' },
        { key: 'surfaceSoft', labelKey: 'theme.fields.surfaceSoft' },
        { key: 'primary', labelKey: 'theme.fields.primary' },
        { key: 'primaryStrong', labelKey: 'theme.fields.primaryStrong' },
        { key: 'accent', labelKey: 'theme.fields.accent' },
        { key: 'text', labelKey: 'theme.fields.text' },
        { key: 'muted', labelKey: 'theme.fields.muted' },
      ];
    },
    updateCustomThemeField(field, value) {
      this.app.updateCustomThemeField(field, value);
      this.$nextTick(() => {
        if (this.app.settingsOpen) {
          this.updatePanelScrollProgress();
        }
      });
    },
    selectTheme(themeValue) {
      // Update the active theme through an explicit card click.
      // 通过明确的卡片点击切换当前主题。
      if (this.app.theme !== themeValue) {
        this.app.theme = themeValue;
        this.app.applyTheme();
      }
      if (themeValue === 'custom') {
        this.themeWorkbenchOpen = true;
        this.customThemeOpen = true;
      }
      this.$nextTick(() => {
        if (this.app.settingsOpen) {
          this.positionDropdown();
          this.updatePanelScrollProgress();
        }
      });
    },
    updatePanelScrollProgress() {
      // Keep the settings progress bar synchronized with the panel scroll position.
      // 让设置面板进度条与当前滚动位置同步。
      const panel = this.$refs.dropdownPanel;
      if (!panel) {
        this.panelScrollProgress = 0;
        return;
      }
      const maxScrollTop = Math.max(0, panel.scrollHeight - panel.clientHeight);
      if (maxScrollTop <= 0) {
        this.panelScrollProgress = 1;
        return;
      }
      this.panelScrollProgress = Math.min(1, Math.max(0, panel.scrollTop / maxScrollTop));
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
      if (this.app.isCompactViewport) {
        const width = Math.min(440, Math.max(0, viewportWidth - viewportPadding * 2));
        const left = Math.max(viewportPadding, Math.round((viewportWidth - width) / 2));
        const maxHeight = Math.max(0, viewportHeight - viewportPadding * 2);
        this.dropdownPlacement = 'down';
        this.dropdownStyle = {
          position: 'fixed',
          top: `${viewportPadding}px`,
          left: `${left}px`,
          right: 'auto',
          bottom: 'auto',
          width: `${Math.round(width)}px`,
          maxHeight: `${Math.round(maxHeight)}px`,
          visibility: 'visible',
        };
        this.$nextTick(() => {
          if (this.app.settingsOpen) {
            this.updatePanelScrollProgress();
          }
        });
        return;
      }
      const widthLimit = Math.max(0, viewportWidth - viewportPadding * 2);
      const width = Math.min(400, widthLimit);
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
      this.$nextTick(() => {
        if (this.app.settingsOpen) {
          this.updatePanelScrollProgress();
        }
      });
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
        <span class="settings-trigger-badges">
          <span
            class="settings-trigger-badge settings-trigger-badge--theme"
            :style="themePreviewStyle(currentThemeCard())"
          >
            {{ app.t('theme.options.' + app.theme) }}
          </span>
        </span>
      </button>
      <teleport to="body">
        <div
          v-if="app.settingsOpen"
          class="settings-backdrop"
          :class="{ 'settings-backdrop--compact': app.isCompactViewport }"
          @click="app.closeSettingsMenu()"
        ></div>
        <!-- Render the panel outside the sidebar so overflow cannot clip it. -->
        <!-- 将面板渲染到侧栏外部，避免被 overflow 裁切。 -->
        <div
          v-if="app.settingsOpen"
          ref="dropdownPanel"
          class="settings-dropdown settings-dropdown--floating"
          :class="{
            'settings-dropdown--up': dropdownPlacement === 'up',
            'settings-dropdown--compact': app.isCompactViewport,
          }"
          :style="dropdownStyle"
          @click.stop
          @scroll.passive="updatePanelScrollProgress"
        >
          <div class="settings-header">
            <div class="settings-eyebrow">{{ app.t('settings.customize') }}</div>
            <div class="settings-title">{{ app.t('i18n.title') }}</div>
          </div>
          <!-- Scroll progress / 滚动进度：提示设置面板在长内容中的位置。 -->
          <div
            class="settings-progress"
            role="progressbar"
            :aria-label="app.t('settings.progressLabel')"
            aria-valuemin="0"
            aria-valuemax="100"
            :aria-valuenow="Math.round(panelScrollProgress * 100)"
          >
            <div class="settings-progress-head">
              <div class="settings-progress-label">{{ app.t('settings.progressLabel') }}</div>
              <div class="settings-progress-value">{{ Math.round(panelScrollProgress * 100) }}%</div>
            </div>
            <div class="settings-progress-track">
              <div class="settings-progress-fill" :style="{ width: Math.max(8, Math.round(panelScrollProgress * 100)) + '%' }"></div>
            </div>
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
          <section class="settings-section settings-section-theme">
            <button
              class="settings-theme-summary"
              type="button"
              :aria-expanded="themeWorkbenchOpen ? 'true' : 'false'"
              @click="toggleThemeWorkbench"
            >
              <div class="settings-theme-summary-copy">
                <div class="settings-section-title">{{ app.t('theme.manage') }}</div>
                <div class="settings-section-note">{{ themeWorkbenchOpen ? app.t('theme.hint') : app.t('theme.collapsedHint') }}</div>
              </div>
              <div class="settings-theme-summary-side">
                <div class="settings-theme-current" :style="themePreviewStyle(currentThemeCard())">
                  <span class="settings-theme-current-dot"></span>
                  <span>{{ app.t('theme.options.' + app.theme) }}</span>
                </div>
                <span class="settings-section-toggle" :class="{ 'settings-section-toggle-open': themeWorkbenchOpen }" aria-hidden="true">+</span>
              </div>
            </button>
            <div v-if="themeWorkbenchOpen" class="settings-theme-workbench">
              <div class="settings-section-head settings-section-head--theme">
                <div>
                  <div class="settings-section-title">{{ app.t('theme.presets') }}</div>
                  <div class="settings-section-note">{{ app.t('theme.presetsHint') }}</div>
                </div>
                <div class="settings-theme-current" :style="themePreviewStyle(currentThemeCard())">
                  <span class="settings-theme-current-dot"></span>
                  <span>{{ app.t('theme.active') }}</span>
                </div>
              </div>
              <div class="settings-theme-grid">
                <button
                  v-for="theme in themeCards()"
                  :key="theme.value"
                  class="settings-theme-card"
                  :class="{ active: app.theme === theme.value }"
                  type="button"
                  :aria-pressed="app.theme === theme.value ? 'true' : 'false'"
                  @click="selectTheme(theme.value)"
                >
                  <div class="settings-theme-preview" :style="themePreviewStyle(theme)">
                    <span class="settings-theme-preview-chip settings-theme-preview-chip--primary"></span>
                    <span class="settings-theme-preview-chip settings-theme-preview-chip--accent"></span>
                    <span class="settings-theme-preview-chip settings-theme-preview-chip--surface"></span>
                  </div>
                  <div class="settings-theme-copy">
                    <div class="settings-theme-title">{{ theme.primaryLabel }}</div>
                    <div class="settings-theme-sub">{{ theme.secondaryLabel }}</div>
                  </div>
                  <div v-if="app.theme === theme.value" class="settings-theme-active">{{ app.t('theme.active') }}</div>
                </button>
              </div>
              <div class="settings-theme-custom">
                <button
                  class="settings-theme-custom-head"
                  type="button"
                  :aria-expanded="customThemeOpen ? 'true' : 'false'"
                  @click="toggleCustomThemeWorkbench"
                >
                  <div class="settings-theme-custom-copy">
                    <div class="settings-section-title">{{ app.t('theme.customTitle') }}</div>
                    <div class="settings-section-note">{{ app.t('theme.customHint') }}</div>
                  </div>
                  <span class="settings-section-toggle" :class="{ 'settings-section-toggle-open': customThemeOpen }" aria-hidden="true">+</span>
                </button>
                <div v-if="customThemeOpen" class="settings-theme-custom-body">
                  <div class="settings-theme-token-grid">
                    <label
                      v-for="field in customThemeFields()"
                      :key="field.key"
                      class="settings-theme-token"
                    >
                      <span class="settings-theme-token-copy">
                        <span class="settings-theme-token-label">{{ app.t(field.labelKey) }}</span>
                        <span class="settings-theme-token-value">{{ app.customTheme[field.key] }}</span>
                      </span>
                      <input
                        class="settings-theme-token-input"
                        type="color"
                        :value="app.customTheme[field.key]"
                        @input="updateCustomThemeField(field.key, $event.target.value)"
                      />
                    </label>
                  </div>
                  <div class="settings-theme-custom-actions">
                    <button class="settings-theme-action settings-theme-action--primary" type="button" @click="selectTheme('custom')">
                      {{ app.t('theme.options.custom') }}
                    </button>
                    <button class="settings-theme-action" type="button" @click="app.resetCustomTheme()">
                      {{ app.t('theme.reset') }}
                    </button>
                  </div>
                </div>
              </div>
            </div>
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
