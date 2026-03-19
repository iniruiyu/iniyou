window.BilingualSelectField = {
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
    modelValue: {
      type: [String, Number],
      default: '',
    },
    options: {
      type: Array,
      default: () => [],
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update:modelValue', 'change'],
  methods: {
    optionValue(option) {
      if (option && typeof option === 'object' && 'value' in option) {
        return option.value;
      }
      return option;
    },
    optionLabel(option) {
      if (option == null) {
        return '';
      }
      if (typeof option === 'string' || typeof option === 'number') {
        return String(option);
      }
      if (typeof option.label === 'string' && option.label.trim()) {
        return option.label;
      }
      return option.primaryLabel || option.primary || option.name || '';
    },
    handleChange(event) {
      const value = event.target.value;
      this.$emit('update:modelValue', value);
      this.$emit('change', value);
    },
  },
  // Reusable bilingual select shell.
  // Reusable select shell for the active language only.
  // 仅显示当前语言的下拉外壳，避免选项里重复拼接双语文本。
  template: `
    <div class="identity-field">
      <label class="identity-label">
        <span class="identity-label-main">{{ primaryLabel }}</span>
      </label>
      <select
        :disabled="disabled"
        :value="modelValue"
        @change="handleChange"
      >
        <option
          v-for="option in options"
          :key="String(optionValue(option))"
          :value="optionValue(option)"
        >
          {{ optionLabel(option) }}
        </option>
      </select>
      <div v-if="helperText" class="form-hint">{{ helperText }}</div>
    </div>
  `,
};
