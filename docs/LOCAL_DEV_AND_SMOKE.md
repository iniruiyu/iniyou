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

当前版本提供显式迁移命令 `make migrate`，等价于 `cd backend && go run ./cmd/migrate -service all` / The current version provides an explicit migration command `make migrate`, which is equivalent to `cd backend && go run ./cmd/migrate -service all`.

建议在首次初始化数据库、拉取 schema 变更或需要回填历史数据时先执行该命令 / Run it first when initializing a database, pulling schema changes, or backfilling historical data.

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

直接打开：

- [`frontend/index.html`](../frontend/index.html)

## 5. 手工联调步骤

建议按以下顺序联调：

1. 注册第一个账号
2. 注册第二个账号
3. 更新昵称、用户名、域名和资料可见范围
4. 搜索用户并建立好友关系
5. 进入聊天页发送消息
6. 进入空间并发布公共文章
7. 打开作者主页与文章详情
8. 绑定一个链上账号并检查主页摘要是否更新

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

## 7. 当前限制

- 冒烟脚本依赖本地服务已启动
- 冒烟脚本当前未覆盖前端页面行为
- 完整本地环境下的 `make smoke` 实跑留档仍待完成 / Full-environment `make smoke` evidence capture is still pending.
- 区块链账号绑定目前只做基础格式与签名载荷校验，不包含真实链上验签
- 数据库迁移已提供显式命令，后续如需版本化迁移脚本可继续扩展 / Database migration now has an explicit command, and versioned migration scripts can be added later if needed.

## 8. 维护规则

- 若本地启动方式变化，需要同步更新本文件和 `README.md`
- 若自动冒烟脚本覆盖范围变化，需要同步更新本文件
- 若迁移策略从当前显式命令升级为版本化迁移工具，需要先更新本文件再实施
