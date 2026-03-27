window.ProfileMembershipModal = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  // Keep membership switching isolated from the profile page itself.
  // 将会员切换从个人主页本体中隔离出来。
  template: `
    <div v-if="app.membershipModalOpen" class="modal-backdrop modal-backdrop--sheet" @click.self="app.closeMembershipModal">
      <div class="modal modal--sheet membership-modal">
        <div class="modal-header">
          <div>
            <div class="space-toolbar-kicker">{{ app.t('profile.membership.title') }}</div>
            <div class="modal-title">{{ app.t('profile.membership.sheetTitle') }}</div>
          </div>
          <button class="ghost compact" type="button" @click="app.closeMembershipModal">×</button>
        </div>
        <div class="membership-summary-line membership-summary-line--sheet">
          <span>{{ app.t('profile.membership.current') }}</span>
          <strong>{{ app.localizedLevelName }}</strong>
        </div>
        <div class="level-grid membership-level-grid">
          <div class="level-card" v-for="level in app.levels" :key="level.planID">
            <div class="level-title">{{ app.localizedLevelText('name', level) }}</div>
            <div class="level-price">{{ app.localizedLevelText('price', level) }}</div>
            <ul class="level-features">
              <li v-for="feature in app.localizedLevelText('features', level)" :key="feature">{{ feature }}</li>
            </ul>
            <button v-if="app.isCurrentLevel(level)" class="ghost" disabled>{{ app.t('levels.current') }}</button>
            <button v-else class="ghost" @click="app.selectMembershipLevel(level.planID)">{{ app.t('profile.membership.subscribe') }}</button>
          </div>
        </div>
      </div>
    </div>
  `,
};
