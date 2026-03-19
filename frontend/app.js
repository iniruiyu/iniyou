const { createApp } = Vue;

// Persisted active space keys.
// 持久化的当前空间键。
const ACTIVE_PRIVATE_SPACE_KEY = 'iniyou_active_private_space';
const ACTIVE_PUBLIC_SPACE_KEY = 'iniyou_active_public_space';

// Quick chat presets for emoji/sticker insertion.
// 聊天快捷预设，便于插入表情与贴纸。
const CHAT_QUICK_SNIPPETS = [
  { kind: 'emoji', value: '😀', label: '😀' },
  { kind: 'emoji', value: '😂', label: '😂' },
  { kind: 'emoji', value: '🥳', label: '🥳' },
  { kind: 'emoji', value: '👍', label: '👍' },
  { kind: 'emoji', value: '❤️', label: '❤️' },
  { kind: 'emoji', value: '🔥', label: '🔥' },
  { kind: 'sticker', value: '【开心】', label: '开心' },
  { kind: 'sticker', value: '【加油】', label: '加油' },
  { kind: 'sticker', value: '【收到】', label: '收到' },
  { kind: 'sticker', value: '【抱抱】', label: '抱抱' },
  { kind: 'sticker', value: '【赞】', label: '点赞' },
  { kind: 'sticker', value: '【感谢】', label: '感谢' },
];
const CHAT_STICKER_TOKENS = new Set(
  CHAT_QUICK_SNIPPETS.filter((item) => item.kind === 'sticker').map(
    (item) => item.value,
  ),
);

const app = createApp({
  data() {
    return {
      // Current view in SPA.
      // 当前 SPA 视图。
      view: 'auth',
      // API base URL.
      // 接口基础地址。
      apiBase: 'http://localhost:8080/api/v1',
      // Space service API base URL.
      // 空间服务接口基础地址。
      spaceApiBase: 'http://localhost:8082/api/v1',
      // Message service API base URL.
      // 通讯服务接口基础地址。
      messageApiBase: 'http://localhost:8081/api/v1',
      // Visible auth mode on the guest landing page.
      // 未登录首页当前显示的认证模式。
      authMode: 'login',
      // Settings dropdown visibility.
      // 设置下拉菜单显示状态。
      settingsOpen: false,
      // Sidebar collapsed state.
      // 侧边栏折叠状态。
      sidebarCollapsed: false,
      // JWT token.
      // JWT 令牌。
      token: '',
      // Current language code.
      // 当前语言代码。
      locale: 'zh-CN',
      // Current profile tab.
      // 当前个人主页选项卡。
      profileTab: 'levels',
      // Active private space ID.
      // 当前私人空间 ID。
      activePrivateSpaceId: '',
      // Active public space ID.
      // 当前公共空间 ID。
      activePublicSpaceId: '',
      // Theme selection.
      // 皮肤主题选择。
      theme: 'midnight',
      // Language display names.
      // 语言显示名称。
      languageMeta: {
        'zh-CN': { name: '简体中文', dir: 'ltr' },
        'zh-TW': { name: '繁體中文', dir: 'ltr' },
        'en-US': { name: 'English', dir: 'ltr' },
      },
      // Theme options for skin switching.
      // 皮肤切换可选主题。
      themeOptions: [
        { value: 'midnight', labelKey: 'theme.options.midnight' },
        { value: 'dawn', labelKey: 'theme.options.dawn' },
        { value: 'ocean', labelKey: 'theme.options.ocean' },
      ],
      // i18n dictionaries. New languages can be appended at runtime.
      // 国际化字典，可在运行时追加新语言。
      translations: {
        'zh-CN': {
          htmlTitle: '账号服务 · 身份卡与空间',
          brandSub: '身份卡 + 空间',
          landing: {
            heroPill: '登录或注册后进入工作台',
            heroTitle: '先完成账号流程，再进入首页与工作台。',
            heroSub: '未登录用户先进入登录或注册流程。登录与注册共用一个入口区，但同一时间只显示一个表单。',
            authEyebrow: '账号入口',
            loginHint: '输入账号后直接进入控制台。',
            registerHint: '创建账号后自动进入你的空间。',
            statStepOne: '选择登录或注册，缩短首次进入路径。',
            statStepTwo: '完成认证后进入首页。',
            statStepThree: '语言切换保持在右上角稳定可见。',
            previewLabel: 'Auth Flow',
            previewTitle: '未登录态聚焦在账号流程',
            previewSub: '账号入口、语言设置和功能说明分区清晰，避免在首页提前展示完整业务模块。',
            featurePrivateTitle: '可见范围',
            featurePrivateSub: '按需设置所有人可见、好友可见或仅自己可见。',
            featurePublicTitle: '空间',
            featurePublicSub: '展示项目、发布内容并建立连接。',
            featureLiveTitle: '实时互动',
            featureLiveSub: '登录后进入聊天、好友和资料工作台。',
          },
          settings: {
            menu: '设置',
            customize: '界面与语言',
          },
          profile: {
            identity: {
              title: '身份卡',
              sub: '昵称和域名分开维护，域名用于登录和子域名入口。',
              nickname: '用户昵称',
              username: '用户名',
              domain: '域名',
              signature: '签名',
              phoneVisibility: '手机号可见范围',
              emailVisibility: '邮箱可见范围',
              ageVisibility: '年龄可见范围',
              genderVisibility: '性别可见范围',
              visibility: {
                public: '公开',
                friends: '仅好友可见',
                private: '仅自己可见',
              },
              domainPlaceholder: '输入域名',
              signaturePlaceholder: '输入签名',
              domainHint: '域名只能使用英文字母和数字，长度不超过 63，并作为身份卡和登录入口。',
              domainRequired: '请输入域名。',
              domainError: '域名只能包含英文字母和数字，且最长 63 个字符。',
              save: '保存身份卡',
            },
            tabs: {
              levels: '会员等级',
              subscription: '订阅',
              blockchain: '链上账号',
            },
            levels: {
              title: '会员等级',
              sub: '选择适合你的会员等级方案。',
            },
            subscription: {
              title: '订阅概览',
              sub: '查看订阅方案与到期时间。',
            },
            blockchain: {
              title: '链上账号概览',
              sub: '查看已绑定的链上账号。',
              empty: '尚未绑定链上账号。',
            },
            spaces: {
              title: '公开空间',
              sub: '查看当前用户公开展示的空间。',
              empty: '当前没有公开空间。',
            },
          },
          profileMenu: {
            title: '个人主页菜单',
            subtitle: '会员等级、订阅、链上账号',
          },
          theme: {
            title: '外观皮肤',
            label: '选择皮肤',
            options: {
              midnight: '深空黑',
              dawn: '晨光白',
              ocean: '深海蓝',
            },
          },
          common: {
            guest: '访客',
            notAvailable: '--',
            cancel: '取消',
          },
          nav: {
            auth: '登录注册',
            dashboard: '账号主页',
            space: '空间',
            profile: '用户主页',
            postDetail: '文章详情',
            levels: '会员等级',
            subscription: '订阅',
            blockchain: '链上账号',
            friends: '好友',
            chat: '实时聊天',
            collapse: '折叠导航',
            expand: '展开导航',
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
            auth: '登录注册',
            dashboard: '账号主页',
            space: '空间',
            private: '空间',
            public: '空间',
            profile: '用户主页',
            postDetail: '文章详情',
            levels: '会员等级',
            subscription: '订阅管理',
            blockchain: '链上账号',
            friends: '好友',
            chat: '实时聊天',
          },
          pageSub: {
            auth: '快速进入你的身份卡与空间',
            dashboard: '账户摘要与空间信息',
            space: '查看可见空间并发布内容',
            private: '查看可见空间并发布内容',
            public: '浏览可见空间与内容',
            profile: '查看作者的公开内容与互动记录',
            postDetail: '查看文章正文、评论与互动详情',
            levels: '选择适合你的会员等级',
            subscription: '管理订阅与权益',
            blockchain: '管理外部区块链账号绑定',
            friends: '建立联系与私聊',
            chat: '实时沟通与反馈',
          },
          auth: {
            welcomeTitle: '欢迎回来',
            welcomeSub: '登录后进入你的身份卡与空间。',
            createTitle: '创建新账号',
            createSub: '加入会员体系，解锁更大空间与更多互动。',
            accountPlaceholder: '邮箱、手机、用户名、域名',
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
            blockchainStat: '链上账号',
            spaceSummaryTitle: '空间摘要',
            spaceSummarySub: '空间用于展示与分享，创建者可以单独设置可见范围。',
            profileTitle: '资料设置',
            profileSub: '更新展示名称和用户名，主页与聊天窗口会同步显示。',
            blockchainTitle: '链上扩展',
            blockchainSub: '已绑定链上账号会在这里汇总，便于后续资产与身份联动。',
            displayNamePlaceholder: '输入昵称',
            usernamePlaceholder: '输入用户名',
            usernameHint: '仅允许英文字母和数字，长度不超过 63，并作为二级域名使用。',
            usernameRequired: '请输入用户名。',
            usernameError: '用户名只能包含英文字母和数字，且最长 63 个字符。',
            saveProfile: '保存资料',
            saveSuccess: '资料已更新',
            saveError: '资料更新失败，请稍后重试。',
          },
          spaces: {
            privateTitle: '空间',
            privateSub: '查看可见空间并管理内容。',
            publicTitle: '空间',
            publicSub: '分享内容、展示项目、连接更多人。',
            createTitle: '创建空间',
            createSub: '名称、二级域名和可见范围可以独立设置，留空时会自动生成。',
            editTitle: '编辑空间',
            editSub: '修改名称、描述、二级域名和可见范围，名称和域名互不关联。',
            settingsAction: '设置空间资料',
            typeLabel: '空间类型',
            namePlaceholder: '空间名称',
            descPlaceholder: '空间描述',
            subdomainLabel: '二级域名',
            subdomainHint: '仅允许英文字母和数字，长度不超过 63，留空时后端会自动生成。',
            subdomainEditHint: '仅允许英文字母和数字，长度不超过 63。',
            createAction: '创建空间',
            editAction: '编辑空间',
            saveAction: '保存修改',
            currentLabel: '当前空间',
            enterAction: '进入空间',
            visibilityLabel: '可见范围',
            createSuccess: '空间已创建',
            createError: '空间创建失败，请检查名称后重试。',
            editSuccess: '空间已更新。',
            editError: '空间更新失败，请稍后重试。',
            deleteAction: '删除空间',
            deleteConfirm: '删除空间后，该空间及其内容都会被移除，是否继续？',
            deleteSuccess: '空间已删除。',
            deleteError: '空间删除失败，请稍后重试。',
            subdomainRequired: '编辑空间时二级域名不能为空。',
            subdomainError: '二级域名只能包含英文字母和数字，且最长 63 个字符。',
            type: {
              private: '空间',
              public: '空间',
            },
            visibility: {
              public: '所有人可见',
              friends: '好友可见',
              private: '仅自己可见',
            },
          },
          posts: {
            feedTitle: '空间内容流',
            feedSub: '创建者可以在进入空间后发帖，其他人可查看并互动。',
            privateFeedTitle: '空间内容',
            privateFeedSub: '查看你发布的文章。',
            profileFeedTitle: '作者内容',
            profileFeedSub: '浏览该作者公开发布的文章。',
            creatorHint: '只有空间创建者可以在这里发帖、设置空间资料并管理帖子，其他人可查看并点赞、评论、回复。',
            viewerHint: '你当前以访客身份浏览该空间，只能点赞、评论和回复。',
            titlePlaceholder: '文章标题',
            contentPlaceholder: '写点什么，分享给大家...',
            publishAction: '发布文章',
            visibilityLabel: '可见性',
            spaceLabel: '所属空间',
            spaceRequired: '请先进入或创建对应空间。',
            publishSuccess: '文章已发布。',
            publishError: '文章发布失败，请稍后重试。',
            privateEmpty: '当前空间里还没有文章。',
            publicEmpty: '空间里还没有文章，先发布第一篇吧。',
            profileEmpty: '该作者还没有公开文章。',
            empty: '空间里还没有文章，先发布第一篇吧。',
            like: '点赞',
            unlike: '取消点赞',
            comment: '评论',
            commentPlaceholder: '写下你的评论...',
            commentAction: '发送评论',
            commentError: '评论失败，请稍后重试。',
            reply: '回复',
            replyPlaceholder: '写下回复...',
            replyAction: '发送回复',
            cancelReply: '取消回复',
            share: '转发',
            shareError: '转发失败，请稍后重试。',
            deleteAction: '删除文章',
            deleteConfirm: '删除文章后，相关评论、点赞和转发也会被移除，是否继续？',
            deleteSuccess: '文章已删除。',
            deleteError: '文章删除失败，请稍后重试。',
            privateLabel: '仅自己可见',
            publicLabel: '公开',
            viewAuthor: '查看作者主页',
            backToFeed: '返回空间',
            articleCount: '文章数',
            openChat: '发起聊天',
            addFriend: '添加好友',
            acceptFriend: '接受好友',
            openDetail: '查看详情',
            edit: '编辑文章',
            editTitle: '编辑文章',
            editAction: '保存修改',
            editSuccess: '文章已更新。',
            editError: '文章更新失败，请稍后重试。',
            statusLabel: '发布状态',
            statusDraft: '草稿',
            statusPublished: '已发布',
            statusHidden: '已隐藏',
            attachImage: '添加图片',
            attachVideo: '添加小视频',
            clearMedia: '清除媒体',
            mediaPreview: '媒体预览',
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
          blockchain: {
            title: '链上账号绑定',
            sub: '绑定外部区块链地址，为后续链上身份和资产能力预留入口。',
            providerLabel: '提供方',
            chainLabel: '链网络',
            addressPlaceholder: '钱包地址、账号地址',
            signaturePlaceholder: '签名载荷（必填，用于基础校验）',
            securityHint: '当前版本会校验提供方、链类型、地址格式和签名载荷长度。',
            bindAction: '绑定账号',
            removeAction: '解绑',
            empty: '当前还没有绑定任何链上账号。',
            bindSuccess: '链上账号已绑定。',
            bindError: '链上账号绑定失败，请检查输入后重试。',
            removeSuccess: '链上账号已解绑。',
            removeError: '链上账号解绑失败，请稍后重试。',
            boundAt: '绑定时间',
            openManager: '管理绑定',
            connectedChains: '已连接链',
          },
          friends: {
            title: '好友',
            chat: '聊天',
            searchPlaceholder: '输入展示名、用户名、域名、邮箱、手机号或用户 ID',
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
            quickTitle: '常用表情与贴纸',
            quickPanelTitle: '表情包面板',
            quickPanelHint: '表情与文字表情分开显示。',
            quickEmojiTitle: '常用表情',
            quickStickerTitle: '文字表情',
            quickToggle: '表情',
            quickClose: '关闭',
            backToBottom: '回到底部',
            pickFriend: '选择好友开始聊天',
            onlineNow: '实时在线',
            latest: '最近消息',
            inputPlaceholder: '输入消息...',
            send: '发送',
            loadError: '聊天记录加载失败。',
            emptyConversation: '当前会话还没有消息。',
            sendError: '聊天服务未连接，请先建立连接。',
            attachImage: '图片',
            attachVideo: '视频',
            attachAudio: '语音',
            clearAttachment: '清除附件',
            attachmentHint: '附件会先压缩，7天后自动删除。',
            openAttachment: '打开附件',
            mediaImage: '图片',
            mediaVideo: '视频',
            mediaAudio: '语音',
            mediaFile: '文件',
            friendProfileTitle: '好友资料',
            friendProfileSub: '查看好友的公开资料、联系方式和关系状态。',
            viewProfile: '查看资料',
            friendStatus: '好友状态',
            friendDirection: '关系方向',
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
          htmlTitle: 'Account Service · Space',
          brandSub: 'Identity card + Space',
          landing: {
            heroPill: 'Complete auth before entering the workspace',
            heroTitle: 'Finish the account flow first, then enter the dashboard.',
            heroSub: 'Signed-out users enter the sign-in or sign-up flow first. Both actions share one entry area, but only one form is shown at a time.',
            authEyebrow: 'Account Access',
            loginHint: 'Sign in and jump straight into the workspace.',
            registerHint: 'Create an account and enter your space immediately.',
            statStepOne: 'Choose sign in or sign up for a shorter entry path.',
            statStepTwo: 'Enter the home dashboard after authentication.',
            statStepThree: 'Keep language switching stable in the top-right menu.',
            previewLabel: 'Auth Flow',
            previewTitle: 'Keep the signed-out state focused on account flow',
            previewSub: 'Separate account entry, language settings, and feature guidance clearly instead of exposing the full workspace before login.',
            featurePrivateTitle: 'Visibility',
            featurePrivateSub: 'Set content to visible to everyone, friends only, or only you.',
            featurePublicTitle: 'Space',
            featurePublicSub: 'Showcase projects, publish updates, and build connections.',
            featureLiveTitle: 'Live Collaboration',
            featureLiveSub: 'Open chat, friends, and profile tools after sign-in.',
          },
          settings: {
            menu: 'Settings',
            customize: 'Language & interface',
          },
          profile: {
            identity: {
              title: 'Identity Card',
              sub: 'Keep nickname and domain separate. The domain is your login handle and subdomain entry.',
              nickname: 'Nickname',
              username: 'Username',
              domain: 'Domain',
              signature: 'Signature',
              phoneVisibility: 'Phone visibility',
              emailVisibility: 'Email visibility',
              ageVisibility: 'Age visibility',
              genderVisibility: 'Gender visibility',
              visibility: {
                public: 'Public',
                friends: 'Friends only',
                private: 'Only me',
              },
              domainPlaceholder: 'Enter domain',
              signaturePlaceholder: 'Enter signature',
              domainHint: 'Use letters and numbers only, up to 63 characters. The domain is your identity card and login handle.',
              domainRequired: 'Domain is required.',
              domainError: 'The domain may contain letters and numbers only, up to 63 characters.',
              save: 'Save Identity Card',
            },
            tabs: {
              levels: 'Membership',
              subscription: 'Subscription',
              blockchain: 'Blockchain',
            },
            levels: {
              title: 'Membership Levels',
              sub: 'Choose the right membership tier.',
            },
            subscription: {
              title: 'Subscription Overview',
              sub: 'Review your plan and renewal timeline.',
            },
            blockchain: {
              title: 'Blockchain Overview',
              sub: 'Review bound on-chain accounts.',
              empty: 'No on-chain accounts bound.',
            },
          },
          profileMenu: {
            title: 'Profile Menu',
            subtitle: 'Membership, Subscription, and Blockchain',
          },
          theme: {
            title: 'Theme',
            label: 'Choose skin',
            options: {
              midnight: 'Midnight',
              dawn: 'Dawn',
              ocean: 'Ocean',
            },
          },
          common: {
            guest: 'Guest',
            notAvailable: '--',
            cancel: 'Cancel',
          },
          nav: {
            auth: 'Sign In',
            dashboard: 'Dashboard',
            space: 'Space',
            private: 'Space',
            public: 'Space',
            profile: 'Profile',
            postDetail: 'Post Detail',
            levels: 'Membership',
            subscription: 'Subscription',
            blockchain: 'Blockchain',
            friends: 'Friends',
            chat: 'Live Chat',
            collapse: 'Collapse Nav',
            expand: 'Expand Nav',
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
            auth: 'Sign In',
            dashboard: 'Dashboard',
            space: 'Space',
            private: 'Space',
            public: 'Space',
            profile: 'Profile',
            postDetail: 'Post Detail',
            levels: 'Membership',
            subscription: 'Subscription',
            blockchain: 'Blockchain Accounts',
            friends: 'Friends',
            chat: 'Live Chat',
          },
          pageSub: {
            auth: 'Enter your identity card and space quickly',
            dashboard: 'Account summary and space insights',
            space: 'Browse visible spaces and publish content',
            private: 'Browse visible spaces and publish content',
            public: 'Browse visible spaces and content',
            profile: 'Browse this author\'s public posts and activity',
            postDetail: 'Read the full post, comments, and interaction details',
            levels: 'Choose the right membership tier',
            subscription: 'Manage plan and benefits',
            blockchain: 'Manage external blockchain account bindings',
            friends: 'Build connections and chat privately',
            chat: 'Real-time communication and feedback',
          },
          auth: {
            welcomeTitle: 'Welcome Back',
            welcomeSub: 'Sign in to access your space.',
            createTitle: 'Create Account',
            createSub: 'Join membership plans and unlock larger spaces.',
            accountPlaceholder: 'Email, Phone, Username, Domain',
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
            blockchainStat: 'Blockchain',
            spaceSummaryTitle: 'Space Summary',
            spaceSummarySub: 'Spaces are for showing and sharing, with visibility set by the creator.',
            profileTitle: 'Profile Settings',
            profileSub: 'Update your display name and username for the dashboard and chat header.',
            blockchainTitle: 'Blockchain Extension',
            blockchainSub: 'Bound blockchain accounts are summarized here for future identity and asset linkage.',
            displayNamePlaceholder: 'Enter nickname',
              usernamePlaceholder: 'Enter username',
              usernameHint: 'Letters and numbers only, up to 63 characters, and used as the subdomain handle.',
              usernameRequired: 'Username is required.',
              usernameError: 'Username may contain letters and numbers only, up to 63 characters.',
            saveProfile: 'Save Profile',
            saveSuccess: 'Profile updated',
            saveError: 'Profile update failed. Try again later.',
          },
          spaces: {
            privateTitle: 'Space',
            privateSub: 'Browse visible spaces and manage content.',
            publicTitle: 'Space',
            publicSub: 'Share updates, showcase projects, and connect widely.',
            createTitle: 'Create Space',
            createSub: 'Name, subdomain, and visibility are independent; leave the subdomain blank to auto-generate one.',
            editTitle: 'Edit Space',
            editSub: 'Rename the space and change its subdomain and visibility independently.',
            settingsAction: 'Space settings',
            typeLabel: 'Space Type',
            namePlaceholder: 'Space name',
            descPlaceholder: 'Space description',
            subdomainLabel: 'Subdomain',
            subdomainHint: 'Letters and numbers only, up to 63 characters; leave blank to auto-generate.',
            subdomainEditHint: 'Letters and numbers only, up to 63 characters.',
            createAction: 'Create Space',
            editAction: 'Edit Space',
            saveAction: 'Save Changes',
            currentLabel: 'Current Space',
            enterAction: 'Enter Space',
            visibilityLabel: 'Visibility',
            createSuccess: 'Space created',
            createError: 'Space creation failed. Check the name and try again.',
            editSuccess: 'Space updated.',
            editError: 'Space update failed. Try again later.',
            deleteAction: 'Delete Space',
            deleteConfirm: 'Deleting this space will remove the space and everything inside it. Continue?',
            deleteSuccess: 'Space deleted.',
            deleteError: 'Space deletion failed. Try again later.',
            subdomainRequired: 'A subdomain is required when editing a space.',
            subdomainError: 'The subdomain may contain letters and numbers only, up to 63 characters.',
            type: {
              private: 'Space',
              public: 'Space',
            },
            visibility: {
              public: 'Visible to everyone',
              friends: 'Friends only',
              private: 'Only me',
            },
          },
          posts: {
            feedTitle: 'Space Feed',
            feedSub: 'Share updates, ideas, and project progress.',
            privateFeedTitle: 'Space Content',
            privateFeedSub: 'Review your posts.',
            profileFeedTitle: 'Author Feed',
            profileFeedSub: 'Browse posts published by this author.',
            creatorHint: 'Only the space creator can post here, update space settings, and manage posts; other users can view, like, comment, and reply.',
            viewerHint: 'You are viewing this space as a guest, so you can only like, comment, and reply.',
            titlePlaceholder: 'Post title',
            contentPlaceholder: 'Write something to share...',
            publishAction: 'Publish Post',
            visibilityLabel: 'Visibility',
            spaceLabel: 'Space',
            spaceRequired: 'Please enter or create the matching space first.',
            publishSuccess: 'Post published.',
            publishError: 'Publishing failed. Try again later.',
            privateEmpty: 'No posts in this space yet.',
            publicEmpty: 'The space feed is empty. Publish the first post.',
            profileEmpty: 'This author has no public posts yet.',
            empty: 'The space feed is empty. Publish the first post.',
            like: 'Like',
            unlike: 'Unlike',
            comment: 'Comment',
            commentPlaceholder: 'Write a comment...',
            commentAction: 'Send Comment',
            commentError: 'Comment failed. Try again later.',
            reply: 'Reply',
            replyPlaceholder: 'Write a reply...',
            replyAction: 'Send Reply',
            cancelReply: 'Cancel Reply',
            share: 'Share',
            shareError: 'Sharing failed. Try again later.',
            deleteAction: 'Delete Post',
            deleteConfirm: 'Deleting this post will also remove comments, likes, and shares. Continue?',
            deleteSuccess: 'Post deleted.',
            deleteError: 'Deleting the post failed. Try again later.',
            privateLabel: 'Private',
            publicLabel: 'Public',
            viewAuthor: 'View Profile',
            backToFeed: 'Back to Space',
            articleCount: 'Posts',
            openChat: 'Open Chat',
            addFriend: 'Add Friend',
            acceptFriend: 'Accept Friend',
            openDetail: 'Open Detail',
            edit: 'Edit Post',
            editTitle: 'Edit Post',
            editAction: 'Save Changes',
            editSuccess: 'Post updated.',
            editError: 'Updating post failed. Try again later.',
            statusLabel: 'Publish Status',
            statusDraft: 'Draft',
            statusPublished: 'Published',
            statusHidden: 'Hidden',
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
          blockchain: {
            title: 'Blockchain Accounts',
            sub: 'Bind external wallet addresses now and reserve room for future on-chain identity features.',
            providerLabel: 'Provider',
            chainLabel: 'Chain',
            addressPlaceholder: 'Wallet address, account address',
            signaturePlaceholder: 'Signature payload (required for baseline checks)',
            securityHint: 'This version validates provider, chain, address format, and signature payload length.',
            bindAction: 'Bind Account',
            removeAction: 'Unbind',
            empty: 'There are no blockchain accounts bound yet.',
            bindSuccess: 'Blockchain account bound.',
            bindError: 'Blockchain account binding failed. Check the input and try again.',
            removeSuccess: 'Blockchain account unbound.',
            removeError: 'Blockchain account removal failed. Try again later.',
            boundAt: 'Bound At',
            openManager: 'Manage Bindings',
            connectedChains: 'Connected Chains',
          },
          friends: {
            title: 'Friends',
            chat: 'Chat',
            searchPlaceholder: 'Enter display name, username, domain, email, phone, or user ID',
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
            quickTitle: 'Emoji and stickers',
            quickPanelTitle: 'Emoji panel',
            quickPanelHint: 'Emojis and text stickers are shown separately.',
            quickEmojiTitle: 'Emoji',
            quickStickerTitle: 'Text stickers',
            quickToggle: 'Emoji',
            quickClose: 'Close',
            backToBottom: 'Back to latest',
            pickFriend: 'Select a friend to start chatting',
            onlineNow: 'Live',
            latest: 'Latest',
            inputPlaceholder: 'Type a message...',
            send: 'Send',
            loadError: 'Failed to load chat history.',
            emptyConversation: 'There are no messages in this conversation yet.',
            sendError: 'Chat service is not connected yet.',
            attachImage: 'Image',
            attachVideo: 'Video',
            attachAudio: 'Voice',
            clearAttachment: 'Clear attachment',
            attachmentHint: 'Attachments are compressed and auto-delete after 7 days.',
            openAttachment: 'Open attachment',
            mediaImage: 'Image',
            mediaVideo: 'Video',
            mediaAudio: 'Voice',
            mediaFile: 'File',
            friendProfileTitle: 'Friend Profile',
            friendProfileSub: 'View your friend’s public details, contact info, and relationship status.',
            viewProfile: 'View Profile',
            friendStatus: 'Friend Status',
            friendDirection: 'Relation Direction',
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
        username: 'lanyu',
        domain: 'lanyu01',
        signature: 'Build with calm focus.',
        age: '',
        gender: '',
        email: '',
        phone: '',
        phoneVisibility: 'private',
        emailVisibility: 'private',
        ageVisibility: 'private',
        genderVisibility: 'private',
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
      // External blockchain account bindings.
      // 外部区块链账号绑定数据。
      externalAccounts: [],
      // External account binding form.
      // 外部账号绑定表单。
      externalAccountDraft: {
        provider: 'evm',
        chain: 'ethereum',
        accountAddress: '',
        signaturePayload: '',
      },
      // Supported blockchain providers and chain options.
      // 支持的链上提供方与链选项。
      blockchainProviders: {
        evm: ['ethereum', 'base', 'bsc', 'polygon'],
        solana: ['solana'],
        tron: ['tron'],
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
        username: '',
        domain: '',
        signature: '',
        phoneVisibility: 'private',
        emailVisibility: 'private',
        ageVisibility: 'private',
        genderVisibility: 'private',
      },
      // Space modal state.
      // 空间弹窗状态。
      spaceModalOpen: false,
      // Space creation form.
      // 空间创建表单。
      spaceDraft: {
        id: '',
        type: 'public',
        visibility: 'public',
        name: '',
        description: '',
        subdomain: '',
      },
      // Post modal state.
      // 文章弹窗状态。
      postModalOpen: false,
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
          subdomain: 'idea-vault',
          status: 'active',
          name: { 'zh-CN': '灵感仓库', 'en-US': 'Idea Vault' },
          desc: { 'zh-CN': '只属于我的草稿与想法收纳处。', 'en-US': 'A private place for drafts and ideas.' },
        },
        {
          id: 's2',
          type: 'public',
          subdomain: 'shareboard',
          status: 'active',
          name: { 'zh-CN': '分享计划', 'en-US': 'Shareboard' },
          desc: { 'zh-CN': '公开更新项目进度与成果。', 'en-US': 'Post public progress updates and results.' },
        },
      ],
      // Social posts list.
      // 社交文章列表。
      posts: [],
      // Current user's post list.
      // 当前用户文章列表。
      privatePosts: [],
      // Selected profile summary.
      // 当前查看的用户主页摘要。
      profileUser: {
        id: '',
        name: '',
        username: '',
        domain: '',
        secondary: '',
        signature: '',
        age: '',
        gender: '',
        email: '',
        phone: '',
        relationStatus: '',
        direction: '',
      },
      // Selected profile post list.
      // 当前查看的用户主页文章列表。
      profilePosts: [],
      // Selected profile space list.
      // 当前查看的用户主页空间列表。
      profileSpaces: [],
      // Currently entered space object.
      // 当前进入的空间对象。
      currentSpace: null,
      // Current post detail.
      // 当前文章详情。
      currentPost: null,
      // Post composer form.
      // 文章发布表单。
      postDraft: {
        title: '',
        content: '',
        visibility: 'public',
        status: 'published',
        spaceId: '',
        mediaType: '',
        mediaName: '',
        mediaMime: '',
        mediaData: '',
        mediaUrl: '',
      },
      // Post edit form.
      // 文章编辑表单。
      editPostDraft: {
        id: '',
        title: '',
        content: '',
        visibility: 'public',
        status: 'published',
        spaceId: '',
        mediaType: '',
        mediaName: '',
        mediaMime: '',
        mediaData: '',
        mediaUrl: '',
      },
      // Posts in the currently open space.
      // 当前打开空间的帖子列表。
      spacePosts: [],
      // Per-post comment drafts.
      // 每篇文章的评论草稿。
      commentDrafts: {},
      // Per-comment reply drafts and active reply targets.
      // 每条评论的回复草稿与当前展开的回复目标。
      replyDrafts: {},
      commentReplyTargets: {},
      // Membership levels.
      // 会员等级数据。
      levels: [
        {
          name: 'Basic',
          planID: 'basic',
          price: { 'zh-CN': '免费', 'en-US': 'Free' },
          features: {
            'zh-CN': ['基础空间', '好友聊天', '空间展示'],
            'en-US': ['Base space quota', 'Friend chat', 'Space showcase'],
          },
        },
        {
          name: 'Premium',
          planID: 'premium',
          price: { 'zh-CN': '¥19/月', 'en-US': '$19/mo' },
          features: {
            'zh-CN': ['更大空间额度', '高级主题', '优先支持'],
            'en-US': ['Larger space quota', 'Advanced themes', 'Priority support'],
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
      // Chat friend profile modal state.
      // 聊天好友资料弹窗状态。
      chatFriendProfile: null,
      // Chat history.
      // 聊天记录。
      chatMessages: [
        { id: 'm1', from: 'f1', content: { 'zh-CN': '今晚要一起看发布会吗？', 'en-US': 'Want to watch the launch event tonight?' }, time: '20:18' },
        { id: 'm2', from: 'u-1001', content: { 'zh-CN': '当然，开个公共空间直播！', 'en-US': 'Sure, let us stream it in the public space!' }, time: '20:19' },
      ],
      // Message input.
      // 输入消息。
      chatInput: '',
      // Chat quick panel visibility.
      // 聊天快捷面板显示状态。
      chatQuickPanelOpen: false,
      // Quick inserts for emoji and sticker packs.
      // 表情包与贴纸快捷插入项。
      chatQuickSnippets: CHAT_QUICK_SNIPPETS,
      // Current chat attachment draft.
      // 当前聊天附件草稿。
      chatAttachment: null,
        // Cached object URLs for decoded chat media.
        // 解码后的聊天媒体对象 URL 缓存。
        chatMediaUrls: [],
        // Whether the history viewport is already near the latest message.
        // 历史视口是否已经接近最新消息。
        chatHistoryAtBottom: true,
        // Conversation list summaries.
        // 会话列表摘要。
        chatSummaries: [],
      // Whether the current host route has already been applied.
      // 当前主机路由是否已经应用。
      hostRouteApplied: false,
    };
  },
  computed: {
    appContext() {
      return this;
    },
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
      if (this.view === 'postDetail' && this.currentPost?.title) {
        return this.currentPost.title;
      }
      if (this.view === 'profile' && this.profileUser.name) {
        const handle = this.profileUser.domain || this.profileUser.username;
        return handle ? `${this.profileUser.name} · @${handle}` : this.profileUser.name;
      }
      if (this.view === 'profile' && (this.profileUser.domain || this.profileUser.username)) {
        return `@${this.profileUser.domain || this.profileUser.username}`;
      }
      if (this.view === 'space' || this.view === 'private' || this.view === 'public') {
        const activeSpace = this.activePublicSpace;
        const label = activeSpace ? this.localizedSpaceText('name', activeSpace) : '';
        if (label) {
          return `${this.t('pageTitle.space')} · ${label}`;
        }
        return this.t('pageTitle.space');
      }
      return this.t(`pageTitle.${this.view}`) || this.t('pageTitle.dashboard');
    },
    pageSub() {
      if (this.view === 'postDetail' && this.currentPost) {
        return this.currentPost.spaceLabel
          ? `${this.t('pageSub.postDetail')} · ${this.currentPost.spaceLabel}`
          : this.t('pageSub.postDetail');
      }
      if (this.view === 'profile' && (this.profileUser.domain || this.profileUser.username)) {
        return `@${this.profileUser.domain || this.profileUser.username}`;
      }
      if (this.view === 'profile' && this.profileUser.name) {
        return this.t('posts.profileFeedSub');
      }
      if (this.view === 'space' || this.view === 'private' || this.view === 'public') {
        const activeSpace = this.activePublicSpace;
        if (activeSpace?.subdomain) {
          return `${this.t('pageSub.space')} · @${activeSpace.subdomain}`;
        }
        return this.t('pageSub.space');
      }
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
    blockchainProviderOptions() {
      return Object.keys(this.blockchainProviders);
    },
    blockchainChainOptions() {
      return this.blockchainProviders[this.externalAccountDraft.provider] || [];
    },
    activeExternalAccounts() {
      return this.externalAccounts.filter((account) => account.bindingStatus === 'active');
    },
    connectedChainList() {
      return Array.from(new Set(this.activeExternalAccounts.map((account) => account.chain).filter(Boolean)));
    },
    connectedChainText() {
      return this.connectedChainList.join(', ') || this.t('common.notAvailable');
    },
    hasBlockchainAccounts() {
      // Check if any blockchain account is active.
      // 判断是否存在可用的链上账号。
      return this.activeExternalAccounts.length > 0;
    },
    acceptedFriends() {
      return this.friends.filter((friend) => friend.status === 'accepted');
    },
    pendingIncomingFriends() {
      return this.friends.filter(
        (friend) => friend.status === 'pending' && friend.direction === 'incoming',
      );
    },
    pendingFriendCount() {
      return this.pendingIncomingFriends.length;
    },
    topPendingFriend() {
      return this.pendingIncomingFriends
        .slice()
        .sort((a, b) => {
          const aTime = a.createdAt ? new Date(a.createdAt).getTime() : 0;
          const bTime = b.createdAt ? new Date(b.createdAt).getTime() : 0;
          if (aTime !== bTime) {
            return bTime - aTime;
          }
          return a.name.localeCompare(b.name);
        })[0] || null;
    },
    chatEntries() {
      return this.acceptedFriends.map((friend) => {
        const summary = this.chatSummaries.find((item) => item.peerId === friend.id);
        // Normalize last message timestamp to avoid invalid dates.
        // 规范最后消息时间，避免无效日期显示。
        const lastAtRaw = summary?.lastAt || '';
        const lastAt = this.safeTimestamp(lastAtRaw) ? lastAtRaw : '';
        return {
          ...friend,
          lastMessage: summary?.lastMessage || '',
          lastMessageType: summary?.lastMessageType || 'text',
          lastMessagePreview: summary?.lastMessagePreview || summary?.lastMessage || '',
          lastAt,
          unreadCount: summary?.unreadCount || 0,
        };
      }).sort((a, b) => {
        const aHasMessage = Boolean(a.lastAt);
        const bHasMessage = Boolean(b.lastAt);
        if (aHasMessage !== bHasMessage) {
          return aHasMessage ? -1 : 1;
        }
        const aTime = this.safeTimestamp(a.lastAt);
        const bTime = this.safeTimestamp(b.lastAt);
        if (aTime !== bTime) {
          return bTime - aTime;
        }
        const aFriendAt = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const bFriendAt = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        if (aFriendAt !== bFriendAt) {
          return bFriendAt - aFriendAt;
        }
        return a.name.localeCompare(b.name);
      });
    },
    chatEmojiSnippets() {
      // Split emoji snippets into their own panel section.
      // 将表情片段单独拆分到独立区域。
      return this.chatQuickSnippets.filter((item) => item.kind === 'emoji');
    },
    chatStickerSnippets() {
      // Split text stickers into their own panel section.
      // 将文字表情单独拆分到独立区域。
      return this.chatQuickSnippets.filter((item) => item.kind === 'sticker');
    },
    activePrivateSpace() {
      return this.resolveSpaceForVisibility('private');
    },
    activePublicSpace() {
      return this.resolveSpaceForVisibility('public');
    },
    visiblePrivatePosts() {
      return this.postsForSpace(this.privatePosts, this.activePrivateSpace?.id || '');
    },
    visiblePublicPosts() {
      return this.postsForSpace(this.posts, this.activePublicSpace?.id || '');
    },
    activeSpace() {
      return this.currentSpace || this.activePublicSpace || this.activePrivateSpace || null;
    },
    activeSpacePosts() {
      return this.postsForSpace(this.spacePosts, this.activeSpace?.id || '');
    },
    ownedSpaces() {
      if (!this.user?.id) {
        return [];
      }
      return this.spaces.filter((space) => space && space.userId === this.user.id);
    },
    visibleProfileSpaces() {
      return Array.isArray(this.profileSpaces) ? this.profileSpaces : [];
    },
    privateSpaces() {
      // Keep the legacy helper aligned with the owned-space-only model.
      // 让旧的辅助方法与“只看自己创建的空间”模型保持一致。
      return this.ownedSpaces;
    },
    publicSpaces() {
      // Keep the legacy helper aligned with the owned-space-only model.
      // 让旧的辅助方法与“只看自己创建的空间”模型保持一致。
      return this.ownedSpaces;
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
    view(nextView) {
      if (nextView === 'chat') {
        this.scrollChatHistoryToBottom(true);
        return;
      }
      this.closeChatQuickPanel();
    },
    'externalAccountDraft.provider'(nextProvider) {
      // Keep the selected chain aligned with the selected provider.
      // 让选中的链始终与当前提供方保持一致。
      const chains = this.blockchainProviders[nextProvider] || [];
      if (!chains.includes(this.externalAccountDraft.chain)) {
        this.externalAccountDraft.chain = chains[0] || '';
      }
    },
  },
  methods: {
    // Space and post payload helpers.
    // 空间与文章载荷辅助方法。
    mapCommentItem(comment) {
      return {
        id: comment.id,
        authorName: comment.author_name,
        parentCommentId: comment.parent_comment_id || '',
        content: comment.content,
        createdAt: comment.created_at,
      };
    },
    commentThreadItems(comments) {
      // Flatten nested comments into a stable display order.
      // 将嵌套评论展开为稳定的展示顺序。
      const items = Array.isArray(comments) ? comments : [];
      const buckets = new Map();
      items.forEach((comment) => {
        const parentId = String(comment.parentCommentId || '').trim();
        if (!buckets.has(parentId)) {
          buckets.set(parentId, []);
        }
        buckets.get(parentId).push(comment);
      });
      const ordered = [];
      const visit = (parentId, depth) => {
        const siblings = (buckets.get(parentId) || []).slice().sort((left, right) => {
          const leftAt = Date.parse(left.createdAt || '') || 0;
          const rightAt = Date.parse(right.createdAt || '') || 0;
          return leftAt - rightAt;
        });
        siblings.forEach((comment) => {
          ordered.push({ comment, depth });
          visit(comment.id, depth + 1);
        });
      };
      visit('', 0);
      return ordered;
    },
    mapPostItem(item) {
      const spaceName = item.space_name || '';
      const spaceSubdomain = item.space_subdomain || '';
      const spaceType = item.space_type || '';
      const mediaType = item.media_type || '';
      const mediaName = item.media_name || '';
      const mediaMime = item.media_mime || '';
      const mediaData = item.media_data || '';
      const spaceLabel = spaceName && spaceSubdomain
        ? `${spaceName} · @${spaceSubdomain}`
        : spaceName || spaceSubdomain || spaceType || item.visibility || '';
      const mediaMimeType = mediaMime || this.inferAttachmentMime(mediaType, mediaName, mediaMime);
      return {
        id: item.id,
        userId: item.user_id,
        spaceId: item.space_id || '',
        spaceUserId: item.space_user_id || '',
        spaceName,
        spaceSubdomain,
        spaceType,
        spaceLabel,
        authorName: item.author_name,
        title: item.title,
        content: item.content,
        mediaType,
        mediaName,
        mediaMime,
        mediaData,
        mediaUrl: mediaData ? `data:${mediaMimeType};base64,${mediaData}` : '',
        status: item.status || 'published',
        visibility: item.visibility || 'public',
        likesCount: Number(item.likes_count || 0),
        commentsCount: Number(item.comments_count || 0),
        sharesCount: Number(item.shares_count || 0),
        likedByMe: Boolean(item.liked_by_me),
        createdAt: item.created_at,
        comments: Array.isArray(item.comments)
          ? item.comments.map((comment) => this.mapCommentItem(comment))
          : [],
      };
    },
    mapSpaceItem(item) {
      const name = item.name || '';
      const subdomain = item.subdomain || '';
      const spaceLabel = subdomain ? `${name} · @${subdomain}` : name;
      return {
        id: item.id,
        type: item.type || 'private',
        visibility: item.visibility || (item.type === 'private' ? 'private' : 'public'),
        subdomain,
        status: item.status || 'active',
        name: {
          'zh-CN': item.name || '',
          'en-US': item.name || '',
          'zh-TW': item.name || '',
        },
        desc: {
          'zh-CN': item.description || '',
          'en-US': item.description || '',
          'zh-TW': item.description || '',
        },
        createdAt: item.created_at || '',
        updatedAt: item.updated_at || '',
        spaceLabel,
      };
    },
    findSpaceById(spaceId) {
      if (!spaceId) {
        return null;
      }
      return this.spaces.find((space) => space.id === spaceId) || null;
    },
    postsForSpace(posts, spaceId) {
      if (!spaceId) {
        return posts;
      }
      return posts.filter((post) => post.spaceId === spaceId);
    },
    normalizeSpaceSlug(value) {
      // Normalize a free-form string into a subdomain-safe slug.
      // 将自由文本规范化为适合二级域名的 slug。
      const lower = String(value || '').trim().toLowerCase();
      if (!lower) {
        return '';
      }
      const buffer = [];
      for (const rune of lower) {
        const code = rune.codePointAt(0);
        const isLetter = code >= 0x61 && code <= 0x7a;
        const isDigit = code >= 0x30 && code <= 0x39;
        if (isLetter || isDigit) {
          buffer.push(rune);
        }
      }
      return buffer.join('');
    },
    suggestSpaceSubdomain(name, type) {
      // Suggest a readable subdomain from the space name.
      // 根据空间名称建议一个可读的二级域名。
      return this.normalizeSpaceSlug(name).slice(0, 63);
    },
    isValidSpaceSubdomain(value) {
      // Validate the subdomain format before sending it to the server.
      // 在提交到服务端前校验二级域名格式。
      return /^[a-z0-9]{1,63}$/.test(String(value || '').trim().toLowerCase());
    },
    hostSubdomainLabel() {
      // Extract the leading host label for subdomain routing.
      // 提取用于子域名路由的首个主机标识。
      const host = (window.location.hostname || '').toLowerCase();
      if (!host || host === 'localhost' || host === '127.0.0.1') {
        return '';
      }
      const parts = host.split('.').filter(Boolean);
      if (parts.length < 3 && !host.endsWith('.localhost')) {
        return '';
      }
      const label = parts[0];
      if (!label || label === 'www') {
        return '';
      }
      return label;
    },
    spaceFromHost() {
      // Try to map the current host subdomain to a known space.
      // 尝试把当前主机的子域名映射到已知空间。
      const label = this.hostSubdomainLabel();
      if (!label) {
        return null;
      }
      return this.spaces.find((space) => space.subdomain?.toLowerCase() === label) || null;
    },
    resolveSpaceForVisibility(visibility, preferredSpaceId = '') {
      // Resolve the active space for a visibility scope.
      // 为可见性范围解析当前空间。
      if (this.currentSpace) {
        return this.currentSpace;
      }
      const preferred = this.findSpaceById(preferredSpaceId);
      if (preferred) {
        return preferred;
      }
      const activeId = this.activePublicSpaceId || this.activePrivateSpaceId;
      const active = this.findSpaceById(activeId);
      if (active) {
        return active;
      }
      const hostSpace = this.spaceFromHost();
      if (hostSpace) {
        return hostSpace;
      }
      return this.spaces[0] || null;
    },
    selectedSpaceIdForVisibility(visibility, preferredSpaceId = '') {
      const space = this.resolveSpaceForVisibility(visibility, preferredSpaceId);
      return space ? space.id : '';
    },
    managedSpacesForVisibility(visibility) {
      // Collect spaces the current user can actually publish into.
      // 汇总当前用户真正可以发布内容的空间。
      return this.ownedSpaces;
    },
    managedSpaceIdForVisibility(visibility, preferredSpaceId = '') {
      // Return a publishable space ID for the current viewer.
      // 返回当前用户可发布内容的空间 ID。
      const spaces = this.managedSpacesForVisibility(visibility);
      const preferred = spaces.find((space) => space.id === preferredSpaceId);
      if (preferred) {
        return preferred.id;
      }
      const activeId = this.activePublicSpaceId || this.activePrivateSpaceId;
      const active = spaces.find((space) => space.id === activeId);
      if (active) {
        return active.id;
      }
      return spaces[0]?.id || '';
    },
    persistActiveSpace(storageKey, spaceId) {
      if (spaceId) {
        localStorage.setItem(storageKey, spaceId);
        return;
      }
      localStorage.removeItem(storageKey);
    },
    syncActiveSpaces() {
      // Keep active spaces aligned with the current data set.
      // 让当前空间与最新空间列表保持同步。
      const activeSpace = this.currentSpace || this.resolveSpaceForVisibility('public', this.activePublicSpaceId || this.activePrivateSpaceId);
      this.activePrivateSpaceId = activeSpace ? activeSpace.id : '';
      this.activePublicSpaceId = activeSpace ? activeSpace.id : '';
      this.persistActiveSpace(ACTIVE_PRIVATE_SPACE_KEY, this.activePrivateSpaceId);
      this.persistActiveSpace(ACTIVE_PUBLIC_SPACE_KEY, this.activePublicSpaceId);
    },
    setActiveSpace(space) {
      // Persist the selected space without changing the current page.
      // 仅保存当前空间选择，不直接切换页面。
      if (!space) {
        return;
      }
      this.currentSpace = space;
      this.activePrivateSpaceId = space.id;
      this.activePublicSpaceId = space.id;
      this.persistActiveSpace(ACTIVE_PRIVATE_SPACE_KEY, space.id);
      this.persistActiveSpace(ACTIVE_PUBLIC_SPACE_KEY, space.id);
    },
    async enterSpace(space) {
      // Enter a space and switch to the matching page.
      // 进入空间并切换到对应页面。
      if (!space) {
        return;
      }
      this.setActiveSpace(space);
      await this.loadSpacePosts(space.id);
      this.view = 'space';
    },
    openSpaceComposer(type) {
      // Open the space composer dialog in create mode.
      // 以创建模式打开空间弹窗。
      this.spaceDraft.id = '';
      this.spaceDraft.type = type === 'public' ? 'public' : 'private';
      this.spaceDraft.visibility = this.spaceDraft.type === 'private' ? 'private' : 'public';
      this.spaceDraft.name = '';
      this.spaceDraft.description = '';
      this.spaceDraft.subdomain = '';
      this.spaceModalOpen = true;
    },
    openSpaceEditor(space) {
      // Open the space composer dialog in edit mode.
      // 以编辑模式打开空间弹窗。
      if (!space || !space.id) {
        return;
      }
      if (space.userId !== this.user.id) {
        return;
      }
      this.spaceDraft.id = space.id;
      this.spaceDraft.type = space.type === 'public' ? 'public' : 'private';
      this.spaceDraft.visibility = space.visibility || (space.type === 'private' ? 'private' : 'public');
      this.spaceDraft.name = this.localizedSpaceText('name', space);
      this.spaceDraft.description = this.localizedSpaceText('desc', space);
      this.spaceDraft.subdomain = space.subdomain || '';
      if (!this.spaceDraft.subdomain.trim()) {
        this.spaceDraft.subdomain = this.suggestSpaceSubdomain(this.spaceDraft.name, this.spaceDraft.type);
      }
      this.spaceModalOpen = true;
    },
    closeSpaceComposer() {
      // Close the space modal and reset its draft state.
      // 关闭空间弹窗并重置草稿状态。
      this.spaceModalOpen = false;
      this.spaceDraft.id = '';
      this.spaceDraft.type = 'public';
      this.spaceDraft.visibility = 'public';
      this.spaceDraft.name = '';
      this.spaceDraft.description = '';
      this.spaceDraft.subdomain = '';
    },
    openPostComposer(space) {
      // Open the post composer dialog for the active space.
      // 为当前空间打开文章发布弹窗。
      const activeSpace = space && space.id ? space : this.activeSpace;
      if (!activeSpace || activeSpace.userId !== this.user.id) {
        this.setError(this.t('posts.spaceRequired'));
        return;
      }
      this.postDraft.title = '';
      this.postDraft.content = '';
      this.postDraft.visibility = 'public';
      this.postDraft.status = 'published';
      this.postDraft.spaceId = activeSpace.id;
      this.clearPostMedia('create');
      this.postModalOpen = true;
    },
    closePostComposer() {
      // Close the post composer and clear media state.
      // 关闭文章发布弹窗并清理媒体状态。
      this.postModalOpen = false;
      this.postDraft.title = '';
      this.postDraft.content = '';
      this.postDraft.visibility = 'public';
      this.postDraft.status = 'published';
      this.postDraft.spaceId = '';
      this.clearPostMedia('create');
    },
    clearPostMedia(target = 'create') {
      // Clear post media fields for create or edit state.
      // 清空发布态或编辑态的文章媒体字段。
      const draft = target === 'edit' ? this.editPostDraft : this.postDraft;
      draft.mediaType = '';
      draft.mediaName = '';
      draft.mediaMime = '';
      draft.mediaData = '';
      draft.mediaUrl = '';
    },
    pickPostMedia(target = 'create', preferredType = 'image') {
      // Open the browser file chooser for a post media draft.
      // 打开浏览器文件选择器以选择文章媒体。
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = preferredType === 'video' ? 'video/*' : 'image/*';
      input.multiple = false;
      input.addEventListener('change', (event) => {
        this.handlePostMediaPick(target, event);
      }, { once: true });
      input.click();
    },
    async handlePostMediaPick(target, event) {
      // Read an image or video file into the post media draft.
      // 读取图片或视频文件并写入文章媒体草稿。
      const input = event?.target;
      const file = input?.files?.[0];
      if (!file) {
        return;
      }
      const draft = target === 'edit' ? this.editPostDraft : this.postDraft;
      const inferredMime = this.inferAttachmentMime(
        file.type.startsWith('video/') ? 'video' : 'image',
        file.name,
        file.type || '',
      );
      const mediaType = inferredMime.startsWith('video/') ? 'video' : 'image';
      const bytes = await file.arrayBuffer();
      draft.mediaType = mediaType;
      draft.mediaName = file.name;
      draft.mediaMime = inferredMime;
      draft.mediaData = this.bytesToBase64(new Uint8Array(bytes));
      draft.mediaUrl = `data:${inferredMime};base64,${draft.mediaData}`;
      if (input) {
        input.value = '';
      }
    },
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
    peerLocaleText(key) {
      // Show the counterpart language beside the active one.
      // 在当前语言旁展示另一种语言，避免双语文案挤在同一行。
      const peerLocale = this.locale === 'en-US' ? 'zh-CN' : 'en-US';
      const peerValue = this.getByPath(this.translations[peerLocale], key);
      if (typeof peerValue === 'string') {
        return peerValue;
      }
      const fallback = this.getByPath(this.translations['zh-CN'], key);
      return typeof fallback === 'string' ? fallback : '';
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
            common: { guest: '訪客', cancel: '取消' },
            nav: {
            auth: '登入註冊',
              dashboard: '帳號主頁',
              space: '空間',
              private: '私人空間',
              public: '公共空間',
              levels: '會員等級',
              subscription: '訂閱',
              blockchain: '鏈上帳號',
              friends: '好友',
              chat: '即時聊天',
              collapse: '收合導航',
              expand: '展開導航',
            },
          profile: {
            identity: {
              title: '身分卡',
              sub: '暱稱和域名分開維護，域名用於登入和子網域入口。',
              nickname: '使用者暱稱',
              username: '使用者名稱',
              domain: '域名',
              signature: '簽名',
              phoneVisibility: '手機可見範圍',
              emailVisibility: '信箱可見範圍',
              ageVisibility: '年齡可見範圍',
              genderVisibility: '性別可見範圍',
              visibility: {
                public: '公開',
                friends: '僅好友可見',
                private: '僅自己可見',
              },
              domainPlaceholder: '輸入網域',
              signaturePlaceholder: '輸入簽名',
              domainHint: '域名只能使用英文字母和數字，長度不超過 63，並作為身分卡和登入入口。',
              domainRequired: '請輸入域名。',
              domainError: '域名只能包含英文字母和數字，且最長 63 個字元。',
              save: '儲存身分卡',
            },
            tabs: {
              levels: '會員等級',
              subscription: '訂閱',
              blockchain: '鏈上帳號',
            },
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
            auth: '登入註冊',
              dashboard: '帳號主頁',
              space: '空間',
              private: '空間',
              public: '空間',
              levels: '會員等級',
              subscription: '訂閱管理',
              blockchain: '鏈上帳號',
              friends: '好友',
              chat: '即時聊天',
            },
            pageSub: {
              auth: '快速進入你的身份卡與空間',
              dashboard: '帳戶摘要與空間資訊',
              space: '查看可見空間並發布內容',
              private: '查看可見空間並發布內容',
              public: '瀏覽可見空間與內容',
              levels: '選擇適合你的會員等級',
              subscription: '管理訂閱與權益',
              blockchain: '管理外部鏈上帳號綁定',
              friends: '建立聯繫與私聊',
              chat: '即時溝通與回饋',
            },
            auth: {
              welcomeTitle: '歡迎回來',
              welcomeSub: '登入後進入你的空間。',
              createTitle: '建立新帳號',
              createSub: '加入會員體系，解鎖更大空間與更多互動。',
            accountPlaceholder: '信箱、手機、使用者名稱、域名',
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
              blockchainStat: '鏈上帳號',
              spaceSummaryTitle: '空間摘要',
              spaceSummarySub: '空間用於展示與分享，建立者可單獨設定可見範圍。',
              profileTitle: '資料設定',
              profileSub: '更新顯示名稱與使用者名稱，主頁與聊天視窗會同步顯示。',
              blockchainTitle: '鏈上擴展',
              blockchainSub: '已綁定的鏈上帳號會在此彙總，便於後續資產與身份聯動。',
              displayNamePlaceholder: '輸入暱稱',
              usernamePlaceholder: '輸入使用者名稱',
              usernameHint: '僅允許英文字母和數字，長度不超過 63，並作為子網域使用。',
              usernameRequired: '請輸入使用者名稱。',
              usernameError: '使用者名稱只能包含英文字母和數字，且最長 63 個字元。',
              saveProfile: '儲存資料',
              saveSuccess: '資料已更新',
              saveError: '資料更新失敗，請稍後重試。',
            },
            spaces: {
              privateTitle: '空間',
              privateSub: '查看可見空間並管理內容。',
              publicTitle: '空間',
              publicSub: '分享內容、展示專案、連結更多人。',
              createTitle: '建立空間',
              createSub: '名稱、二級網域和可見範圍可以獨立設定，留空時會自動生成。',
              settingsAction: '空間設定',
              typeLabel: '空間類型',
              namePlaceholder: '空間名稱',
              descPlaceholder: '空間描述',
              subdomainLabel: '二級網域',
              subdomainHint: '僅允許英文字母和數字，長度不超過 63，留空時後端會自動生成。',
              subdomainEditHint: '僅允許英文字母和數字，長度不超過 63。',
              createAction: '建立空間',
              editAction: '編輯空間',
              saveAction: '儲存修改',
              currentLabel: '目前空間',
              enterAction: '進入空間',
              visibilityLabel: '可見範圍',
              createSuccess: '空間已建立',
              createError: '空間建立失敗，請檢查名稱後重試。',
              editSuccess: '空間已更新。',
              editError: '空間更新失敗，請稍後重試。',
              deleteAction: '刪除空間',
              deleteConfirm: '刪除空間後，該空間及其內容都會被移除，是否繼續？',
              deleteSuccess: '空間已刪除。',
              deleteError: '空間刪除失敗，請稍後重試。',
              subdomainRequired: '編輯空間時二級網域不能為空。',
              subdomainError: '二級網域只能包含英文字母和數字，且最長 63 個字元。',
              type: { private: '空間', public: '空間' },
              visibility: {
                public: '所有人可見',
                friends: '好友可見',
                private: '僅自己可見',
              },
            },
            posts: {
              feedTitle: '空間內容流',
              feedSub: '發布你的近況、想法與專案更新。',
              creatorHint: '只有空間建立者可以在這裡發帖、設定空間資料並管理文章，其他人可查看並按讚、評論、回覆。',
              viewerHint: '你目前以訪客身份瀏覽這個空間，只能按讚、評論和回覆。',
              titlePlaceholder: '文章標題',
              contentPlaceholder: '寫點什麼，分享給大家...',
              publishAction: '發布文章',
              visibilityLabel: '可見性',
              spaceLabel: '所屬空間',
              spaceRequired: '請先進入或建立對應空間。',
              publishSuccess: '文章已發布。',
              publishError: '文章發布失敗，請稍後重試。',
              privateEmpty: '目前空間裡還沒有文章。',
              publicEmpty: '空間裡還沒有文章，先發布第一篇吧。',
              profileEmpty: '該作者還沒有公開文章。',
              empty: '空間裡還沒有文章，先發布第一篇吧。',
              unlike: '取消按讚',
              commentPlaceholder: '寫下你的評論...',
              commentAction: '送出評論',
              commentError: '評論失敗，請稍後重試。',
              reply: '回覆',
              replyPlaceholder: '寫下回覆...',
              replyAction: '送出回覆',
              cancelReply: '取消回覆',
              share: '轉發',
              shareError: '轉發失敗，請稍後重試。',
              privateLabel: '僅自己可見',
              publicLabel: '公開',
              backToFeed: '返回空間',
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
            blockchain: {
              title: '鏈上帳號綁定',
              sub: '綁定外部區塊鏈地址，為後續鏈上身份與資產能力預留入口。',
              providerLabel: '提供方',
              chainLabel: '鏈網路',
            addressPlaceholder: '錢包地址、帳號地址',
              signaturePlaceholder: '簽名載荷（必填，用於基礎校驗）',
              securityHint: '目前版本會校驗提供方、鏈類型、地址格式與簽名載荷長度。',
              bindAction: '綁定帳號',
              removeAction: '解除綁定',
              empty: '目前還沒有綁定任何鏈上帳號。',
              bindSuccess: '鏈上帳號已綁定。',
              bindError: '鏈上帳號綁定失敗，請檢查輸入後重試。',
              removeSuccess: '鏈上帳號已解除綁定。',
              removeError: '鏈上帳號解除綁定失敗，請稍後重試。',
              boundAt: '綁定時間',
              openManager: '管理綁定',
              connectedChains: '已連接鏈',
            },
            friends: {
              searchPlaceholder: '輸入顯示名稱、使用者名稱、域名、信箱、手機號碼或使用者 ID',
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
            quickTitle: '常用表情與貼紙',
            quickPanelTitle: '表情包面板',
            quickPanelHint: '表情與文字表情分開顯示。',
            quickEmojiTitle: '常用表情',
            quickStickerTitle: '文字表情',
            quickToggle: '表情',
            quickClose: '關閉',
            backToBottom: '回到底部',
            pickFriend: '選擇好友開始聊天',
            onlineNow: '即時在線',
              inputPlaceholder: '輸入訊息...',
              send: '送出',
              loadError: '聊天記錄載入失敗。',
              emptyConversation: '目前會話還沒有訊息。',
              sendError: '聊天服務尚未連線，請先建立連線。',
              attachImage: '圖片',
              attachVideo: '影片',
              attachAudio: '語音',
              clearAttachment: '清除附件',
              attachmentHint: '附件會先壓縮，7天後自動刪除。',
              openAttachment: '開啟附件',
              mediaImage: '圖片',
              mediaVideo: '影片',
              mediaAudio: '語音',
              mediaFile: '檔案',
              friendProfileTitle: '好友資料',
              friendProfileSub: '查看好友的公開資料、聯絡方式與關係狀態。',
              viewProfile: '查看資料',
              friendStatus: '好友狀態',
              friendDirection: '關係方向',
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
      this.externalAccounts = [];
      this.externalAccountDraft = {
        provider: 'evm',
        chain: 'ethereum',
        accountAddress: '',
        signaturePayload: '',
      };
      this.blockchainProviders = {
        evm: ['ethereum', 'base', 'bsc', 'polygon'],
        solana: ['solana'],
        tron: ['tron'],
      };
      this.spaces = [];
      this.posts = [];
      this.privatePosts = [];
      this.profileUser = {
        id: '',
        name: '',
        username: '',
        domain: '',
        secondary: '',
        signature: '',
        age: '',
        gender: '',
        email: '',
        phone: '',
        relationStatus: '',
        direction: '',
      };
      this.profilePosts = [];
      this.profileSpaces = [];
      this.currentSpace = null;
      this.currentPost = null;
      this.spaceModalOpen = false;
      this.postModalOpen = false;
      this.spaceDraft.id = '';
      this.spaceDraft.type = 'private';
      this.spaceDraft.name = '';
      this.spaceDraft.description = '';
      this.spaceDraft.subdomain = '';
      this.postDraft.title = '';
      this.postDraft.content = '';
      this.postDraft.visibility = 'public';
      this.postDraft.status = 'published';
      this.postDraft.spaceId = '';
      this.postDraft.mediaType = '';
      this.postDraft.mediaName = '';
      this.postDraft.mediaMime = '';
      this.postDraft.mediaData = '';
      this.postDraft.mediaUrl = '';
      this.editPostDraft = { id: '', title: '', content: '', visibility: 'public', status: 'published', spaceId: '', mediaType: '', mediaName: '', mediaMime: '', mediaData: '', mediaUrl: '' };
      this.commentDrafts = {};
      this.replyDrafts = {};
      this.commentReplyTargets = {};
      this.spacePosts = [];
      this.friends = [];
      this.newFriendQuery = '';
      this.friendSearchResults = [];
      this.friendSearchPerformed = false;
      this.chatMessages = [];
      this.chatSummaries = [];
      this.revokeChatMediaUrls();
      this.chatAttachment = null;
      this.chatFriendProfile = null;
      this.chatQuickPanelOpen = false;
      this.chatHistoryAtBottom = true;
      this.activeChat = null;
      this.activePrivateSpaceId = '';
      this.activePublicSpaceId = '';
      this.profileDraft.displayName = '';
      this.profileDraft.username = '';
      this.profileDraft.domain = '';
      this.profileDraft.signature = '';
      this.profileDraft.phoneVisibility = 'private';
      this.profileDraft.emailVisibility = 'private';
      this.profileDraft.ageVisibility = 'private';
      this.profileDraft.genderVisibility = 'private';
      this.user.domain = '';
      this.user.signature = '';
      this.user.age = '';
      this.user.gender = '';
      this.user.email = '';
      this.user.phone = '';
      this.user.phoneVisibility = 'private';
      this.user.emailVisibility = 'private';
      this.user.ageVisibility = 'private';
      this.user.genderVisibility = 'private';
      this.hostRouteApplied = false;
      this.auth.account = '';
      this.auth.password = '';
      localStorage.removeItem('token');
      localStorage.removeItem(ACTIVE_PRIVATE_SPACE_KEY);
      localStorage.removeItem(ACTIVE_PUBLIC_SPACE_KEY);
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
      return friend.secondary || friend.domain || friend.username || friend.id;
    },
    friendProfileRows(friend) {
      // Build the rows shown in the chat friend profile modal.
      // 构建聊天好友资料弹窗中展示的字段行。
      if (!friend) {
        return [];
      }
      const missing = this.t('common.notAvailable') || '-';
      return [
        {
          key: 'username',
          label: this.t('profile.identity.username'),
          value: friend.username ? `@${friend.username}` : missing,
        },
        {
          key: 'domain',
          label: this.t('profile.identity.domain'),
          value: friend.domain ? `@${friend.domain}` : missing,
        },
        {
          key: 'signature',
          label: this.t('profile.identity.signature'),
          value: friend.signature || missing,
        },
        {
          key: 'email',
          label: this.t('dashboard.emailPlaceholder'),
          value: friend.email || missing,
        },
        {
          key: 'phone',
          label: this.t('dashboard.phonePlaceholder'),
          value: friend.phone || missing,
        },
        {
          key: 'status',
          label: this.t('chat.friendStatus'),
          value: this.statusLabel(friend.status),
        },
        {
          key: 'direction',
          label: this.t('chat.friendDirection'),
          value: this.directionLabel(friend.direction),
        },
      ];
    },
    openChatFriendProfile(friend) {
      // Open the chat friend profile modal with a frozen friend snapshot.
      // 使用冻结的好友快照打开聊天好友资料弹窗。
      if (!friend) {
        return;
      }
      this.closeChatQuickPanel();
      this.chatFriendProfile = { ...friend };
    },
    async openChatFriendProfilePage() {
      // Jump from the modal to the full profile page.
      // 从弹窗跳转到完整个人主页。
      if (!this.chatFriendProfile?.id) {
        return;
      }
      const friend = { ...this.chatFriendProfile };
      this.closeChatFriendProfile();
      await this.openProfile(friend.id, friend.name);
    },
    closeChatFriendProfile() {
      // Close the chat friend profile modal.
      // 关闭聊天好友资料弹窗。
      this.chatFriendProfile = null;
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
    activeProfileFriend() {
      // Resolve profile user into an accepted friend entry when available.
      // 在可用时将当前主页用户映射为已接受好友。
      return this.friends.find((friend) => friend.id === this.profileUser.id && friend.status === 'accepted') || null;
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
    safeTimestamp(value) {
      // Return a safe epoch timestamp or 0 when invalid.
      // 返回安全时间戳，非法值则返回 0。
      if (!value) {
        return 0;
      }
      const date = new Date(value);
      const time = date.getTime();
      return Number.isNaN(time) ? 0 : time;
    },
    formatChatTime(value) {
      // Format chat time safely to avoid "Invalid Date".
      // 安全格式化聊天时间，避免出现“Invalid Date”。
      const time = this.safeTimestamp(value);
      if (!time) {
        return '';
      }
      return new Date(time).toLocaleTimeString(this.locale, {
        hour: '2-digit',
        minute: '2-digit',
      });
    },
    formatByteSize(bytes) {
      // Format attachment sizes for the draft card.
      // 为附件草稿卡片格式化文件大小。
      const value = Number(bytes || 0);
      if (!Number.isFinite(value) || value <= 0) {
        return '0 B';
      }
      const units = ['B', 'KB', 'MB', 'GB', 'TB'];
      let size = value;
      let unitIndex = 0;
      while (size >= 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex += 1;
      }
      const precision = unitIndex === 0 || size >= 10 ? 0 : 1;
      return `${size.toFixed(precision)} ${units[unitIndex]}`;
    },
    localizedSpaceText(field, item) {
      return item[field][this.locale] || item[field]['zh-CN'] || '';
    },
    identityVisibilityOptions() {
      // Shared identity visibility choices / 共用身份资料可见范围选项。
      return [
        {
          value: 'public',
          primaryLabel: this.t('profile.identity.visibility.public'),
          secondaryLabel: this.peerLocaleText('profile.identity.visibility.public'),
        },
        {
          value: 'friends',
          primaryLabel: this.t('profile.identity.visibility.friends'),
          secondaryLabel: this.peerLocaleText('profile.identity.visibility.friends'),
        },
        {
          value: 'private',
          primaryLabel: this.t('profile.identity.visibility.private'),
          secondaryLabel: this.peerLocaleText('profile.identity.visibility.private'),
        },
      ];
    },
    postVisibilityOptions() {
      // Shared post visibility choices / 共用内容可见范围选项。
      return [
        {
          value: 'public',
          primaryLabel: this.t('posts.publicLabel'),
          secondaryLabel: this.peerLocaleText('posts.publicLabel'),
        },
        {
          value: 'private',
          primaryLabel: this.t('posts.privateLabel'),
          secondaryLabel: this.peerLocaleText('posts.privateLabel'),
        },
      ];
    },
    postStatusOptions() {
      // Shared post status choices / 共用内容状态选项。
      return [
        {
          value: 'published',
          primaryLabel: this.t('posts.statusPublished'),
          secondaryLabel: this.peerLocaleText('posts.statusPublished'),
        },
        {
          value: 'draft',
          primaryLabel: this.t('posts.statusDraft'),
          secondaryLabel: this.peerLocaleText('posts.statusDraft'),
        },
        {
          value: 'hidden',
          primaryLabel: this.t('posts.statusHidden'),
          secondaryLabel: this.peerLocaleText('posts.statusHidden'),
        },
      ];
    },
    spaceTypeOptions() {
      // Shared space type choices / 共用空间类型选项。
      return [
        {
          value: 'private',
          primaryLabel: this.t('spaces.type.private'),
          secondaryLabel: this.peerLocaleText('spaces.type.private'),
        },
        {
          value: 'public',
          primaryLabel: this.t('spaces.type.public'),
          secondaryLabel: this.peerLocaleText('spaces.type.public'),
        },
      ];
    },
    spaceVisibilityOptions() {
      // Shared space visibility choices / 共用空间可见范围选项。
      return [
        {
          value: 'public',
          primaryLabel: this.t('spaces.visibility.public'),
          secondaryLabel: this.peerLocaleText('spaces.visibility.public'),
        },
        {
          value: 'friends',
          primaryLabel: this.t('spaces.visibility.friends'),
          secondaryLabel: this.peerLocaleText('spaces.visibility.friends'),
        },
        {
          value: 'private',
          primaryLabel: this.t('spaces.visibility.private'),
          secondaryLabel: this.peerLocaleText('spaces.visibility.private'),
        },
      ];
    },
    syncSpaceDraftVisibility(type) {
      // Keep the draft visibility aligned with the chosen space type.
      // 让空间草稿的可见范围与选择的空间类型保持一致。
      if (type === 'private') {
        this.spaceDraft.visibility = 'private';
        return;
      }
      if (!this.spaceDraft.visibility || this.spaceDraft.visibility === 'private') {
        this.spaceDraft.visibility = 'public';
      }
    },
    spaceOptions(spaces) {
      // Keep the space picker labels focused on the actual space name and handle.
      // 空间选择器直接展示空间名称与句柄，避免二级域名入口信息被截断。
      return (Array.isArray(spaces) ? spaces : [])
        .filter((space) => space && space.userId === this.user.id)
        .filter((space) => space.type !== 'public' || space.visibility !== 'private')
        .map((space) => ({
          value: space.id,
          label: `${this.localizedSpaceText('name', space)} · @${space.subdomain}`,
        }));
    },
    blockchainProviderChoiceOptions() {
      // Provider labels / 提供方选项：保留简短代码名，避免下拉过宽。
      return (this.blockchainProviderOptions || []).map((provider) => ({
        value: provider,
        label: provider.toUpperCase(),
      }));
    },
    blockchainChainChoiceOptions() {
      // Chain labels / 链网络选项：保留链名本身，保持识别性和紧凑布局。
      return (this.blockchainChainOptions || []).map((chain) => ({
        value: chain,
        label: chain,
      }));
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
    spaceVisibilityLabel(visibility) {
      if (visibility === 'friends') {
        return this.t('spaces.visibility.friends');
      }
      if (visibility === 'private') {
        return this.t('spaces.visibility.private');
      }
      return this.t('spaces.visibility.public');
    },
    postStatusLabel(status) {
      return this.t(`posts.status${String(status).charAt(0).toUpperCase()}${String(status).slice(1)}`) || status;
    },
    canEditPost(post) {
      // Allow editing by the post author or the owning space creator.
      // 允许文章作者或空间创建者编辑内容。
      return Boolean(
        post &&
        this.user &&
        (post.userId === this.user.id || post.spaceUserId === this.user.id),
      );
    },
    toggleCommentReply(postID, commentID) {
      // Toggle the reply composer for a single comment thread.
      // 切换单条评论的回复输入框。
      if (!postID || !commentID) {
        return;
      }
      const current = this.commentReplyTargets[postID] || '';
      if (current === commentID) {
        delete this.commentReplyTargets[postID];
        return;
      }
      this.commentReplyTargets[postID] = commentID;
      if (typeof this.replyDrafts[commentID] !== 'string') {
        this.replyDrafts[commentID] = '';
      }
    },
    cancelCommentReply(postID, commentID) {
      // Close a reply composer and clear the draft for that branch.
      // 关闭回复输入框并清理对应草稿。
      if (postID && this.commentReplyTargets[postID] === commentID) {
        delete this.commentReplyTargets[postID];
      }
      if (commentID) {
        delete this.replyDrafts[commentID];
      }
    },
    isCurrentLevel(level) {
      // Check whether the level card matches the current user tier.
      // 判断当前等级卡片是否对应用户当前等级。
      return String(this.user.level || '').toLowerCase() === String(level.planID || '').toLowerCase();
    },
    localizedMessageContent(message) {
      if (!message || message.content == null) {
        return '';
      }
      if (typeof message.content === 'string') {
        return message.content;
      }
      return message.content[this.locale] || message.content['zh-CN'] || '';
    },
    isStickerMessage(message) {
      const content = this.localizedMessageContent(message).trim();
      return String(message?.messageType || '').toLowerCase() === 'text' &&
        CHAT_STICKER_TOKENS.has(content);
    },
    messageMediaLabel(message) {
      const type = String(message?.messageType || '').toLowerCase();
      if (type === 'image') {
        return this.t('chat.mediaImage');
      }
      if (type === 'video') {
        return this.t('chat.mediaVideo');
      }
      if (type === 'audio') {
        return this.t('chat.mediaAudio');
      }
      return this.t('chat.mediaFile');
    },
    insertChatSnippet(snippet) {
      // Append an emoji or sticker snippet into the composer.
      // 将表情或贴纸片段追加到输入框。
      const value = String(snippet || '');
      if (!value) {
        return;
      }
      this.chatInput = `${this.chatInput || ''}${value}`;
      this.$nextTick(() => {
        const input = this.$refs.chatInput;
        if (input && typeof input.focus === 'function') {
          input.focus();
        }
      });
    },
    updateChatHistoryScrollState(history) {
      // Track whether the message viewport is already near the latest message.
      // 判断消息视口是否已经接近最新消息。
      if (!history) {
        this.chatHistoryAtBottom = true;
        return true;
      }
      const maxScrollTop = Math.max(0, history.scrollHeight - history.clientHeight);
      const atBottom = maxScrollTop - history.scrollTop <= 24;
      this.chatHistoryAtBottom = atBottom;
      return atBottom;
    },
    handleChatHistoryScroll(event) {
      // Update the scroll hint while the user reads older messages.
      // 用户查看更早消息时更新滚动提示状态。
      this.updateChatHistoryScrollState(event?.target || this.$refs.chatHistory);
    },
    scrollChatHistoryToBottom(immediate = false) {
      // Keep the latest message visible after load/send events.
      // 在加载或发送后保持最新消息可见。
      this.$nextTick(() => {
        const history = this.$refs.chatHistory;
        if (!history) {
          this.chatHistoryAtBottom = true;
          return;
        }
        const targetTop = Math.max(0, history.scrollHeight - history.clientHeight);
        if (immediate || typeof history.scrollTo !== 'function') {
          history.scrollTop = targetTop;
          this.updateChatHistoryScrollState(history);
          return;
        }
        history.scrollTo({
          top: targetTop,
          behavior: 'smooth',
        });
        this.chatHistoryAtBottom = true;
      });
    },
    revokeChatMediaUrls() {
      // Release blob URLs created for message previews.
      // 释放用于消息预览的 Blob URL。
      if (Array.isArray(this.chatMediaUrls)) {
        this.chatMediaUrls.forEach((url) => {
          try {
            URL.revokeObjectURL(url);
          } catch (_error) {}
        });
      }
      this.chatMediaUrls = [];
    },
    base64ToBytes(base64) {
      // Decode a base64 payload into bytes.
      // 将 base64 载荷解码为字节数组。
      const normalized = String(base64 || '').trim();
      if (!normalized) {
        return null;
      }
      try {
        const binary = atob(normalized);
        const bytes = new Uint8Array(binary.length);
        for (let index = 0; index < binary.length; index += 1) {
          bytes[index] = binary.charCodeAt(index);
        }
        return bytes;
      } catch (_error) {
        return null;
      }
    },
    bytesToBase64(bytes) {
      // Encode bytes into a base64 payload.
      // 将字节数组编码为 base64 载荷。
      if (!bytes || !bytes.length) {
        return '';
      }
      let binary = '';
      const chunkSize = 0x8000;
      for (let index = 0; index < bytes.length; index += chunkSize) {
        binary += String.fromCharCode(
          ...bytes.subarray(index, index + chunkSize),
        );
      }
      return btoa(binary);
    },
    async compressAttachmentBytes(bytes) {
      // Compress attachment bytes with gzip when the browser supports it.
      // 当浏览器支持时使用 gzip 压缩附件字节。
      if (!bytes || !bytes.length || typeof CompressionStream !== 'function') {
        return bytes;
      }
      try {
        const stream = new Blob([bytes]).stream().pipeThrough(
          new CompressionStream('gzip'),
        );
        const buffer = await new Response(stream).arrayBuffer();
        return new Uint8Array(buffer);
      } catch (_error) {
        return bytes;
      }
    },
    async decompressAttachmentBytes(bytes) {
      // Decompress attachment bytes when the browser exposes DecompressionStream.
      // 当浏览器提供 DecompressionStream 时解压附件字节。
      if (!bytes || !bytes.length || typeof DecompressionStream !== 'function') {
        return bytes;
      }
      try {
        const stream = new Blob([bytes]).stream().pipeThrough(
          new DecompressionStream('gzip'),
        );
        const buffer = await new Response(stream).arrayBuffer();
        return new Uint8Array(buffer);
      } catch (_error) {
        return bytes;
      }
    },
    normalizeAttachmentType(messageType, mime, fileName) {
      // Normalize attachment type from the requested type or file metadata.
      // 根据请求类型或文件元数据规范附件类型。
      const normalized = String(messageType || '').toLowerCase().trim();
      if (
        normalized === 'text' ||
        normalized === 'image' ||
        normalized === 'video' ||
        normalized === 'audio'
      ) {
        return normalized;
      }
      const safeMime = String(mime || '').toLowerCase();
      if (safeMime.startsWith('image/')) {
        return 'image';
      }
      if (safeMime.startsWith('video/')) {
        return 'video';
      }
      if (safeMime.startsWith('audio/')) {
        return 'audio';
      }
      const lower = String(fileName || '').toLowerCase();
      if (/\.(png|jpe?g|gif|webp|bmp)$/i.test(lower)) {
        return 'image';
      }
      if (/\.(mp4|mov|webm|m4v|mkv)$/i.test(lower)) {
        return 'video';
      }
      if (/\.(mp3|wav|ogg|m4a|aac)$/i.test(lower)) {
        return 'audio';
      }
      return 'text';
    },
    inferAttachmentMime(messageType, fileName, declaredMime = '') {
      // Infer a specific MIME type so media previews can be rendered reliably.
      // 推断具体 MIME 类型，便于稳定渲染媒体预览。
      const safeMime = String(declaredMime || '').trim();
      if (safeMime && !safeMime.includes('*') && safeMime !== 'application/octet-stream') {
        return safeMime;
      }
      const lower = String(fileName || '').toLowerCase();
      if (lower.endsWith('.png')) {
        return 'image/png';
      }
      if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        return 'image/jpeg';
      }
      if (lower.endsWith('.gif')) {
        return 'image/gif';
      }
      if (lower.endsWith('.webp')) {
        return 'image/webp';
      }
      if (lower.endsWith('.mp4')) {
        return 'video/mp4';
      }
      if (lower.endsWith('.mov')) {
        return 'video/quicktime';
      }
      if (lower.endsWith('.webm')) {
        return 'video/webm';
      }
      if (lower.endsWith('.m4v')) {
        return 'video/x-m4v';
      }
      if (lower.endsWith('.mkv')) {
        return 'video/x-matroska';
      }
      if (lower.endsWith('.mp3')) {
        return 'audio/mpeg';
      }
      if (lower.endsWith('.wav')) {
        return 'audio/wav';
      }
      if (lower.endsWith('.ogg')) {
        return 'audio/ogg';
      }
      if (lower.endsWith('.m4a')) {
        return 'audio/mp4';
      }
      if (lower.endsWith('.aac')) {
        return 'audio/aac';
      }
      if (messageType === 'image') {
        return 'image/png';
      }
      if (messageType === 'video') {
        return 'video/mp4';
      }
      if (messageType === 'audio') {
        return 'audio/mpeg';
      }
      return 'application/octet-stream';
    },
    async buildChatMediaUrl(mediaData, mediaMime, messageType, fileName = '') {
      // Build a browser-safe object URL for the decoded media bytes.
      // 为解码后的媒体字节构建浏览器可用的对象 URL。
      const bytes = this.base64ToBytes(mediaData);
      if (!bytes) {
        return '';
      }
      const decodedBytes = await this.decompressAttachmentBytes(bytes);
      const mime = this.inferAttachmentMime(messageType, fileName, mediaMime);
      try {
        const url = URL.createObjectURL(new Blob([decodedBytes], { type: mime }));
        this.chatMediaUrls.push(url);
        return url;
      } catch (_error) {
        return '';
      }
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
      this.settingsOpen = false;
    },
    setAuthMode(mode) {
      this.authMode = mode === 'register' ? 'register' : 'login';
      this.clearFeedback();
    },
    toggleSettingsMenu() {
      this.settingsOpen = !this.settingsOpen;
    },
    closeSettingsMenu() {
      this.settingsOpen = false;
    },
    toggleSidebar() {
      // Toggle sidebar collapsed state.
      // 切换侧边栏折叠状态。
      this.sidebarCollapsed = !this.sidebarCollapsed;
    },
    toggleChatQuickPanel() {
      // Toggle the chat quick panel instead of keeping it always visible.
      // 切换聊天快捷面板，避免表情框一直占据输入区。
      this.chatQuickPanelOpen = !this.chatQuickPanelOpen;
    },
    closeChatQuickPanel() {
      // Close the chat quick panel when clicking outside or after sending.
      // 点击外部或发送后收起聊天快捷面板。
      this.chatQuickPanelOpen = false;
    },
    openProfileTab(tabKey) {
      // Open profile view with a specific tab.
      // 打开个人主页并定位到指定选项卡。
      if (!tabKey) {
        return;
      }
      if (tabKey === 'blockchain' && !this.hasBlockchainAccounts) {
        // Skip blockchain tab when no accounts.
        // 没有链上账号时跳过该选项卡。
        // Default to membership tab for profile view.
        // 默认回到个人主页的会员等级标签。
        this.profileTab = 'levels';
        this.view = 'profile';
        return;
      }
      this.profileTab = tabKey;
      this.view = 'profile';
    },
    applyTheme() {
      // Apply theme selection to the document root.
      // 将皮肤选择应用到页面根节点。
      if (!this.theme) {
        return;
      }
      document.documentElement.dataset.theme = this.theme;
      localStorage.setItem('theme', this.theme);
    },
    handleDocumentClick(event) {
      if (event.target.closest('.settings-menu')) {
        return;
      }
      this.closeSettingsMenu();
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
        if (!this.token) {
          return;
        }
        await this.loadSpaces();
        await this.loadSubscription();
        await this.loadExternalAccounts();
        await this.loadPosts();
        await this.loadPrivatePosts();
        await this.loadFriends();
        await this.loadConversationSummaries();
        if (this.activeChat) {
          await this.loadConversation(this.activeChat.id);
        } else {
          await this.loadUnread();
        }
        const routedToProfile = await this.applyHostRouteFromHost();
        if (!routedToProfile) {
          this.view = 'dashboard';
        }
        this.settingsOpen = false;
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
        if (!this.token) {
          return;
        }
        await this.loadSpaces();
        await this.loadSubscription();
        await this.loadExternalAccounts();
        await this.loadPosts();
        await this.loadPrivatePosts();
        await this.loadFriends();
        await this.loadConversationSummaries();
        if (this.activeChat) {
          await this.loadConversation(this.activeChat.id);
        } else {
          await this.loadUnread();
        }
        const routedToProfile = await this.applyHostRouteFromHost();
        if (!routedToProfile) {
          this.view = 'dashboard';
        }
        this.settingsOpen = false;
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
      this.user.username = data.username || this.user.username;
      this.user.domain = data.domain || this.user.domain;
      this.user.signature = data.signature ?? this.user.signature ?? '';
      this.user.age = data.age ?? this.user.age ?? '';
      this.user.gender = data.gender ?? this.user.gender ?? '';
      this.user.email = data.email ?? this.user.email ?? '';
      this.user.phone = data.phone ?? this.user.phone ?? '';
      this.user.phoneVisibility = data.phone_visibility || this.user.phoneVisibility || 'private';
      this.user.emailVisibility = data.email_visibility || this.user.emailVisibility || 'private';
      this.user.ageVisibility = data.age_visibility || this.user.ageVisibility || 'private';
      this.user.genderVisibility = data.gender_visibility || this.user.genderVisibility || 'private';
      this.user.level = data.level || this.user.level;
      this.profileDraft.displayName = data.display_name || '';
      this.profileDraft.username = data.username || this.profileDraft.username || '';
      this.profileDraft.domain = data.domain || this.profileDraft.domain || '';
      this.profileDraft.signature = data.signature ?? this.profileDraft.signature ?? '';
      this.profileDraft.phoneVisibility = data.phone_visibility || this.profileDraft.phoneVisibility || 'private';
      this.profileDraft.emailVisibility = data.email_visibility || this.profileDraft.emailVisibility || 'private';
      this.profileDraft.ageVisibility = data.age_visibility || this.profileDraft.ageVisibility || 'private';
      this.profileDraft.genderVisibility = data.gender_visibility || this.profileDraft.genderVisibility || 'private';
    },
    async loadSpaces() {
      // Load spaces from server.
      // 从服务端加载空间。
      if (!this.token) {
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/spaces`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      if (Array.isArray(data.items)) {
        this.spaces = data.items.map((item) => this.mapSpaceItem(item));
        if (this.currentSpace?.id) {
          const refreshed = this.findSpaceById(this.currentSpace.id);
          if (refreshed) {
            this.currentSpace = refreshed;
          }
        }
        this.syncActiveSpaces();
        const activeSpace = this.currentSpace || this.activeSpace;
        if (activeSpace?.id) {
          await this.loadSpacePosts(activeSpace.id);
        } else {
          this.spacePosts = [];
        }
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
    async loadExternalAccounts() {
      // Load current user's blockchain account bindings.
      // 加载当前用户的链上账号绑定。
      if (!this.token) {
        this.externalAccounts = [];
        return;
      }
      const res = await fetch(`${this.apiBase}/external-accounts`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      this.externalAccounts = Array.isArray(data.items)
        ? data.items.map((item) => ({
            id: item.id,
            provider: item.provider || '',
            chain: item.chain || '',
            accountAddress: item.account_address || '',
            bindingStatus: item.binding_status || 'inactive',
            metadata: item.metadata || '',
            createdAt: item.created_at || '',
          }))
        : [];
    },
    async loadPosts() {
      // Load the public content feed.
      // 加载公共内容流。
      if (!this.token) {
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/posts?visibility=public&limit=50`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      if (Array.isArray(data.items)) {
        this.posts = data.items.map((item) => this.mapPostItem(item));
      }
    },
    async loadSpacePosts(spaceID) {
      // Load posts for the currently selected space.
      // 加载当前选中空间的帖子流。
      if (!this.token || !spaceID) {
        this.spacePosts = [];
        return;
      }
      const encoded = encodeURIComponent(spaceID);
      const res = await fetch(`${this.spaceApiBase}/spaces/${encoded}/posts?visibility=all&limit=50`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      this.spacePosts = Array.isArray(data.items)
        ? data.items.map((item) => this.mapPostItem(item))
        : [];
    },
    async loadPrivatePosts() {
      // Load posts created by the current user.
      // 加载当前用户发布的文章。
      if (!this.token || !this.user.id) {
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/users/${this.user.id}/posts?visibility=all&limit=50`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      if (Array.isArray(data.items)) {
        this.privatePosts = data.items.map((item) => this.mapPostItem(item));
      }
    },
    async openProfile(userID, fallbackName = '') {
      // Open another user's public profile feed.
      // 打开其他用户的公开内容主页。
      if (!this.token || !userID) {
        return;
      }
      const profileRes = await fetch(`${this.apiBase}/users/${userID}/profile`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (profileRes.ok) {
        const profile = await profileRes.json();
        const profileSecondary = [
          profile.domain ? `@${profile.domain}` : '',
          profile.username ? `@${profile.username}` : '',
          profile.signature || '',
          profile.email || '',
          profile.phone || '',
          profile.age ?? '',
          profile.gender || '',
          profile.user_id || userID,
        ].filter(Boolean).join(' · ');
        this.profileUser = {
          id: profile.user_id || userID,
          name: profile.display_name || fallbackName || userID,
          username: profile.username || '',
          domain: profile.domain || '',
          secondary: profileSecondary,
          signature: profile.signature || '',
          age: profile.age ?? '',
          gender: profile.gender || '',
          email: profile.email || '',
          phone: profile.phone || '',
          relationStatus: profile.relation_status || '',
          direction: profile.direction || '',
        };
      } else {
        this.profileUser = {
          id: userID,
          name: fallbackName || userID,
          username: '',
          domain: '',
          secondary: userID,
          signature: '',
          age: '',
          gender: '',
          email: '',
          phone: '',
          relationStatus: '',
          direction: '',
        };
      }
      const res = await fetch(`${this.apiBase}/users/${userID}/posts?visibility=public&limit=50`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      this.profilePosts = Array.isArray(data.items)
        ? data.items.map((item) => this.mapPostItem(item))
        : [];
      await this.loadProfileSpaces(this.profileUser.id || userID);
      if (this.profilePosts[0]?.authorName) {
        this.profileUser.name = this.profilePosts[0].authorName;
      }
      // Reset profile tab when opening profile.
      // 打开个人主页时重置选项卡。
      // Reset to membership tab in profile.
      // 重置为个人主页的会员等级标签。
      this.profileTab = 'levels';
      this.view = 'profile';
    },
    async loadProfileSpaces(userID) {
      // Load public spaces for the opened profile.
      // 加载当前主页的公开空间。
      if (!this.token || !userID) {
        this.profileSpaces = [];
        return;
      }
      const encoded = encodeURIComponent(String(userID).trim());
      const res = await fetch(`${this.spaceApiBase}/users/${encoded}/spaces?visibility=public`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      this.profileSpaces = Array.isArray(data.items)
        ? data.items.map((item) => this.mapSpaceItem(item))
        : [];
    },
    async openProfileByDomain(domain) {
      // Resolve a domain identity card into the corresponding profile.
      // 将域名身份卡解析为对应的个人主页。
      if (!this.token || !domain) {
        return false;
      }
      const encoded = encodeURIComponent(String(domain).trim().toLowerCase());
      const res = await fetch(`${this.apiBase}/users/domain/${encoded}/profile`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return false;
      }
      const profile = await res.json();
      await this.openProfile(profile.user_id || '', profile.display_name || '');
      return true;
    },
    async openProfileByUsername(username) {
      // Resolve a username subdomain into the corresponding profile.
      // 将用户名子域名解析为对应的个人主页。
      if (!this.token || !username) {
        return false;
      }
      const encoded = encodeURIComponent(String(username).trim().toLowerCase());
      const res = await fetch(`${this.apiBase}/users/username/${encoded}/profile`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return false;
      }
      const profile = await res.json();
      await this.openProfile(profile.user_id || '', profile.display_name || '');
      return true;
    },
    async applyHostRouteFromHost() {
      // Route subdomain-hosted identity pages once per session.
      // 每个会话仅路由一次基于子域名的身份主页。
      if (this.hostRouteApplied || !this.token) {
        return false;
      }
      const label = this.hostSubdomainLabel();
      if (!label) {
        this.hostRouteApplied = true;
        return false;
      }
      if (this.spaceFromHost()) {
        this.hostRouteApplied = true;
        return false;
      }
      this.hostRouteApplied = true;
      if (await this.openProfileByDomain(label)) {
        return true;
      }
      return this.openProfileByUsername(label);
    },
    async openPostDetail(postID) {
      // Open a single post detail page.
      // 打开单篇文章详情页。
      if (!this.token || !postID) {
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/posts/${postID}`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const item = await res.json();
      this.currentPost = this.mapPostItem(item);
      const selectedSpace = this.findSpaceById(item.space_id) ||
        this.visibleProfileSpaces.find((space) => space.id === item.space_id) ||
        (this.currentSpace?.id === item.space_id ? this.currentSpace : null);
      if (selectedSpace) {
        this.setActiveSpace(selectedSpace);
        await this.loadSpacePosts(selectedSpace.id);
      }
      this.editPostDraft = {
        id: item.id,
        title: item.title,
        content: item.content,
        visibility: item.visibility,
        status: item.status || 'published',
        spaceId: item.space_id || '',
        mediaType: item.mediaType || '',
        mediaName: item.mediaName || '',
        mediaMime: item.mediaMime || '',
        mediaData: item.mediaData || '',
        mediaUrl: item.mediaUrl || '',
      };
      this.view = 'postDetail';
    },
    backFromPostDetail() {
      // Return from detail view to the combined space feed.
      // 从详情页返回合并后的空间内容流。
      this.view = 'space';
    },
    backToPublicFeed() {
      // Return from profile view to the combined space feed.
      // 从用户主页返回合并后的空间内容流。
      this.view = 'space';
    },
    async refreshActiveProfile() {
      // Refresh profile data when the profile page is open.
      // 当用户主页打开时刷新主页数据。
      if (this.view === 'profile' && this.profileUser.id) {
        await this.openProfile(this.profileUser.id, this.profileUser.name);
      }
    },
    async addProfileFriend() {
      // Send a friend request from the profile header.
      // 从用户主页头部发送好友请求。
      if (!this.profileUser.id || this.profileUser.id === this.user.id) {
        return;
      }
      await this.addFriend({
        id: this.profileUser.id,
      });
      await this.refreshActiveProfile();
    },
    async acceptProfileFriend() {
      // Accept an incoming friend request from the profile header.
      // 在用户主页头部接受收到的好友请求。
      if (!this.profileUser.id) {
        return;
      }
      await this.acceptFriend({
        id: this.profileUser.id,
        direction: 'incoming',
        status: 'pending',
      });
      await this.refreshActiveProfile();
    },
    async createPost() {
      // Create a new social post.
      // 创建新的社交文章。
      this.clearFeedback();
      if (!this.token || !this.postDraft.title.trim()) {
        return;
      }
      const spaceId = String(this.postDraft.spaceId || '').trim();
      const space = this.findSpaceById(spaceId);
      if (!space || space.userId !== this.user.id) {
        this.setError(this.t('posts.spaceRequired'));
        return;
      }
      if (!this.postDraft.content.trim() && !this.postDraft.mediaData.trim()) {
        this.setError(this.t('posts.publishError'));
        return;
      }
      if (!spaceId) {
        this.setError(this.t('posts.spaceRequired'));
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/posts`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: this.postDraft.title.trim(),
          content: this.postDraft.content.trim(),
          visibility: this.postDraft.visibility,
          status: this.postDraft.status,
          space_id: spaceId,
          media_type: this.postDraft.mediaType,
          media_name: this.postDraft.mediaName,
          media_mime: this.postDraft.mediaMime,
          media_data: this.postDraft.mediaData,
        }),
      });
      if (!res.ok) {
        this.setError(this.t('posts.publishError'));
        return;
      }
      this.postDraft.spaceId = spaceId;
      this.view = 'space';
      await this.loadSpacePosts(spaceId);
      this.postDraft.title = '';
      this.postDraft.content = '';
      this.postDraft.visibility = 'public';
      this.postDraft.status = 'published';
      this.postDraft.mediaType = '';
      this.postDraft.mediaName = '';
      this.postDraft.mediaMime = '';
      this.postDraft.mediaData = '';
      this.postDraft.mediaUrl = '';
      this.postModalOpen = false;
      await this.loadPosts();
      await this.loadPrivatePosts();
      if (this.currentPost?.id) {
        await this.openPostDetail(this.currentPost.id);
      }
      this.setFlash(this.t('posts.publishSuccess'));
    },
    async startEditPost(post) {
      // Load an existing post into the edit form.
      // 将已有文章载入编辑表单。
      if (!this.canEditPost(post)) {
        return;
      }
      await this.openPostDetail(post.id);
      const selectedPost = this.currentPost || post;
      const spaceId = selectedPost.spaceId || '';
      this.editPostDraft = {
        id: selectedPost.id,
        title: selectedPost.title,
        content: selectedPost.content,
        visibility: selectedPost.visibility,
        status: selectedPost.status || 'published',
        spaceId,
        mediaType: selectedPost.mediaType || '',
        mediaName: selectedPost.mediaName || '',
        mediaMime: selectedPost.mediaMime || '',
        mediaData: selectedPost.mediaData || '',
        mediaUrl: selectedPost.mediaUrl || '',
      };
      this.view = 'postDetail';
    },
    async savePostEdit() {
      // Persist the current post edit form.
      // 保存当前文章编辑表单。
      this.clearFeedback();
      if (!this.token || !this.editPostDraft.id || !this.editPostDraft.title.trim()) {
        return;
      }
      const spaceId = String(this.editPostDraft.spaceId || '').trim();
      const space = this.findSpaceById(spaceId);
      if (!space || space.userId !== this.user.id) {
        this.setError(this.t('posts.spaceRequired'));
        return;
      }
      if (!this.editPostDraft.content.trim() && !this.editPostDraft.mediaData.trim()) {
        this.setError(this.t('posts.editError'));
        return;
      }
      if (!spaceId) {
        this.setError(this.t('posts.spaceRequired'));
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/posts/${this.editPostDraft.id}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: this.editPostDraft.title.trim(),
          content: this.editPostDraft.content.trim(),
          visibility: this.editPostDraft.visibility,
          status: this.editPostDraft.status,
          space_id: spaceId,
          media_type: this.editPostDraft.mediaType,
          media_name: this.editPostDraft.mediaName,
          media_mime: this.editPostDraft.mediaMime,
          media_data: this.editPostDraft.mediaData,
        }),
      });
      if (!res.ok) {
        this.setError(this.t('posts.editError'));
        return;
      }
      await this.loadPosts();
      await this.loadPrivatePosts();
      await this.loadSpacePosts(spaceId);
      await this.openPostDetail(this.editPostDraft.id);
      this.setFlash(this.t('posts.editSuccess'));
    },
    async togglePostLike(post) {
      // Toggle like state for a post.
      // 切换文章点赞状态。
      this.clearFeedback();
      if (!this.token || !post) {
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/posts/${post.id}/likes`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      await this.loadPosts();
      await this.loadPrivatePosts();
      await this.loadSpacePosts(post.spaceId || this.activeSpace?.id || '');
      if (this.currentPost?.id === post.id) {
        await this.openPostDetail(post.id);
      }
    },
    async submitComment(post, parentCommentId = '') {
      // Submit a comment or reply to a post.
      // 向文章提交评论或回复。
      this.clearFeedback();
      const rootDraft = this.commentDrafts[post.id] || '';
      const replyDraft = parentCommentId ? this.replyDrafts[parentCommentId] || '' : '';
      const content = parentCommentId ? replyDraft : rootDraft;
      if (!this.token || !post || !content.trim()) {
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/posts/${post.id}/comments`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: content.trim(),
          parent_comment_id: parentCommentId || '',
        }),
      });
      if (!res.ok) {
        this.setError(this.t('posts.commentError'));
        return;
      }
      if (parentCommentId) {
        delete this.replyDrafts[parentCommentId];
        if (this.commentReplyTargets[post.id] === parentCommentId) {
          delete this.commentReplyTargets[post.id];
        }
      } else {
        this.commentDrafts[post.id] = '';
      }
      await this.loadPosts();
      await this.loadPrivatePosts();
      await this.loadSpacePosts(post.spaceId || this.activeSpace?.id || '');
      if (this.currentPost?.id === post.id) {
        await this.openPostDetail(post.id);
      }
    },
    async sharePost(post) {
      // Share a post in the social feed.
      // 在内容流中转发文章。
      this.clearFeedback();
      if (!this.token || !post) {
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/posts/${post.id}/shares`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.setError(this.t('posts.shareError'));
        return;
      }
      await this.loadPosts();
      await this.loadPrivatePosts();
      await this.loadSpacePosts(post.spaceId || this.activeSpace?.id || '');
      if (this.currentPost?.id === post.id) {
        await this.openPostDetail(post.id);
      }
    },
    async saveProfile() {
      // Persist identity card changes to the account service.
      // 将身份卡变更保存到账号服务。
      this.clearFeedback();
      const displayName = this.profileDraft.displayName.trim();
      const username = this.profileDraft.username.trim().toLowerCase();
      const domain = this.profileDraft.domain.trim().toLowerCase();
      if (!this.token || !displayName) {
        this.setError(this.t('dashboard.saveError'));
        return;
      }
      if (!username) {
        this.setError(this.t('dashboard.usernameRequired'));
        return;
      }
      if (!this.isValidSpaceSubdomain(username)) {
        this.setError(this.t('dashboard.usernameError'));
        return;
      }
      if (!domain) {
        this.setError(this.t('profile.identity.domainRequired'));
        return;
      }
      if (!this.isValidSpaceSubdomain(domain)) {
        this.setError(this.t('profile.identity.domainError'));
        return;
      }
      const res = await fetch(`${this.apiBase}/me`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          display_name: displayName,
          username,
          domain,
          signature: this.profileDraft.signature.trim(),
          phone_visibility: this.profileDraft.phoneVisibility,
          email_visibility: this.profileDraft.emailVisibility,
          age_visibility: this.profileDraft.ageVisibility,
          gender_visibility: this.profileDraft.genderVisibility,
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
    async bindExternalAccount() {
      // Create a new blockchain account binding for the current user.
      // 为当前用户创建新的链上账号绑定。
      this.clearFeedback();
      if (
        !this.token ||
        !this.externalAccountDraft.accountAddress.trim() ||
        !this.externalAccountDraft.signaturePayload.trim()
      ) {
        this.setError(this.t('blockchain.bindError'));
        return;
      }
      const res = await fetch(`${this.apiBase}/external-accounts`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          provider: this.externalAccountDraft.provider,
          chain: this.externalAccountDraft.chain,
          account_address: this.externalAccountDraft.accountAddress.trim(),
          signature_payload: this.externalAccountDraft.signaturePayload.trim(),
        }),
      });
      if (!res.ok) {
        this.setError(this.t('blockchain.bindError'));
        return;
      }
      this.externalAccountDraft.accountAddress = '';
      this.externalAccountDraft.signaturePayload = '';
      await this.loadExternalAccounts();
      this.setFlash(this.t('blockchain.bindSuccess'));
    },
    async removeExternalAccount(account) {
      // Remove a blockchain account binding from the current user.
      // 删除当前用户的链上账号绑定。
      this.clearFeedback();
      if (!this.token || !account || !account.id) {
        return;
      }
      const res = await fetch(`${this.apiBase}/external-accounts/${account.id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.setError(this.t('blockchain.removeError'));
        return;
      }
      await this.loadExternalAccounts();
      this.setFlash(this.t('blockchain.removeSuccess'));
    },
    async createSpace() {
      // Create or update a space from the current form.
      // 根据当前表单创建或更新空间。
      this.clearFeedback();
      if (!this.token || !this.spaceDraft.name.trim()) {
        return;
      }
      const subdomain = this.spaceDraft.subdomain.trim().toLowerCase();
      const visibility = this.spaceDraft.type === 'private' ? 'private' : (this.spaceDraft.visibility || 'public');
      if (subdomain && !this.isValidSpaceSubdomain(subdomain)) {
        this.setError(this.t('spaces.subdomainError'));
        return;
      }
      if (this.spaceDraft.id) {
        if (!subdomain) {
          this.setError(this.t('spaces.subdomainRequired'));
          return;
        }
        const res = await fetch(`${this.spaceApiBase}/spaces/${this.spaceDraft.id}`, {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${this.token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: this.spaceDraft.name.trim(),
            description: this.spaceDraft.description.trim(),
            subdomain,
            visibility,
          }),
        });
        if (!res.ok) {
          this.setError(this.t('spaces.editError'));
          return;
        }
        const item = await res.json();
        const updatedSpace = this.mapSpaceItem(item);
        await this.loadSpaces();
        this.setActiveSpace(updatedSpace);
        await this.loadSpacePosts(updatedSpace.id);
        this.view = 'space';
        this.closeSpaceComposer();
        this.setFlash(this.t('spaces.editSuccess'));
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/spaces`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          type: this.spaceDraft.type,
          visibility,
          name: this.spaceDraft.name.trim(),
          description: this.spaceDraft.description.trim(),
          ...(subdomain ? { subdomain } : {}),
        }),
      });
      if (!res.ok) {
        this.setError(this.t('spaces.createError'));
        return;
      }
      const item = await res.json();
      const createdSpace = this.mapSpaceItem(item);
      await this.loadSpaces();
      this.setActiveSpace(createdSpace);
      await this.loadSpacePosts(createdSpace.id);
      this.view = 'space';
      this.closeSpaceComposer();
      this.setFlash(this.t('spaces.createSuccess'));
    },
    async deleteSpace(space) {
      // Delete a space and all content that belongs to it.
      // 删除一个空间以及其下属全部内容。
      this.clearFeedback();
      if (!this.token || !space || !space.id) {
        return;
      }
      if (space.userId !== this.user.id) {
        this.setError(this.t('spaces.editError'));
        return;
      }
      const label = this.localizedSpaceText('name', space) || space.subdomain || space.id;
      const confirmed = window.confirm(`${this.t('spaces.deleteConfirm')}\n${label}`);
      if (!confirmed) {
        return;
      }
      const res = await fetch(`${this.spaceApiBase}/spaces/${space.id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.setError(this.t('spaces.deleteError'));
        return;
      }
      const relatedPostIds = new Set([
        ...this.posts.filter((post) => post.spaceId === space.id).map((post) => post.id),
        ...this.privatePosts.filter((post) => post.spaceId === space.id).map((post) => post.id),
        ...this.spacePosts.filter((post) => post.spaceId === space.id).map((post) => post.id),
        ...this.profilePosts.filter((post) => post.spaceId === space.id).map((post) => post.id),
        ...(this.currentPost && this.currentPost.spaceId === space.id ? [this.currentPost.id] : []),
      ]);
      relatedPostIds.forEach((postId) => {
        delete this.commentDrafts[postId];
      });
      this.replyDrafts = {};
      this.commentReplyTargets = {};
      if (this.postDraft.spaceId === space.id) {
        this.postDraft.spaceId = '';
      }
      if (this.editPostDraft.spaceId === space.id) {
        this.editPostDraft = {
          id: '',
          title: '',
          content: '',
          visibility: 'public',
          status: 'published',
          spaceId: '',
          mediaType: '',
          mediaName: '',
          mediaMime: '',
          mediaData: '',
          mediaUrl: '',
        };
      }
      if (this.spaceDraft.id === space.id) {
        this.closeSpaceComposer();
      }
      if (this.currentSpace && this.currentSpace.id === space.id) {
        this.currentSpace = null;
      }
      if (this.currentPost && this.currentPost.spaceId === space.id) {
        this.currentPost = null;
        this.editPostDraft = {
          id: '',
          title: '',
          content: '',
          visibility: 'public',
          status: 'published',
          spaceId: '',
          mediaType: '',
          mediaName: '',
          mediaMime: '',
          mediaData: '',
          mediaUrl: '',
        };
        if (this.view === 'postDetail') {
          this.view = 'space';
        }
      }
      await this.loadSpaces();
      await this.loadPosts();
      await this.loadPrivatePosts();
      await this.loadSpacePosts(this.activeSpace?.id || '');
      if (this.view === 'profile' && this.profileUser.id === this.user.id) {
        await this.openProfile(this.profileUser.id, this.profileUser.name);
      }
      this.setFlash(this.t('spaces.deleteSuccess'));
    },
    async deletePost(post) {
      // Delete a social post and its interaction history.
      // 删除一篇社交文章及其互动记录。
      this.clearFeedback();
      if (!this.token || !post || !post.id) {
        return;
      }
      const label = post.title || post.id;
      const confirmed = window.confirm(`${this.t('posts.deleteConfirm')}\n${label}`);
      if (!confirmed) {
        return;
      }
      const spaceId = post.spaceId || this.activeSpace?.id || '';
      const res = await fetch(`${this.spaceApiBase}/posts/${post.id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.setError(this.t('posts.deleteError'));
        return;
      }
      delete this.commentDrafts[post.id];
      this.replyDrafts = {};
      this.commentReplyTargets = {};
      if (this.editPostDraft.id === post.id) {
        this.editPostDraft = {
          id: '',
          title: '',
          content: '',
          visibility: 'public',
          status: 'published',
          spaceId: '',
          mediaType: '',
          mediaName: '',
          mediaMime: '',
          mediaData: '',
          mediaUrl: '',
        };
      }
      if (this.currentPost && this.currentPost.id === post.id) {
        this.currentPost = null;
        this.editPostDraft = {
          id: '',
          title: '',
          content: '',
          visibility: 'public',
          status: 'published',
          spaceId: '',
          mediaType: '',
          mediaName: '',
          mediaMime: '',
          mediaData: '',
          mediaUrl: '',
        };
        if (this.view === 'postDetail') {
          this.view = 'space';
        }
      }
      await this.loadPosts();
      await this.loadPrivatePosts();
      await this.loadSpacePosts(spaceId);
      if (this.view === 'profile' && this.profileUser.id === this.user.id) {
        await this.openProfile(this.profileUser.id, this.profileUser.name);
      }
      this.setFlash(this.t('posts.deleteSuccess'));
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
          name: item.display_name || item.domain || item.username || item.email || item.phone || item.friend_id,
          username: item.username || '',
          domain: item.domain || '',
          signature: item.signature || '',
          secondary: [
            item.domain ? `@${item.domain}` : '',
            item.username ? `@${item.username}` : '',
            item.signature || '',
            item.age ?? '',
            item.gender || '',
            item.email || '',
            item.phone || '',
            item.friend_id || '',
          ].filter(Boolean).join(' · '),
          age: item.age ?? '',
          gender: item.gender || '',
          email: item.email || '',
          phone: item.phone || '',
          status: item.status || 'offline',
          direction: item.direction || 'outgoing',
          createdAt: item.created_at || '',
        }));
        if (!this.activeChat || !this.acceptedFriends.find((friend) => friend.id === this.activeChat.id)) {
          this.activeChat = this.acceptedFriends[0] || null;
          if (!this.activeChat) {
            this.chatMessages = [];
          }
        }
        if (this.chatFriendProfile && (!this.activeChat || this.chatFriendProfile.id !== this.activeChat.id)) {
          this.closeChatFriendProfile();
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
            name: item.display_name || item.domain || item.username || item.email || item.phone || item.user_id,
            username: item.username || '',
            domain: item.domain || '',
            signature: item.signature || '',
            secondary: [
              item.domain ? `@${item.domain}` : '',
              item.username ? `@${item.username}` : '',
              item.signature || '',
              item.age ?? '',
              item.gender || '',
              item.email || '',
              item.phone || '',
              item.user_id || '',
            ].filter(Boolean).join(' · '),
            age: item.age ?? '',
            gender: item.gender || '',
            email: item.email || '',
            phone: item.phone || '',
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
        this.revokeChatMediaUrls();
        this.chatMessages = [];
        this.chatHistoryAtBottom = true;
        return;
      }
      this.revokeChatMediaUrls();
      this.chatMessages = [];
      this.chatHistoryAtBottom = true;
      const params = new URLSearchParams({ peer_id: friendID, limit: '100' });
      const res = await fetch(`${this.messageApiBase}/messages?${params.toString()}`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        this.setError(this.t('chat.loadError'));
        this.chatHistoryAtBottom = true;
        return;
      }
      const data = await res.json();
        if (Array.isArray(data.items)) {
          this.chatMessages = await Promise.all(
            data.items.map(async (item) => {
            // Support snake_case and camelCase message payloads.
            // 兼容下划线与驼峰字段的消息数据。
            const messageType = String(
              item.message_type || item.MessageType || item.messageType || 'text',
            ).toLowerCase();
            const mediaName = item.media_name || item.MediaName || '';
            const mediaMime = item.media_mime || item.MediaMime || '';
            const mediaData = item.media_data || item.MediaData || '';
            const mediaUrl = mediaData
              ? await this.buildChatMediaUrl(
                  mediaData,
                  mediaMime,
                  messageType,
                  mediaName,
                )
              : '';
            return {
              id: item.id || item.ID,
              from: item.sender_id || item.SenderID || item.from,
              to: item.receiver_id || item.ReceiverID || item.to || '',
              messageType,
              content: item.content || item.Content || '',
              mediaName,
              mediaMime,
              mediaData,
              mediaUrl,
              readAt: item.read_at || item.ReadAt || item.readAt || '',
              expiresAt: item.expires_at || item.ExpiresAt || item.expiresAt || '',
              time: this.formatChatTime(
                item.created_at || item.CreatedAt || item.createdAt,
              ),
              };
            }),
          );
        }
        this.scrollChatHistoryToBottom(true);
        await this.loadUnread();
      },
    async loadConversationSummaries() {
      // Load conversation previews for the current user.
      // 加载当前用户的会话预览列表。
      if (!this.token) {
        this.chatSummaries = [];
        return;
      }
      const res = await fetch(`${this.messageApiBase}/conversations`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      if (!res.ok) {
        return;
      }
      const data = await res.json();
      this.chatSummaries = Array.isArray(data.items)
        ? data.items.map((item) => ({
            peerId: item.peer_id || item.peerId || '',
            lastMessage: item.last_message || item.lastMessage || '',
            lastMessageType: item.last_message_type || item.lastMessageType || 'text',
            lastMessagePreview:
              item.last_message_preview || item.lastMessagePreview || item.last_message || item.lastMessage || '',
            lastAt: item.last_at || item.lastAt || '',
            unreadCount: Number(item.unread_count || item.unreadCount || 0),
          }))
        : [];
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
      await this.loadConversationSummaries();
    },
    async refreshActiveConversation() {
      // Refresh the open conversation after send/receive events.
      // 在发送或接收后刷新当前打开的会话。
      if (this.activeChat) {
        await this.loadConversation(this.activeChat.id);
        return;
      }
      await this.loadUnread();
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
      await this.refreshActiveProfile();
    },
    async startChat(friend) {
      // Switch to chat view and set active friend.
      // 切换到聊天视图并设置好友。
      if (friend.status !== 'accepted') {
        return;
      }
      this.view = 'chat';
      this.activeChat = friend;
      this.closeChatQuickPanel();
      this.closeChatFriendProfile();
      this.chatAttachment = null;
      this.chatMessages = [];
      this.chatHistoryAtBottom = true;
      await this.loadConversation(friend.id);
    },
    async pickChatAttachment(messageType) {
      // Pick, compress, and stage a chat attachment for the active conversation.
      // 为当前会话选择、压缩并挂载聊天附件。
      if (!this.activeChat) {
        this.setError('请先选择聊天对象');
        return;
      }
      const normalizedType = String(messageType || '').toLowerCase().trim();
      const input = document.createElement('input');
      input.type = 'file';
      input.accept =
        normalizedType === 'image'
          ? 'image/*'
          : normalizedType === 'video'
          ? 'video/*'
          : normalizedType === 'audio'
          ? 'audio/*'
          : '*/*';
      input.multiple = false;
      input.style.display = 'none';

      const selected = await new Promise((resolve) => {
        const cleanup = () => {
          input.removeEventListener('change', onChange);
          window.removeEventListener('focus', onFocus);
          if (input.parentNode) {
            input.parentNode.removeChild(input);
          }
        };
        const onChange = async () => {
          cleanup();
          const file = input.files && input.files[0] ? input.files[0] : null;
          if (!file) {
            resolve(null);
            return;
          }
          try {
            const rawBytes = new Uint8Array(await file.arrayBuffer());
            const mime = this.inferAttachmentMime(
              normalizedType,
              file.name,
              file.type || '',
            );
            const attachmentType = this.normalizeAttachmentType(
              normalizedType,
              mime,
              file.name,
            );
            const compressedBytes = await this.compressAttachmentBytes(rawBytes);
            resolve({
              messageType: attachmentType,
              mediaName: file.name,
              mediaMime: mime,
              mediaData: this.bytesToBase64(compressedBytes),
              originalSizeBytes: rawBytes.length,
            });
          } catch (_error) {
            resolve(null);
          }
        };
        const onFocus = () => {
          window.setTimeout(() => {
            if (!input.files || input.files.length === 0) {
              cleanup();
              resolve(null);
            }
          }, 250);
        };
        input.addEventListener('change', onChange);
        window.addEventListener('focus', onFocus, { once: true });
        document.body.appendChild(input);
        input.click();
      });

      if (!selected) {
        return;
      }
      this.chatAttachment = selected;
      this.view = 'chat';
    },
    clearChatAttachment() {
      // Clear the staged chat attachment.
      // 清空已挂载的聊天附件。
      this.chatAttachment = null;
    },
    openChatAttachment(message) {
      // Open a decoded chat attachment in a new tab.
      // 在新标签页打开已解码的聊天附件。
      if (!message || !message.mediaUrl) {
        return;
      }
      window.open(message.mediaUrl, '_blank');
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
        const payload = JSON.parse(event.data);
        const relatesToActiveChat =
          this.activeChat &&
          (payload.from === this.activeChat.id || payload.to === this.activeChat.id);
        if (relatesToActiveChat) {
          this.refreshActiveConversation();
          return;
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
      this.authMode = 'login';
      this.setFlash(this.t('auth.logoutSuccess'));
    },
    async sendMessage() {
      // Send message to active friend.
      // 发送消息给当前好友。
      this.clearFeedback();
      if (!this.activeChat) {
        return;
      }
      this.closeChatQuickPanel();
      const content = this.chatInput.trim();
      const attachment = this.chatAttachment;
      if (!content && !attachment) {
        return;
      }
      const message = {
        peer_id: this.activeChat.id,
        content,
        message_type: attachment?.messageType || 'text',
        media_name: attachment?.mediaName || '',
        media_mime: attachment?.mediaMime || '',
        media_data: attachment?.mediaData || '',
        expires_in_minutes: attachment ? 7 * 24 * 60 : 0,
      };
      const res = await fetch(`${this.messageApiBase}/messages`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      });
      if (!res.ok) {
        this.setError(this.t('chat.sendError'));
        return;
      }
      this.chatInput = '';
      this.chatAttachment = null;
      await this.refreshActiveConversation();
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

    // Restore theme from local storage.
    // 从本地存储恢复皮肤主题。
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme && this.themeOptions.find((option) => option.value === savedTheme)) {
      this.theme = savedTheme;
    }
    this.applyTheme();
    this.activePrivateSpaceId = localStorage.getItem(ACTIVE_PRIVATE_SPACE_KEY) || '';
    this.activePublicSpaceId = localStorage.getItem(ACTIVE_PUBLIC_SPACE_KEY) || '';

    // Load token from storage.
    // 从本地存储读取 token。
    const stored = localStorage.getItem('token');
    if (stored) {
      this.token = stored;
      this.view = 'dashboard';
      this.loadMe().then(async () => {
        if (!this.token) {
          return;
        }
        await this.loadSpaces();
        await this.loadSubscription();
        await this.loadExternalAccounts();
        await this.loadPosts();
        await this.loadPrivatePosts();
        await this.loadFriends();
        await this.loadConversationSummaries();
        if (this.activeChat) {
          await this.loadConversation(this.activeChat.id);
        } else {
          await this.loadUnread();
        }
        const routedToProfile = await this.applyHostRouteFromHost();
        if (!routedToProfile) {
          this.view = 'dashboard';
        }
      });
    }
    document.addEventListener('click', this.handleDocumentClick);
  },
  beforeUnmount() {
    document.removeEventListener('click', this.handleDocumentClick);
    this.revokeChatMediaUrls();
  },
});

app.component('settings-menu', window.SettingsMenu);
app.component('auth-panel', window.AuthPanel);
app.component('landing-page', window.LandingPage);
app.component('bilingual-field', window.BilingualField);
app.component('bilingual-select-field', window.BilingualSelectField);
app.component('bilingual-action-button', window.BilingualActionButton);

app.mount('#app');
