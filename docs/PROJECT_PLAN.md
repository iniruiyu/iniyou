# 项目规划

## 1. 项目目标

搭建一个可持续迭代的新项目基础框架，优先明确跨端能力、前端设计产出方式以及后端接口规范，确保后续开发能围绕统一文档推进。

当前业务方向以用户体系和社交能力为核心，并预留区块链账号接入扩展能力。

整体架构要求前后端分离，并保持服务边界、模块边界和职责划分清晰。

## 2. 规划原则

- 先规划清楚，再进入开发
- 先完成核心业务主链路，再进入扩展能力
- 先确定模块边界，再落代码实现
- 所有规划变更都必须记录到文档

## 3. 端能力范围

### 3.1 支持平台

- 网页端
- Windows 桌面端
- 移动端

### 3.2 设计原则

- 核心功能一致：不同端共享主要业务流程与信息结构
- 体验适配差异化：根据端特性调整导航、布局与交互密度
- 组件复用优先：尽量抽象统一设计语言与前端组件规范

## 4. 前端规划

### 4.0 技术选型

- 前端技术基础：Flutter、HTML5、CSS3、JavaScript
- 允许使用框架：Vue 3
- 优先原则：优先采用平台原生能力与少依赖方案

### 4.1 交付目标

- 先完成信息架构与页面结构定义
- 输出前端设计图，统一存放在 `docs/design/`
- 在设计确认后再进入前端工程搭建
- 建立多语言界面基线，覆盖首批内建语言与后续扩展机制
- 建立账号身份卡与空间单入口基线，账号服务与空间服务按职责拆分
- 建立个人主页单入口，账号主页与用户主页合并为一个 personal home，避免双前端重复展示同类内容

### 4.2 前端职责范围

- 承担页面展示与用户交互
- 承担表单校验和基础状态管理
- 通过 API 与后端通信
- Flutter 前端与 Legacy Web 前端共用同一套后端接口，接口变更必须同时兼容双端
- 不承载后端业务规则

### 4.3 页面设计要求

- 网页端适配大屏与常规笔记本屏幕
- Windows 端遵循桌面场景布局，强调效率与多区域信息展示
- 移动端优先保证单手操作、关键入口可达和内容层级清晰
- 跨端设计需要考虑 Flutter 端与 Web 端在组件抽象上的一致性
- 首批界面语言需内建支持 English、简体中文、繁體中文
- 语言切换需覆盖导航、按钮、状态提示、页面标题、表单占位文本和主要交互反馈
- 前端需支持基于语言元数据切换 `lang` 与 `dir`
- 需预留 RTL 布局能力，后续接入 RTL 语言时再启用
- 后续新增语言应通过增量配置扩展，而不是重写页面逻辑

### 4.4 首批设计产物

- 个人主页
- 列表页
- 详情页
- 表单页
- 身份卡编辑页
- 空间进入与空间上下文页
- 空间创建与发布弹窗
- 全局导航与响应式布局规则

## 5. 后端规划

### 5.0 技术选型

- 语言：Golang
- Web 框架：Gin
- ORM：Gorm
- 数据库：MySQL、PostgreSQL
- 约束：尽量不增加非必要第三方库
- 约束：尽量避免 CGO，优先纯 Go 实现方案

### 5.1 后端职责范围

- 提供 RESTful API
- 承担业务规则、权限校验和数据访问
- 提供统一错误处理和响应结构
- 保持领域边界和模块边界清晰

### 5.2 接口规范

- 使用 RESTful API 风格
- 资源命名采用复数名词
- 使用标准 HTTP 方法表达操作语义
- 使用统一状态码与错误返回结构
- 接口版本化，例如 `/api/v1/...`

### 5.3 基础约定

- `GET /resources`: 查询资源列表
- `GET /resources/{id}`: 查询资源详情
- `POST /resources`: 创建资源
- `PUT /resources/{id}`: 全量更新资源
- `PATCH /resources/{id}`: 部分更新资源
- `DELETE /resources/{id}`: 删除资源

### 5.4 非功能要求

- 预留鉴权机制
- 预留分页、排序、筛选能力
- 统一日志、监控和错误追踪方案
- 数据访问层需兼容 MySQL 与 PostgreSQL 的基本差异
- 模块边界清晰，便于后续扩展账号体系、社交能力和区块链接入能力
- 前后端分离，前端通过标准 API 与后端通信
- 后端构建与部署尽量基于纯 Go 依赖，降低跨平台编译复杂度

## 6. 功能阶段规划

### 6.1 第一阶段：核心主链路

- 用户注册与登录
- 用户基础资料
- 用户身份卡、域名登录与资料可见范围
- 空间创建、进入与空间内内容发布
- 文章发布与浏览
- 点赞、评论、转发
- 基础聊天
- 聊天媒体附件、未读角标与好友提醒
- 聊天全屏布局、历史滚动、回到底部按钮与表情/贴纸快捷插入

### 6.2 第二阶段：资产与权益

- 钱包
- 会员
- 权益

### 6.3 第三阶段：扩展能力

- 区块链账号接入
- 其他新增业务模块

## 7. 业务模块规划

### 7.1 用户相关

- 账号系统
- 登录
- 注册
- 钱包
- 会员
- 权益

### 7.2 社交相关

- 用户聊天
- 发表文章
- 查看他人内容
- 点赞
- 评论
- 转发
- 空间创建、空间进入与空间内内容浏览，统一使用“空间”作为入口名称

### 7.3 后续扩展

- 支持区块链账号接入
- 支持需求持续扩展与模块增量演进
- 保持用户域、内容域、互动域、资产域之间的边界清晰

## 8. 规则与治理

- 需求变更先更新需求文档
- 接口变更先更新 API 文档
- 数据结构变更先更新数据模型文档
- 设计变更先更新设计文档
- 架构变更先更新架构文档
- 开发任务变更更新开发大纲
- 开发前应先保证四类核心文档口径一致
- 多语言范围、语言代码和文本方向变更时，需同步更新需求与前端设计文档

## 9. 推荐目录规划

```text
new-project/
├── README.md
├── docs/
│   ├── PROJECT_PLAN.md
│   ├── REQUIREMENTS.md
│   ├── API_SPEC.md
│   ├── DATA_MODEL.md
│   ├── ARCHITECTURE_DECISIONS.md
│   ├── design/
│   │   └── FRONTEND_DESIGN.md
│   └── development-outline/
├── frontend/
├── backend/
│   ├── cmd/
│   ├── internal/
│   └── pkg/
└── shared/
```

## 10. 阶段拆分

### 阶段一：规划

- 明确目标、端范围、设计方式、接口规范
- 完成基础文档
- 固化首版技术选型与依赖控制原则
- 建立可持续更新的需求文档
- 梳理核心功能边界与优先级
- 梳理 API 清单与数据实体关系

### 阶段二：设计

- 完成低保真设计图
- 确认组件风格、导航结构、响应式规则
- 完成页面与功能映射关系
- 完成跨端设计策略
- 完成多语言切换方案与可选 RTL 布局设计约束

### 阶段三：开发初始化

- 初始化前端工程
- 初始化后端工程
- 建立基础 CI、代码规范与分支规范
- 建立双语注释规范，确保关键代码可维护
- 建立可扩展的 i18n 结构与内建语言配置

## 11. 开发执行方式

- 当前项目执行任务统一记录在 `docs/development-outline/`
- 开发任务按序号推进，前置任务完成后再进入后续任务
- 若需求扩展导致任务变化，需要同步调整开发大纲文件
- 默认以“完成开发大纲目录内全部任务”为项目完成标准
- 在开发开始前，应先确认需求、接口、数据、设计、架构、任务六类文档已经整理完成

## 12. 当前状态

当前仓库已完成初始化，并已确定首版技术栈与首批功能方向。后续如果需求、架构、设计或第三方依赖发生变动，必须同步更新对应文档。

进度记录 / Progress log:

- 2026-03-20：继续对齐 Flutter 个人主页为 Vue 风格布局，收紧顶部重复英雄卡，并把用户 ID 留在个人资料摘要、将修改入口拆成资料/隐私两处 / Continued aligning the Flutter profile page with the Vue layout by tightening the duplicated top hero card, keeping the user ID in the personal info summary, and splitting the edit entry into personal-info and privacy actions.
- 2026-03-20：继续升级 Flutter 聊天好友资料弹层，改为打开即加载、宽屏双栏、失败可重试的公开空间入口面板 / Continued upgrading the Flutter chat friend-profile dialog into an open-immediately, dual-column, retryable public-space entry panel.
- 2026-03-20：把 Flutter 聊天好友资料弹层改成可滚动的响应式布局，避免小屏下空间卡片和进入按钮被裁切 / Made the Flutter chat friend-profile dialog scrollable and responsive so small screens no longer clip space cards or the enter button.
- 2026-03-20：继续收紧 Flutter 聊天好友资料弹层，改为轻量预览并移除自动拉取公开空间，避免点击资料时触发 Web 端卡死 / Continued tightening the Flutter chat friend-profile dialog into a lightweight preview and removed the automatic public-space fetch to avoid Web freezes when opening the profile.
- 2026-03-20：进一步简化 Flutter 聊天好友资料弹层，去掉公开空间列表和重绘链路，只保留好友资料轻量预览与“查看主页”入口 / Further simplified the Flutter chat friend-profile dialog by removing the public-space list and rebuild chain, leaving only a lightweight profile preview and an "open profile" entry.
- 2026-03-20：修复 Flutter 从好友资料进入公开空间后被自有空间列表覆盖的问题，保留外部进入的当前空间上下文 / Fixed the Flutter friend-profile public-space entry path so external spaces are no longer overwritten by the owned-space list and the current space context is preserved.
- 2026-03-20：在账号服务登录与鉴权链路里接入 active 状态校验，停用账号会在登录和 JWT 中间件阶段被拒绝 / Integrated active-status checks into the account-service login and auth flow so inactive accounts are rejected both at sign-in and in the JWT middleware.
- 2026-03-20：补齐账号密码修改接口，并通过 `password_version` 让旧 token 在改密后自动失效 / Added the account password-change endpoint and used `password_version` to automatically invalidate older tokens after a password change.
- 2026-03-20：对齐数据实体草案与后端当前 GORM 模型，补充 `level`、`subscriptions` 和索引建议 / Aligned the data-model draft with the current GORM models, including `level`, `subscriptions`, and index guidance.
- 2026-03-20：校准开发大纲状态口径，明确下一步优先收口数据模型、账号安全、内容状态和 `make smoke` 留档 / Calibrated the development-outline status wording and clarified the next priorities: data model, account security, content status, and `make smoke` evidence.
- 2026-03-20：重构个人主页顶部用户 ID 信息框，移除顶部单独展示并把用户 ID 下移到个人资料摘要，同时将修改资料/隐私设置拆分为两个按钮 / Reworked the personal-home top user-ID box by removing the separate header card, moving the user ID into the personal info summary, and splitting profile edit/privacy settings into two buttons.
- 2026-03-20：继续修复 Vue 个人主页订阅切换异常，并把 Vue 账号主页/用户主页与 Flutter 工作台摘要统一并入个人主页，确保主导航主页只进入自己的主页 / Continued fixing the Vue personal-home subscription switch error and merged the Vue account home/user profile plus Flutter workspace summary into the personal home, keeping the main-nav home entry pinned to the current user's own profile.
- 2026-03-20：补齐 Vue 会员弹层的本地化解析 helper，修正订阅卡片渲染 key 和价格/权益展示，避免点击订阅后因 localizedLevelText 缺失报错 / Added the Vue membership sheet localization helper, fixed the subscription card render key plus price/feature display, and prevented the subscribe action from failing because localizedLevelText was missing.
- 2026-03-20：完成双前端空间工作台折叠为顶部按钮的方案收口，并把 Vue 空间内容流说明文案精简为纯帖子内容 / Completed the dual-frontend plan to collapse the workspace into a top button and simplified the Vue space feed copy to post content only.
- 2026-03-20：继续收紧空间页，移除内容流 / 当前空间设置说明卡，并把文章图片缩放上限明确为 1600px / Further tightened the space page by removing the feed/current-space-settings info cards and making the article image scaling cap explicit at 1600px.
- 2026-03-20：调整 Vue 空间首页进入逻辑，确保从主页导航进入“空间”时侧边导航保持可见，并移除空状态卡 / Adjusted the Vue space-home entry flow so the sidebar stays visible when entering “Space” from the home navigation and removed the empty-state card.
- 2026-03-20：修复 Vue 主页“空间”按钮的事件误传问题，改为显式打开空间首页 / Fixed the Vue home “Space” button event-passing bug by explicitly opening the space home page.
- 2026-03-20：修复 Vue 进入具体空间后未铺满窗口的问题，改为空间模式全宽主容器 / Fixed the Vue specific-space page not filling the viewport by switching the space shell to a full-width main container.
- 2026-03-20：继续修正 Vue 具体空间页的全屏铺满问题，改为视口级固定主容器并追加样式缓存版本号 / Further corrected the Vue specific-space full-screen layout by using a viewport-fixed main container and adding a stylesheet cache-busting version.
- 2026-03-20：修复从好友资料弹窗进入好友空间时弹窗未关闭的问题，并把弹窗内“进入空间”按钮统一改为好友空间专用进入方法 / Fixed the friend-profile modal staying open when entering a friend space and switched the modal's "enter space" button to the dedicated friend-space entry method.
- 2026-03-20：修复 Vue 好友空间进入后无法向下滚动的问题，将空间内容区改为独立纵向滚动容器，避免固定壳层截断帖子列表 / Fixed the Vue friend-space scrolling issue by turning the space content area into an independent vertical scroll container so the fixed shell no longer clips the post list.
- 2026-03-20：清理 Flutter 个人主页编辑器中的残留旧按钮引用，修正 `_openProfileEditor` 与 `loading` 的未定义问题，并通过 `flutter analyze flutter_frontend` / Cleaned up stale legacy edit-button references in the Flutter profile editor, fixed the undefined `_openProfileEditor` and `loading` symbols, and passed `flutter analyze flutter_frontend`.
- 2026-03-20：补齐 Flutter 聊天好友资料弹窗的同类关闭逻辑，进入好友空间时先用根导航器收起弹窗再切换空间页 / Completed the same close-before-enter flow for the Flutter chat friend-profile dialog by dismissing it with the root navigator before switching to the space page.
- 2026-03-20：完成双前端个人主页摘要化改造，拆分个人资料/隐私设置、会员订阅底部弹层与公开空间入口 / Completed the dual-frontend profile-page summary redesign, splitting personal info/privacy settings, adding the membership subscribe bottom sheet, and showing public space entrances only.
- 2026-03-20：重新收紧 Vue 空间模式壳层为单列布局，并让主内容固定铺满视口，同时通过样式版本号强制刷新缓存 / Re-tightened the Vue space shell to a single-column layout, pinned the main content to the viewport, and bumped the stylesheet version to force a cache refresh.
- 2026-03-20：将 Flutter 好友页的“主页”入口改为弹层预览，并保留弹层内打开完整主页的入口 / Changed the Flutter friends-page “Profile” entry to a modal preview while keeping an in-modal entry to open the full profile page.
- 2026-03-20：修正主导航“主页”入口，仅打开当前登录用户自己的主页，并保留他人主页的独立打开路径 / Fixed the main-nav "Profile" entry so it always opens the current user's own profile while keeping separate entry paths for other users' profiles.
- 2026-03-20：完成 Flutter 文章编辑弹窗化，补齐 `clear_media` 接口与图片等比缩放，并明确 Flutter/Web 共用同一套后端接口 / Completed Flutter post editing modal flow, added `clear_media` support and proportional image scaling, and confirmed Flutter/Web share the same backend API.
- 2026-03-20：补齐 Vue 文章多图片上传、随机文件名、可删除画廊与等比缩放，并让前后端继续共用同一套文章接口 / Added Vue multi-image uploads, randomized file names, removable galleries, and proportional scaling while keeping the shared post API across frontends.
- 2026-03-20：补齐文章媒体真实落盘、按文章目录存储与删除时物理清理，避免空留服务器文件 / Added physical on-disk storage for article media, per-post directories, and deletion cleanup to avoid orphaned server files.
- 2026-03-20：补齐 Flutter/Vue 文章正文 Markdown 渲染与 Flutter 多图编辑/发布画廊，继续统一双前端文章展示与提交口径 / Added Markdown rendering for article bodies in Flutter and Vue plus Flutter multi-image compose/edit galleries, keeping article display and submission consistent across both frontends.
- 2026-03-19：修复 Flutter 发布附件在非 Web 端空实现导致的图片/视频失效，并补齐文章编辑的附件按钮、预览与保存对齐 / Fixed Flutter publish attachments failing on non-web builds due to a stub implementation, and added edit attachment buttons, preview, and aligned save actions.
- 2026-03-17：同步双前端导航与个人主页结构调整 / Synced dual-frontend navigation and profile structure updates.
- 2026-03-17：收敛首批语言范围并保留 RTL 扩展 / Reduced built-in language scope while reserving RTL extension.
- 2026-03-18：补充空间子域名、空间上下文与弹窗式创建路径 / Added space subdomain, active space context, and modal-based creation flow.
- 2026-03-18：补充空间改名、改域名、删除与文章删除能力 / Added space rename, subdomain change, deletion, and post deletion capabilities.
- 2026-03-18：启动聊天媒体附件、过期清理与双端提醒布局优化 / Started chat media attachments, expiry cleanup, and dual-end reminder layout refinement.
- 2026-03-18：完成聊天全屏布局、历史滚动与表情/贴纸快捷入口 / Completed full-screen chat layout, history scrolling, and emoji/sticker quick-entry support.
- 2026-03-18：补充 Vue 聊天页全高壳层，避免长消息列表遮挡发送按钮 / Added a full-height Vue chat shell to keep the send box visible with long histories.
- 2026-03-18：补充 Vue 聊天页回到底部浮动按钮并美化滚动条 / Added a back-to-bottom floating button and polished the chat scrollbar in the Vue view.
- 2026-03-18：补充用户名作为个人主页与二级域名入口的统一句柄 / Added username as the unified handle for profile and subdomain routing.
- 2026-03-18：拆分账号服务与空间服务，并补充域名身份卡与资料可见范围 / Split account and space services, and added domain identity cards with profile visibility scopes.
- 2026-03-18：统一前端空间入口为“空间”，合并私人/公共空间展示 / Unified the frontend space entry as "Space" and merged private/public space presentation.
- 2026-03-18：同步 Flutter 身份卡可见范围为响应式双列布局，避免双语标签挤压 / Synced Flutter identity card visibility controls to a responsive two-column layout and avoided bilingual label crowding.
- 2026-03-18：同步 Flutter 身份卡昵称、用户名、域名为分层双语标签 / Synced Flutter identity card nickname, username, and domain to layered bilingual labels.
- 2026-03-18：抽出 web 与 Flutter 的双语字段组件，统一身份卡字段布局 / Extracted bilingual field components for web and Flutter to unify identity card field layout.
- 2026-03-18：抽出 web 与 Flutter 的双语下拉组件，统一身份卡、空间、发布和设置菜单的选择框 / Extracted bilingual dropdown components for web and Flutter to unify identity card, space, publish, and settings menu select boxes.
- 2026-03-18：抽出 web 与 Flutter 的双语按钮组件，统一登录、设置、社交、弹窗和内容发布按钮 / Extracted bilingual action button components for web and Flutter to unify login, settings, social, modal, and content publishing buttons.
- 2026-03-18：优化 Flutter 聊天表情面板、新消息提醒卡片和主题视觉层次 / Refined the Flutter chat emoji panel, reminder card, and theme depth.
- 2026-03-18：同步 Vue 聊天表情面板关闭交互并收紧折叠菜单按钮贴边 / Synced Vue chat emoji panel close behavior and tightened the collapsed menu button to the edge.
- 2026-03-18：完成聊天表情面板收起、Vue 同步与提醒卡强化，并记录收尾状态 / Finished chat quick panel collapse, Vue sync, and reminder card emphasis, with a final progress note.
- 2026-03-19：统一空间入口为单一“空间”页，并将首页摘要改为仅展示公共可见空间 / Unified the space entry into a single “Space” page and limited home summaries to publicly visible spaces.
- 2026-03-19：补齐空间页当前选中空间同步，并限制空间卡片编辑/删除仅对创建者可见 / Synced the currently selected space in the space page and limited space card edit/delete actions to creators only.
- 2026-03-19：收紧空间列表与个人主页空间可见范围，并补齐空间内容页图文/小视频发布与帖子媒体展示 / Tightened space list and profile space visibility, and added image/short-video publishing plus post media rendering in the space content page.
- 2026-03-19：优化 Vue 空间页为单一内容流，并新增评论楼中楼回复与创建者专属空间操作 / Refined the Vue space page into a single content feed and added threaded comment replies plus creator-only space actions.
- 2026-03-19：收口空间相关文案为当前语言单语显示，并补充聊天好友资料弹窗 / Collapsed space-related labels to the active language only and added a chat friend profile modal.
- 2026-03-19：空间页切换为“进入后才显示帖子”的独立内容页，并新增当前空间导航与设置入口 / Turned the space page into an enter-first content page with current-space navigation and settings entry.
- 2026-03-19：修正 Vue 空间页导航文案键，并让 Flutter 进入空间时立即拉取当前空间帖子 / Fixed the Vue space-page nav labels and made Flutter fetch space posts immediately after entering a space.
- 2026-03-19：恢复 Vue 空间页的创建入口与“我的空间”列表，并让空间帖子流只依赖已进入的当前空间 / Restored the Vue space-page create entry and “My spaces” list, and bound the feed strictly to the entered current space.
- 2026-03-19：修正 Vue 空间页发帖按钮文案引用，统一使用文章发布文案 / Fixed the Vue space-page publish button label to use the post publishing text.
- 2026-03-19：重构空间页为独立壳层，折叠我的空间并将创建入口收口到最后一个选项卡 / Refactored the space page into a dedicated shell, collapsed My Spaces, and moved the create entry into the last tab.
- 2026-03-19：优化 Flutter 空间按钮视觉，并将空间导航动作收回到空间头部信息卡 / Polished Flutter space buttons and moved space navigation actions back into the space header card.
- 2026-03-19：进一步美化 Flutter 统一按钮皮肤，为空间主操作加入更明显的层次和渐变 / Further polished the Flutter unified button skin and added stronger depth and gradients to space primary actions.
- 2026-03-19：将 Flutter 进入空间后的首屏重构为空间横幅 + 内容流/工作台双栏布局 / Reworked the Flutter space entry screen into a space banner with a content-feed/workspace two-column layout.
- 2026-03-19：调整空间入口为保留站点导航的普通空间页，不再切换为隐藏导航的壳层 / Adjusted the space entry to keep the site navigation visible instead of switching to a hidden-nav shell.
- 2026-03-19：收口好友资料、账号主页与聊天页为空间独立页面，仅在好友资料中展示对方公开空间入口 / Separated friend profile, account home, and chat into space-independent pages, while showing a friend's public space entry only inside the friend profile modal.
- 2026-03-19：将进入空间后的页面改为独立内容页并补充显式返回按钮，确保空间页不显示主导航 / Turned the entered-space view into a dedicated content page with an explicit back button, ensuring the space page does not show the main navigation.
- 2026-03-19：收紧空间页为单层头部布局，去掉重复英雄块，并让好友/聊天页顶部不再重复标题与空间域名字段 / Tightened the space page into a single header layout, removed the duplicated hero block, and stopped friend/chat pages from repeating titles and space domain fields.
- 2026-03-19：修正 Vue 空间头部的条件渲染，确保空间工作台导航只在空间页显示 / Fixed Vue space-header conditional rendering so the space workspace navigation appears only on the space page.
- 2026-03-19：移除账号首页的空间摘要卡，并同步收紧 Flutter dashboard 的空间摘要区域 / Removed the space-summary card from the account homepage and tightened the Flutter dashboard space summary area.
- 2026-03-19：重做 Vue 主题设置弹层的分区与控件皮肤，避免浅色主题下出现生硬的原生下拉样式 / Reworked the Vue theme-settings dropdown sections and control skin to avoid harsh native select styling in the light theme.
- 2026-03-19：修正浅色主题下深色侧栏的文字对比度，确保导航与设置入口始终可读 / Fixed the text contrast for the dark sidebar in the light theme so navigation and settings remain readable.
- 2026-03-19：收紧 Vue 空间概览，让页面只保留工作台选项卡和空间卡片，并将进入空间后的内容流独立展示 / Tightened the Vue space overview so it keeps only the workbench tabs and space cards, with the entered-space content flow shown separately.
- 2026-03-19：修复 Flutter 删除空间后当前空间缓存未清空导致的 record not found，并统一订阅、外部账号等按钮的本地状态刷新链路 / Fixed the Flutter stale current-space cache after space deletion causing record-not-found errors, and unified local-state refresh paths for subscription and external-account actions.
- 2026-03-19：删除前端显式订阅页面与订阅状态对象，只保留会员等级展示与升级动作；避免 UI 概念与后端权益接口重复 / Removed the explicit subscription page and subscription state object from the frontend, keeping only membership-level display and upgrade actions to avoid duplicating UI concepts and backend entitlement APIs.
- 2026-03-19：恢复 Vue 空间页默认展开工作台，确保进入空间后直接显示“我的空间”内容而不是空壳层 / Restored the default expanded Vue space workspace so entering space immediately shows “My spaces” content instead of an empty shell.
- 2026-03-19：收紧空间删除后的前端状态清理，避免已删空间继续出现在发帖下拉和空间内容流中，并让空间页仅在有效当前空间存在时展示帖子 / Tightened frontend state cleanup after deleting a space to prevent deleted spaces from lingering in composer pickers and feeds, and only show posts when a valid current space exists.
- 2026-03-19：拆分“空间工作台”和“具体空间内容”入口，确保点击空间只开工作台，点击卡片进入按钮才进入对应空间 / Split the "space workspace" and "specific space content" entries so clicking Space opens only the workspace and card entry buttons open the target space.
- 2026-03-19：统一空间内容媒体为 16:9 等比预览框，并将图片上传尽量转成 WebP；同时把 Vue 文章编辑改为弹窗式编辑 / Unified space content media into 16:9 proportional previews, converted image uploads to WebP where possible, and switched Vue post editing to a modal dialog.
- 2026-03-19：修复 Vue 点击空间时标题解析崩溃，原因是空间文案解析未兼容普通字符串与未映射对象 / Fixed the Vue crash when entering Space because space-label parsing did not handle plain strings or partially mapped objects.
- 2026-03-20：继续拆分 Flutter 个人主页修改资料/隐私设置弹窗，个人资料与隐私设置分别只显示自己的字段，并切换为区块化保存文案 / Continued splitting the Flutter personal-home edit/privacy dialogs so personal info and privacy settings each show only their own fields and use section-specific save labels.
- 2026-03-20：继续收紧 Flutter 个人主页顶部总览，移除会员等级与链上账号重复摘要，仅保留空间与好友快速统计 / Continued tightening the Flutter personal-home top summary by removing duplicated membership and chain snapshots and keeping only the space and friend quick stats.
