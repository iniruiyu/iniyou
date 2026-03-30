# 本地联调与冒烟流程

## 1. 文档用途

本文件用于记录本地数据库初始化、服务启动、接口联调和最小冒烟测试步骤，作为当前版本交付前的联调基线。

## 2. 前置条件

- 已安装 PostgreSQL 14+
- 已安装 Go 1.22+
- 已安装 Node.js 18+
- 仓库根目录已有 `.env`，或按 `.env.example` 配置环境变量

## 3. 数据库初始化

### 3.1 创建数据库

示例：

```bash
createdb account_service
```

如使用自定义主机、端口或账号，请确保 `.env` 中的 `DB_DSN` 与实际数据库一致。

### 3.2 迁移执行方式

当前版本提供版本化迁移命令 `make migrate`，等价于 `cd backend && go run ./cmd/migrate -service all` / The current version provides a versioned migration command `make migrate`, which is equivalent to `cd backend && go run ./cmd/migrate -service all`.

建议在首次初始化数据库、拉取 schema 变更或需要回填历史数据时先执行该命令 / Run it first when initializing a database, pulling schema changes, or backfilling historical data.

如需只执行某个服务的迁移，可使用 `make migrate MIGRATE_SERVICE=account|space|message` / To run one service only, use `make migrate MIGRATE_SERVICE=account|space|message`.

说明：`learning-service` 当前不依赖数据库迁移；它使用数据库仅用于鉴权用户校验，课程正文文件通过 `MARKDOWN_STORAGE_DIR` 落盘保存 / `learning-service` currently does not require database migrations; it only uses the database for auth-user validation, while course Markdown bodies are persisted through `MARKDOWN_STORAGE_DIR`.

命令支持以下目标 / The command supports the following targets:

- `all`
- `account`
- `space`
- `message`

服务启动时仍会执行各自的服务级迁移，便于本地开发时自动恢复 / Each service still runs its own service-scoped migration at startup for local development recovery.

- 账号服务自动迁移：
  - `users`
  - `subscriptions`
  - `external_accounts`
  - `friends`
- 空间服务自动迁移：
  - `spaces`
  - `posts`
  - `comments`
  - `post_likes`
  - `post_shares`
- 通讯服务自动迁移：
  - `messages`

## 4. 本地启动顺序

### 4.1 启动账号服务

```bash
make run-account
```

默认地址：

- `http://localhost:8080`

### 4.2 启动空间服务

```bash
make run-space
```

默认地址：

- `http://localhost:8082`

### 4.3 启动通讯服务

```bash
make run-message
```

默认地址：

- `http://localhost:8081`

### 4.4 打开前端页面

### 4.4 启动学习服务（教育微服务）

```bash
make run-learning
```

默认地址：

- `http://localhost:8083`

可选环境变量：

- `MARKDOWN_STORAGE_DIR`：学习服务 Markdown 课程文件目录，默认 `D:/codeX/iniyou/uploads/learning-service/markdown-files`

也可以直接启动 Go 入口：

```bash
cd backend
SERVICE_PORT=8083 go run ./cmd/learning-service
```

### 4.5 打开前端页面

直接打开：

- [`frontend/index.html`](../frontend/index.html)

### 4.6 容器化启动

如果本地已经安装 Docker 和 Docker Compose，可以直接使用容器化部署栈 / If Docker and Docker Compose are installed locally, you can use the containerized deployment stack directly.

```bash
make deploy
```

常用辅助命令 / Common helper commands:

- `make deploy-status`
- `make deploy-logs`
- `make deploy-down`

`make deploy` 会先构建镜像、启动数据库、运行版本化迁移，再启动账号、空间、通讯、学习和 Legacy Web 服务 / `make deploy` builds the images first, starts the database, runs the versioned migration, and then brings up the account, space, message, learning, and Legacy Web services.

## 5. 手工联调步骤

建议按以下顺序联调：

1. 注册第一个账号
2. 注册第二个账号
3. 更新昵称、用户名、域名和资料可见范围
4. 搜索用户并建立好友关系
5. 进入聊天页发送消息
6. 进入空间并发布公共文章
7. 调用学习服务保存或读取一个 Markdown 课程文件
8. 在学习页点击一个 `go` 代码块的“运行 Go”按钮，并确认页面内返回执行输出
9. 打开作者主页与文章详情
10. 绑定一个链上账号并检查主页摘要是否更新

## 6. 自动冒烟脚本

仓库提供最小冒烟脚本：

```bash
make smoke
```

脚本位置：

- [`scripts/local-smoke.sh`](../scripts/local-smoke.sh)

当前脚本覆盖：

- 注册两个用户
- 查询当前用户资料
- 建立好友关系
- 发送一条消息
- 拉取会话摘要
- 保存并读取一个学习服务 Markdown 文件
- 学习页内的 Go 代码块点击执行（手工验证）

## 7. 当前限制

- 冒烟脚本依赖本地服务已启动
- 冒烟脚本当前未覆盖前端页面行为
- 完整本地环境下的 `make smoke` 已实跑并留档 / Full-environment `make smoke` evidence has been captured and recorded.
- 容器化部署基线已提供，但生产级部署自动化、滚动发布和远程环境编排仍待补齐 / The containerized deployment baseline is available, but production-grade deployment automation, rolling release, and remote environment orchestration still need to be added.
- 区块链账号绑定目前只做基础格式与签名载荷校验，不包含真实链上验签
- 数据库迁移已提供版本化脚本，服务启动仍保留回退迁移；后续如需更完整的回滚脚本，可继续扩展 / Database migration now has versioned scripts, and service startup still keeps a fallback migration path; rollback scripts can be added later if needed.

## 8. 维护规则

- 若本地启动方式变化，需要同步更新本文件和 `README.md`
- 若自动冒烟脚本覆盖范围变化，需要同步更新本文件
- 若迁移策略从当前版本化脚本升级为更完整的回滚工具，需要先更新本文件再实施
