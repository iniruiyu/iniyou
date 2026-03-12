# iniyou

`iniyou` 是一个包含账号、社交内容、聊天和链上账号扩展能力的项目仓库。当前仓库同时保存规划文档和已落地实现，后续开发以本仓库为唯一主线。

## 项目结构

- `backend/`: Golang 后端，包含 `account-service` 和 `message-service`
- `frontend/`: 原生 HTML、CSS、JavaScript 前端页面
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
- `SERVICE_PORT`: 可选；账号服务默认 `8080`，通讯服务默认 `8081`

## 本地启动

1. 启动 PostgreSQL，并确保 `DB_DSN` 指向可用数据库。
2. 在一个终端运行账号服务：

```bash
make run-account
```

3. 在另一个终端运行通讯服务：

```bash
make run-message
```

4. 直接打开 [`frontend/index.html`](/root/new-project/frontend/index.html) 进行本地页面联调。

说明：

- 账号服务默认监听 `http://localhost:8080`
- 通讯服务默认监听 `http://localhost:8081`
- 前端默认直接请求上述两个本地服务

## 测试与构建

运行基础检查：

```bash
make test
```

单独运行：

```bash
make test-backend
make test-frontend
make build
```

构建产物输出到 `build/`：

- `build/account-service`
- `build/message-service`

## 关键文档

- [`docs/REQUIREMENTS.md`](/root/new-project/docs/REQUIREMENTS.md): 需求范围与变更
- [`docs/API_SPEC.md`](/root/new-project/docs/API_SPEC.md): RESTful API 清单
- [`docs/DATA_MODEL.md`](/root/new-project/docs/DATA_MODEL.md): 数据模型基线
- [`docs/design/FRONTEND_DESIGN.md`](/root/new-project/docs/design/FRONTEND_DESIGN.md): 前端设计说明
- [`docs/development-outline/`](/root/new-project/docs/development-outline): 开发阶段与任务拆分

## 开发规则

- 新需求先写入相关 `md`，再开始评估或开发
- 当前任务未完成时，优先收口并提交，再拆下一步
- 关键代码注释保持英文中文双语
- 新增接口、数据模型或页面变更时，同步更新相关文档
