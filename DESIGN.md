# 账号服务设计文档

## 1. 项目概述
本项目是一个使用 Go 语言实现的账号服务微服务，提供用户注册、登录、鉴权、账号管理等能力。账号服务只保留用户名、域名、密码、手机号、签名、状态等身份字段，个人资料字段通过可见范围控制。空间能力已拆分到独立的 `space-service`。服务采用 Gin 作为 HTTP 通讯框架，使用 GORM 访问 PostgreSQL 数据库。服务可以接入“reddit 加速”（作为外部加速/代理或资源加速层），用于提升特定外部依赖的访问效率。

## 2. 技术栈
- 语言：Go
- Web 框架：Gin
- ORM：GORM
- 数据库：PostgreSQL
- 外部加速：reddit 加速（按需接入）

## 3. 目标与非目标
### 3.1 目标
- 提供账号相关的核心能力：注册、登录、登出、重置密码、账号信息管理。
- 提供域名身份卡能力，支持用户名与域名分离，并允许通过域名登录。
- 提供个人资料可见范围控制，满足手机号、年龄、性别、邮箱等字段的公开范围配置。
- 统一鉴权入口，支持 JWT/Session（可配置）。
- 规范的错误码与响应格式。
- 可水平扩展，满足高并发场景。
- 可观测性（日志、指标、链路追踪）。

### 3.2 非目标
- 不包含复杂的社交关系、推荐等业务。
- 不负责空间、内容、评论与转发的业务规则，这些能力由独立空间服务负责。
- 不负责客户端实现。

## 4. 系统架构
### 4.1 组件
- API 层（Gin）
- Service 层（业务逻辑）
- Repository 层（GORM + PostgreSQL）
- Auth 模块（JWT/Session）
- 外部加速模块（reddit 加速）

### 4.2 数据流
1. 客户端请求进入 Gin 路由
2. 进入中间件（鉴权、日志、限流等）
3. 调用 Service 层逻辑
4. 通过 Repository 层读写 PostgreSQL
5. 返回统一格式响应

## 5. 核心模块设计
### 5.1 用户注册
- 输入：邮箱/手机号 + 密码 + 可选资料
- 输出：用户 ID + Token
- 处理：
  - 校验格式与重复
  - 密码加密存储（bcrypt/argon2）

### 5.2 用户登录
- 输入：账号 + 密码（账号可为邮箱、手机号、用户名或域名）
- 输出：Token
- 处理：
  - 校验账号存在
  - 验证密码

### 5.3 鉴权
- 统一 JWT/Session 验证
- 中间件解析 token
- 支持过期与刷新

### 5.4 账号管理
- 查询用户资料
- 修改资料
- 密码修改
- 域名身份卡管理
- 个人资料可见范围管理

## 6. 数据库设计（PostgreSQL）
### 6.1 users 表
- id (uuid, pk)
- email (unique, nullable)
- phone (unique, nullable)
- username (unique, nullable, alphanumeric host label)
- domain (unique, nullable, alphanumeric host label)
- display_name
- signature
- age
- gender
- phone_visibility
- email_visibility
- age_visibility
- gender_visibility
- password_hash
- status (active/disabled)
- created_at
- updated_at

### 6.2 sessions 表（可选）
- id
- user_id
- token
- expires_at

## 7. API 设计（示例）
- POST /api/v1/register
- POST /api/v1/login
- POST /api/v1/logout
- GET  /api/v1/me
- PUT  /api/v1/me
- POST /api/v1/password/reset
- GET  /api/v1/users/domain/{domain}/profile

## 8. 安全与合规
- 密码不明文存储，采用安全哈希
- 账户锁定与防暴力破解
- 请求限流与验证码支持

## 9. 可观测性
- 日志：结构化日志
- 指标：Prometheus
- 追踪：OpenTelemetry

## 10. 部署与运维
- 容器化：Docker
- 配置管理：环境变量 / 配置文件
- CI/CD：自动化测试与部署

## 11. 后续扩展
- 多因素认证
- OAuth 第三方登录
- 多租户支持

---
文档版本：v0.1
