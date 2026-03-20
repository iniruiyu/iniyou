# 前端设计图

## 1. 设计目标

为网页端、Windows 桌面端和移动端建立统一的信息架构与交互骨架，先输出低保真设计，后续再补视觉规范与高保真稿。

当前前端选型基线：

- 跨端主方向为 Flutter
- Web 技术基线保留 HTML5、CSS3、JavaScript
- Legacy Web 实现可继续使用 Vue 3 风格拆分
- 仓库内允许 `frontend/` 与 `flutter_frontend/` 并存，二者共享同一套业务信息架构与接口基线
- 两套前端必须共用同一套后端 RESTful API，差异只体现在布局、组件实现和局部交互上

## 2. 设计边界

- 本文件只定义前端页面、交互、布局和跨端体验
- 本文件不承担后端接口实现细节
- 若设计变化影响接口或数据结构，需要同步更新架构文档
- 本文件需要同时约束 Legacy Web 与 Flutter 两套实现，避免页面命名、导航层级和任务路径漂移

## 3. 设计方向

- 统一信息架构，不同端做差异化布局
- 优先保证导航清晰、主任务路径短、核心内容可快速识别
- Flutter 前端作为后续跨端主实现，Legacy Web 作为联调和轻量演示实现保留
- 两套前端优先复用同一套页面层级、状态语义和接口分组，并共用同一套后端 API
- 后续可基于本文件继续补充配色、字体、间距与组件规范
- 页面结构设计需兼顾 Flutter 组件化实现和 Vue 3 页面拆分方式
- 空间入口统一命名为“空间”，私人/公共仅作为空间类型展示与筛选，不再作为一级导航并列入口
- 账号页需要清晰区分昵称、用户名和域名身份卡，并提供个人资料可见范围设置
- 空间与内容创建、编辑、删除都应尽量通过单按钮触发弹窗或确认流程完成
- 文章编辑应使用弹窗式编辑，图片预览需要保持等比缩放并限制最大尺寸，避免大图撑破卡片或弹窗
- 文章编辑与发布弹窗应支持多图片画廊和单项删除，图片选择后先等比缩放再预览，避免旧版单图逻辑继续覆盖新附件
- 空间卡片应提供进入、编辑和删除入口，文章卡片应提供编辑和删除入口
- 空间名称与二级域名需解耦展示，二级域名仅允许英文字母和数字，且最长 63 个字符
- 聊天页应尽量占满主内容区，消息历史区独立滚动，输入区固定在底部
- 常用表情与贴纸应以快捷插入区呈现，减少输入切换成本

## 3.1 双前端协作原则

- `frontend/` 用于快速联调、接口验证、需求试跑
- `flutter_frontend/` 用于沉淀跨端主实现，优先覆盖 Web，再向桌面和移动扩展
- 两套前端共用同一套后端接口，任何字段新增、删除或状态调整都必须同步检查双端兼容性
- 新页面或核心交互变更时，先更新本文件，再决定需要同步到哪一套前端
- 若两套前端暂时存在能力差异，必须在文档中明确“主实现”和“降级实现”
- 不允许出现仅在某一前端中存在、但未在本文件登记的信息架构分叉

## 4. 需求驱动的设计输入

当前前端设计需要覆盖以下核心功能域：

- 用户体系：账号、登录、注册、钱包、会员、权益
- 社交体系：聊天、文章发布、内容浏览、点赞、评论、转发
- 扩展预留：区块链账号接入入口与相关账户绑定流程
- 多语言体系：English、简体中文、繁體中文，以及后续语言扩展能力

## 4.1 多语言与排版方向

- 前端界面需要提供显式语言切换入口
- 首批内建语言：
  - `en-US`
  - `zh-CN`
  - `zh-TW`
- 语言切换后，以下内容必须同步更新：
  - 页面标题
  - 导航名称
  - 表单标签与占位文本
  - 按钮文案
  - 状态与反馈提示
  - 空状态与错误提示
- 语言元数据至少包含：
  - `code`
  - `name`
  - `dir`
- 页面布局、文本对齐和操作区顺序应支持根据 `dir` 自动调整
- 当前默认 LTR，预留 RTL 扩展能力供后续语言接入
- 后续新增语言时，应尽量通过补充翻译字典与语言元数据完成

## 5. 页面结构总览

### 5.1 一级页面

- 认证页
- 个人主页 / Personal Home
- 内容流 / 发布页
- 个人资料页
- 好友页
- 聊天页
- 订阅页
- 外部账号页
- 设置页（保留扩展位）

### 5.2 关键页面关系

- 未登录用户先进入登录或注册流程
- 登录后进入个人主页 / Login should open the personal home.
- 个人主页可进入内容流、聊天、个人资料 / The personal home should link to the content feed, chat, and profile settings.
- 个人资料页可进入订阅、外部账号、设置
- 内容流可进入文章详情、用户主页、互动操作
- 好友页可发起好友申请，并进入聊天页
- 聊天页由“会话列表 + 会话窗口”构成

## 6. 页面骨架

### 6.1 网页端 / Windows 桌面端

```text
+---------------------------------------------------------------+
| Logo | Search | Primary Nav                | User / Setting   |
+-------------------+-------------------------------------------+
| Sidebar           | Page Header                              |
| - Personal Home   +-------------------------------------------+
| - List            | Stats Card | Stats Card | Stats Card     |
| - Detail          +-------------------------------------------+
| - Settings        | Main Content Area                        |
|                   | - Table / Card List                      |
|                   | - Filters                                |
|                   | - Quick Actions                          |
+-------------------+-------------------------------------------+
```

说明：

- Legacy Web 与 Flutter Web 都应优先采用左侧导航 + 主内容区
- Windows 端可以延续相同结构，增强多栏信息显示与快捷操作区
- 如 Windows 端采用 Flutter 桌面实现，应优先复用 Flutter Web 的页面与状态模型
- 导航允许在左侧与顶部之间切换，折叠状态仅保留图标入口

### 6.2 移动端

```text
+-----------------------+
| Header / Search       |
+-----------------------+
| Quick Summary Card    |
+-----------------------+
| Primary Actions       |
+-----------------------+
| Content List          |
| - Item                |
| - Item                |
| - Item                |
+-----------------------+
| Bottom Navigation     |
+-----------------------+
```

说明：

- 采用顶部标题 + 底部主导航
- 强化首屏摘要与关键操作入口
- 列表与详情采用纵向流式布局
- 如移动端采用 Flutter，实现时应优先保证组件状态与页面路由结构清晰
- Legacy Web 不要求覆盖移动端原生能力，但信息架构应保持可映射

## 7. 功能与页面映射

### 7.1 用户功能

- 登录：登录页
- 注册：注册页
- 用户资料：用户中心
- 会员：订阅页
- 权益：订阅页 / 用户中心摘要

### 7.2 社交功能

- 发布文章：文章发布页
- 浏览文章：文章列表页、文章详情页
- 查看他人：个人主页
- 点赞评论转发：文章详情页、互动组件
- 聊天：聊天列表页、聊天会话页
- 空间：统一空间页、空间创建弹窗、空间内文章流，私人/公共作为页面内分区呈现

### 7.3 扩展功能

- 区块链账号接入：用户中心或设置页中的扩展入口

## 7.4 当前实现映射

- `frontend/` 当前覆盖：认证、内容流、好友、聊天、订阅、外部账号、多语言能力、空间进入与空间创建弹窗、个人主页单入口与公开空间入口
- `flutter_frontend/` 当前覆盖：未登录落地页、个人主页、统一空间页、文章详情、好友、聊天、等级、订阅、外部账号、身份卡编辑、空间上下文与弹窗创建入口，工作台摘要已并入个人主页顶部
- 若某页面只在 Legacy Web 存在而 Flutter 尚未补齐，必须保证导航层级不变，并在页面内提示能力差异
- 当前聊天页的优化目标包含：媒体附件发送、未读角标、新好友浮动提醒、全屏占满布局、消息滚动与表情/贴纸快捷入口

## 7.5 Flutter 当前结构约束

- Flutter 前端当前已拆分为以下层级：
  - `api/`: REST 与 WebSocket 相关访问逻辑
  - `controllers/`: 多接口编排、结果装配、会话动作与状态同步辅助（含 `app_actions.dart`、`session_actions.dart`、`post_state_actions.dart`）
  - `models/`: 页面共享数据模型与格式化辅助
  - `widgets/`: 可跨页面复用的基础组件
  - `views/`: 页面壳层与页面区块
- `main.dart` 负责应用入口、全局状态、页面分发与 `setState` 收口，不再承载大段静态 UI 模板或集中式多接口编排
- 未登录态、个人主页区块、社交区块、设置区块和已登录主壳层应继续保持独立文件，避免再次回退到单文件堆叠
- 已登录页面的大段参数拼装优先放入 `views/view_factories.dart`，避免 `main.dart` 再次膨胀为模板拼装层
- 新增 Flutter 页面时，优先落到 `views/`，只有跨页面复用价值明确时才放入 `widgets/`
- 当前 `controllers/` 已用于承接首页刷新、资料加载、详情加载、发帖、空间创建、好友/聊天刷新、订阅激活和外部账号刷新动作；后续如继续抽状态层，可新增 `state/`，但不得破坏当前页面命名和信息架构

## 8. 核心页面建议

### 8.1 个人主页

- 展示个人摘要、会员状态与公开空间入口 / Show personal summary, membership status, and public space entrances.
- 展示最近活动 / Show recent activity.
- 提供订阅、资料编辑与设置快捷入口 / Provide quick actions for subscription, profile editing, and settings.

### 8.2 列表页

- 支持筛选、搜索、排序
- 支持表格视图与卡片视图切换

### 8.3 详情页

- 基本信息区
- 关联信息区
- 操作区

### 8.4 表单页

- 分组展示字段
- 明确必填项、校验状态与提交反馈

### 8.5 用户中心相关页面

- 登录页
- 注册页
- 账户中心
- 钱包页
- 会员与权益页

### 8.6 社交相关页面

- 聊天会话页
- 文章发布页
- 文章详情页
- 评论互动区
- 个人主页
- 文章发布与编辑弹窗中的媒体区应支持多图画廊、单项删除和随机命名后的稳定预览
- 聊天会话页需提供附件工具条、消息媒体预览、未读提示和新好友提醒入口
- 聊天会话页需尽量占满主内容区，消息记录独立滚动，输入区与快捷表情/贴纸区保持在视线范围内
- 聊天会话页在长历史场景下应提供回到底部浮动按钮，并将右侧滚动条做得更轻量、更清晰

### 8.7 个人主页页面约束

- 个人主页需要展示：
  - 作者名称 / Author name
  - 域名身份摘要 / Domain identity summary
  - 个人资料摘要 / Personal info summary
  - 隐私设置摘要 / Privacy settings summary
  - 当前会员等级 / Current membership level
  - 公开空间入口 / Public space entrances
- 个人主页顶部应将原工作台的空间、好友、会员和外部账号统计折叠为一个汇总摘要区 / The top of the personal home should fold the old workspace's space, friend, membership, and external-account stats into a single summary block.
- 个人资料摘要中应展示用户 ID，修改资料与隐私设置分别通过各自按钮触发 / The personal info summary should show the user ID, and edit/privacy actions should be split into their own buttons.
- 个人主页默认不展示内容流，只展示公开空间入口与必要摘要信息 / Profile pages should not show a content feed by default; they should only show public space entrances and required summary info.
- 个人主页中的关系动作需要根据当前关系状态切换：
  - 未建立关系：显示“添加好友”
  - 收到待处理请求：显示“接受好友”
  - 已是好友：显示“发起聊天”
- 用户应可从公共内容流直接进入作者主页
- 用户应可从作者主页返回公共内容流
- 主导航中的“主页”入口必须固定打开自己的主页；查看他人主页应使用独立入口或好友弹层 / The main-nav "Profile" entry must always open the current user's own profile; viewing others' profiles should use a separate entry or friend modal.
- 好友主页入口应以弹层优先，完整主页入口放在弹层内 / Friend profile entry points should prefer a modal, with the full profile entry placed inside that modal.
- 个人资料编辑应通过按钮打开弹窗完成，个人资料摘要应显示用户 ID，页面顶部不再保留单独的用户 ID 卡片 / Profile editing should happen in a button-opened modal, the personal info summary should show the user ID, and the page should no longer keep a separate user-ID card at the top.
- 会员等级在个人主页只保留当前等级和订阅按钮，点击后在底部抽屉显示等级卡片 / Profile membership should keep only the current level and a subscribe button, with level cards shown in a bottom sheet.
- 个人资料页应允许编辑用户名、域名和可见范围，用户名同时作为登录别名与个人主页 / 二级域名入口句柄 / The profile page should allow editing the username, domain, and visibility scopes; the username also acts as the login alias and the profile/subdomain handle.

### 8.8 空间相关页面约束

- 空间必须展示名称、类型和二级域名，进入后页面头部与内容区都要明确当前空间
- 空间必须以单一“空间”入口进入，进入后在页面内再区分私人/公共分区
- 公共空间和私人空间的创建入口必须以单一按钮触发，再在弹窗或底部抽屉内完成表单填写
- 内容发布入口必须依附当前空间上下文，页面内应可见文章所属空间信息
- 双前端在进入具体空间后，应将“我的空间 / 创建空间”工作台折叠为顶部按钮弹层；Flutter 入口命名为“空间工作台”，Vue 空间内容流仅保留帖子内容 / After entering a specific space, both frontends should collapse the “My spaces / Create space” workspace into a top-button popover; the Flutter entry is named “Space workspace”, and the Vue space feed should keep only post content.
- 空间页应只保留帖子列表、发布按钮和工作台入口，不再展示内容流 / 当前空间设置说明卡；图片上传与编辑提示应明确最长边 1600px 的缩放上限 / The space page should keep only the post list, publish button, and workspace entry, without content-feed/current-space-settings info cards; image upload and editing guidance should state the 1600px long-edge cap.
- 从主页导航进入“空间”时，侧边导航应保持可见，空间首页直接展示空间列表；只有进入具体空间时才切换到折叠弹层 / When entering “Space” from the home navigation, the sidebar should remain visible and the space home should show the list directly; only a specific space should switch to the collapsed popover.
- 主页“空间”入口必须显式调用空参方法，避免 Vue 事件对象被误判为具体空间 / The home “Space” entry must explicitly call the no-arg handler to avoid Vue event objects being mistaken for a specific space.
- 空间子域名输入应显式提示仅支持英文字母和数字，且最长 63 个字符 / The space subdomain input should explicitly indicate that only letters and digits are allowed, up to 63 characters.
- 桌面端优先使用居中的弹窗，移动端优先使用底部抽屉，以保证空间和内容创建路径短而清晰

## 9. 交互规则

- 登录注册流程要尽量短
- 核心发布入口需要清晰可见
- 点赞评论转发操作要低学习成本
- 聊天入口在移动端和桌面端都要快速可达
- 聊天页在桌面端采用“会话列表 + 消息窗口”双栏布局，在移动端收敛为单栏堆叠布局
- 新好友提醒以浮动提醒条或卡片角标表达，新消息提示以会话角标或导航徽标表达
- 媒体消息编辑区需在文本输入附近提供图片、视频、语音入口，并展示压缩后预览
- 订阅、外部账号入口应统一放在用户中心体系下
- 语言切换入口在桌面端与网页端应保持稳定可见
- 切换语言后不应打断当前页面上下文
- 进入空间内容前应先选择或识别当前空间上下文，避免跨空间内容混看
- 若后续接入 RTL 语言，导航、按钮组和卡片信息排列需保持可读性与操作一致性
- 双前端的文案和页面命名允许样式差异，但不允许主任务路径差异

## 10. 响应式规则

- 大屏：多栏布局，信息密度更高
- 中屏：保留侧边导航，压缩卡片列数
- 小屏：切换为单列布局，侧边导航转为底部导航或抽屉菜单
- 社交互动入口在移动端应保持高可达性，聊天与发布入口不应过深
- 若后续接入 RTL 语言，响应式规则仍需成立，不能因方向切换破坏主操作路径

## 11. 设计规则

- 页面命名要与需求模块一致
- 设计稿命名要与开发页面名尽量一致
- 跨端页面保持信息结构一致
- 平台差异优先体现在布局和交互密度，而不是业务流程差异

## 12. 后续补充项

- 品牌色与视觉风格
- 设计 Token
- 组件清单
- 页面流程图
- 高保真设计稿链接
- 聊天与社交互动页面细化稿
- 区块链账号接入相关交互稿
- 多语言组件规范与 RTL 适配稿

## 13. 进度记录

- 2026-03-20：重构个人主页顶部用户 ID 信息框，移除顶部独立卡片并将用户 ID 下移到个人资料摘要，同时拆分修改资料/隐私设置按钮 / Reworked the personal-home top user-ID box, removed the separate header card, moved the user ID into the personal info summary, and split the edit/privacy buttons.
- 2026-03-20：完成双前端空间工作台折叠为顶部按钮，并收紧 Vue 空间内容流说明文案 / Completed the dual-frontend workspace collapse into a top button and tightened the Vue space-feed copy.
- 2026-03-20：继续修复 Vue 个人主页订阅切换异常，并把 Vue 账号主页/用户主页与 Flutter 工作台摘要统一并入个人主页，确保主导航主页只进入自己的主页 / Continued fixing the Vue personal-home subscription switch error and merged the Vue account home/user profile plus Flutter workspace summary into the personal home, keeping the main-nav home entry pinned to the current user's own profile.
- 2026-03-20：继续收紧空间页文案，移除内容流与当前空间设置说明，并在文章图片缩放提示中明确 1600px 上限 / Further tightened the space-page copy, removing feed/current-space-settings text and making the 1600px image cap explicit in article scaling hints.
- 2026-03-20：调整 Vue 空间首页从导航进入时的展示逻辑，并去掉空状态卡 / Adjusted the Vue space-home navigation entry behavior and removed the empty-state card.
- 2026-03-20：修复 Vue 主页“空间”入口的事件误传，并保持首页空间列表可见 / Fixed the Vue home “Space” entry event-passing issue and kept the space list visible on the home page.
- 2026-03-20：统一 Flutter/Web 后端接口口径，并补齐文章编辑弹窗与图片等比缩放设计约束 / Aligned Flutter/Web backend API contracts and added modal post editing plus proportional image scaling constraints.
- 2026-03-20：完成双前端个人主页摘要页改造，切分个人资料/隐私设置、会员等级底部抽屉与公开空间入口 / Completed the dual-frontend profile summary-page redesign, splitting personal info/privacy settings, adding the membership bottom sheet, and showing public space entrances only.
- 2026-03-17：完成双前端导航结构与个人主页标签调整 / Completed dual-frontend navigation structure and profile tab alignment.
- 2026-03-17：收敛首批内建语言为中英双语与繁体中文 / Reduced built-in languages to English, Simplified Chinese, and Traditional Chinese.
- 2026-03-18：收口 Vue 顶部切换并改为整栏折叠 / Removed Vue top switch and switched to full sidebar collapse.
- 2026-03-18：将设置入口移动到退出登录左侧 / Moved settings entry to the left of logout.
- 2026-03-18：恢复 Vue 折叠为真实隐藏侧栏并保持主区原排版 / Restored real sidebar hiding while keeping the main layout intact.
- 2026-03-18：改为常驻浮动按钮控制侧栏折叠 / Switched to a persistent floating button to control sidebar collapse.
- 2026-03-18：拆分展开/收起入口，展开态仅保留导航内隐藏按钮 / Separated expand/collapse entries so expanded state keeps only the in-nav hide button.
- 2026-03-18：补充空间二级域名、空间上下文与弹窗创建的前端设计约束 / Added frontend design constraints for space subdomains, active space context, and modal creation flows.
- 2026-03-18：启动聊天媒体附件、未读角标和新好友提醒的双端布局优化 / Started dual-end chat layout refinement for media attachments, unread badges, and friend reminders.
- 2026-03-18：补充 Vue 聊天页回到底部浮动按钮与右侧滚动条样式优化 / Added a back-to-bottom floating button and refined right-side scrollbar styling for the Vue chat view.

## 14. 维护约定

- 本文件用于持续记录前端设计变动
- 若设计调整影响跨端结构、组件边界或技术实现，需要同步更新 `docs/PROJECT_PLAN.md` 与 `docs/ARCHITECTURE_DECISIONS.md`
- 若设计调整由需求变更触发，需要同步更新 `docs/REQUIREMENTS.md`
- 若页面结构与功能映射发生变动，需要先更新本文件再进入开发
- 若只修改其中一套前端实现，也要先确认是否影响共享信息架构；若影响，必须先改本文件
