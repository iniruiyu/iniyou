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
      const primary = option.primaryLabel || option.primary || '';
      const secondary = option.secondaryLabel || option.secondary || '';
      return [primary, secondary].filter(Boolean).join(' / ');
    },
    handleChange(event) {
      const value = event.target.value;
      this.$emit('update:modelValue', value);
      this.$emit('change', value);
    },
  },
  // Reusable bilingual select shell.
  // 可复用双语下拉外壳：统一主标签、副标签和选项渲染逻辑。
  template: `
    <div class="identity-field">
      <label class="identity-label">
        <span class="identity-label-main">{{ primaryLabel }}</span>
        <span class="identity-label-sub">{{ secondaryLabel }}</span>
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
