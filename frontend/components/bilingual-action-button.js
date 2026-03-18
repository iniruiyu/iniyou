window.BilingualActionButton = {
  props: {
    primaryLabel: {
      type: String,
      required: true,
    },
    secondaryLabel: {
      type: String,
      required: true,
    },
    variant: {
      type: String,
      default: 'primary',
    },
    type: {
      type: String,
      default: 'button',
    },
    compact: {
      type: Boolean,
      default: false,
    },
    danger: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['click'],
  computed: {
    buttonClass() {
      return [
        this.variant || 'primary',
        this.compact ? 'compact' : '',
        this.danger ? 'danger' : '',
        'bilingual-action-button',
      ]
        .filter(Boolean)
        .join(' ');
    },
  },
  methods: {
    handleClick(event) {
      this.$emit('click', event);
    },
  },
  // Reusable bilingual action button shell.
  // 可复用双语动作按钮外壳：统一主标签、副标签与按钮层级。
  template: `
    <button
      :class="buttonClass"
      :type="type"
      :disabled="disabled"
      @click="handleClick"
    >
      <span class="bilingual-action-button-main">{{ primaryLabel }}</span>
      <span class="bilingual-action-button-sub">{{ secondaryLabel }}</span>
    </button>
  `,
};
