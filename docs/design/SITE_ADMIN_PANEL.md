# 网站总管理面板设计 / Site Admin Panel Design

## 1. 目标 / Goal

- 为管理员提供一个跨微服务的总控入口，统一查看站点服务状态与管理工作区。 / Provide administrators with a cross-microservice control entry that centralizes site service health and management workspaces.
- 将“课程后台”从单点入口升级为网站管理体系中的专题工作区。 / Upgrade the course console from a single-purpose entry into a focused workspace inside the site management system.
- 保持现有账号、空间、消息、学习四类服务入口不变，同时补一层管理员总览。 / Keep the existing account, space, message, and learning service entries unchanged while adding an administrator overview layer.

## 2. 权限边界 / Permission Boundary

- 当前最小实现继续使用 `users.level = admin` 作为网站总管理面板的准入条件。 / The current minimum implementation continues using `users.level = admin` as the site admin panel admission rule.
- 普通登录用户不显示网站管理面板入口，也不应通过前端路由直接停留在该页面。 / Regular signed-in users do not see the site admin panel entry and should not remain on that page through frontend routing.
- 总管理面板本身不直接提升后端权限，只负责聚合状态与跳转至已有管理员工作区。 / The site admin panel itself does not elevate backend permissions; it only aggregates status and routes into existing administrator workspaces.

## 3. 页面职责 / Page Responsibilities

- 展示账号、空间、消息、学习四类服务的在线状态。 / Show online status for the account, space, message, and learning services.
- 展示总服务数、在线服务数、离线服务数、管理工作区数量等运营级摘要。 / Show operational summaries such as total services, online services, offline services, and admin workspace counts.
- 提供管理员快捷动作：进入个人主页、空间、聊天、学习页、课程后台。 / Provide administrator quick actions to enter the profile, space, chat, learning page, and course console.
- 承接后续更多后台能力，例如审核中心、运营公告、平台配置等。 / Serve as the parent surface for future admin capabilities such as review queues, announcements, and platform configuration.

## 4. 信息来源 / Data Sources

- `account-service` 始终视为在线基础服务。 / `account-service` is treated as the always-online base service.
- `space-service`、`message-service`、`learning-service` 继续复用已有 `GET /api/v1/health` 探测。 / `space-service`, `message-service`, and `learning-service` continue reusing the existing `GET /api/v1/health` probes.
- 新增独立 `admin-service`，公开 `GET /api/v1/health` 与管理员专属 `GET /api/v1/overview`。 / A dedicated `admin-service` is added, exposing public `GET /api/v1/health` and admin-only `GET /api/v1/overview`.

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

- 已落地独立 `admin-service`，并作为第五个微服务纳入双前端健康探测。 / A dedicated `admin-service` is now implemented and included as the fifth microservice in dual-frontend health probing.
- 管理员总览页可显示服务健康状态和已有管理员入口。 / The administrator overview page can show service health and existing admin entries.
- 课程后台继续承担学习内容创建、编辑、发布、归档等具体动作。 / The course console continues handling concrete learning content creation, editing, publishing, and archiving actions.

## 8. 下一阶段 / Next Phase

- 继续把总管理面板从健康探测页升级为真实运营工作台，逐步让前端改读 `admin-service` 的统一总览载荷。 / Continue upgrading the site admin panel from a health view into a real operations workspace and gradually move the frontends to the unified overview payload from `admin-service`.
- 增加平台级待办，例如“待发布课程”“离线服务提醒”“最近管理员动作”。 / Add platform-level queues such as “lessons pending publish”, “offline service alerts”, and “recent administrator actions”.
- 把课程后台、空间治理、消息治理统一收敛到总管理面板的二级导航。 / Converge the course console, space governance, and messaging governance into secondary navigation under the site admin panel.
