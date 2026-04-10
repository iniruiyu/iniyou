# iniyou

`iniyou` 是一个覆盖账号、空间、社交内容、聊天和链上扩展能力的项目仓库。当前仓库同时包含规划文档与已落地实现。

当前前端双轨并存：

- `frontend/`: Legacy Web，用于快速联调
- `flutter_frontend/`: 跨端主方向

## 项目结构

- `backend/`: Golang 后端，包含 `account-service`、`space-service`、`message-service` 和 `learning-service`
- `frontend/`: Legacy Web 前端
- `flutter_frontend/`: Flutter 前端工程，按 `api/`、`controllers/`、`models/`、`widgets/`、`views/` 分层
- `docker-compose.yml`: 容器化部署栈
- `backend/Dockerfile`: 后端容器镜像构建文件
- `frontend/Dockerfile`: Legacy Web 容器镜像构建文件
- `frontend/nginx.conf`: Legacy Web 静态站点配置
- `scripts/deploy-stack.sh`: 本地部署编排脚本
- `scripts/remote-deploy.sh`: 远程部署助手脚本
- `.github/workflows/`: CI 和 Release 流水线
- `docs/`: 需求、设计、接口和开发大纲
- `DESIGN.md`: 当前阶段设计说明
- `Makefile`: 本地测试、构建和启动命令

## 运行依赖

- Go 1.22 或更高版本
- Node.js 18 或更高版本
- PostgreSQL 14 或更高版本

## 环境变量

复制模板：

```bash
cp .env.example .env
```

主要变量：

- `DB_DSN`: PostgreSQL 连接串
- `JWT_SECRET`: 登录签名密钥
- `TOKEN_TTL_MIN`: 登录态有效时间（分钟）
- `SERVICE_PORT`: 可选；账号服务默认 `8080`，空间服务默认 `8082`，通讯服务默认 `8081`，学习服务默认 `8083`
- `MARKDOWN_STORAGE_DIR`: 可选；学习服务 Markdown 课程文件落盘目录，默认 `D:/codeX/iniyou/uploads/learning-service/markdown-files`
- `backend/.env.local`: 开发期本地覆盖配置文件；如存在，会在进程环境变量之后生效，当前可由网站总控直接写入 `DB_DSN`
- `learning-service` 现支持在学习页内运行受限 `go`、`javascript`、`python` 代码块；运行环境要求服务所在机器可用对应运行时（Go/Node.js/Python），当前限制为 32 KB 代码、Go 8 秒超时、JavaScript/Python 5 秒超时、16 KB 输出上限，并对高风险模块与导入做基础拦截
- Flutter 学习页会优先从 `learning-service /api/v1/markdown-files` 同步课程目录，并自动发现 `courses/{courseId}.{locale}.md` 形式的新课程文件
- 课程内容维护当前已收敛到管理员权限，只有 `users.role = admin` 的账号才会看到双前端中的课程新建与保存入口，并可调用 `learning-service /api/v1/markdown-files/*path`
- 管理员当前还可删除某个课程语言版本文件，用于快速下架课程内容；完整草稿/审核/上架流转仍待独立管理员后台继续落地
- 如需设置管理员，可使用 `backend/cmd/admin-tool` 直接修改账号角色，例如：`cd backend && go run ./cmd/admin-tool --email your@email.com --role admin`

## 管理员权限工具 / Admin Tool

`backend/cmd/admin-tool` 用于直接修改账号角色或会员等级，适合本地开发、联调环境初始化和测试账号提权。`backend/cmd/admin-tool` updates one account role or membership level directly and is intended for local development, integration setup, and test-account promotion.

使用约束 / Usage rules:

- 该工具要求在 `backend/` 目录下运行，并使用当前环境变量里的 `DB_DSN` 连接数据库。 Run the tool from `backend/` and let it use the current `DB_DSN` database connection.
- `--user-id`、`--email`、`--username` 三个参数只能传一个，工具会按该标识精确查找用户。 Pass exactly one of `--user-id`, `--email`, or `--username`; the tool resolves one exact user from that identifier.
- `--role` 用于设置权限角色，当前支持 `admin` 和 `member`；`--level` 用于设置会员等级，当前支持 `basic`、`premium`、`vip`。 `--role` sets the permission role and currently supports `admin` and `member`; `--level` sets the membership tier and currently supports `basic`, `premium`, and `vip`.
- 角色与会员等级已经拆分：`users.role` 控制管理权限，`users.level` 只表示订阅等级。 Roles and membership tiers are now separated: `users.role` controls administration permission, while `users.level` represents subscription tier only.
- 当前工具只更新 `users.role` 和/或 `users.level` 字段，不会改动 `status`、密码或其他资料。 The tool only updates `users.role` and/or `users.level`; it does not modify `status`, passwords, or other profile fields.

示例命令 / Examples:

```bash
cd backend
go run ./cmd/admin-tool --email your@email.com --role admin
go run ./cmd/admin-tool --username your_username --role admin
go run ./cmd/admin-tool --user-id your-user-id --level basic
go run ./cmd/admin-tool --user-id your-user-id --role member --level vip
```

执行结果 / Result:

- 成功时会输出用户 ID、邮箱、用户名、旧角色/新角色以及旧等级/新等级，便于确认修改是否命中正确账号。 On success, the tool prints the user ID, email, username, old/new role, and old/new level so you can verify the exact target account.
- 修改完成后，需要让前端重新登录或刷新当前用户信息，管理员入口才会按新权限显示。 After the update, re-login or refresh the current user state in the frontend so administrator entries reflect the new permission.

## 网站总控数据库配置 / Site Admin Database Config

- 网站总控中的“数据库配置”区域现在支持直接读取和写入 `backend/.env.local` 里的 `DB_DSN`。 The database configuration section in the site admin panel can now read and write `DB_DSN` inside `backend/.env.local` directly.
- 配置优先级为：进程环境变量 > `backend/.env.local` > 代码默认值。 The precedence is: process environment variables > `backend/.env.local` > in-code defaults.
- 保存新 DSN 后不会热更新已经运行中的服务；开发期需要手动重启 `account-service`、`admin-service`、`space-service`、`message-service`、`learning-service`，让它们重新加载配置。 Saving a new DSN does not hot-reload already running services; in development you must restart `account-service`, `admin-service`, `space-service`, `message-service`, and `learning-service` so they reload the configuration.

## 网站总控信息架构 / Site Admin Information Architecture

- 网站总控页面按功能分为三组：`站点控制 / Site controls`、`微服务工作台 / Microservice workbench`、`运行观察 / Operations and runtime`。 The site admin page is organized into three functional groups: `Site controls`, `Microservice workbench`, and `Operations and runtime`.
- 微服务列表默认折叠，避免总控首页被单个服务的大量配置淹没。点击展开后显示服务清单，再点击某个服务会打开站内设置弹层。 The microservice list is collapsed by default so the landing view is not dominated by per-service detail. Expand the group to see the service list, then open a service-specific settings modal from any row.
- 站点级直接操作项保留在主页面内，包括待处理提醒、数据库连接配置、用户权限与状态管理。 Site-level direct controls stay on the main page, including the attention queue, database connection management, and user role/status management.

## Legacy Web 设置菜单与主题 / Legacy Web Settings Menu and Themes

- Legacy Web 的侧边栏设置菜单现在始终通过 Teleport 渲染到 `body`，在小窗口和折叠导航模式下会以顶层浮板显示，避免被侧边栏、遮罩或滚动容器盖住。 The Legacy Web settings menu is now always teleported to `body`, and in compact navigation mode it appears as a top-level floating sheet so it is never obscured by the sidebar, overlay, or scrolling containers.
- 主题区域默认折叠为“主题工作台 / Theme workbench”，先显示当前主题摘要，再按需展开预设主题和自定义主题编辑器。 The theme area is collapsed into a `Theme workbench` by default, showing only the active-theme summary until the user expands preset themes or the custom-theme editor.
- 自定义主题保存在浏览器本地存储中，当前支持背景、主面板、次级面板、主色、强化主色、强调色、正文文字和次级文字八个核心变量。 The custom theme is stored in browser local storage and currently exposes eight core tokens: background, panel, soft panel, primary, strong primary, accent, body text, and muted text.

## 本地启动

1. 启动 PostgreSQL，并确认 `DB_DSN` 可用。
2. 如数据库结构有变更，先运行版本化迁移：

```bash
make migrate
```

如需只迁移单个服务，可用：

```bash
make migrate MIGRATE_SERVICE=account
```

3. 运行账号服务：

```bash
make run-account
```

4. 运行空间服务：

```bash
make run-space
```

5. 运行通讯服务：

```bash
make run-message
```

6. 运行学习服务（教育微服务）：

```bash
make run-learning
```

也可以直接从后端目录启动：

```bash
cd backend
SERVICE_PORT=8083 go run ./cmd/learning-service
```

如需自定义课程 Markdown 文件落盘目录，可在启动前设置：

```bash
MARKDOWN_STORAGE_DIR=D:/codeX/iniyou/uploads/learning-service/markdown-files make run-learning
```

7. 选择前端启动方式：

Legacy Web:

```bash
Start-Process frontend/index.html
```

Flutter Web:

```bash
make run-flutter-web
```

默认地址：

- 账号服务默认监听 `http://localhost:8080`
- 空间服务默认监听 `http://localhost:8082`
- 通讯服务默认监听 `http://localhost:8081`
- 学习服务默认监听 `http://localhost:8083`
- 两套前端默认直接请求上述四个本地服务
- Flutter 入口：[`flutter_frontend/lib/main.dart`](./flutter_frontend/lib/main.dart)
- Flutter 主要视图目录：[`flutter_frontend/lib/views`](./flutter_frontend/lib/views)

## Flutter 前端结构

- `flutter_frontend/lib/main.dart`: 应用入口、状态与视图分发
- `flutter_frontend/lib/api/api_client.dart`: 接口访问层
- `flutter_frontend/lib/controllers/app_actions.dart`: 多接口编排与动作辅助层
- `flutter_frontend/lib/controllers/post_state_actions.dart`: 帖子列表与详情同步的纯状态辅助
- `flutter_frontend/lib/controllers/session_actions.dart`: 会话管理、Token 存取与 Socket 辅助
- `flutter_frontend/lib/models/app_models.dart`: 前端数据模型与格式化辅助
- `flutter_frontend/lib/widgets/app_cards.dart`: 通用卡片与基础展示组件
- `flutter_frontend/lib/views/guest_landing_view.dart`: 未登录落地页
- `flutter_frontend/lib/views/content_sections.dart`: 工作台摘要、空间与内容流区块
- `flutter_frontend/lib/views/section_body_router.dart`: 已登录主内容区视图分发
- `flutter_frontend/lib/views/view_factories.dart`: 已登录各页面视图参数工厂
- `flutter_frontend/lib/views/social_views.dart`: 个人主页、文章详情、好友、聊天
- `flutter_frontend/lib/views/settings_views.dart`: 等级、订阅、区块链接入
- `flutter_frontend/lib/views/shell_widgets.dart`: 侧边栏与反馈横幅
- `flutter_frontend/lib/views/authenticated_home_view.dart`: 登录后主内容壳层
- `flutter_frontend/lib/views/authenticated_shell_view.dart`: 登录后主壳层

## 测试与构建

基础检查：

```bash
make test
```

按需执行：

```bash
make test-backend
make test-frontend
make test-flutter
make migrate
make build-flutter-web
make build
make smoke
make deploy
make deploy-remote
make deploy-down
make deploy-status
make deploy-logs
```

CI 自动检查会在 `push` 和 `pull_request` 时运行同样的后端、前端、Flutter 和容器校验 / The CI pipeline runs the same backend, frontend, Flutter, and container checks on `push` and `pull_request`.

构建产物输出到 `build/`：

- `build/account-service`
- `build/space-service`
- `build/message-service`
- `build/learning-service`
- `build/migrate`

## 容器部署

Docker 环境可直接使用容器化部署栈：

```bash
make deploy
```

常用辅助命令：

```bash
make deploy-remote
make deploy-status
make deploy-logs
make deploy-down
```

`make deploy` 会先构建后端、前端和迁移镜像，再启动数据库、执行版本化迁移，最后拉起业务服务。 / `make deploy` first builds the backend, frontend, and migration images, then starts the database, runs the versioned migrations, and finally brings up the application services.

`make deploy-remote` 会在远程主机的已检出仓库中先拉取最新 `main` 分支，再执行同一套容器化部署脚本。 / `make deploy-remote` pulls the latest `main` branch in the remote host's checked-out repository and then runs the same containerized deployment script.

GitHub Actions 还提供了 `Release` 工作流，可在 CI 通过后自动 SSH 部署到远程主机。 / GitHub Actions also provides a `Release` workflow that can SSH-deploy to the remote host after CI passes.

该工作流默认读取 `DEPLOY_HOST`、`DEPLOY_USER`、`DEPLOY_PATH` 和 `DEPLOY_SSH_PRIVATE_KEY`，可选读取 `DEPLOY_KNOWN_HOSTS`。 / The workflow reads `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_PATH`, and `DEPLOY_SSH_PRIVATE_KEY` by default, and can optionally read `DEPLOY_KNOWN_HOSTS`.

## 关键文档

- [`docs/REQUIREMENTS.md`](./docs/REQUIREMENTS.md): 需求范围与变更
- [`docs/API_SPEC.md`](./docs/API_SPEC.md): RESTful API 清单
- [`docs/DATA_MODEL.md`](./docs/DATA_MODEL.md): 数据模型基线
- [`docs/LOCAL_DEV_AND_SMOKE.md`](./docs/LOCAL_DEV_AND_SMOKE.md): 本地联调、数据库初始化与冒烟流程
- [`docs/RELEASE_CHECKLIST.md`](./docs/RELEASE_CHECKLIST.md): 发布前检查清单
- [`docs/DELIVERY_BASELINE.md`](./docs/DELIVERY_BASELINE.md): 当前交付范围与限制
- [`docs/design/FRONTEND_DESIGN.md`](./docs/design/FRONTEND_DESIGN.md): 前端设计说明
- [`docs/development-outline/`](./docs/development-outline): 开发阶段与任务拆分

## 开发规则

- 新需求先写入相关 `md`，再开始评估或开发
- 当前任务未完成时，优先收口并提交，再拆下一步
- 关键代码注释保持英文中文双语
- 新增接口、数据模型或页面变更时，同步更新相关文档
- Flutter 与 Legacy Web 保持同一信息架构，差异主要放在实现与适配层
