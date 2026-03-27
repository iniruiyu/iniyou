function createReadonlyProxy(key) {
  return function readProxy() {
    return this.app[key];
  };
}

function createMethodProxy(key) {
  return function methodProxy(...args) {
    return this.app[key](...args);
  };
}

window.ProfilePage = {
  props: {
    app: {
      type: Object,
      required: true,
    },
  },
  computed: {
    // Mirror the root profile state so the page can stay self-contained.
    // 映射根应用的个人主页状态，方便页面独立收口。
    profileUser: createReadonlyProxy('profileUser'),
    user: createReadonlyProxy('user'),
    profileDraft: createReadonlyProxy('profileDraft'),
    visibleProfileSpaces: createReadonlyProxy('visibleProfileSpaces'),
    acceptedFriends: createReadonlyProxy('acceptedFriends'),
    activeExternalAccounts: createReadonlyProxy('activeExternalAccounts'),
    localizedLevelName: createReadonlyProxy('localizedLevelName'),
    connectedChainText: createReadonlyProxy('connectedChainText'),
    hasBlockchainAccounts: createReadonlyProxy('hasBlockchainAccounts'),
    profileTab: {
      get() {
        return this.app.profileTab;
      },
      set(value) {
        this.app.profileTab = value;
      },
    },
  },
  methods: {
    profileAvatarStyle: createMethodProxy('profileAvatarStyle'),
    profileAvatarInitials: createMethodProxy('profileAvatarInitials'),
    profileDisplayValue: createMethodProxy('profileDisplayValue'),
    profileDisplayNumber: createMethodProxy('profileDisplayNumber'),
    profileBirthdayLabel: createMethodProxy('profileBirthdayLabel'),
    profileBirthDateLabel: createMethodProxy('profileBirthDateLabel'),
    profileBirthdayFromBirthDate: createMethodProxy('profileBirthdayFromBirthDate'),
    profileAgeFromBirthDate: createMethodProxy('profileAgeFromBirthDate'),
    spaceVisibilityLabel: createMethodProxy('spaceVisibilityLabel'),
    statusLabel: createMethodProxy('statusLabel'),
    identityVisibilityLabel: createMethodProxy('identityVisibilityLabel'),
    openIdentityEditor: createMethodProxy('openIdentityEditor'),
    activeProfileFriend: createMethodProxy('activeProfileFriend'),
    startChat: createMethodProxy('startChat'),
    acceptProfileFriend: createMethodProxy('acceptProfileFriend'),
    addProfileFriend: createMethodProxy('addProfileFriend'),
    backToPublicFeed: createMethodProxy('backToPublicFeed'),
    openMembershipModal: createMethodProxy('openMembershipModal'),
    closeMembershipModal: createMethodProxy('closeMembershipModal'),
    isCurrentLevel: createMethodProxy('isCurrentLevel'),
    localizedLevelText: createMethodProxy('localizedLevelText'),
    enterFriendSpace: createMethodProxy('enterFriendSpace'),
  },
  // Standalone profile page so the main template can stay focused on shell layout.
  // 独立的个人主页组件，让主模板只保留壳层结构。
  template: `
    <section class="panel profile-page">
      <div v-if="profileUser" class="profile-home-feed">
        <div v-if="profileUser.id !== user.id" class="post-composer profile-hero-card">
          <div class="post-header">
            <div>
              <div class="space-toolbar-kicker">{{ app.t('pageTitle.profile') }}</div>
              <h3>{{ profileUser.name || app.t('posts.profileFeedTitle') }}</h3>
              <p>{{ app.t('pageSub.profile') }}</p>
              <div v-if="profileUser.secondary" class="post-meta">{{ profileUser.secondary }}</div>
              <div v-if="profileUser.relationStatus" class="post-meta">{{ statusLabel(profileUser.relationStatus) }}</div>
            </div>
            <div class="profile-actions">
              <bilingual-action-button
                v-if="profileUser.id === user.id"
                variant="primary"
                type="button"
                :primary-label="app.t('profile.identity.editAction')"
                :secondary-label="app.peerLocaleText('profile.identity.editAction')"
                @click="openIdentityEditor"
              ></bilingual-action-button>
              <bilingual-action-button
                v-else-if="activeProfileFriend()"
                variant="ghost"
                compact
                type="button"
                :primary-label="app.t('posts.openChat')"
                :secondary-label="app.peerLocaleText('posts.openChat')"
                @click="startChat(activeProfileFriend())"
              ></bilingual-action-button>
              <bilingual-action-button
                v-else-if="profileUser.relationStatus === 'pending' && profileUser.direction === 'incoming'"
                variant="ghost"
                compact
                type="button"
                :primary-label="app.t('posts.acceptFriend')"
                :secondary-label="app.peerLocaleText('posts.acceptFriend')"
                @click="acceptProfileFriend"
              ></bilingual-action-button>
              <bilingual-action-button
                v-else-if="profileUser.id && profileUser.id !== user.id && !profileUser.relationStatus"
                variant="ghost"
                compact
                type="button"
                :primary-label="app.t('posts.addFriend')"
                :secondary-label="app.peerLocaleText('posts.addFriend')"
                @click="addProfileFriend"
              ></bilingual-action-button>
              <bilingual-action-button
                v-else
                variant="ghost"
                compact
                type="button"
                :primary-label="app.t('posts.backToFeed')"
                :secondary-label="app.peerLocaleText('posts.backToFeed')"
                @click="backToPublicFeed"
              ></bilingual-action-button>
            </div>
          </div>
        </div>
        <!-- Show hidden-field placeholders only for other viewers. -->
        <!-- 仅在他人查看时显示“未公开”占位。 -->
        <template v-if="profileUser.id !== user.id">
          <div class="profile-summary-grid">
            <div class="panel identity-summary-card">
              <div class="topbar">
                <div>
                  <h3>{{ app.t('profile.identity.title') }}</h3>
                  <p>{{ app.t('profile.identity.sub') }}</p>
                </div>
              </div>
              <div class="profile-identity-head">
                <div class="avatar large profile-avatar" :style="profileAvatarStyle(profileUser.avatarUrl)">
                  <span v-if="!profileUser.avatarUrl">{{ profileAvatarInitials(profileUser.name) }}</span>
                </div>
                <div class="profile-identity-head-copy">
                  <strong>{{ profileDisplayValue(profileUser.name) }}</strong>
                  <span>{{ profileUser.domain ? '@' + profileUser.domain : (profileUser.username ? '@' + profileUser.username : profileUser.id) }}</span>
                </div>
              </div>
              <div class="identity-summary-list identity-summary-list--compact">
                <div class="identity-summary-item identity-summary-item--wide">
                  <span>{{ app.t('profile.identity.userId') }}</span>
                  <strong>{{ profileUser.id }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.nickname') }}</span>
                  <strong>{{ profileDisplayValue(profileUser.name) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.username') }}</span>
                  <strong>{{ profileUser.username ? '@' + profileUser.username : app.t('common.notPublic') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.domain') }}</span>
                  <strong>{{ profileUser.domain ? '@' + profileUser.domain : app.t('common.notPublic') }}</strong>
                </div>
                <div class="identity-summary-item identity-summary-item--wide">
                  <span>{{ app.t('profile.identity.signature') }}</span>
                  <strong>{{ profileDisplayValue(profileUser.signature) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.emailLabel') }}</span>
                  <strong>{{ profileDisplayValue(profileUser.email) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.phoneLabel') }}</span>
                  <strong>{{ profileDisplayValue(profileUser.phone) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.birthdayLabel') }}</span>
                  <strong>{{ profileDisplayValue(profileUser.birthday ? profileBirthdayLabel(profileUser.birthday) : '') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.ageLabel') }}</span>
                  <strong>{{ profileDisplayNumber(profileUser.age) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.genderLabel') }}</span>
                  <strong>{{ profileDisplayValue(profileUser.gender) }}</strong>
                </div>
                <div class="identity-summary-item identity-summary-item--wide">
                  <span>{{ app.t('profile.spaces.title') }}</span>
                  <strong>{{ visibleProfileSpaces.length }}</strong>
                </div>
              </div>
            </div>
          </div>
        </template>
        <template v-if="profileUser.id === user.id">
          <div class="panel-grid">
            <div class="panel">
              <h2>{{ app.t('dashboard.overviewTitle') }}</h2>
              <p>{{ app.t('dashboard.overviewSub') }}</p>
              <div class="stats">
                <div class="stat">
                  <div class="stat-title">{{ app.t('profile.spaces.title') }}</div>
                  <div class="stat-value">{{ visibleProfileSpaces.length }}</div>
                </div>
                <div class="stat">
                  <div class="stat-title">{{ app.t('dashboard.friendStat') }}</div>
                  <div class="stat-value">{{ acceptedFriends.length }}</div>
                </div>
                <div class="stat">
                  <div class="stat-title">{{ app.t('dashboard.levelStat') }}</div>
                  <div class="stat-value">{{ localizedLevelName }}</div>
                </div>
                <div class="stat">
                  <div class="stat-title">{{ app.t('dashboard.blockchainStat') }}</div>
                  <div class="stat-value">{{ activeExternalAccounts.length }}</div>
                </div>
              </div>
            </div>
          </div>
        </template>
        <template v-if="profileUser.id === user.id">
          <!-- Split the owner profile into basic info, contact details, and privacy cards for a calmer layout. -->
          <!-- 将本人资料拆成基础信息、联系方式和隐私三张卡，排版更清晰。 -->
          <div class="profile-summary-grid">
            <div class="panel identity-summary-card">
              <div class="topbar">
                <div>
                  <h3>{{ app.t('profile.identity.personalTitle') }}</h3>
                  <p>{{ app.t('profile.identity.personalSub') }}</p>
                </div>
                <bilingual-action-button
                  variant="tonal"
                  compact
                  class="profile-summary-action"
                  type="button"
                  :primary-label="app.t('profile.identity.editAction')"
                  :secondary-label="app.peerLocaleText('profile.identity.editAction')"
                  @click="openIdentityEditor('personal')"
                ></bilingual-action-button>
              </div>
              <div class="profile-identity-head">
                <div class="avatar large profile-avatar" :style="profileAvatarStyle(profileDraft.avatarUrl || user.avatarUrl)">
                  <span v-if="!(profileDraft.avatarUrl || user.avatarUrl)">{{ profileAvatarInitials(profileDraft.displayName || user.name) }}</span>
                </div>
                <div class="profile-identity-head-copy">
                  <strong>{{ profileDraft.displayName || app.t('common.notAvailable') }}</strong>
                  <span>{{ profileDraft.domain ? '@' + profileDraft.domain : (profileDraft.username ? '@' + profileDraft.username : profileUser.id) }}</span>
                </div>
              </div>
              <div class="identity-summary-list identity-summary-list--compact">
                <div class="identity-summary-item identity-summary-item--wide">
                  <span>{{ app.t('profile.identity.userId') }}</span>
                  <strong>{{ profileUser.id }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.nickname') }}</span>
                  <strong>{{ profileDraft.displayName || app.t('common.notAvailable') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.username') }}</span>
                  <strong>{{ profileDraft.username ? '@' + profileDraft.username : app.t('common.notAvailable') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.domain') }}</span>
                  <strong>{{ profileDraft.domain ? '@' + profileDraft.domain : app.t('common.notAvailable') }}</strong>
                </div>
                <div class="identity-summary-item identity-summary-item--wide">
                  <span>{{ app.t('profile.identity.signature') }}</span>
                  <strong>{{ profileDraft.signature || app.t('common.notAvailable') }}</strong>
                </div>
              </div>
            </div>
            <div class="panel identity-summary-card">
              <div class="topbar">
                <div>
                  <h3>{{ app.t('profile.identity.contactTitle') }}</h3>
                  <p>{{ app.t('profile.identity.contactSub') }}</p>
                </div>
                <bilingual-action-button
                  variant="tonal"
                  compact
                  class="profile-summary-action"
                  type="button"
                  :primary-label="app.t('profile.identity.contactAction')"
                  :secondary-label="app.peerLocaleText('profile.identity.contactAction')"
                  @click="openIdentityEditor('contact')"
                ></bilingual-action-button>
              </div>
              <div class="identity-summary-list identity-summary-list--compact">
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.emailLabel') }}</span>
                  <strong>{{ profileUser.email || app.t('common.notAvailable') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.phoneLabel') }}</span>
                  <strong>{{ profileUser.phone || app.t('common.notAvailable') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.birthDateLabel') }}</span>
                  <strong>{{ profileDraft.birthDate ? profileBirthDateLabel(profileDraft.birthDate) : app.t('common.notAvailable') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.birthdayLabel') }}</span>
                  <strong>{{ profileDraft.birthDate ? profileBirthdayFromBirthDate(profileDraft.birthDate) : app.t('common.notAvailable') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.ageLabel') }}</span>
                  <strong>{{ profileUser.age !== '' && profileUser.age !== null ? profileUser.age : app.t('common.notAvailable') }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.genderLabel') }}</span>
                  <strong>{{ profileUser.gender || app.t('common.notAvailable') }}</strong>
                </div>
              </div>
            </div>
            <div class="panel identity-summary-card">
              <div class="topbar">
                <div>
                  <h3>{{ app.t('profile.identity.privacyTitle') }}</h3>
                  <p>{{ app.t('profile.identity.privacySub') }}</p>
                </div>
                <bilingual-action-button
                  variant="tonal"
                  compact
                  class="profile-summary-action"
                  type="button"
                  :primary-label="app.t('profile.identity.privacyAction')"
                  :secondary-label="app.peerLocaleText('profile.identity.privacyAction')"
                  @click="openIdentityEditor('privacy')"
                ></bilingual-action-button>
              </div>
              <div class="identity-summary-list identity-summary-list--compact">
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.phoneVisibility') }}</span>
                  <strong>{{ identityVisibilityLabel(profileDraft.phoneVisibility) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.emailVisibility') }}</span>
                  <strong>{{ identityVisibilityLabel(profileDraft.emailVisibility) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.ageVisibility') }}</span>
                  <strong>{{ identityVisibilityLabel(profileDraft.ageVisibility) }}</strong>
                </div>
                <div class="identity-summary-item">
                  <span>{{ app.t('profile.identity.genderVisibility') }}</span>
                  <strong>{{ identityVisibilityLabel(profileDraft.genderVisibility) }}</strong>
                </div>
              </div>
            </div>
          </div>
          <div class="panel profile-membership-card">
            <div class="topbar">
              <div>
                <h3>{{ app.t('profile.membership.title') }}</h3>
              </div>
              <bilingual-action-button
                variant="primary"
                type="button"
                :primary-label="app.t('profile.membership.subscribe')"
                :secondary-label="app.peerLocaleText('profile.membership.subscribe')"
                @click="openMembershipModal"
              ></bilingual-action-button>
            </div>
            <div class="membership-summary-line">
              <span>{{ app.t('profile.membership.current') }}</span>
              <strong>{{ localizedLevelName }}</strong>
            </div>
          </div>
          <div v-if="hasBlockchainAccounts" class="panel profile-blockchain-card">
            <div class="topbar">
              <div>
                <h3>{{ app.t('profile.blockchain.title') }}</h3>
                <p>{{ app.t('profile.blockchain.sub') }}</p>
              </div>
              <bilingual-action-button
                variant="ghost"
                type="button"
                :primary-label="app.t('blockchain.openManager')"
                :secondary-label="app.peerLocaleText('blockchain.openManager')"
                @click="profileTab = profileTab === 'blockchain' ? 'summary' : 'blockchain'"
              ></bilingual-action-button>
            </div>
            <div class="membership-summary-line">
              <span>{{ app.t('blockchain.connectedChains') }}</span>
              <strong>{{ connectedChainText }}</strong>
            </div>
            <div v-if="profileTab === 'blockchain'" class="friends-grid profile-blockchain-grid">
              <div class="friend-card" v-for="account in activeExternalAccounts" :key="account.id">
                <div class="avatar small"></div>
                <div>
                  <div class="friend-name">{{ account.provider.toUpperCase() }} <span v-if="account.chain">· {{ account.chain }}</span></div>
                  <div class="friend-secondary">{{ account.accountAddress }}</div>
                  <div class="friend-status">{{ statusLabel(account.bindingStatus) }}</div>
                </div>
              </div>
              <div v-if="activeExternalAccounts.length === 0" class="empty-state">{{ app.t('profile.blockchain.empty') }}</div>
            </div>
          </div>
        </template>
        <div class="panel profile-spaces-card">
          <div class="topbar">
            <div>
              <h3>{{ app.t('profile.spaces.title') }}</h3>
            </div>
            <div class="space-toolbar-kicker">{{ visibleProfileSpaces.length }} {{ app.t('profile.spaces.publicList') }}</div>
          </div>
          <div v-if="visibleProfileSpaces.length === 0" class="empty-state">{{ app.t('profile.spaces.empty') }}</div>
          <div v-else class="space-cards profile-space-cards">
            <div class="space-card" v-for="space in visibleProfileSpaces" :key="space.id">
              <div class="space-tag public">{{ spaceVisibilityLabel(space.visibility) }}</div>
              <div class="space-title">{{ app.localizedSpaceText('name', space) }}</div>
              <div class="space-desc">{{ app.localizedSpaceText('desc', space) }}</div>
              <div class="space-meta">@{{ space.subdomain }}</div>
              <div class="space-card-actions">
                <bilingual-action-button
                  variant="ghost"
                  compact
                  type="button"
                  :primary-label="app.t('spaces.enterAction')"
                  :secondary-label="app.peerLocaleText('spaces.enterAction')"
                  @click="enterFriendSpace(space)"
                ></bilingual-action-button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-else class="empty-state">{{ app.t('posts.profileEmpty') }}</div>
    </section>
  `,
};
