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
  // 可复用双语字段外壳：统一主标签、副标签和输入控件的层级。
  template: `
    <div class="identity-field">
      <label class="identity-label">
        <span class="identity-label-main">{{ primaryLabel }}</span>
        <span class="identity-label-sub">{{ secondaryLabel }}</span>
      </label>
      <slot></slot>
      <div v-if="helperText" class="form-hint">{{ helperText }}</div>
    </div>
  `,
};
