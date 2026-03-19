# 需求文档

## 1. 文档用途

本文件用于记录当前功能需求、业务范围和需求变更。该文档会持续演进，后续新增、删减或调整需求时都要更新本文件。

## 2. 维护规则

- 需求变更首先更新本文件
- 如果需求变化影响项目规划，需要同步更新 `docs/PROJECT_PLAN.md`
- 如果需求变化影响界面和交互，需要同步更新 `docs/design/FRONTEND_DESIGN.md`
- 如果需求变化影响技术选型、模块划分或依赖策略，需要同步更新 `docs/ARCHITECTURE_DECISIONS.md`

## 3. 产品方向

当前项目以用户体系和社交互动为核心，未来支持区块链账号接入，并要求整体架构具备良好的扩展能力，方便后续持续追加业务模块。

## 4. 当前版本范围定义

### 4.1 当前版本目标

- 建立完整的用户体系
- 建立完整的社交基础能力
- 建立可扩展的钱包、会员、权益能力
- 为区块链账号接入预留扩展位

### 4.2 当前版本不强制要求一次完成的内容

- 多链深度集成
- 复杂推荐系统
- 复杂风控系统
- 大规模实时分布式消息能力
- 高级运营后台

说明：

- 当前版本优先把产品主链路跑通
- 超出当前版本范围的能力可以预留接口和数据结构，但不要求首版全部实现

## 5. 当前核心需求

### 5.1 用户相关

- 账号系统
- 登录
- 注册
- 钱包
- 会员
- 权益

说明：

- 用户体系需要作为核心基础能力
- 钱包、会员、权益需要与账号体系关联，但保留独立扩展空间
- 每个用户都可以设置唯一用户名，用户名由英文字母和数字组成，可作为个人主页和登录别名入口 / Each user can set a unique alphanumeric username used for profile and login alias routing.
- 每个用户都可以设置唯一域名，域名由英文字母和数字组成，作为身份卡与登录入口；昵称与域名需要分开维护，手机号、年龄、性别、邮箱等个人信息字段需要支持可见范围控制 / Each user can set a unique alphanumeric domain handle used as the identity card and login entry; nickname must stay separate from the domain, and personal fields such as phone, age, gender, and email need visibility scopes.
- 登录时支持邮箱、手机号、用户名或域名 / Login supports email, phone, username, or domain.

细化功能：

- 用户注册
- 用户登录
- 用户退出登录
- 用户基础资料查看与编辑
- 用户账号状态管理
- 用户钱包信息查看
- 用户会员信息查看
- 用户权益信息查看

### 5.2 社交相关

- 每个账号都可以聊天
- 每个账号都可以发表自己的文章
- 用户之间可以互相查看内容
- 支持点赞
- 支持评论
- 支持转发

说明：

- 社交能力是首批核心业务之一
- 内容、互动和聊天能力后续可能继续拆分细化
- 空间能力属于社交内容的入口层，内容浏览和发布必须先进入对应空间上下文 / Space is the entry layer for social content, and browsing or publishing content must happen inside the current space context.
- 空间能力由独立空间服务提供，账号服务只保留身份与资料相关的核心字段 / Space capabilities are provided by an independent space service, while the account service only keeps identity- and profile-related core fields.
- 创建空间时需要生成稳定的二级域名标识，方便后续通过子域名进入空间 / Creating a space must generate a stable subdomain handle so it can be entered through the subdomain later.
- 文章发布需要记录所属空间，便于页面展示当前上下文 / Post publishing must record the owning space so the page can display the current context.
- 空间名称与二级域名需要独立维护，二级域名前缀只能使用英文字母和数字，且最长 63 个字符 / Space names and subdomains must be maintained independently, and the subdomain prefix may contain letters and numbers only, up to 63 characters.
- 用户名、域名和空间二级域名都应限制为 63 个字符，保证可直接作为 DNS 子域名使用 / Usernames, domains, and space subdomains should all be limited to 63 characters so they can be used directly as DNS subdomains.
- 空间列表只展示当前用户创建的空间，个人主页只展示该用户公开的空间，不再自动生成默认空间 / Space lists only show spaces created by the current user, profiles only show that user's public spaces, and no default space is auto-generated.

细化功能：

- 创建空间并设置可见范围
- 通过二级域名进入空间
- 通过域名进入个人主页 / Enter the author page through the domain handle
- 个人主页仅展示公开空间 / Profile pages only show public spaces
- 修改空间名称
- 修改空间二级域名
- 修改空间可见范围
- 删除空间
- 在当前空间内发布图文和小视频内容
- 在当前空间内查看内容流
- 记录文章所属空间
- 发布文章
- 查看文章列表
- 查看文章详情
- 删除文章
- 查看用户主页
- 点赞文章
- 评论文章
- 转发文章
- 发起聊天会话
- 查看聊天列表
- 查看聊天消息
- 发送聊天消息

### 5.3 空间相关

- 空间创建入口需要在同一表单中同时设置名称、二级域名和可见范围 / The space creation entry should set the name, subdomain, and visibility scope in one form.
- 空间列表需要展示空间名称、可见范围和二级域名 / Space lists should show the space name, visibility scope, and subdomain.
- 空间卡片需要支持进入、改名、改域名、改可见范围和删除，且只有创建者可见编辑与删除入口 / Space cards should support enter, rename, subdomain changes, visibility updates, and deletion, and edit/delete actions should only be visible to the creator.
- 空间页面需要统一使用“空间”作为入口名称，不再拆分私人/公共页面 / The space page should use "Space" as the single entry name and no longer split private/public pages.
- 点击“空间”只应进入工作台页，只有点击空间卡片里的“进入空间”才应进入具体空间内容页 / Clicking "Space" should open the workspace page only, and entering a specific space content page must happen from the card's "Enter space" action.
- 进入空间后，发布和查看内容都应记录在该空间上下文中 / After entering a space, both publishing and browsing content should be recorded in that space context.
- 前端创建空间和发布内容时应使用单一按钮打开弹窗，再在弹窗内完成表单操作
- 空间内容页需要展示当前空间和空间内容流，并支持图文与小视频附件发布 / The space content page should show the current space and the feed, and support image plus short-video attachments.
  - 空间内容页不再重复展示个人空间列表，空间列表入口保留在首页与个人主页 / The space content page should not repeat the owned-space list; the space list entry stays on the home and profile pages.
  - Vue 空间页进入后应默认展开工作台与“我的空间”内容，避免先显示空壳层 / Vue space pages should default to an expanded workspace and “My spaces” content instead of showing an empty shell first.
  - 删除空间后必须立即清理当前空间、空间帖子缓存和发帖下拉选项，空间页在没有有效当前空间时只显示工作台，不再回填已删除空间 / After deleting a space, the current space, space post cache, and composer picker must be cleared immediately, and the space page should show only the workspace when no valid current space remains instead of backfilling the deleted space.
  - 空间内容中的图片和视频需要保持原始比例显示，图片上传应尽量先转换为 WebP 格式再提交 / Space content images and videos should keep their original aspect ratio, and image uploads should be converted to WebP when possible before submission.
  - Vue 文章编辑应使用独立弹窗完成，避免在正文下方内联展开编辑区 / Vue post editing should use a dedicated modal instead of expanding an inline editor below the article.
  - 文章卡片需要支持删除当前用户自己的内容，以及空间创建者删除其空间内内容 / Post cards should support deleting the current user's content, and space creators should be able to delete posts inside their spaces.
- 变更型操作需要先更新本地状态再刷新服务端数据，删除空间或文章后必须立即清理当前空间与相关缓存，会员等级升级和外部账号变更也要同步更新界面；前端不再保留独立订阅页面或订阅状态对象 / Mutation actions must update local state before refreshing server data; deleting spaces or posts must immediately clear the current space and related caches, membership-level upgrades and external-account changes must update the UI at once, and the frontend must no longer keep a separate subscription page or subscription state object.
- 评论需要支持楼中楼回复 / Comments should support threaded replies.

### 5.4 后续扩展

- 支持接入区块链账号
- 允许继续扩展新的业务需求
- 系统设计需要方便扩展，避免当前实现阻塞未来迭代

扩展要求：

- 区块链账号绑定应作为独立扩展模块
- 不应破坏原有账号登录注册主流程
- 应预留多身份、多账号映射能力

### 5.5 多语言界面

- 前端界面必须支持多语言切换
- 当前内建语言必须包含：
  - English
  - 简体中文（`zh-CN`）
  - 繁體中文（`zh-TW`）
- 多语言能力应覆盖导航、表单、状态提示、按钮文案、页面标题和主要交互反馈
- 语言配置必须支持继续扩展，后续新增语言时不应要求重写整套界面逻辑
- 语言元数据应支持至少以下属性：
  - 语言代码
  - 显示名称
  - 文本方向
- 当前默认支持 LTR，预留 RTL（Right-to-Left）排版扩展能力
- 若后续接入阿拉伯语等 RTL 语言，应可通过配置切换排版方向

## 6. 功能模块拆分

### 6.1 账户与身份模块

- 用户注册
- 用户登录
- 用户退出
- 身份校验
- 用户资料管理

### 6.2 资产与权益模块

- 钱包主页
- 钱包账户信息
- 会员等级信息
- 权益列表与说明

### 6.3 内容模块

- 文章发布
- 文章编辑
- 文章列表
- 文章详情
- 用户主页内容展示
- 空间内文章发布
- 空间内文章浏览
- 文章所属空间记录

### 6.4 互动模块

- 点赞
- 评论
- 转发

### 6.5 聊天模块

- 会话列表
- 会话详情
- 消息发送
- 消息读取状态
- 文本、图片、视频、语音消息发送
- 媒体消息发送前压缩，过期后自动删除
- 会话列表未读角标与新好友浮动提醒
- 桌面端与移动端聊天布局自适应优化
- 聊天页面需要全屏占满可用区域，历史消息支持滚动/滑动查看
- 聊天页面需要提供回到底部浮动按钮，并美化右侧滚动条视觉样式
- 聊天输入区需要提供常用表情与贴纸快捷插入

### 6.6 扩展身份模块

- 区块链账号绑定
- 区块链账号解绑
- 外部身份映射

## 7. 需求优先级

### 7.1 P0

- 用户注册
- 用户登录
- 用户资料基础能力
- 空间创建与进入
- 文章发布与浏览
- 点赞评论转发
- 基础聊天
- 聊天媒体附件、未读角标与好友提醒
- 聊天全屏布局、历史滚动与表情/贴纸快捷入口

### 7.2 P1

- 钱包
- 会员
- 权益
- 用户主页完善

### 7.3 P2

- 区块链账号接入
- 更多扩展业务能力
## 8. 需求分层建议

- 账户与身份层：账号、登录、注册
- 用户资产层：钱包、会员、权益
- 内容层：文章发布、文章浏览
- 互动层：点赞、评论、转发
- 实时通信层：聊天
- 外部身份扩展层：区块链账号接入

## 9. 扩展性要求

- 功能模块要支持独立演进
- 接口设计要预留版本化与扩展字段
- 数据模型要避免把未来扩展能力硬编码进当前单一结构
- 前后端都应采用可扩展的模块边界
- 前后端必须分离，保证系统职责清晰
- 后端实现尽量采用纯 Go 方案，避免因 CGO 影响构建与扩展
- 代码实现阶段应保持清晰注释，关键部分采用英文中文双语注释
- 多语言实现应采用可扩展字典结构，避免把文案散落硬编码在页面逻辑中
- 前端应支持按语言元数据切换 `lang` 与 `dir`
- 语言扩展时应优先通过增量翻译配置完成，而不是复制整套页面实现

## 10. 需求变更记录规则

- 新增功能时，先补充到对应模块
- 调整优先级时，需要同步更新优先级章节
- 若需求影响页面结构，要同步更新设计文档
- 若需求影响模块边界、接口或数据模型，要同步更新架构文档

## 11. 当前状态

当前需求为首版基础范围，后续还会继续补充。每次补充需求时，应把新增能力、影响范围和优先级写入本文件。

## 12. 变更日志

### 2026-03-19

- Flutter 发布文章时，非 Web 端必须接入真实附件选择器，不能只保留 stub；文章编辑页也必须共享同一套附件状态、预览与清除能力，避免出现“发布能选、编辑不能改”的断链问题 / Flutter post publishing must use a real attachment picker on non-web platforms instead of a stub only; the post editor must share the same attachment state, preview, and clear actions to avoid split workflows where publish works but edit does not.
- Vue 进入空间时，空间标题与页面说明必须兼容普通字符串和多语言对象，不能直接假设存在 `zh-CN` 键；类似解析函数要先做空值与类型检查，避免直接点“空间”时因标题计算崩溃 / When Vue enters Space, the space title and subtitle must tolerate both plain strings and multilingual objects and must not assume a `zh-CN` key exists; parsing helpers should guard against nulls and types so clicking Space never crashes on title computation.
- 收口空间相关界面文案为当前语言单语显示，不再同时展示中文和英文 / Collapsed space-related UI labels to the active language only instead of showing bilingual text side by side.
- 在聊天界面新增好友资料弹窗，支持查看资料并跳转到完整个人主页 / Added a friend profile modal in chat so users can review details and jump to the full profile page.
- 空间页改为进入后才显示该空间帖子，并增加当前空间导航与设置区 / The space page now shows posts only after entering a space and includes current-space navigation and settings.
- 空间页导航按钮改为使用现有导航文案键，避免显示原始 key；Flutter 进入空间后立即拉取帖子，避免依赖手动刷新 / The space-page nav buttons now reuse existing nav translation keys instead of showing raw keys, and Flutter fetches posts immediately after entering a space without requiring a manual refresh.
- Vue 空间页需要同时展示创建入口与“我的空间”列表，并且帖子流只能跟随已进入的当前空间 / The Vue space page must show both the create entry and “My spaces” list, and the feed must follow only the entered current space.

### 2026-03-18

- 新增空间相关需求，明确私人空间与公共空间都需要二级域名标识 / Added space requirements with second-level domain identifiers for private and public spaces.
- 明确公共空间内容需要先进入空间上下文，再进行浏览或发布 / Clarified that public space content must be accessed through the active space context.
- 完成聊天全屏布局、历史滚动与表情/贴纸快捷插入 / Completed full-screen chat layout, history scrolling, and emoji/sticker quick inserts.
- 明确文章需要记录所属空间，并要求双端以弹窗方式完成空间与内容创建 / Clarified that posts must record their owning space and both clients should use modal entry for space/content creation.
- 明确空间名称与二级域名解耦，空间和文章都支持删除，个人空间列表仅展示用户创建的空间 / Clarified that space names and subdomains are independent, spaces and posts support deletion, and personal space lists only show user-created spaces.
- 补充用户名作为个人主页与二级域名入口的统一句柄 / Added username as the unified handle for profile and subdomain routing.

### 2026-03-17

- 收敛首批语言为 English、简体中文与繁體中文 / Reduced built-in languages to English, Simplified Chinese, and Traditional Chinese.
- 保留 RTL 扩展能力，不再内建希伯来语 / Kept RTL extensibility while removing built-in Hebrew.

### 2026-03-18

- 新增聊天媒体消息、过期自动删除与双端布局优化需求 / Added chat media messages, automatic expiry cleanup, and dual-end layout refinement.
- 新增新好友浮动提醒与新消息图标提示需求 / Added floating new-friend reminders and unread message badge hints.
- 新增聊天回到底部按钮与滚动条美化需求 / Added a back-to-bottom button and scrollbar polish requirement for chat.

### 2026-03-12

- 新增多语言界面需求
- 明确内建语言为 English、简体中文、繁體中文、希伯来语
- 明确希伯来语需要支持 RTL 排版
- 明确语言元数据与翻译字典需支持后续扩展

### 2026-03-11

- 新增需求文档
- 确定首批需求包含用户相关能力
- 确定首批需求包含社交相关能力
- 确定后续需要支持区块链账号接入
- 明确系统需要支持持续扩展
- 明确前后端分离
- 明确后端尽量避免 CGO，优先纯 Go
- 明确关键代码注释采用英文中文双语
- 补充当前版本范围定义
- 补充功能模块拆分与优先级
- 补充需求变更记录规则
