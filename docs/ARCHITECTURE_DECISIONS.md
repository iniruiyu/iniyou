# 架构选型记录

## 1. 文档用途

本文件用于记录项目架构选择、技术栈约束、依赖边界，以及后续所有架构变更。

## 2. 记录规则

- 每次架构规划调整，都要同步更新本文件
- 每次设计变动影响技术实现时，也要同步更新本文件
- 每次需求变动影响模块划分、数据模型或接口边界时，也要同步更新本文件
- 如引入第三方库，必须记录引入原因、用途和影响范围

## 3. 编码与注释约束

- 代码需要保持清晰、可维护
- 关键逻辑、复杂流程、核心接口、领域模型建议补充注释
- 注释采用英文中文双语，便于跨语言协作和后续维护
- 注释应解释设计意图和边界，不写无意义的逐行描述

## 4. 核心架构原则

- 前后端分离
- 模块按领域拆分
- 接口优先
- 纯 Go 优先
- 尽量少依赖第三方库
- 预留扩展位，不为当前版本过度耦合未来能力

## 5. 当前架构选择

### 5.1 前端

- 跨端方向：Flutter
- Web 基础技术：HTML5、CSS3、JavaScript
- 可选前端框架：Vue 3

选择原则：

- 优先使用标准能力与框架内建能力
- 尽量避免不必要的第三方依赖
- 设计与实现要兼顾网页端、Windows 端和移动端
- 页面、组件、状态和 API 调用需要分层清晰

### 5.2 后端

- 语言：Golang
- Web 框架：Gin
- ORM：Gorm
- 数据库：MySQL、PostgreSQL
- API 风格：RESTful
- 实现约束：尽量避免 CGO，优先纯 Go 方案

选择原则：

- 接口语义清晰，优先资源化设计
- 数据层需要兼容 MySQL 与 PostgreSQL
- 优先控制依赖数量，保持系统可维护性
- 模块设计要支持用户域、社交域和区块链账号扩展解耦演进
- 优先选择纯 Go 驱动和纯 Go 工具链，降低构建、部署和跨平台成本
- 应保持 handler、service、repository、model 的职责清晰

## 6. 前端架构边界

- Web 前端与 Flutter 前端属于并列前端实现层
- 前端负责界面、交互、路由、页面状态和 API 调用
- 前端不直接承担服务端业务判定
- 组件层、页面层、服务调用层应明确分离

## 7. 后端架构边界

- 后端负责业务逻辑、数据访问、鉴权和领域规则
- API 层只做参数接收、响应转换和错误映射
- Service 层负责业务编排
- Repository 层负责数据访问
- Model 层负责领域对象和数据库对象定义
- 后端内部模块边界要避免用户域、社交域、资产域混杂

## 8. 模块划分建议

### 8.1 用户域

- user
- auth
- profile

### 8.2 资产域

- wallet
- membership
- benefit

### 8.3 社交域

- space
- post
- comment
- like
- repost

### 8.4 通信域

- conversation
- message

### 8.5 扩展域

- external_identity
- blockchain_account

## 9. 模块化约束

- 用户域需覆盖账号系统、登录注册、钱包、会员、权益
- 社交域需覆盖空间、聊天、文章发布、浏览、点赞、评论、转发
- 区块链账号接入作为后续扩展域预留，不在首版强耦合到核心账号体系
- 接口、服务、数据模型尽量按领域拆分，避免后续扩展时跨模块牵连过大
- 首版实现应避免将 Web、Windows、移动端逻辑直接耦合在单一前端实现中

## 10. API 与数据约束

- API 采用 `/api/v1/` 版本前缀
- 资源命名使用复数名词
- 返回结构保持统一
- 错误结构保持统一
- 空间采用稳定的 `subdomain` 作为入口标识，文章采用 `space_id` 记录归属空间
- 前端可根据当前子域名自动识别空间上下文，创建与发布动作必须显式携带当前空间信息
- 空间名称与二级域名彼此独立，二级域名前缀只允许英文字母和数字，且最长 63 个字符
- 用户名与空间二级域名共享同一英数字 host label 命名空间，用户名既是登录别名也是个人主页入口句柄 / Username and space subdomains share the same alphanumeric host-label namespace; the username is both a login alias and a profile entry handle.
- 个人空间列表只展示 `source=user` 的空间，历史默认空间通过 `source=system` 隐藏
- 空间编辑、空间删除与文章删除均通过 REST 资源操作完成
- 数据模型需预留扩展字段
- 数据库设计需兼容 MySQL 与 PostgreSQL
- API 变更以 `docs/API_SPEC.md` 为准同步维护
- 数据实体变更以 `docs/DATA_MODEL.md` 为准同步维护

## 11. 第三方库使用策略

- 默认不额外引入第三方库
- 如标准库、Flutter 官方能力、Vue 3 官方生态、Gin、Gorm 已能满足需求，则不再扩展
- 如确需引入，必须先评估必要性、维护成本、许可证和替代方案
- 如依赖需要启用 CGO，应默认视为高成本方案，需单独记录原因
- 聊天媒体能力优先使用浏览器原生文件处理、压缩与预览能力，以及现有纯 Go / Flutter 基础库，避免为了附件功能额外引入媒体 SDK

## 12. 第三方库登记表

当前登记：无

后续新增依赖时，按以下格式追加：

```text
- 名称：
  用途：
  引入原因：
  影响范围：
  维护成本评估：
  是否涉及 CGO：
```

## 13. 架构变更规则

- 技术栈变化必须更新本文件
- 分层变化必须更新本文件
- 模块边界变化必须更新本文件
- 第三方依赖变化必须更新本文件
- API 契约大改必须更新本文件与 API 文档
- 关键实体关系变化必须更新本文件与数据模型文档

## 14. 变更日志

### 2026-03-11

- 新增架构选型记录文件
- 确定前端采用 Flutter、HTML5、CSS3、JavaScript，可使用 Vue 3
- 确定后端采用 Golang、Gin、Gorm，数据库适配 MySQL 与 PostgreSQL
- 确定第三方库从严控制，并要求所有新增依赖登记到本文件
- 增加用户域、社交域和区块链账号扩展能力的模块化约束
- 增加前后端分离约束
- 增加后端优先纯 Go、尽量避免 CGO 的约束
- 增加英文中文双语注释约束
- 补充核心架构原则
- 补充前端、后端边界与模块划分建议
- 补充架构变更规则
- 补充 API 文档与数据模型文档协同规则

### 2026-03-18

- 明确聊天媒体附件优先采用浏览器原生能力与现有基础库实现 / Preferred browser-native media handling and existing base libraries for chat attachments.

### 2026-03-18

- 为空间体系补充 `subdomain` 入口标识和 `space_id` 内容归属约束 / Added `subdomain` entry keys and `space_id` ownership constraints for the space system.
- 补充空间名称与二级域名解耦、个人列表仅展示用户创建空间、以及空间/文章删除的资源化约束 / Added decoupled space naming, user-created-only personal lists, and resource-based deletion constraints for spaces and posts.
