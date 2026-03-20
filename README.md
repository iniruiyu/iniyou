# iniyou

`iniyou` 是一个包含账号、空间、社交内容、聊天和链上账号扩展能力的项目仓库。当前仓库同时保存规划文档和已落地实现，后续开发以本仓库为唯一主线。

当前前端采取双实现并存策略：

- `frontend/`: 现有静态 Web 前端，适合快速本地联调和接口验证
- `flutter_frontend/`: 新增 Flutter 前端，作为后续跨端主方向

## 项目结构

- `backend/`: Golang 后端，包含 `account-service`、`space-service` 和 `message-service`
- `frontend/`: 原生 HTML、CSS、JavaScript 前端页面（Legacy Web）
- `flutter_frontend/`: Flutter 前端工程（Web 优先，可继续扩展桌面/移动端）
  - 当前已按 `api/`、`controllers/`、`models/`、`widgets/`、`views/` 分层
- `docs/`: 需求、设计、接口和开发大纲
- `DESIGN.md`: 当前阶段设计说明
- `Makefile`: 本地测试、构建和启动命令

## 运行依赖

- Go 1.22 或更高版本
- Node.js 18 或更高版本
- PostgreSQL 14 或更高版本

## 环境变量

复制一份环境变量模板：

```bash
cp .env.example .env
```

当前主要变量：

- `DB_DSN`: PostgreSQL 连接串
- `JWT_SECRET`: 登录签名密钥
- `TOKEN_TTL_MIN`: 登录态有效时间（分钟）
- `SERVICE_PORT`: 可选；账号服务默认 `8080`，空间服务默认 `8082`，通讯服务默认 `8081`

## 本地启动

1. 启动 PostgreSQL，并确保 `DB_DSN` 指向可用数据库。
2. 在一个终端运行账号服务：

```bash
make run-account
```

3. 在另一个终端运行空间服务：

```bash
make run-space
```

4. 在另一个终端运行通讯服务：

```bash
make run-message
```

4. 选择一套前端启动方式：

Legacy Web：

```bash
Start-Process frontend/index.html
```

Flutter Web：

```bash
make run-flutter-web
```

说明：

- 账号服务默认监听 `http://localhost:8080`
- 空间服务默认监听 `http://localhost:8082`
- 通讯服务默认监听 `http://localhost:8081`
- 两套前端默认直接请求上述三个本地服务
- Flutter 前端默认入口为 [`flutter_frontend/lib/main.dart`](./flutter_frontend/lib/main.dart)
- Flutter 当前主要视图文件位于 [`flutter_frontend/lib/views`](./flutter_frontend/lib/views)

## Flutter 前端结构

- `flutter_frontend/lib/main.dart`: 应用入口、状态与视图分发
- `flutter_frontend/lib/api/api_client.dart`: 接口访问层
- `flutter_frontend/lib/controllers/app_actions.dart`: 多接口编排与动作辅助层
- `flutter_frontend/lib/controllers/post_state_actions.dart`: 帖子列表与详情同步的纯状态辅助
- `flutter_frontend/lib/controllers/session_actions.dart`: 会话管理、token 存取与 socket 辅助
- `flutter_frontend/lib/models/app_models.dart`: 前端数据模型与格式化辅助
- `flutter_frontend/lib/widgets/app_cards.dart`: 通用卡片与基础展示组件
- `flutter_frontend/lib/views/guest_landing_view.dart`: 未登录落地页
- `flutter_frontend/lib/views/content_sections.dart`: 工作台摘要、空间与内容流区块
- `flutter_frontend/lib/views/section_body_router.dart`: 已登录主内容区的视图分发
- `flutter_frontend/lib/views/view_factories.dart`: 已登录各页面视图参数拼装工厂
- `flutter_frontend/lib/views/social_views.dart`: 个人主页、文章详情、好友、聊天
- `flutter_frontend/lib/views/settings_views.dart`: 等级、订阅、区块链接入
- `flutter_frontend/lib/views/shell_widgets.dart`: 侧边栏与反馈横幅
- `flutter_frontend/lib/views/authenticated_home_view.dart`: 登录后主内容壳层（banner、摘要、内容区）
- `flutter_frontend/lib/views/authenticated_shell_view.dart`: 登录后主壳层

## 测试与构建

运行基础检查：

```bash
make test
```

单独运行：

```bash
make test-backend
make test-frontend
make test-flutter
make build-flutter-web
make build
make smoke
```

构建产物输出到 `build/`：

- `build/account-service`
- `build/space-service`
- `build/message-service`

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
- Flutter 前端与 Legacy Web 前端在信息架构上需保持一致，差异优先体现在技术实现和布局适配层
