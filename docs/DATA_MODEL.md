# 数据实体与关系草案

## 1. 文档用途

本文件用于记录当前版本的数据实体基线，并区分“当前已落地模型”和“后续预留模型”，作为数据库设计和后端领域建模的参考。

## 2. 建模原则

- 优先按领域拆分实体
- 公共字段尽量统一
- 实体之间避免不必要强耦合
- 为后续扩展预留字段和状态位
- 兼容 MySQL 与 PostgreSQL

## 3. 公共字段建议

所有核心实体建议具备以下公共字段：

- `id`
- `created_at`
- `updated_at`
- `deleted_at` 或软删除标记
- `status`

## 4. 当前已落地实体

### 4.1 用户与身份域

#### `users`

- `id`
- `display_name`
- `username`
- `domain`
- `signature`
- `email`
- `phone`
- `age`
- `gender`
- `level`
- `password_version`
- `phone_visibility`
- `email_visibility`
- `age_visibility`
- `gender_visibility`
- `status`

说明：

- `display_name` 是用户昵称，`username` 是登录别名，`domain` 是身份卡与二级域名入口句柄 / `display_name` is the nickname, `username` is the login alias, and `domain` is the identity-card subdomain handle.
- `username` 与 `domain` 都应仅使用英文字母和数字，且与 `spaces.subdomain` 共享同一 host label 命名空间 / `username` and `domain` should both be alphanumeric and share the same host-label namespace as `spaces.subdomain`.
- `email`、`phone`、`age`、`gender` 等字段可根据可见范围控制对外展示 / `email`, `phone`, `age`, and `gender` are exposed according to the configured visibility scope.
- `password_version` 用于 JWT 失效控制，密码修改后会递增该值，从而让旧 token 自动失效 / `password_version` is used for JWT invalidation; it increments after a password change so older tokens expire automatically.
- `password_hash` 当前直接保存在 `users` 表中，尚未拆分为独立凭据表 / `password_hash` currently remains in `users` and has not been split into a separate credentials table yet.

#### `friends`

- `id`
- `user_id`
- `friend_id`
- `status`
- `created_at`

说明：

- 好友关系当前用单表表达请求方向与接受状态，`status` 主要使用 `pending`、`accepted`、`blocked` / Friend requests and accepted relations are currently stored in a single table with directional status values.

### 4.2 订阅与外部身份域

#### `subscriptions`

- `id`
- `user_id`
- `plan_id`
- `status`
- `started_at`
- `ended_at`

说明：

- 当前订阅升级会同时更新 `users.level`，未单独落地 `memberships`、`benefits`、`user_benefits` / Subscription upgrades currently also update `users.level`; separate membership and benefit tables are still reserved.

#### `external_accounts`

- `id`
- `user_id`
- `provider`
- `chain`
- `account_identifier`
- `account_address`
- `binding_status`
- `metadata`

### 4.3 空间与内容域

#### `spaces`

- `id`
- `user_id`
- `type`
- `source`
- `subdomain`
- `name`
- `description`
- `status`
- `visibility`

说明：

- `source` 用于区分用户创建空间与系统种子空间，当前约定为 `user` 或 `system`
- `subdomain` 作为空间入口标识，需要与前端和后端保持一致
- `visibility` 控制空间对当前用户的可见范围，当前约定为 `public`、`friends` 或 `private` / `visibility` controls whether a space is visible to everyone, friends only, or only the owner.
- 当前代码已为 `user_id + type` 配置复合索引，支持按用户与空间类型的回退查询 / The code now uses a composite `user_id + type` index to support fallback queries by user and space type.
- `spaces` 与 `posts` 由独立空间服务管理，账号服务只保留身份域数据

#### `posts`

- `id`
- `user_id`
- `space_id`
- `title`
- `content`
- `media_type`
- `media_name`
- `media_mime`
- `media_data`
- `media_items`
- `status`
- `visibility`

说明：

- `media_items` 建议以 JSON 字符串保存按顺序排列的媒体数组，支持多图或单视频附件 / `media_items` should be stored as a JSON string containing an ordered media array for multi-image or single-video attachments.
- `media_name` 保存服务端实际落盘文件名，`media_items` 中的 `media_name` 也应视为用于文件定位与清理的存储名 / `media_name` stores the server-side on-disk filename, and `media_name` inside `media_items` should also be treated as the storage name used for file lookup and cleanup.
- `media_*` 仍保留为旧版单图兼容字段，并同步第一项媒体信息；服务端会将媒体写入磁盘，同时保留 JSON 载荷以兼容双端 / `media_*` remain as legacy single-media compatibility fields and mirror the first media item; the server writes files to disk while keeping the JSON payload for dual-end compatibility.
- `space_user_id` 不是持久化字段，而是 `PostView` 响应中根据 `space_id` 关联 `spaces.user_id` 生成的派生字段 / `space_user_id` is not a persisted field; it is a derived `PostView` response field populated from `spaces.user_id` via `space_id`.
- `content` 建议按 Markdown 语法存储，前端渲染时保持同一套富文本规则 / `content` should preferably be stored as Markdown syntax so both frontends can render it with the same rich-text rules.
- 当前写接口只接受 `public` 或 `private` 两种文章可见范围，`friends` 仅在读取逻辑里保留兼容判断 / Current write APIs only accept `public` and `private` post visibility; `friends` remains only in read-side compatibility logic.

### 4.4 内容与互动域

#### `comments`

- `id`
- `post_id`
- `user_id`
- `parent_comment_id`
- `content`
- `status`

说明：

- `parent_comment_id` 用于楼中楼回复，空值表示一级评论 / `parent_comment_id` is used for threaded replies, and a null value means a top-level comment.

#### `post_likes`

- `id`
- `post_id`
- `user_id`
- `status`

#### `post_shares`

- `id`
- `post_id`
- `user_id`
- `share_type`
- `status`

### 4.5 聊天域

#### `messages`

- `id`
- `sender_id`
- `receiver_id`
- `message_type`
- `content`
- `media_name`
- `media_mime`
- `media_data`
- `created_at`
- `read_at`
- `expires_at`

说明：

- 当前聊天为点对点消息模型，会话摘要由 `messages` 表按 `sender_id/receiver_id` 聚合得到 / Chat currently uses a direct message model, and conversation summaries are derived from `messages`.
- 未单独拆分 `chat_conversations`、`chat_participants`、`message_reads` / Separate conversation, participant, and read tables have not been introduced yet.

## 5. 实体关系

- `users` 与 `friends` 为一对多关系
- `users` 与 `subscriptions` 为一对多关系
- `users` 与 `posts` 为一对多关系
- `spaces` 与 `posts` 为一对多关系
- `posts` 与 `comments` 为一对多关系，`comments` 通过 `parent_comment_id` 构成树状回复 / `posts` and `comments` are one-to-many, and `comments` form a threaded reply tree through `parent_comment_id`.
- `posts` 与 `post_likes` 为一对多关系
- `posts` 与 `post_shares` 为一对多关系
- `posts.media_*` 与 `posts.media_items` 一起用于承载图文和小视频附件 / `posts.media_*` and `posts.media_items` together carry image and short-video attachments.
- `users` 与 `messages` 分别通过 `sender_id`、`receiver_id` 形成双向一对多关系
- `users` 与 `external_accounts` 为一对多关系

说明：

- `message_type` 用于区分 `text`、`image`、`video`、`audio`
- `media_data` 建议保存前端压缩后的 base64 payload，便于双端直接渲染
- `expires_at` 为空表示长期保存；不为空时由后台定期清理，过期即删除

## 6. 当前版本最小必需实体

### 6.1 P0

- `users`
- `friends`
- `spaces`
- `posts`
- `comments`
- `post_likes`
- `post_shares`
- `messages`

### 6.2 P1

- `subscriptions`
- `external_accounts`

### 6.3 P2

- `wallets`
- `wallet_transactions`
- `memberships`
- `benefits`
- `user_benefits`
- `auth_credentials`
- `user_profiles`
- `chat_conversations`
- `chat_participants`
- `message_reads`

## 7. 索引建议

- `users.email` 唯一索引
- `users.phone` 唯一索引
- `users.username` 唯一索引
- `users.domain` 唯一索引
- `friends.user_id` 普通索引
- `friends.friend_id` 普通索引
- `spaces.subdomain` 唯一索引
- `spaces(user_id, type)` 普通索引
- `subscriptions(user_id, started_at)` 普通索引
- `posts.user_id` 普通索引
- `posts.space_id` 普通索引
- `comments.post_id` 普通索引
- `comments(parent_comment_id)` 普通索引
- `post_likes(post_id, user_id)` 唯一索引
- `messages.sender_id` 普通索引
- `messages.receiver_id` 普通索引
- `messages.read_at` 普通索引
- `messages.expires_at` 普通索引
- `external_accounts(provider, account_identifier)` 唯一索引
- `wallets.user_id` 唯一索引

## 8. 兼容性注意事项

- JSON 扩展字段在 MySQL 与 PostgreSQL 上的处理要统一抽象
- 时间字段需要统一时区策略
- 文本长度与索引长度需要兼容两种数据库
- 自增或主键策略后续统一确定
- 当前后端服务启动采用 GORM `AutoMigrate`，并在账号/空间服务启动后执行用户名与历史空间回填 / The backend services use GORM `AutoMigrate` at startup and then backfill usernames and legacy spaces in the account/space services.

## 9. 文档维护规则

- 新增模块时，必须补充实体与关系
- 字段调整影响接口时，必须同步更新 API 文档
- 字段调整影响页面时，必须同步更新设计文档

## 10. 变更日志

### 2026-03-24

- 将实体清单区分为“当前已落地”与“后续预留” / Split the entity list into implemented and reserved sections.
- 按实际代码收口聊天模型为 `messages` 单表直连方案 / Aligned the chat model to the actual single-table `messages` implementation.
- 明确 `friends`、`subscriptions`、`external_accounts` 已落地，钱包和独立凭据表仍为预留 / Clarified that `friends`, `subscriptions`, and `external_accounts` are implemented, while wallets and separate credential tables remain reserved.

### 2026-03-25

- 收回 `posts.space_user_id` 的持久化误写，并明确该字段只在 `PostView` 中派生 / Removed the mistaken persistent `posts.space_user_id` entry and clarified that the field is only derived in `PostView`.
- 对齐 `spaces(user_id, type)` 复合索引说明与后端实现 / Aligned the `spaces(user_id, type)` composite index note with the backend implementation.

### 2026-03-11

- 新增数据实体与关系草案
- 建立用户、资产、内容、聊天和外部身份五大领域实体基线

### 2026-03-12

- 细化 `external_accounts` 字段，补充 `chain` 与绑定状态表达

### 2026-03-18

- 细化 `chat_messages` 字段，补充媒体消息载荷与过期时间 / Expanded `chat_messages` with media payload and expiry time.

### 2026-03-18

- 新增 `spaces` 实体，补充 `subdomain` 作为空间二级域名标识 / Added the `spaces` entity and its `subdomain` as the second-level domain key.
- 补充 `spaces.source`，用于区分用户创建空间与系统种子空间 / Added `spaces.source` to distinguish user-created spaces from system seeded spaces.
- 为 `posts` 增加 `space_id`，用于记录文章所属空间 / Added `space_id` to `posts` to record content ownership by space.
- 补充空间与内容之间的一对多关系与索引建议 / Added the one-to-many relation and index guidance between spaces and posts.
- 补充 `users.username` 作为个人主页与二级域名入口句柄 / Added `users.username` as the profile and subdomain handle.

### 2026-03-20

- 补充文章媒体真实落盘与物理删除的存储语义 / Added storage semantics for physically persisted article media and deletion cleanup.
- 对齐当前 GORM 模型与数据实体草案，补充 `level`、`subscriptions` 和索引建议 / Aligned the data-model draft with the current GORM models, including `level`, `subscriptions`, and index guidance.
