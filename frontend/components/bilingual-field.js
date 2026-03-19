window.BilingualField = {
  props: {
    primaryLabel: {
      type: String,
      required: true,
    },
    secondaryLabel: {
      type: String,
      required: true,
    },
    helperText: {
      type: String,
      default: '',
    },
  },
  // Reusable bilingual field shell.
  // Reusable field shell for the active language only.
  // 仅显示当前语言的字段外壳，避免标签区堆叠双语文案。
  template: `
    <div class="identity-field">
      <label class="identity-label">
        <span class="identity-label-main">{{ primaryLabel }}</span>
      </label>
      <slot></slot>
      <div v-if="helperText" class="form-hint">{{ helperText }}</div>
    </div>
  `,
};
