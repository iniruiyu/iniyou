# 03 后端架构与工程初始化

## 1. 目标

完成纯 Go 优先的后端工程初始化，建立清晰的模块边界、RESTful API 结构和服务分层。

## 2. 状态

<<<<<<< ours
- 状态：进行中
- 当前基线：路由/服务/仓储分层、统一响应、API 版本化和健康检查规范已明确，账号服务承担登录主链路，空间与消息服务作为可选微服务 / Routing, service, repository layering, unified responses, API versioning, and health checks are defined, with the account service carrying the login path and space/message treated as optional microservices.
- 当前基线补充：学习课程 Markdown 文件能力已拆分为独立 `learning-service`，使用文件系统存储而不是新增数据库表 / Baseline update: learning-course Markdown file capability is split into an independent `learning-service` and uses filesystem storage instead of adding database tables.
- 进行中：后端工程初始化、配置加载和数据库兼容收口 / In progress: backend bootstrapping, config loading, and database compatibility closure.

## 3. 任务清单

- 初始化后端工程目录
- 设计 `cmd/`、`internal/`、`pkg/` 的职责
- 建立配置加载方案
- 建立路由层、服务层、仓储层分层结构
- 建立统一响应结构和错误处理结构
- 建立 API 版本化规范
- 建立健康检查接口
- 让账号、空间、消息服务统一暴露 `GET /api/v1/health`，供前端服务导航和登录后可见性刷新使用 / Expose `GET /api/v1/health` on the account, space, and message services for frontend service navigation and post-login visibility refresh.
- 新增 `learning-service`，独立暴露 `GET /api/v1/health` 与 Markdown 文件存取接口
- 建立日志与基础中间件方案
- 明确 MySQL 与 PostgreSQL 的兼容策略
- 确保后端模块结构可直接映射 `docs/API_SPEC.md` 与 `docs/DATA_MODEL.md`
- 审核依赖，避免引入需要 CGO 的方案

## 4. 完成标准

- 后端服务可启动
- API 基础骨架可用
- 分层结构明确
=======
- 状态：已完成
- 完成时间：2026-03-12

## 3. 任务清单

- [x] 初始化后端工程目录
- [x] 设计 `cmd/`、`internal/`、`pkg/` 的职责
- [x] 建立配置加载方案
- [x] 建立路由层、服务层、仓储层分层结构
- [x] 建立统一响应结构和错误处理结构
- [x] 建立 API 版本化规范
- [x] 建立健康检查接口
- [x] 建立日志与基础中间件方案
- [x] 明确 MySQL 与 PostgreSQL 的兼容策略
- [x] 确保后端模块结构可直接映射 `docs/API_SPEC.md` 与 `docs/DATA_MODEL.md`
- [x] 审核依赖，避免引入需要 CGO 的方案

## 4. 执行记录

- 后端工程已初始化在 `backend/`，并拆分 `cmd/` 与 `internal/`。
- 已具备配置加载、数据库连接、鉴权中间件、业务处理与服务模块。
- API 已采用 `/api/v1` 版本前缀并按资源划分接口。
- 架构边界与依赖约束已在 `docs/ARCHITECTURE_DECISIONS.md` 固化。

## 5. 完成标准

- [x] 后端服务可启动
- [x] API 基础骨架可用
- [x] 分层结构明确
>>>>>>> theirs
