# iniyou

`iniyou` 是一个覆盖账号、空间、社交内容、聊天和链上扩展能力的项目仓库。当前仓库同时包含规划文档与已落地实现。

当前前端双轨并存：

- `frontend/`: Legacy Web，用于快速联调
- `flutter_frontend/`: 跨端主方向

## 项目结构

- `backend/`: Golang 后端，包含 `account-service`、`space-service` 和 `message-service`
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
- `SERVICE_PORT`: 可选；账号服务默认 `8080`，空间服务默认 `8082`，通讯服务默认 `8081`

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

6. 选择前端启动方式：

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
- 两套前端默认直接请求上述三个本地服务
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
