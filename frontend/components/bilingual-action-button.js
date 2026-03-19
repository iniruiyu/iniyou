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
  // Reusable action button shell for the active language only.
  // 仅显示当前语言的动作按钮外壳，避免同一按钮内重复展示双语。
  template: `
    <button
      :class="buttonClass"
      :type="type"
      :disabled="disabled"
      @click="handleClick"
    >
      <span class="bilingual-action-button-main">{{ primaryLabel }}</span>
    </button>
  `,
};
