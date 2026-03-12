const { createApp } = Vue;

createApp({
  data() {
    return {
      // Current view in SPA.
      // 当前 SPA 视图。
      view: 'dashboard',
      // API base URL.
      // 接口基础地址。
      apiBase: 'http://localhost:8080/api/v1',
      // Message service API base URL.
      // 通讯服务接口基础地址。
      messageApiBase: 'http://localhost:8081/api/v1',
      // JWT token.
      // JWT 令牌。
      token: '',
      // Current language code.
      // 当前语言代码。
      locale: 'zh-CN',
      // Language display names.
      // 语言显示名称。
      languageMeta: {
        'zh-CN': { name: '简体中文', dir: 'ltr' },
        'zh-TW': { name: '繁體中文', dir: 'ltr' },
        'en-US': { name: 'English', dir: 'ltr' },
        he: { name: 'עברית', dir: 'rtl' },
      },
      // i18n dictionaries. New languages can be appended at runtime.
      // 国际化字典，可在运行时追加新语言。
      translations: {
        'zh-CN': {
          htmlTitle: '账号服务 · 私人空间与公共空间',
          brandSub: '私人 + 公共空间',
          common: {
            guest: '访客',
            notAvailable: '--',
          },
          nav: {
            auth: '登录 / 注册',
            dashboard: '账号主页',
            private: '私人空间',
            public: '公共空间',
            levels: '会员等级',
            subscription: '订阅',
            friends: '好友',
            chat: '实时聊天',
          },
          ws: {
            statusLabel: '连接状态',
            unreadLabel: '未读消息',
            connect: '连接聊天',
            disconnect: '断开聊天',
            disconnected: '未连接',
            connecting: '连接中...',
            connected: '已连接',
            closed: '已断开',
            needLogin: '需要登录',
          },
          pageTitle: {
            auth: '登录 / 注册',
            dashboard: '账号主页',
            private: '私人空间',
            public: '公共空间',
            levels: '会员等级',
            subscription: '订阅管理',
            friends: '好友',
            chat: '实时聊天',
          },
          pageSub: {
            auth: '快速进入你的私人空间与公共空间',
            dashboard: '账户摘要与空间信息',
            private: '沉淀个人内容',
            public: '展示公共内容与连接',
            levels: '选择适合你的会员等级',
            subscription: '管理订阅与权益',
            friends: '建立联系与私聊',
            chat: '实时沟通与反馈',
          },
          auth: {
            welcomeTitle: '欢迎回来',
            welcomeSub: '登录后进入你的私人空间与公共空间。',
            createTitle: '创建新账号',
            createSub: '加入会员体系，解锁更大空间与更多互动。',
            accountPlaceholder: '邮箱 / 手机',
            passwordPlaceholder: '密码',
            emailPlaceholder: '邮箱',
            phonePlaceholder: '手机号',
            login: '登录',
            register: '注册',
            logout: '退出登录',
            logoutSuccess: '已退出登录。',
            loginError: '登录失败，请检查账号和密码。',
            registerError: '注册失败，请检查输入信息。',
          },
          dashboard: {
            overviewTitle: '账号概览',
            overviewSub: '清晰掌控你的会员等级、订阅状态与空间使用情况。',
            levelStat: '会员等级',
            planStat: '订阅状态',
            friendStat: '好友数量',
            spaceSummaryTitle: '空间摘要',
            spaceSummarySub: '私人空间用于沉淀，公共空间用于分享。',
            profileTitle: '资料设置',
            profileSub: '更新展示名称，主页与聊天窗口会同步显示。',
            displayNamePlaceholder: '输入展示名称',
            saveProfile: '保存资料',
            saveSuccess: '资料已更新',
            saveError: '资料更新失败，请稍后重试。',
          },
          spaces: {
            privateTitle: '私人空间',
            privateSub: '用于自我整理、草稿与私密记录。',
            publicTitle: '公共空间',
            publicSub: '分享内容、展示项目、连接更多人。',
            createTitle: '创建空间',
            createSub: '新增一个私人空间或公共空间。',
            namePlaceholder: '空间名称',
            descPlaceholder: '空间描述',
            createAction: '创建空间',
            createSuccess: '空间已创建',
            createError: '空间创建失败，请检查名称后重试。',
            type: {
              private: '私人',
              public: '公共',
            },
          },
          posts: {
            feedTitle: '公共内容流',
            feedSub: '发布你的近况、想法和项目更新。',
            titlePlaceholder: '文章标题',
            contentPlaceholder: '写点什么，分享给大家...',
            publishAction: '发布文章',
            publishSuccess: '文章已发布。',
            publishError: '文章发布失败，请稍后重试。',
            empty: '公共内容流还没有文章，先发布第一篇吧。',
            like: '点赞',
            unlike: '取消点赞',
            comment: '评论',
            commentPlaceholder: '写下你的评论...',
            commentAction: '发送评论',
            commentError: '评论失败，请稍后重试。',
            share: '转发',
            shareError: '转发失败，请稍后重试。',
            privateLabel: '仅自己可见',
            publicLabel: '公开',
          },
          levels: {
            title: '会员等级',
            upgrade: '升级',
            current: '当前等级',
          },
          subscription: {
            title: '订阅管理',
            currentPlan: '当前方案',
            status: '订阅状态',
            startedAt: '开始时间',
            expiresAt: '到期时间',
            renew: '续订',
            activate: '立即开通',
            empty: '当前还没有有效订阅。',
            actionSuccess: '订阅已生效。',
            actionError: '订阅操作失败，请稍后重试。',
          },
          friends: {
            title: '好友',
            chat: '聊天',
            searchPlaceholder: '输入展示名、邮箱、手机号或用户 ID',
            searchAction: '搜索用户',
            addAction: '发送请求',
            acceptAction: '接受',
            directionIncoming: '收到的请求',
            directionOutgoing: '我发出的请求',
            contactSeparator: ' · ',
            empty: '还没有好友关系，先添加一个吧。',
            searchEmpty: '没有找到匹配用户。',
            searchHint: '先搜索用户，再发起好友请求。',
            searchError: '用户搜索失败，请稍后重试。',
            addError: '好友请求发送失败。',
            addSuccess: '好友请求已发送。',
            acceptError: '接受好友请求失败。',
          },
          chat: {
            title: '会话',
            pickFriend: '选择好友开始聊天',
            onlineNow: '实时在线',
            inputPlaceholder: '输入消息...',
            send: '发送',
            loadError: '聊天记录加载失败。',
            emptyConversation: '当前会话还没有消息。',
            sendError: '聊天服务未连接，请先建立连接。',
          },
          plans: {
            basic: '基础会员',
            premium: '高级会员',
            vip: 'VIP 会员',
            monthly: '月度订阅',
          },
          statuses: {
            online: '在线',
            busy: '忙碌中',
            offline: '离线',
            inactive: '未开通',
            active: '生效中',
            expired: '已过期',
            canceled: '已取消',
            pending: '待确认',
            accepted: '已通过',
            blocked: '已屏蔽',
          },
          i18n: {
            title: '语言设置',
            choose: '当前语言',
            addTitle: '新增语言',
            codePlaceholder: '语言代码（如：ja-JP）',
            namePlaceholder: '显示名称（如：日本語）',
            dirLabel: '文字方向',
            dirLtr: '从左到右',
            dirRtl: '从右到左',
            jsonPlaceholder: '可选：覆盖翻译 JSON（结构按 zh-CN）',
            addButton: '添加语言',
          },
        },
        'en-US': {
          htmlTitle: 'Account Service · Private & Public Spaces',
          brandSub: 'Private + Public Spaces',
          common: {
            guest: 'Guest',
            notAvailable: '--',
          },
          nav: {
            auth: 'Sign In / Sign Up',
            dashboard: 'Dashboard',
            private: 'Private Space',
            public: 'Public Space',
            levels: 'Membership',
            subscription: 'Subscription',
            friends: 'Friends',
            chat: 'Live Chat',
          },
          ws: {
            statusLabel: 'Connection',
            unreadLabel: 'Unread',
            connect: 'Connect Chat',
            disconnect: 'Disconnect Chat',
            disconnected: 'Disconnected',
            connecting: 'Connecting...',
            connected: 'Connected',
            closed: 'Closed',
            needLogin: 'Login Required',
          },
          pageTitle: {
            auth: 'Sign In / Sign Up',
            dashboard: 'Dashboard',
            private: 'Private Space',
            public: 'Public Space',
            levels: 'Membership',
            subscription: 'Subscription',
            friends: 'Friends',
            chat: 'Live Chat',
          },
          pageSub: {
            auth: 'Enter your private and public spaces quickly',
            dashboard: 'Account summary and space insights',
            private: 'Keep personal content organized',
            public: 'Showcase content and connect',
            levels: 'Choose the right membership tier',
            subscription: 'Manage plan and benefits',
            friends: 'Build connections and chat privately',
            chat: 'Real-time communication and feedback',
          },
          auth: {
            welcomeTitle: 'Welcome Back',
            welcomeSub: 'Sign in to access your private and public spaces.',
            createTitle: 'Create Account',
            createSub: 'Join membership plans and unlock larger spaces.',
            accountPlaceholder: 'Email / Phone',
            passwordPlaceholder: 'Password',
            emailPlaceholder: 'Email',
            phonePlaceholder: 'Phone',
            login: 'Sign In',
            register: 'Sign Up',
            logout: 'Sign Out',
            logoutSuccess: 'Signed out.',
            loginError: 'Sign in failed. Check your account and password.',
            registerError: 'Sign up failed. Check your inputs and try again.',
          },
          dashboard: {
            overviewTitle: 'Account Overview',
            overviewSub: 'Track your level, subscription, and space usage clearly.',
            levelStat: 'Membership',
            planStat: 'Subscription',
            friendStat: 'Friends',
            spaceSummaryTitle: 'Space Summary',
            spaceSummarySub: 'Private spaces for focus, public spaces for sharing.',
            profileTitle: 'Profile Settings',
            profileSub: 'Update your display name for the dashboard and chat header.',
            displayNamePlaceholder: 'Enter display name',
            saveProfile: 'Save Profile',
            saveSuccess: 'Profile updated',
            saveError: 'Profile update failed. Try again later.',
          },
          spaces: {
            privateTitle: 'Private Space',
            privateSub: 'For personal notes, drafts, and private records.',
            publicTitle: 'Public Space',
            publicSub: 'Share updates, showcase projects, and connect widely.',
            createTitle: 'Create Space',
            createSub: 'Add a new private or public space.',
            namePlaceholder: 'Space name',
            descPlaceholder: 'Space description',
            createAction: 'Create Space',
            createSuccess: 'Space created',
            createError: 'Space creation failed. Check the name and try again.',
            type: {
              private: 'Private',
              public: 'Public',
            },
          },
          posts: {
            feedTitle: 'Public Feed',
            feedSub: 'Share updates, ideas, and project progress.',
            titlePlaceholder: 'Post title',
            contentPlaceholder: 'Write something to share...',
            publishAction: 'Publish Post',
            publishSuccess: 'Post published.',
            publishError: 'Publishing failed. Try again later.',
            empty: 'The public feed is empty. Publish the first post.',
            like: 'Like',
            unlike: 'Unlike',
            comment: 'Comment',
            commentPlaceholder: 'Write a comment...',
            commentAction: 'Send Comment',
            commentError: 'Comment failed. Try again later.',
            share: 'Share',
            shareError: 'Sharing failed. Try again later.',
            privateLabel: 'Private',
            publicLabel: 'Public',
          },
          levels: {
            title: 'Membership Levels',
            upgrade: 'Upgrade',
            current: 'Current Tier',
          },
          subscription: {
            title: 'Subscription',
            currentPlan: 'Current Plan',
            status: 'Status',
            startedAt: 'Started At',
            expiresAt: 'Expires At',
            renew: 'Renew',
            activate: 'Activate',
            empty: 'There is no active subscription yet.',
            actionSuccess: 'Subscription is active now.',
            actionError: 'Subscription action failed. Try again later.',
          },
          friends: {
            title: 'Friends',
            chat: 'Chat',
            searchPlaceholder: 'Enter display name, email, phone, or user ID',
            searchAction: 'Search Users',
            addAction: 'Send Request',
            acceptAction: 'Accept',
            directionIncoming: 'Incoming request',
            directionOutgoing: 'Outgoing request',
            contactSeparator: ' · ',
            empty: 'No friend relations yet. Add one to get started.',
            searchEmpty: 'No matching users found.',
            searchHint: 'Search for a user first, then send a friend request.',
            searchError: 'User search failed. Try again later.',
            addError: 'Sending friend request failed.',
            addSuccess: 'Friend request sent.',
            acceptError: 'Accepting friend request failed.',
          },
          chat: {
            title: 'Conversations',
            pickFriend: 'Select a friend to start chatting',
            onlineNow: 'Live',
            inputPlaceholder: 'Type a message...',
            send: 'Send',
            loadError: 'Failed to load chat history.',
            emptyConversation: 'There are no messages in this conversation yet.',
            sendError: 'Chat service is not connected yet.',
          },
          plans: {
            basic: 'Basic',
            premium: 'Premium',
            vip: 'VIP',
            monthly: 'Monthly Plan',
          },
          statuses: {
            online: 'Online',
            busy: 'Busy',
            offline: 'Offline',
            inactive: 'Inactive',
            active: 'Active',
            expired: 'Expired',
            canceled: 'Canceled',
            pending: 'Pending',
            accepted: 'Accepted',
            blocked: 'Blocked',
          },
          i18n: {
            title: 'Language Settings',
            choose: 'Current Language',
            addTitle: 'Add Language',
            codePlaceholder: 'Language code (e.g. ja-JP)',
            namePlaceholder: 'Display name (e.g. Japanese)',
            dirLabel: 'Text Direction',
            dirLtr: 'Left to Right',
            dirRtl: 'Right to Left',
            jsonPlaceholder: 'Optional: override JSON (same shape as zh-CN)',
            addButton: 'Add Language',
          },
        },
      },
      // WebSocket status key.
      // WebSocket 状态键。
      wsStatusKey: 'disconnected',
      ws: null,
      unreadCount: 0,
      user: {
        id: 'u-1001',
        name: 'Lan Yu',
        level: 'Premium',
        planKey: 'monthly',
      },
      // Current subscription data.
      // 当前订阅数据。
      subscription: {
        planID: '',
        status: 'inactive',
        startedAt: '',
        endedAt: '',
      },
      // Auth form data.
      // 登录注册表单数据。
      auth: {
        account: '',
        password: '',
        email: '',
        phone: '',
      },
      // Profile editing form.
      // 资料编辑表单。
      profileDraft: {
        displayName: '',
      },
      // Space creation form.
      // 空间创建表单。
      spaceDraft: {
        type: 'private',
        name: '',
        description: '',
      },
      // Lightweight feedback text.
      // 轻量反馈文本。
      flashMessage: '',
      errorMessage: '',
      // Language creation form.
      // 新增语言表单。
      newLanguage: {
        code: '',
        name: '',
        dir: 'ltr',
        json: '',
      },
      // Space cards.
      // 空间卡片数据。
      spaces: [
        {
          id: 's1',
          type: 'private',
          name: { 'zh-CN': '灵感仓库', 'en-US': 'Idea Vault' },
          desc: { 'zh-CN': '只属于我的草稿与想法收纳处。', 'en-US': 'A private place for drafts and ideas.' },
        },
        {
          id: 's2',
          type: 'public',
          name: { 'zh-CN': '分享计划', 'en-US': 'Shareboard' },
          desc: { 'zh-CN': '公开更新项目进度与成果。', 'en-US': 'Post public progress updates and results.' },
        },
      ],
      // Social posts list.
      // 社交文章列表。
      posts: [],
      // Post composer form.
      // 文章发布表单。
      postDraft: {
        title: '',
        content: '',
        visibility: 'public',
      },
      // Per-post comment drafts.
      // 每篇文章的评论草稿。
      commentDrafts: {},
      // Membership levels.
      // 会员等级数据。
      levels: [
        {
          name: 'Basic',
          planID: 'basic',
          price: { 'zh-CN': '免费', 'en-US': 'Free' },
          features: {
            'zh-CN': ['基础空间', '好友聊天', '公共空间展示'],
            'en-US': ['Base space quota', 'Friend chat', 'Public showcase'],
          },
        },
        {
          name: 'Premium',
          planID: 'premium',
          price: { 'zh-CN': '¥19/月', 'en-US': '$19/mo' },
          features: {
            'zh-CN': ['更大私人空间', '高级主题', '优先支持'],
            'en-US': ['Larger private space', 'Advanced themes', 'Priority support'],
          },
        },
        {
          name: 'VIP',
          planID: 'vip',
          price: { 'zh-CN': '¥49/月', 'en-US': '$49/mo' },
          features: {
            'zh-CN': ['无限空间', '定制展示', '专属客服'],
            'en-US': ['Unlimited spaces', 'Custom presentation', 'Dedicated support'],
          },
        },
      ],
      // Friend list.
      // 好友列表数据。
      friends: [
        { id: 'f1', name: 'Mira', secondary: 'mira@example.com', status: 'accepted', direction: 'outgoing' },
        { id: 'f2', name: 'Ethan', secondary: '+1 202-555-0189', status: 'accepted', direction: 'outgoing' },
        { id: 'f3', name: 'Kai', secondary: 'kai@example.com', status: 'pending', direction: 'incoming' },
      ],
      // Friend search input.
      // 好友搜索输入框。
      newFriendQuery: '',
      // Friend search results.
      // 好友搜索结果。
      friendSearchResults: [],
      friendSearchPerformed: false,
      // Active chat target.
      // 当前聊天对象。
      activeChat: null,
      // Chat history.
      // 聊天记录。
      chatMessages: [
        { id: 'm1', from: 'f1', content: { 'zh-CN': '今晚要一起看发布会吗？', 'en-US': 'Want to watch the launch event tonight?' }, time: '20:18' },
        { id: 'm2', from: 'u-1001', content: { 'zh-CN': '当然，开个公共空间直播！', 'en-US': 'Sure, let us stream it in the public space!' }, time: '20:19' },
      ],
      // Message input.
      // 输入消息。
      chatInput: '',
    };
  },
  computed: {
    languageOptions() {
      return Object.keys(this.translations).map((code) => ({
        code,
        name: this.getLanguageMeta(code).name,
      }));
    },
    localeDirection() {
      return this.getLanguageMeta(this.locale).dir || 'ltr';
    },
    pageTitle() {
      return this.t(`pageTitle.${this.view}`) || this.t('pageTitle.dashboard');
    },
    pageSub() {
      return this.t(`pageSub.${this.view}`) || '';
    },
    isLoggedIn() {
      return Boolean(this.token);
    },
    wsStatusText() {
      return this.t(`ws.${this.wsStatusKey}`);
    },
    localizedPlan() {
      const planKey = this.subscription.planID || this.user.planKey;
      return this.t(`plans.${planKey}`) || planKey;
    },
    localizedLevelName() {
      return this.t(`plans.${String(this.user.level || '').toLowerCase()}`) || this.user.level;
    },
    acceptedFriends() {
      return this.friends.filter((friend) => friend.status === 'accepted');
    },
    privateSpaces() {
      return this.spaces.filter((s) => s.type === 'private');
    },
    publicSpaces() {
      return this.spaces.filter((s) => s.type === 'public');
    },
  },
  watch: {
    locale(nextLocale) {
      // Keep language preference and HTML lang in sync.
      // 保持语言偏好与 HTML lang 同步。
      localStorage.setItem('locale', nextLocale);
      document.documentElement.lang = nextLocale;
      document.documentElement.dir = this.localeDirection;
      document.title = this.t('htmlTitle');
    },
  },
  methods: {
    getLanguageMeta(code) {
      // Normalize language metadata for built-in and runtime locales.
      // 统一处理内建语言与运行时语言的元数据。
      const meta = this.languageMeta[code];
      if (typeof meta === 'string') {
        return { name: meta, dir: 'ltr' };
      }
      if (meta && typeof meta === 'object') {
        return {
          name: meta.name || code,
          dir: meta.dir || 'ltr',
        };
      }
      return { name: code, dir: 'ltr' };
    },
    t(key) {
      // Resolve translation path with zh-CN fallback.
      // 读取翻译路径并回退到 zh-CN。
      const current = this.getByPath(this.translations[this.locale], key);
      if (typeof current === 'string') {
        return current;
      }
      const fallback = this.getByPath(this.translations['zh-CN'], key);
      return typeof fallback === 'string' ? fallback : key;
    },
    getByPath(obj, path) {
      if (!obj || !path) {
        return null;
      }
      return path.split('.').reduce((acc, segment) => (acc && acc[segment] !== undefined ? acc[segment] : null), obj);
    },
    deepMerge(target, patch) {
      // Deep merge for custom language overrides.
      // 用于新增语言覆盖内容的深度合并。
      const output = Array.isArray(target) ? [...target] : { ...target };
      Object.keys(patch || {}).forEach((key) => {
        const patchValue = patch[key];
        const targetValue = output[key];
        if (
          patchValue &&
          typeof patchValue === 'object' &&
          !Array.isArray(patchValue) &&
          targetValue &&
          typeof targetValue === 'object' &&
          !Array.isArray(targetValue)
        ) {
          output[key] = this.deepMerge(targetValue, patchValue);
          return;
        }
        output[key] = patchValue;
      });
      return output;
    },
    installBuiltinLocales() {
      // Build built-in locales from base dictionaries plus minimal overrides.
      // 通过基础字典和补丁组装内建语言。
      if (!this.translations['zh-TW']) {
        this.translations['zh-TW'] = this.deepMerge(
          JSON.parse(JSON.stringify(this.translations['zh-CN'])),
          {
            htmlTitle: '帳號服務 · 私人空間與公共空間',
            common: { guest: '訪客' },
            nav: {
              auth: '登入 / 註冊',
              dashboard: '帳號主頁',
              private: '私人空間',
              public: '公共空間',
              levels: '會員等級',
              subscription: '訂閱',
              friends: '好友',
              chat: '即時聊天',
            },
            ws: {
              statusLabel: '連線狀態',
              unreadLabel: '未讀訊息',
              connect: '連線聊天',
              disconnect: '中斷聊天',
              disconnected: '未連線',
              connecting: '連線中...',
              connected: '已連線',
              closed: '已中斷',
              needLogin: '需要登入',
            },
            pageTitle: {
              auth: '登入 / 註冊',
              dashboard: '帳號主頁',
              private: '私人空間',
              public: '公共空間',
              levels: '會員等級',
              subscription: '訂閱管理',
              friends: '好友',
              chat: '即時聊天',
            },
            pageSub: {
              auth: '快速進入你的私人空間與公共空間',
              dashboard: '帳戶摘要與空間資訊',
              private: '沉澱個人內容',
              public: '展示公共內容與連結',
              levels: '選擇適合你的會員等級',
              subscription: '管理訂閱與權益',
              friends: '建立聯繫與私聊',
              chat: '即時溝通與回饋',
            },
            auth: {
              welcomeTitle: '歡迎回來',
              welcomeSub: '登入後進入你的私人空間與公共空間。',
              createTitle: '建立新帳號',
              createSub: '加入會員體系，解鎖更大空間與更多互動。',
              accountPlaceholder: '信箱 / 手機',
              passwordPlaceholder: '密碼',
              emailPlaceholder: '信箱',
              phonePlaceholder: '手機號碼',
              login: '登入',
              register: '註冊',
              logout: '登出',
              logoutSuccess: '已登出。',
              loginError: '登入失敗，請檢查帳號和密碼。',
              registerError: '註冊失敗，請檢查輸入資訊。',
            },
            dashboard: {
              overviewTitle: '帳號概覽',
              overviewSub: '清楚掌握你的會員等級、訂閱狀態與空間使用情況。',
              levelStat: '會員等級',
              planStat: '訂閱狀態',
              friendStat: '好友數量',
              spaceSummaryTitle: '空間摘要',
              spaceSummarySub: '私人空間用於沉澱，公共空間用於分享。',
              profileTitle: '資料設定',
              profileSub: '更新顯示名稱，主頁與聊天視窗會同步顯示。',
              displayNamePlaceholder: '輸入顯示名稱',
              saveProfile: '儲存資料',
              saveSuccess: '資料已更新',
              saveError: '資料更新失敗，請稍後重試。',
            },
            spaces: {
              privateSub: '用於自我整理、草稿與私密記錄。',
              publicSub: '分享內容、展示專案、連結更多人。',
              createTitle: '建立空間',
              createSub: '新增一個私人空間或公共空間。',
              namePlaceholder: '空間名稱',
              descPlaceholder: '空間描述',
              createAction: '建立空間',
              createSuccess: '空間已建立',
              createError: '空間建立失敗，請檢查名稱後重試。',
              type: { private: '私人', public: '公共' },
            },
            posts: {
              feedTitle: '公共內容流',
              feedSub: '發布你的近況、想法與專案更新。',
              titlePlaceholder: '文章標題',
              contentPlaceholder: '寫點什麼，分享給大家...',
              publishAction: '發布文章',
              publishSuccess: '文章已發布。',
              publishError: '文章發布失敗，請稍後重試。',
              empty: '公共內容流還沒有文章，先發布第一篇吧。',
              unlike: '取消按讚',
              commentPlaceholder: '寫下你的評論...',
              commentAction: '送出評論',
              commentError: '評論失敗，請稍後重試。',
              share: '轉發',
              shareError: '轉發失敗，請稍後重試。',
              privateLabel: '僅自己可見',
              publicLabel: '公開',
            },
            subscription: {
              title: '訂閱管理',
              currentPlan: '目前方案',
              status: '訂閱狀態',
              startedAt: '開始時間',
              expiresAt: '到期時間',
              renew: '續訂',
              activate: '立即開通',
              empty: '目前還沒有有效訂閱。',
              actionSuccess: '訂閱已生效。',
              actionError: '訂閱操作失敗，請稍後重試。',
            },
            friends: {
              searchPlaceholder: '輸入顯示名稱、信箱、手機號碼或使用者 ID',
              searchAction: '搜尋使用者',
              addAction: '送出請求',
              acceptAction: '接受',
              directionIncoming: '收到的請求',
              directionOutgoing: '我發出的請求',
              empty: '還沒有好友關係，先新增一個吧。',
              searchEmpty: '沒有找到符合的使用者。',
              searchHint: '先搜尋使用者，再發起好友請求。',
              searchError: '使用者搜尋失敗，請稍後重試。',
              addError: '好友請求送出失敗。',
              addSuccess: '好友請求已送出。',
              acceptError: '接受好友請求失敗。',
            },
            chat: {
              title: '會話',
              pickFriend: '選擇好友開始聊天',
              onlineNow: '即時在線',
              inputPlaceholder: '輸入訊息...',
              send: '送出',
              loadError: '聊天記錄載入失敗。',
              emptyConversation: '目前會話還沒有訊息。',
              sendError: '聊天服務尚未連線，請先建立連線。',
            },
            plans: {
              basic: '基礎會員',
              premium: '高級會員',
              vip: 'VIP 會員',
              monthly: '月度訂閱',
            },
            statuses: {
              busy: '忙碌中',
              inactive: '未開通',
              active: '生效中',
              expired: '已過期',
              canceled: '已取消',
              pending: '待確認',
              accepted: '已通過',
              blocked: '已封鎖',
            },
            i18n: {
              title: '語言設定',
              choose: '目前語言',
              addTitle: '新增語言',
              codePlaceholder: '語言代碼（例如：ja-JP）',
              namePlaceholder: '顯示名稱（例如：日本語）',
              dirLabel: '文字方向',
              dirLtr: '由左至右',
              dirRtl: '由右至左',
              jsonPlaceholder: '可選：覆蓋翻譯 JSON（結構比照 zh-CN）',
              addButton: '新增語言',
            },
          },
        );
      }
      if (!this.translations.he) {
        this.translations.he = this.deepMerge(
          JSON.parse(JSON.stringify(this.translations['en-US'])),
          {
            htmlTitle: 'שירות חשבון · מרחב פרטי וציבורי',
            brandSub: 'מרחב פרטי + ציבורי',
            common: { guest: 'אורח' },
            nav: {
              auth: 'כניסה / הרשמה',
              dashboard: 'לוח בקרה',
              private: 'מרחב פרטי',
              public: 'מרחב ציבורי',
              levels: 'חברות',
              subscription: 'מנוי',
              friends: 'חברים',
              chat: 'צ׳אט חי',
            },
            ws: {
              statusLabel: 'מצב חיבור',
              unreadLabel: 'לא נקראו',
              connect: 'התחבר לצ׳אט',
              disconnect: 'התנתק מהצ׳אט',
              disconnected: 'מנותק',
              connecting: 'מתחבר...',
              connected: 'מחובר',
              closed: 'נסגר',
              needLogin: 'נדרשת כניסה',
            },
            pageTitle: {
              auth: 'כניסה / הרשמה',
              dashboard: 'לוח בקרה',
              private: 'מרחב פרטי',
              public: 'מרחב ציבורי',
              levels: 'חברות',
              subscription: 'מנוי',
              friends: 'חברים',
              chat: 'צ׳אט חי',
            },
            pageSub: {
              auth: 'גישה מהירה למרחב הפרטי והציבורי שלך',
              dashboard: 'סיכום חשבון ותובנות על המרחב',
              private: 'ארגון תוכן אישי',
              public: 'שיתוף תוכן ויצירת קשרים',
              levels: 'בחירת רמת החברות המתאימה',
              subscription: 'ניהול תכנית והטבות',
              friends: 'בניית קשרים ושיחה פרטית',
              chat: 'תקשורת בזמן אמת',
            },
            auth: {
              welcomeTitle: 'ברוך הבא בחזרה',
              welcomeSub: 'התחבר כדי לגשת למרחבים הפרטי והציבורי שלך.',
              createTitle: 'יצירת חשבון',
              createSub: 'הצטרף לתכניות החברות ופתח יותר אפשרויות.',
              accountPlaceholder: 'אימייל / טלפון',
              passwordPlaceholder: 'סיסמה',
              emailPlaceholder: 'אימייל',
              phonePlaceholder: 'טלפון',
              login: 'כניסה',
              register: 'הרשמה',
              logout: 'התנתקות',
              logoutSuccess: 'התנתקת.',
              loginError: 'הכניסה נכשלה. בדוק את החשבון והסיסמה.',
              registerError: 'ההרשמה נכשלה. בדוק את הפרטים ונסה שוב.',
            },
            dashboard: {
              overviewTitle: 'סקירת חשבון',
              overviewSub: 'עקוב בקלות אחרי הרמה, המנוי והשימוש במרחבים.',
              levelStat: 'רמת חברות',
              planStat: 'מנוי',
              friendStat: 'חברים',
              spaceSummaryTitle: 'סיכום מרחבים',
              spaceSummarySub: 'מרחבים פרטיים להתמקדות, מרחבים ציבוריים לשיתוף.',
              profileTitle: 'הגדרות פרופיל',
              profileSub: 'עדכן את שם התצוגה עבור הלוח והצ׳אט.',
              displayNamePlaceholder: 'הכנס שם תצוגה',
              saveProfile: 'שמור פרופיל',
              saveSuccess: 'הפרופיל עודכן',
              saveError: 'עדכון הפרופיל נכשל. נסה שוב מאוחר יותר.',
            },
            spaces: {
              privateTitle: 'מרחב פרטי',
              privateSub: 'להערות אישיות, טיוטות ורשומות פרטיות.',
              publicTitle: 'מרחב ציבורי',
              publicSub: 'שתף עדכונים, הצג פרויקטים וצור קשרים.',
              createTitle: 'יצירת מרחב',
              createSub: 'הוסף מרחב פרטי או ציבורי חדש.',
              namePlaceholder: 'שם המרחב',
              descPlaceholder: 'תיאור המרחב',
              createAction: 'צור מרחב',
              createSuccess: 'המרחב נוצר',
              createError: 'יצירת המרחב נכשלה. בדוק את השם ונסה שוב.',
              type: { private: 'פרטי', public: 'ציבורי' },
            },
            posts: {
              feedTitle: 'פיד ציבורי',
              feedSub: 'שתף עדכונים, רעיונות והתקדמות בפרויקט.',
              titlePlaceholder: 'כותרת הפוסט',
              contentPlaceholder: 'כתוב משהו לשתף...',
              publishAction: 'פרסם פוסט',
              publishSuccess: 'הפוסט פורסם.',
              publishError: 'הפרסום נכשל. נסה שוב מאוחר יותר.',
              empty: 'הפיד הציבורי ריק. פרסם את הפוסט הראשון.',
              like: 'לייק',
              unlike: 'בטל לייק',
              comment: 'תגובה',
              commentPlaceholder: 'כתוב תגובה...',
              commentAction: 'שלח תגובה',
              commentError: 'שליחת התגובה נכשלה. נסה שוב מאוחר יותר.',
              share: 'שיתוף',
              shareError: 'השיתוף נכשל. נסה שוב מאוחר יותר.',
              privateLabel: 'פרטי',
              publicLabel: 'ציבורי',
            },
            levels: {
              title: 'רמות חברות',
              upgrade: 'שדרג',
              current: 'הרמה הנוכחית',
            },
            subscription: {
              title: 'מנוי',
              currentPlan: 'תכנית נוכחית',
              status: 'סטטוס',
              startedAt: 'התחיל ב',
              expiresAt: 'פג תוקף ב',
              renew: 'חדש',
              activate: 'הפעל',
              empty: 'עדיין אין מנוי פעיל.',
              actionSuccess: 'המנוי פעיל כעת.',
              actionError: 'פעולת המנוי נכשלה. נסה שוב מאוחר יותר.',
            },
            friends: {
              title: 'חברים',
              chat: 'צ׳אט',
              searchPlaceholder: 'הכנס שם תצוגה, אימייל, טלפון או מזהה משתמש',
              searchAction: 'חפש משתמשים',
              addAction: 'שלח בקשה',
              acceptAction: 'אשר',
              directionIncoming: 'בקשה נכנסת',
              directionOutgoing: 'בקשה יוצאת',
              contactSeparator: ' · ',
              empty: 'עדיין אין חברים. הוסף אחד כדי להתחיל.',
              searchEmpty: 'לא נמצאו משתמשים מתאימים.',
              searchHint: 'חפש משתמש תחילה ואז שלח בקשת חברות.',
              searchError: 'חיפוש המשתמש נכשל. נסה שוב מאוחר יותר.',
              addError: 'שליחת בקשת החברות נכשלה.',
              addSuccess: 'בקשת החברות נשלחה.',
              acceptError: 'אישור בקשת החברות נכשל.',
            },
            chat: {
              title: 'שיחות',
              pickFriend: 'בחר חבר כדי להתחיל צ׳אט',
              onlineNow: 'מחובר כעת',
              inputPlaceholder: 'הקלד הודעה...',
              send: 'שלח',
              loadError: 'טעינת היסטוריית הצ׳אט נכשלה.',
              emptyConversation: 'עדיין אין הודעות בשיחה הזו.',
              sendError: 'שירות הצ׳אט אינו מחובר עדיין.',
            },
            plans: {
              basic: 'בסיסי',
              premium: 'פרימיום',
              vip: 'VIP',
              monthly: 'תכנית חודשית',
            },
            statuses: {
              online: 'מחובר',
              busy: 'עסוק',
              offline: 'לא מחובר',
              inactive: 'לא פעיל',
              active: 'פעיל',
              expired: 'פג תוקף',
              canceled: 'בוטל',
              pending: 'ממתין',
              accepted: 'אושר',
              blocked: 'נחסם',
            },
            i18n: {
              title: 'הגדרות שפה',
              choose: 'שפה נוכחית',
              addTitle: 'הוסף שפה',
              codePlaceholder: 'קוד שפה (למשל: ar)',
              namePlaceholder: 'שם תצוגה',
              dirLabel: 'כיוון טקסט',
              dirLtr: 'משמאל לימין',
              dirRtl: 'מימין לשמאל',
              jsonPlaceholder: 'אופציונלי: JSON לעדיפות תרגום, לפי מבנה zh-CN',
              addButton: 'הוסף שפה',
            },
          },
        );
      }
    },
    clearFeedback() {
      // Reset transient success/error messages before a new action.
      // 在发起新操作前清空临时成功/失败提示。
      this.flashMessage = '';
      this.errorMessage = '';
    },
    setFlash(message) {
      // Store a success message for inline feedback.
      // 保存用于行内展示的成功提示。
      this.flashMessage = message;
      this.errorMessage = '';
    },
    setError(message) {
      // Store an error message for inline feedback.
      // 保存用于行内展示的错误提示。
      this.errorMessage = message;
      this.flashMessage = '';
    },
    disconnectWs() {
      // Close the current websocket connection if it exists.
      // 如果当前存在 WebSocket 连接则主动关闭。
      if (this.ws) {
        this.ws.close();
        this.ws = null;
      }
      this.wsStatusKey = 'disconnected';
    },
    resetSession() {
      // Reset local session state after logout or auth loss.
      // 在登出或鉴权失效后重置本地会话状态。
      this.disconnectWs();
      this.token = '';
      this.unreadCount = 0;
      this.user = {
        id: 'guest',
        name: this.t('common.guest'),
        level: 'Basic',
        planKey: 'monthly',
      };
      this.subscription = {
        planID: '',
        status: 'inactive',
        startedAt: '',
        endedAt: '',
      };
      this.posts = [];
      this.postDraft.title = '';
      this.postDraft.content = '';
      this.postDraft.visibility = 'public';
      this.commentDrafts = {};
      this.friends = [];
      this.newFriendQuery = '';
      this.friendSearchResults = [];
      this.friendSearchPerformed = false;
      this.chatMessages = [];
      this.activeChat = null;
      this.profileDraft.displayName = '';
      this.auth.account = '';
      this.auth.password = '';
      localStorage.removeItem('token');
    },
    statusLabel(status) {
      return this.t(`statuses.${status}`) || status;
    },
    directionLabel(direction) {
      return this.t(`friends.direction${direction === 'incoming' ? 'Incoming' : 'Outgoing'}`) || direction;
    },
    friendSecondary(friend) {
      // Render the best available secondary contact text.
      // 渲染可用的次级联系信息。
      return friend.secondary || friend.id;
    },
    searchResultActionLabel(result) {
      // Render the action label for a user search result.
      // 渲染用户搜索结果对应的操作文案。
      if (!result.relationStatus) {
        return this.t('friends.addAction');
      }
      return this.statusLabel(result.relationStatus);
    },
    searchResultDisabled(result) {
      // Only allow adding users without an existing relation.
      // 仅允许对尚未建立关系的用户发起添加。
      return Boolean(result.relationStatus);
    },
    formatDateTime(value) {
      // Format backend timestamps into locale-aware display text.
      // 将后端时间戳格式化为本地化展示文本。
      if (!value) {
        return this.t('common.notAvailable');
      }
      const date = new Date(value);
      if (Number.isNaN(date.getTime())) {
        return this.t('common.notAvailable');
      }
      return date.toLocaleString(this.locale, {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
      });
    },
    localizedSpaceText(field, item) {
      return item[field][this.locale] || item[field]['zh-CN'] || '';
    },
    localizedLevelPrice(level) {
      return level.price[this.locale] || level.price['zh-CN'];
    },
    localizedLevelFeatures(level) {
      return level.features[this.locale] || level.features['zh-CN'] || [];
    },
    visibilityLabel(visibility) {
      return visibility === 'private' ? this.t('posts.privateLabel') : this.t('posts.publicLabel');
    },
    isCurrentLevel(level) {
      // Check whether the level card matches the current user tier.
      // 判断当前等级卡片是否对应用户当前等级。
      return String(this.user.level || '').toLowerCase() === String(level.planID || '').toLowerCase();
    },
    localizedMessageContent(message) {
      if (typeof message.content === 'string') {
        return message.content;
      }
      return message.content[this.locale] || message.content['zh-CN'] || '';
    },
    addLanguage() {
      // Add a new language at runtime.
      // 运行时新增语言。
      const code = this.newLanguage.code.trim();
      const name = this.newLanguage.name.trim();
      if (!code || !name) {
        return;
      }

      let customPatch = {};
      if (this.newLanguage.json.trim()) {
        try {
          customPatch = JSON.parse(this.newLanguage.json);
        } catch (_error) {
          return;
        }
      }

      const base = JSON.parse(JSON.stringify(this.translations['zh-CN']));
      this.translations[code] = this.deepMerge(base, customPatch);
      this.languageMeta[code] = { name, dir: this.newLanguage.dir || 'ltr' };

      this.newLanguage.code = '';
      this.newLanguage.name = '';
      this.newLanguage.dir = 'ltr';
      this.newLanguage.json = '';
      this.locale = code;
    },
    async login() {
      // Login and store token.
      // 登录并保存 token。
      this.clearFeedback();
      if (!this.auth.account || !this.auth.password) {
        return;
      }
      const res = await fetch(`${this.apiBase}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          account: this.auth.account,
          password: this.auth.password,
        }),
      });
      if (!res.ok) {
        this.setError(this.t('auth.loginError'));
        return;
      }
      const data = await res.json();
      this.token = data.token || '';
      if (this.token) {
        localStorage.setItem('token', this.token);
        await this.loadMe();
        await this.loadSpaces();
        await this.loadSubscription();
        await this.loadPosts();
        await this.loadFriends();
        if (this.activeChat) {
          await this.loadConversation(this.activeChat.id);
        } else {
          await this.loadUnread();
        }
        this.view = 'dashboard';
      }
    },
    async register() {
      // Register a new user.
      // 注册新用户。
      this.clearFeedback();
      if (!this.auth.password) {
        return;
      }
      const res = await fetch(`${this.apiBase}/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: this.auth.email,
          phone: this.auth.phone,
          password: this.auth.password,
        }),
      });
      if (!res.ok) {
        this.setError(this.t('auth.registerError'));
        return;
      }
      const data = await res.json();
      this.token = data.token || '';
      if (this.token) {
        localStorage.setItem('token', this.token);
        await this.loadMe();
        await this.loadSpaces();
        await this.loadSubscription();
        await this.loadPosts();
        await this.loadFriends();
        if (this.activeChat) {
          await this.loadConversation(this.activeChat.id);
        } else {
          await this.loadUnread();
        }
        this.view = 'dashboard';
      }
    },
    async loadMe() {
      // Load current user profile.
      // 加载当前用户资料。
      if (!this.token) {
        return;
      }
      const res = await fetch(`${this.apiBase}/me`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.resetSession();
        this.view = 'auth';
        return;
      }
      const data = await res.json();
      this.user.id = data.user_id || this.user.id;
      this.user.name = data.display_name || this.user.name;
      this.user.level = data.level || this.user.level;
      this.profileDraft.displayName = data.display_name || '';
    },
    async loadSpaces() {
      // Load spaces from server.
      // 从服务端加载空间。
      if (!this.token) {
        return;
      }
      const res = await fetch(`${this.apiBase}/spaces`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      if (Array.isArray(data.items)) {
        this.spaces = data.items.map((item) => ({
          id: item.id,
          type: item.type,
          name: {
            'zh-CN': item.name,
            'en-US': item.name,
          },
          desc: {
            'zh-CN': item.description,
            'en-US': item.description,
          },
        }));
      }
    },
    async loadSubscription() {
      // Load the latest subscription for the current user.
      // 加载当前用户最新订阅。
      if (!this.token) {
        return;
      }
      const res = await fetch(`${this.apiBase}/subscriptions/current`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      this.subscription = {
        planID: data.plan_id || '',
        status: data.status || 'inactive',
        startedAt: data.started_at || '',
        endedAt: data.ended_at || '',
      };
    },
    async loadPosts() {
      // Load the public content feed.
      // 加载公共内容流。
      if (!this.token) {
        return;
      }
      const res = await fetch(`${this.apiBase}/posts?visibility=public&limit=50`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      if (Array.isArray(data.items)) {
        this.posts = data.items.map((item) => ({
          id: item.id,
          userId: item.user_id,
          authorName: item.author_name,
          title: item.title,
          content: item.content,
          visibility: item.visibility,
          likesCount: Number(item.likes_count || 0),
          commentsCount: Number(item.comments_count || 0),
          sharesCount: Number(item.shares_count || 0),
          likedByMe: Boolean(item.liked_by_me),
          createdAt: item.created_at,
          comments: Array.isArray(item.comments)
            ? item.comments.map((comment) => ({
                id: comment.id,
                authorName: comment.author_name,
                content: comment.content,
                createdAt: comment.created_at,
              }))
            : [],
        }));
      }
    },
    async createPost() {
      // Create a new social post.
      // 创建新的社交文章。
      this.clearFeedback();
      if (!this.token || !this.postDraft.title.trim() || !this.postDraft.content.trim()) {
        return;
      }
      const res = await fetch(`${this.apiBase}/posts`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: this.postDraft.title.trim(),
          content: this.postDraft.content.trim(),
          visibility: this.postDraft.visibility,
        }),
      });
      if (!res.ok) {
        this.setError(this.t('posts.publishError'));
        return;
      }
      this.postDraft.title = '';
      this.postDraft.content = '';
      this.postDraft.visibility = 'public';
      await this.loadPosts();
      this.setFlash(this.t('posts.publishSuccess'));
    },
    async togglePostLike(post) {
      // Toggle like state for a post.
      // 切换文章点赞状态。
      this.clearFeedback();
      if (!this.token || !post) {
        return;
      }
      const res = await fetch(`${this.apiBase}/posts/${post.id}/likes`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      await this.loadPosts();
    },
    async submitComment(post) {
      // Submit a comment to a post.
      // 向文章提交评论。
      this.clearFeedback();
      const content = this.commentDrafts[post.id] || '';
      if (!this.token || !post || !content.trim()) {
        return;
      }
      const res = await fetch(`${this.apiBase}/posts/${post.id}/comments`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: content.trim(),
        }),
      });
      if (!res.ok) {
        this.setError(this.t('posts.commentError'));
        return;
      }
      this.commentDrafts[post.id] = '';
      await this.loadPosts();
    },
    async sharePost(post) {
      // Share a post in the social feed.
      // 在内容流中转发文章。
      this.clearFeedback();
      if (!this.token || !post) {
        return;
      }
      const res = await fetch(`${this.apiBase}/posts/${post.id}/shares`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.setError(this.t('posts.shareError'));
        return;
      }
      await this.loadPosts();
    },
    async saveProfile() {
      // Persist display name changes to the account service.
      // 将展示名称修改保存到账号服务。
      this.clearFeedback();
      if (!this.token || !this.profileDraft.displayName.trim()) {
        return;
      }
      const res = await fetch(`${this.apiBase}/me`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          display_name: this.profileDraft.displayName.trim(),
        }),
      });
      if (!res.ok) {
        this.setError(this.t('dashboard.saveError'));
        return;
      }
      await this.loadMe();
      this.setFlash(this.t('dashboard.saveSuccess'));
    },
    async createSubscription(planID = 'premium') {
      // Create or renew the default monthly subscription.
      // 创建或续订指定会员订阅。
      this.clearFeedback();
      if (!this.token) {
        return;
      }
      const res = await fetch(`${this.apiBase}/subscriptions`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          plan_id: planID,
        }),
      });
      if (!res.ok) {
        this.setError(this.t('subscription.actionError'));
        return;
      }
      await this.loadSubscription();
      await this.loadMe();
      this.setFlash(this.t('subscription.actionSuccess'));
    },
    async createSpace() {
      // Create a new private/public space from the current form.
      // 根据当前表单创建新的私人/公共空间。
      this.clearFeedback();
      if (!this.token || !this.spaceDraft.name.trim()) {
        return;
      }
      const res = await fetch(`${this.apiBase}/spaces`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          type: this.spaceDraft.type,
          name: this.spaceDraft.name.trim(),
          description: this.spaceDraft.description.trim(),
        }),
      });
      if (!res.ok) {
        this.setError(this.t('spaces.createError'));
        return;
      }
      this.spaceDraft.name = '';
      this.spaceDraft.description = '';
      await this.loadSpaces();
      this.setFlash(this.t('spaces.createSuccess'));
    },
    async loadFriends() {
      // Load friend list from server.
      // 从服务端加载好友列表。
      if (!this.token) {
        return;
      }
      const res = await fetch(`${this.apiBase}/friends`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      if (Array.isArray(data.items)) {
        this.friends = data.items.map((item) => ({
          id: item.friend_id,
          name: item.display_name || item.email || item.phone || item.friend_id,
          secondary: item.email || item.phone || item.friend_id,
          status: item.status || 'offline',
          direction: item.direction || 'outgoing',
        }));
        if (!this.activeChat || !this.acceptedFriends.find((friend) => friend.id === this.activeChat.id)) {
          this.activeChat = this.acceptedFriends[0] || null;
          if (!this.activeChat) {
            this.chatMessages = [];
          }
        }
      }
    },
    async searchUsers() {
      // Search users that can be added as friends.
      // 搜索可添加为好友的用户。
      this.clearFeedback();
      if (!this.token || !this.newFriendQuery.trim()) {
        this.friendSearchResults = [];
        this.friendSearchPerformed = false;
        return;
      }
      const query = encodeURIComponent(this.newFriendQuery.trim());
      const res = await fetch(`${this.apiBase}/users/search?q=${query}`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.setError(this.t('friends.searchError'));
        return;
      }
      const data = await res.json();
      this.friendSearchResults = Array.isArray(data.items)
        ? data.items.map((item) => ({
            id: item.user_id,
            name: item.display_name || item.email || item.phone || item.user_id,
            secondary: item.email || item.phone || item.user_id,
            relationStatus: item.relation_status || '',
            direction: item.direction || '',
          }))
        : [];
      this.friendSearchPerformed = true;
    },
    async loadConversation(friendID) {
      // Load chat history for the selected friend.
      // 加载当前好友的历史会话。
      if (!this.token || !friendID) {
        this.chatMessages = [];
        return;
      }
      this.chatMessages = [];
      const params = new URLSearchParams({ peer_id: friendID, limit: '100' });
      const res = await fetch(`${this.messageApiBase}/messages?${params.toString()}`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.setError(this.t('chat.loadError'));
        return;
      }
      const data = await res.json();
      if (Array.isArray(data.items)) {
        this.chatMessages = data.items.map((item) => ({
          id: item.id,
          from: item.sender_id,
          content: {
            'zh-CN': item.content,
            'en-US': item.content,
          },
          time: new Date(item.created_at).toLocaleTimeString(this.locale, { hour: '2-digit', minute: '2-digit' }),
        }));
      }
      await this.loadUnread();
    },
    async loadUnread() {
      // Load aggregate unread count.
      // 加载未读消息总数。
      if (!this.token) {
        this.unreadCount = 0;
        return;
      }
      const res = await fetch(`${this.messageApiBase}/unread`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      this.unreadCount = Number(data.unread || 0);
    },
    async addFriend(result) {
      // Send a new friend request to the selected user.
      // 向选中的用户发送好友请求。
      this.clearFeedback();
      if (!this.token || !result || !result.id) {
        return;
      }
      const res = await fetch(`${this.apiBase}/friends`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          friend_id: result.id,
        }),
      });
      if (!res.ok) {
        this.setError(this.t('friends.addError'));
        return;
      }
      this.friendSearchResults = this.friendSearchResults.map((item) => (
        item.id === result.id
          ? { ...item, relationStatus: 'pending', direction: 'outgoing' }
          : item
      ));
      await this.loadFriends();
      this.setFlash(this.t('friends.addSuccess'));
    },
    async acceptFriend(friend) {
      // Accept an incoming friend request.
      // 接受收到的好友请求。
      this.clearFeedback();
      if (!this.token || !friend || friend.direction !== 'incoming') {
        return;
      }
      const res = await fetch(`${this.apiBase}/friends/accept`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          friend_id: friend.id,
        }),
      });
      if (!res.ok) {
        this.setError(this.t('friends.acceptError'));
        return;
      }
      await this.loadFriends();
      if (this.friendSearchPerformed && this.newFriendQuery.trim()) {
        await this.searchUsers();
      }
    },
    async startChat(friend) {
      // Switch to chat view and set active friend.
      // 切换到聊天视图并设置好友。
      if (friend.status !== 'accepted') {
        return;
      }
      this.view = 'chat';
      this.activeChat = friend;
      this.chatMessages = [];
      await this.loadConversation(friend.id);
    },
    connectWs() {
      // Create websocket connection.
      // 创建 WebSocket 连接。
      if (!this.token) {
        this.wsStatusKey = 'needLogin';
        this.view = 'auth';
        return;
      }
      if (this.ws) {
        this.ws.close();
      }
      this.wsStatusKey = 'connecting';
      this.ws = new WebSocket(`ws://localhost:8081/ws?token=${this.token}`);
      this.ws.onopen = () => {
        this.wsStatusKey = 'connected';
      };
      this.ws.onclose = () => {
        this.wsStatusKey = 'closed';
      };
      this.ws.onmessage = (event) => {
        // Append incoming message.
        // 追加接收消息。
        const payload = JSON.parse(event.data);
        const relatesToActiveChat =
          this.activeChat &&
          (payload.from === this.activeChat.id || payload.to === this.activeChat.id);
        if (relatesToActiveChat) {
          this.chatMessages.push({
            id: `m-${Date.now()}`,
            from: payload.from,
            content: {
              'zh-CN': payload.content,
              'en-US': payload.content,
            },
            time: new Date(payload.created_at || Date.now()).toLocaleTimeString(this.locale, { hour: '2-digit', minute: '2-digit' }),
          });
        }
        this.loadUnread();
      };
    },
    async logout() {
      // Logout from the current session and clear local state.
      // 退出当前会话并清理本地状态。
      this.clearFeedback();
      if (this.token) {
        await fetch(`${this.apiBase}/logout`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${this.token}` },
        }).catch(() => null);
      }
      this.resetSession();
      this.view = 'auth';
      this.setFlash(this.t('auth.logoutSuccess'));
    },
    sendMessage() {
      // Send message to active friend.
      // 发送消息给当前好友。
      this.clearFeedback();
      if (!this.chatInput.trim() || !this.activeChat) {
        return;
      }
      const message = {
        to: this.activeChat.id,
        content: this.chatInput.trim(),
      };
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify(message));
      } else {
        this.setError(this.t('chat.sendError'));
        return;
      }
      this.chatInput = '';
    },
  },
  mounted() {
    // Default active chat.
    // 默认选中第一个好友。
    this.activeChat = this.acceptedFriends[0] || null;

    // Restore language from local storage.
    // 从本地存储恢复语言。
    this.installBuiltinLocales();
    const savedLocale = localStorage.getItem('locale');
    if (savedLocale && this.translations[savedLocale]) {
      this.locale = savedLocale;
    }
    document.documentElement.lang = this.locale;
    document.documentElement.dir = this.localeDirection;
    document.title = this.t('htmlTitle');

    // Load token from storage.
    // 从本地存储读取 token。
    const stored = localStorage.getItem('token');
    if (stored) {
      this.token = stored;
      this.loadMe();
      this.loadSpaces();
      this.loadSubscription();
      this.loadPosts();
      this.loadFriends().then(() => {
        if (this.activeChat) {
          this.loadConversation(this.activeChat.id);
        } else {
          this.loadUnread();
        }
      });
    }
  },
}).mount('#app');
