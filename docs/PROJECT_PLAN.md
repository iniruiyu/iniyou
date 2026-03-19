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

### 4.2 前端职责范围

- 承担页面展示与用户交互
- 承担表单校验和基础状态管理
- 通过 API 与后端通信
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

- 首页/工作台
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
