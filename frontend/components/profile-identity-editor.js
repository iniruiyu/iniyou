window.ProfileIdentityEditor = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  // Keep the identity editor as a dedicated overlay so the profile page stays focused.
  // 将资料编辑器保留为独立浮层，让个人主页本身更专注。
  template: `
    <div v-if="app.identityEditorOpen" class="modal-backdrop modal-backdrop--sheet" @click.self="app.closeIdentityEditor">
      <div class="modal modal--sheet profile-editor-modal">
        <div class="modal-header">
          <div>
            <div class="space-toolbar-kicker">{{ app.t('profile.identity.title') }}</div>
            <div class="modal-title">{{ app.profileEditorTitle(app.identityEditorSection) }}</div>
          </div>
          <button class="ghost compact" type="button" @click="app.closeIdentityEditor">×</button>
        </div>
        <form class="form modal-form" @submit.prevent="app.saveProfile">
          <div class="panel-grid identity-editor-grid">
            <!-- Personal info editor / 个人资料编辑区：只保留身份相关字段。 -->
            <div v-if="app.identityEditorSection === 'personal'" class="panel accent identity-editor-card">
              <h3>{{ app.t('profile.identity.personalTitle') }}</h3>
              <p>{{ app.t('profile.identity.personalSub') }}</p>
              <bilingual-field
                :primary-label="app.t('profile.identity.nickname')"
                :secondary-label="app.peerLocaleText('profile.identity.nickname')"
              >
                <input type="text" :placeholder="app.t('dashboard.displayNamePlaceholder')" v-model="app.profileDraft.displayName" />
              </bilingual-field>
              <bilingual-field
                :primary-label="app.t('profile.identity.username')"
                :secondary-label="app.peerLocaleText('profile.identity.username')"
                :helper-text="app.t('dashboard.usernameHint')"
              >
                <!-- Username field / 用户名字段：用于个人主页和二级域名入口。 -->
                <input type="text" :placeholder="app.t('dashboard.usernamePlaceholder')" v-model="app.profileDraft.username" maxlength="63" autocomplete="username" />
              </bilingual-field>
              <bilingual-field
                :primary-label="app.t('profile.identity.domain')"
                :secondary-label="app.peerLocaleText('profile.identity.domain')"
                :helper-text="app.t('profile.identity.domainHint')"
              >
                <input type="text" :placeholder="app.t('profile.identity.domainPlaceholder')" v-model="app.profileDraft.domain" maxlength="63" autocomplete="username" />
              </bilingual-field>
              <bilingual-field
                :primary-label="app.t('profile.identity.avatarLabel')"
                :secondary-label="app.peerLocaleText('profile.identity.avatarLabel')"
                :helper-text="app.t('profile.identity.avatarHint')"
              >
                <input type="url" :placeholder="app.t('profile.identity.avatarPlaceholder')" v-model="app.profileDraft.avatarUrl" autocomplete="off" />
              </bilingual-field>
              <div class="identity-avatar-editor">
                <div class="avatar large profile-avatar" :style="app.profileAvatarStyle(app.profileDraft.avatarUrl)">
                  <span v-if="!app.profileDraft.avatarUrl">{{ app.profileAvatarInitials(app.profileDraft.displayName || app.user.name) }}</span>
                </div>
                <div class="identity-avatar-copy">
                  <strong>{{ app.t('profile.identity.avatarLabel') }}</strong>
                  <span>{{ app.t('profile.identity.avatarHint') }}</span>
                </div>
              </div>
              <bilingual-field
                :primary-label="app.t('profile.identity.signature')"
                :secondary-label="app.peerLocaleText('profile.identity.signature')"
              >
                <textarea class="post-textarea" :placeholder="app.t('profile.identity.signaturePlaceholder')" v-model="app.profileDraft.signature"></textarea>
              </bilingual-field>
            </div>

            <!-- Contact info editor / 联系方式编辑区：邮箱和手机号作为只读账号资料展示，出生日期与性别继续单独编辑。 -->
            <div v-else-if="app.identityEditorSection === 'contact'" class="panel accent identity-editor-card">
              <h3>{{ app.t('profile.identity.contactTitle') }}</h3>
              <p>{{ app.t('profile.identity.contactSub') }}</p>
              <bilingual-field
                :primary-label="app.t('profile.identity.emailLabel')"
                :secondary-label="app.peerLocaleText('profile.identity.emailLabel')"
              >
                <input
                  type="email"
                  :value="app.profileUser.email || app.t('common.notAvailable')"
                  readonly
                  autocomplete="email"
                />
              </bilingual-field>
              <bilingual-field
                :primary-label="app.t('profile.identity.phoneLabel')"
                :secondary-label="app.peerLocaleText('profile.identity.phoneLabel')"
              >
                <input
                  type="tel"
                  :value="app.profileUser.phone || app.t('common.notAvailable')"
                  readonly
                  autocomplete="tel"
                />
              </bilingual-field>
              <p>{{ app.t('profile.identity.contactNote') }}</p>
              <bilingual-field
                :primary-label="app.t('profile.identity.birthDateLabel')"
                :secondary-label="app.peerLocaleText('profile.identity.birthDateLabel')"
              >
                <input
                  type="date"
                  :placeholder="app.t('profile.identity.birthDatePlaceholder')"
                  v-model="app.profileDraft.birthDate"
                  autocomplete="off"
                />
              </bilingual-field>
              <div class="identity-derived-grid">
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.birthdayLabel') }}</span>
                  <strong>{{ app.profileBirthdayFromBirthDate(app.profileDraft.birthDate) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.ageLabel') }}</span>
                  <strong>{{ app.profileAgeFromBirthDate(app.profileDraft.birthDate) }}</strong>
                </div>
              </div>
              <bilingual-field
                :primary-label="app.t('profile.identity.genderLabel')"
                :secondary-label="app.peerLocaleText('profile.identity.genderLabel')"
              >
                <input
                  type="text"
                  :placeholder="app.t('profile.identity.genderPlaceholder')"
                  v-model="app.profileDraft.gender"
                  autocomplete="off"
                />
              </bilingual-field>
            </div>

            <!-- Privacy editor / 隐私设置区：仅保留可见范围开关。 -->
            <div v-else class="panel identity-editor-card">
              <h3>{{ app.t('profile.identity.privacyTitle') }}</h3>
              <p>{{ app.t('profile.identity.privacySub') }}</p>
              <div class="identity-visibility-grid identity-editor-privacy-grid">
                <bilingual-select-field
                  :primary-label="app.t('profile.identity.phoneVisibility')"
                  :secondary-label="app.peerLocaleText('profile.identity.phoneVisibility')"
                  v-model="app.profileDraft.phoneVisibility"
                  :options="app.identityVisibilityOptions()"
                ></bilingual-select-field>
                <bilingual-select-field
                  :primary-label="app.t('profile.identity.emailVisibility')"
                  :secondary-label="app.peerLocaleText('profile.identity.emailVisibility')"
                  v-model="app.profileDraft.emailVisibility"
                  :options="app.identityVisibilityOptions()"
                ></bilingual-select-field>
                <bilingual-select-field
                  :primary-label="app.t('profile.identity.ageVisibility')"
                  :secondary-label="app.peerLocaleText('profile.identity.ageVisibility')"
                  v-model="app.profileDraft.ageVisibility"
                  :options="app.identityVisibilityOptions()"
                ></bilingual-select-field>
                <bilingual-select-field
                  :primary-label="app.t('profile.identity.genderVisibility')"
                  :secondary-label="app.peerLocaleText('profile.identity.genderVisibility')"
                  v-model="app.profileDraft.genderVisibility"
                  :options="app.identityVisibilityOptions()"
                ></bilingual-select-field>
              </div>
            </div>
          </div>
          <div class="modal-actions">
            <button class="ghost" type="button" @click="app.closeIdentityEditor">{{ app.t('common.cancel') }}</button>
            <button class="primary" type="submit">{{ app.t(app.profileEditorSaveKey(app.identityEditorSection)) }}</button>
          </div>
        </form>
      </div>
    </div>
  `,
};
