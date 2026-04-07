# 网站总管理面板设计 / Site Admin Panel Design

## 1. 目标 / Goal

- 为管理员提供一个跨微服务的总控后台，而不是单纯的健康检查跳转页。 / Provide administrators with a cross-microservice control workspace instead of a simple health-and-routing page.
- 在同一页面集中展示微服务配置、数据库配置、用户管理和运行性能。 / Show microservice configuration, database configuration, user management, and runtime performance on one page.
- 继续保留学习课程后台作为专题工作区，但将其纳入总管理面板统一调度。 / Keep the learning course console as a focused workspace, but place it under the site-wide admin panel.

## 2. 权限边界 / Permission Boundary

- 当前最小实现继续使用 `users.level = admin` 作为网站总管理面板的准入条件。 / The current minimum implementation continues using `users.level = admin` as the site admin panel admission rule.
- 普通登录用户不显示网站管理面板入口，也不应通过前端路由直接停留在该页面。 / Regular signed-in users do not see the site admin panel entry and should not remain on that page through frontend routing.
- 总管理面板本身不直接提升后端权限，只负责聚合状态与跳转至已有管理员工作区。 / The site admin panel itself does not elevate backend permissions; it only aggregates status and routes into existing administrator workspaces.

## 3. 页面职责 / Page Responsibilities

- 展示各个微服务的基础配置，例如 API 地址、健康检查路径、功能范围、实时探测耗时。 / Show base configuration for each microservice, such as API base URL, health path, capability scope, and live probe latency.
- 展示数据库配置摘要和连接池占用，帮助管理员判断环境连接是否异常。 / Show database configuration summary and connection-pool usage so administrators can spot environment issues quickly.
- 提供用户管理入口，允许管理员直接调整最近用户的 `level` 与 `status`。 / Provide user management so administrators can directly adjust recent users' `level` and `status`.
- 展示 `admin-service` 当前进程的运行时性能指标，例如内存、协程、GC 次数、运行时长。 / Show runtime performance metrics for the current `admin-service` process, such as memory, goroutines, GC count, and uptime.
- 提供管理员快捷动作：进入个人主页、空间、聊天、学习页、课程后台。 / Provide administrator quick actions to enter the profile, space, chat, learning page, and course console.

## 4. 信息来源 / Data Sources

- `admin-service` 负责统一聚合总管理面板所需的数据，并公开 `GET /api/v1/health` 与管理员专属 `GET /api/v1/overview`。 / `admin-service` aggregates the site admin panel data and exposes public `GET /api/v1/health` plus administrator-only `GET /api/v1/overview`.
- `GET /api/v1/overview` 当前返回 `summary`、`services`、`database`、`runtime`、`users`，供总控面板统一展示。 / `GET /api/v1/overview` currently returns `summary`, `services`, `database`, `runtime`, and `users` for the global control panel.
- `PATCH /api/v1/users/:id` 负责管理员用户调整操作。 / `PATCH /api/v1/users/:id` handles administrator user updates.
- `account-service`、`space-service`、`message-service` 与 `learning-service` 继续复用各自现有的 `GET /api/v1/health` 作为在线探测来源。 / `account-service`, `space-service`, `message-service`, and `learning-service` continue reusing their existing `GET /api/v1/health` endpoints for online probing.
- 具体微服务后台明细逐步下沉到各自的 `/api/v1/admin/...`。当前 `account-service`、`space-service` 与 `message-service` 已提供 `GET /api/v1/admin/overview`，分别供 `account-admin`、`space-admin` 与 `message-admin` 直接读取。 / Detailed per-service admin data is progressively moving into each service's own `/api/v1/admin/...` surface. `account-service`, `space-service`, and `message-service` now provide `GET /api/v1/admin/overview` for `account-admin`, `space-admin`, and `message-admin`.

## 5. 双前端落点 / Dual-Frontend Placement

- Flutter：新增独立 `adminPanel` 视图，进入后展示管理员总览卡片与跨服务快捷入口。 / Flutter adds a dedicated `adminPanel` view that shows administrator overview cards and cross-service shortcuts.
- Legacy Web：新增独立 `admin-panel` 路由和 `site-admin-panel` 组件。 / Legacy Web adds a dedicated `admin-panel` route and the `site-admin-panel` component.
- 服务导航页中追加“网站管理面板”卡片，作为总管理入口。 / The service navigation page appends a “Site Admin Panel” card as the top-level management entry.
- 主导航中为管理员显示“网站管理”入口。 / The primary navigation shows a “Site Admin” entry for administrators.

## 6. 与课程后台关系 / Relation To Learning Console

- 网站总管理面板是总控页；课程后台是学习服务专题工作区。 / The site admin panel is the global control page; the course console is the learning-focused workspace.
- 当学习服务在线时，总管理面板需要提供直接进入“课程后台”的快捷动作。 / When the learning service is online, the site admin panel should provide a direct shortcut into the course console.
- 当学习服务离线时，总管理面板继续显示该服务状态，但禁用进入动作。 / When the learning service is offline, the panel still shows the service status but disables entry actions.

## 7. 当前落地范围 / Current Applied Scope

- `admin-service` 已独立运行，并作为第五个微服务纳入双前端健康探测与总控聚合。 / `admin-service` now runs independently and acts as the fifth microservice in dual-frontend health probing plus global aggregation.
- 双前端的网站总管理面板已从“健康状态卡片页”升级为真实后台工作台。 / The site admin panel in both frontends has been upgraded from a health-card page into a real administrator workspace.
- 面板当前已覆盖微服务配置、数据库配置、用户管理、运行性能，并保留学习课程后台入口。 / The panel currently covers microservice configuration, database configuration, user management, runtime performance, and keeps the learning course console entry.
- 面板已增加“待处理提醒”和用户筛选，优先暴露离线服务与停用用户。 / The panel now includes an attention queue and user filtering to surface offline services and disabled users first.
- `account-admin`、`space-admin` 与 `message-admin` 已开始迁回各自微服务内部，使用各自的管理员总览接口，而不是继续堆叠在 `admin-service`。 / `account-admin`, `space-admin`, and `message-admin` have started moving back into their own microservices and use service-owned admin overviews instead of continuing to accumulate inside `admin-service`.

## 8. 下一阶段 / Next Phase

- 继续把总管理面板从健康探测页升级为真实运营工作台，但保持 `admin-service` 只做总控聚合，不吞并各微服务自己的后台明细。 / Continue upgrading the site admin panel from a health view into a real operations workspace while keeping `admin-service` focused on global aggregation instead of swallowing each microservice's detailed admin consoles.
- 增加平台级待办，例如“待发布课程”“离线服务提醒”“最近管理员动作”。 / Add platform-level queues such as “lessons pending publish”, “offline service alerts”, and “recent administrator actions”.
- 将空间治理、消息治理进一步做成独立管理员子面板，而不是只保留跳转按钮。 / Expand space governance and message governance into dedicated administrator subpanels instead of only keeping jump actions.
- 在 `admin-service` 内继续扩展更多配置源，例如对象存储、邮件、第三方 OAuth、链上服务等。 / Continue extending `admin-service` with more configuration sources such as object storage, email, third-party OAuth, and blockchain integrations.
- 继续把各微服务管理员入口从“总览页”推进到更细粒度的可执行后台动作，例如账号状态调整、订阅运营和外部绑定审计。 / Continue evolving each per-service admin entry from an overview surface into finer-grained executable admin actions such as account-status changes, subscription operations, and external-binding audits.
