# 07 社交内容与互动体系

## 1. 目标

完成文章发布、浏览和互动能力，建立社交内容核心闭环。

## 2. 状态

- 状态：进行中
- 已完成：
  - 文章发布
  - 公共文章列表
  - 文章详情接口
  - 点赞功能
  - 评论功能
  - 转发功能
  - 基础 RESTful API
  - 前端公共内容流与互动组件
  - 个人主页内容展示
  - 空间创建、进入、改名、改域名与删除
  - 空间二级域名展示与当前上下文记录
  - 空间入口统一为“空间”，私人/公共作为页面内分区展示
  - 内容删除
  - 文章编辑弹窗化，支持媒体清除与图片等比缩放
  - Vue 文章发布与编辑支持多图片上传、可删除画廊和随机文件名
  - 文章媒体真实落盘到可配置目录，并在删除文章、删除空间或替换媒体时物理清理服务器文件
  - Flutter 文章发布与编辑支持多图画廊，双前端文章正文统一按 Markdown 渲染
  - 已修复文章创建时主键误用 `post-...` 非 UUID 字符串导致的 PostgreSQL `uuid` 插入失败 / Fixed post creation using a `post-...` non-UUID string for the primary key, which caused PostgreSQL UUID insert failures.
- 双前端个人主页已合并账号主页与用户主页，Flutter 也已把工作台摘要并入个人主页顶部 / Both frontends now merge the account home and user profile into one personal home, and Flutter folds the workspace summary into the top of the personal home.
- 双前端空间工作台折叠为顶部按钮，进入具体空间后自动收起，Vue 空间内容流移除冗余说明 / Collapsed the dual-frontend space workspace into a top button that auto-collapses after entering a specific space, and removed redundant Vue feed copy
- 双前端空间页移除内容流 / 当前空间设置说明卡，并把文章图片缩放上限明确为 1600px / Removed the space feed/current-space-settings info cards in both frontends and made the 1600px article image scaling cap explicit
- Vue 从主页导航进入“空间”时保持侧边导航可见，空间首页不再展示空状态卡 / Vue now keeps the sidebar visible when entering “Space” from home navigation, and the space home no longer shows the empty-state card
- Vue 主页“空间”按钮改为显式空参调用，避免事件对象误判为具体空间 / Vue home “Space” button now uses an explicit no-arg call to avoid misreading the click event as a space object
- Vue 进入具体空间后改为全宽主容器铺满窗口，避免左侧保留空白列 / Vue specific-space pages now use a full-width main container to avoid leaving a blank left column.
- Vue 具体空间页进一步改为视口级固定主容器，并通过样式版本号避免浏览器继续命中旧布局缓存 / Vue specific-space pages now use a viewport-fixed main container, and the stylesheet version is bumped to avoid stale layout caching.
- Vue 从好友资料弹窗进入好友空间时会先关闭资料层，弹窗内“进入空间”按钮也统一走好友空间专用入口，再切换到空间页 / Vue now closes the friend profile layer before entering a friend's space, and the modal's "enter space" button also uses the dedicated friend-space entry path.
- Flutter 聊天好友资料弹窗进入好友空间时也会先关闭弹窗，并通过根导航器确保空间页切换后不残留资料层 / Flutter now also closes the chat friend-profile dialog before entering a friend space, using the root navigator so no profile layer remains after switching pages.
- 双前端个人主页已收敛为摘要页，只展示个人资料、联系方式、隐私设置、会员等级与公开空间入口，不再展示内容流 / Both frontends' profile pages are now summary pages that only show personal info, contact details, privacy settings, membership level, and public space entrances, without a content feed.
- 双前端好友主页预览已收紧为公开摘要，不再把手机号、邮箱这类私密联系方式直接塞进弹层 / Both frontends' friend profile previews were tightened into public summaries, and private contact details such as phone and email are no longer pushed into the overlay.
- 双前端好友列表、好友搜索结果与会话侧栏的摘要字段也已统一为公开身份信息，不再把联系方式当作卡片主展示内容 / Both frontends' friend lists, friend search results, and chat-side summaries were also unified around public identity fields instead of showing contact details as the main card content.
- Flutter 好友预览弹层与聊天侧栏最近会话/好友列表已统一为卡片化摘要布局，减少不同入口之间的视觉断层 / Flutter friend preview modals and chat sidebar recent-conversation/friend lists were unified into card-based summary layouts to reduce visual drift between entry points.
- 2026-03-27：具体空间页改回保留主导航与折叠顶栏，不再切换成独立紧凑壳层 / Specific space pages now keep the main navigation and collapsed top bar instead of switching into a separate compact shell.
- 2026-03-27：Vue 设置入口并入主菜单，设置面板改为视口级浮层并根据可视空间自动翻转，避免侧栏滚动裁切 / Moved the Vue settings entry into the main menu, and turned the settings panel into a viewport-level floating layer that auto-flips to fit visible space so sidebar scrolling no longer clips it.
- 2026-03-26：将 Flutter 和 Vue 聊天页“最近会话”入口都收纳到右侧菜单，紧凑布局不再让左侧会话列表常驻占位 / Folded both Flutter and Vue chat page "Recent conversations" entries into a right-side menu so compact layouts no longer reserve the left conversation list permanently.
- 2026-03-26：将 Flutter 和 Vue 的账号、会员、语言、设置与退出入口收进主菜单侧栏，并让主导航默认折叠为浮动入口，给聊天区域预留更大横向空间 / Moved the Flutter and Vue account, membership, language, settings, and sign-out actions into the main menu sidebar, and kept the primary navigation collapsed behind a floating trigger to preserve more horizontal space for chat.
- 2026-03-26：把 Vue 设置面板的新增语言收进默认折叠区，并把退出登录并入设置面板；Flutter 仍保留非空间页顶部主导航可见 / Folded Vue's add-language form into a closed-by-default section, moved sign-out into the settings panel, and kept the Flutter top navigation visible outside the space page.
- 2026-03-26：重调 Vue 导航为“折叠时顶层精简导航、展开时浮动左侧抽屉”，并取消主内容对侧栏的空间预留 / Reworked the Vue navigation into a compact top-level nav when collapsed and a floating left drawer when expanded, while removing main-content space reservation for the sidebar.
- 2026-03-26：将 Vue 展开态顶部栏完全隐藏，仅保留折叠态的顶层精简导航，避免顶部再额外占位 / Fully hid the Vue top bar in expanded state and kept only the compact top-level navigation when collapsed so the top area no longer adds extra spacing.
- 2026-03-26：移除 Vue 聊天侧栏底部的连接状态/连接聊天入口，并清理对应的 websocket 死代码，仅保留未读提醒文案 / Removed the Vue chat sidebar footer's connection-status/chat-connect entry and cleaned up the matching websocket dead code, keeping only the unread reminder label.
- 2026-03-26：让 Vue 宽屏展开态主内容右移让位，并在聊天页折叠侧栏时切换为单面板全宽、隐藏最近会话列表，展开时恢复双栏布局 / Shifted the Vue main content right in wide-screen expanded state and switched the chat page to a single full-width panel with the conversation list hidden when the sidebar is collapsed, then restored the two-column layout when expanded.
- 2026-03-26：补强 Vue 折叠态主内容全宽覆盖，强制清掉侧栏右移残留，避免内容区域在折叠后继续缩窄 / Reinforced the Vue collapsed-state full-width content override to clear any leftover sidebar offset and prevent the content area from shrinking after collapse.
- 2026-03-26：为 Vue 主内容壳层和聊天页补上运行时宽度绑定，折叠侧栏时直接将 `main` 与聊天面板切回全宽，避免仅靠 CSS 选择器导致状态失配 / Added runtime width bindings for the Vue main shell and chat page so collapsing the sidebar directly returns `main` and the chat panel to full width instead of relying only on CSS selectors.
- 2026-03-26：继续收紧 Vue 折叠态导航按钮，并给 `main` 与聊天单面板补上直连折叠兜底类，避免展开按钮不够醒目或折叠后仍残留左侧占位 / Further refined the Vue collapsed-state navigation trigger and added direct collapsed fallback classes for `main` and the single-panel chat shell so the expand button reads clearly and no left-side reservation remains after collapse.
- 2026-03-26：修正 Vue 折叠态顶部导航的“空间”入口，只切换到空间首页而不自动展开左侧导航，避免顶部菜单反向改写当前导航状态 / Fixed the Vue collapsed top-nav "Space" entry so it switches to the space home without auto-expanding the left navigation, avoiding the top menu from rewriting the current nav state.
- 2026-03-26：继续统一 Vue 空间流转的导航状态，进入空间首页、进入具体空间和从空间返回工作台都保留当前折叠态；同时把顶部展开按钮收成纯图标胶囊入口 / Further unified Vue space-flow navigation state so entering the workspace, opening a specific space, and returning to the workspace all preserve the current collapsed state, while also tightening the top expand button into an icon-only pill trigger.
- 2026-03-26：继续重做 Flutter 顶部导航与侧栏按钮，改成主题感知的半透明玻璃态组件，并统一折叠按钮、顶部导航与侧栏导航的圆角描边和高亮层次 / Continued redesigning Flutter top-nav and sidebar buttons into theme-aware translucent glass components, unifying the corner radius, border treatment, and highlight layering across the collapsed trigger, top navigation, and sidebar navigation.
- 2026-03-27：把双前端个人主页继续拆成个人资料、联系方式和隐私三块，三个编辑入口不再复用同一个弹窗表单 / Continued splitting both frontends' personal home into separate profile, contact, and privacy blocks so the three edit entries no longer reuse the same dialog form.
- 2026-03-27：个人资料、联系方式和隐私三张卡的操作按钮统一显示为“编辑”，减少标题和按钮文案的重复感 / Unified the action buttons on the personal info, contact, and privacy cards to a single Edit label so the button text no longer repeats the section titles.
- 个人主页的非本人查看态已补齐统一“未公开”占位，避免权限隐藏字段在页面上直接消失 / Non-owner profile views now fill hidden fields with a unified "Not public" placeholder instead of silently omitting them.
- Web 聊天好友资料弹窗的字段行改为单条顺序渲染，隐藏的联系方式只显示一次“未公开”，不再重复插入同一字段 / The Web chat friend profile modal now renders fields once in order, and hidden contact data shows a single "Not public" row instead of duplicate inserts.
- 帖子作者名的后备展示改为只取公开身份信息，避免帖子卡、作者主页入口和评论作者名因为空昵称而泄露邮箱或手机号 / Post author-name fallback now uses only public identity fields, preventing post cards, author-page entry points, and comment author names from leaking email or phone when a nickname is missing.
- 本人视角的个人主页摘要重新展示邮箱、手机号、年龄与性别，和“别人看见未公开”的规则保持分离 / The owner-facing profile summary now shows email, phone, age, and gender again, staying separate from the "Not public" behavior used for other viewers.
- 好友资料弹窗的邮箱与手机号标题改为资料字段标签，修掉了把输入占位键当作展示文案的问题 / The friend profile modal now uses profile field labels for email and phone, fixing the issue where input placeholders were reused as display text.
- 个人资料摘要卡的说明文案也同步扩展为联系方式与基本信息，避免卡片内容和标题语义不一致 / The profile summary card copy was expanded to include contact details and basic info so the card content and title stay aligned.
- 本人资料区在 Web 侧拆成基础资料、联系方式和隐私三张卡，信息密度更均衡 / The Web owner profile area was split into basic info, contact details, and privacy cards to balance the information density.
- 年龄与性别也已经进入个人资料编辑表单，用户可以在自己的主页里直接修改这两项资料 / Age and gender were added to the profile editor form so users can edit those fields directly from their own profile page.
- Vue 进入好友空间或自己创建的空间后，空间壳层会收为单列并固定铺满整个视口，样式地址也会通过版本号刷新以避免浏览器命中旧布局缓存 / After entering a friend's space or one of your own spaces, Vue now collapses the shell into a single column and pins the main content to the full viewport, with a versioned stylesheet URL to avoid stale layout caching.
- Vue 好友空间的帖子列表已改为独立滚动容器，修复进入后无法向下滚动的问题 / Vue friend-space post lists now use an independent scroll container, fixing the issue where the page could not be scrolled downward after entry.
- Vue 空间帖子卡补上图片点击放大查看器，并继续收紧内容卡最大展示尺寸 / Vue space post cards now include a click-to-zoom viewer for images and further cap the content card display size.
- Flutter 个人主页编辑器已清理旧版顶部按钮残留，`flutter analyze flutter_frontend` 重新通过 / Flutter profile editor legacy top-button remnants were removed, and `flutter analyze flutter_frontend` passes again.
- 主导航“主页”入口已固定进入当前登录用户自己的主页，他人主页保留独立打开路径 / The main-nav "Profile" entry now always opens the current user's own profile, while other profiles keep a separate open path.
- Vue 会员等级切换按钮已加固为成功后再关闭切换弹层，避免网络异常时直接中断交互 / The Vue membership switch button is now hardened to close the sheet only after a successful update, avoiding abrupt failures on network errors.
- 进行中：
  - 内容状态与审核预留
- 待完成：
  - 内容审核流与后台处理

## 3.1 下一轮待办拆分

- `07D` 空间体系与空间内内容
  - 当前状态：已完成
  - 创建私人空间与公共空间
  - 生成并展示空间二级域名
  - 在统一空间上下文内发布和浏览内容
  - 文章记录所属空间
  - 修改空间名称与二级域名
  - 删除空间
  - 删除文章
- `07A` 个人主页内容展示
  - 当前状态：已完成
  - 新增按用户查询文章列表接口
  - 提供当前用户内容列表与他人主页内容列表
  - 前端补充个人内容展示区
  - 已实现：从公共内容流进入作者主页并查看其公开文章
  - 已实现：作者主页头部信息、文章数量、好友聊天入口
  - 已实现：作者主页中的加好友、接受好友与状态刷新
- `07B` 文章详情与编辑
  - 当前状态：已完成
  - `07B-1` 文章详情页视图
    - 从内容流进入文章详情
    - 展示文章正文、互动计数、评论列表
    - 支持从详情页执行点赞、评论、转发
    - 当前状态：已完成
  - `07B-2` 文章编辑能力
    - 当前用户可编辑自己的文章
    - 支持更新标题、正文、可见范围与媒体清除
    - 当前状态：已完成（弹窗编辑、clear_media、多图上传、Markdown 正文渲染、图片等比缩放、随机命名、真实落盘与物理删除清理）
  - `07B-3` 可见范围细化
    - 在详情与列表中统一公开/私密文章访问规则
    - 当前状态：已完成
- `07C` 内容状态与审核预留
  - 细化 `draft`、`published`、`hidden` 等状态
  - 为审核字段和后台处理预留结构
  - 当前状态：基础完成，待内容状态与审核预留收口 / Baseline complete, awaiting content-status and moderation reservation closure.
  - 已实现：文章创建与编辑支持 `draft`、`published`、`hidden`
  - 已实现：列表与详情按状态执行基础可见性控制

## 3.2 当前建议优先级

- 优先处理：`07C` 内容状态与审核预留
- 原因：空间主链路已经收口，当前剩余工作更集中在内容状态细化与审核能力预留上

## 3. 任务清单

- 实现文章发布
- 实现文章列表与详情
- 实现个人主页内容展示
- 实现空间创建、进入与空间上下文记录
- 实现空间名称、二级域名和删除能力
- 实现文章删除
- 实现空间入口合并与页面内分区展示
- 实现点赞功能
- 实现评论功能
- 实现转发功能
- 设计内容审核与状态字段预留
- 建立对应 RESTful API
- 建立前端内容流、详情页和互动组件

## 4. 完成标准

- 用户可以发布和浏览文章
- 用户可以进行点赞、评论、转发互动
- 内容模块具备后续扩展能力
