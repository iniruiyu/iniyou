# 数据实体与关系草案

## 1. 文档用途

本文件用于记录当前版本的核心数据实体、字段方向和实体关系，作为数据库设计和后端领域建模的基线。

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

## 4. 核心实体

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
- `phone_visibility`
- `email_visibility`
- `age_visibility`
- `gender_visibility`
- `status`

说明：

- `display_name` 是用户昵称，`username` 是登录别名，`domain` 是身份卡与二级域名入口句柄 / `display_name` is the nickname, `username` is the login alias, and `domain` is the identity-card subdomain handle.
- `username` 与 `domain` 都应仅使用英文字母和数字，且与 `spaces.subdomain` 共享同一 host label 命名空间 / `username` and `domain` should both be alphanumeric and share the same host-label namespace as `spaces.subdomain`.
- `email`、`phone`、`age`、`gender` 等字段可根据可见范围控制对外展示 / `email`, `phone`, `age`, and `gender` are exposed according to the configured visibility scope.

#### `auth_credentials`

- `id`
- `user_id`
- `credential_type`
- `password_hash`
- `password_salt`
- `status`

#### `user_profiles`

- `id`
- `user_id`
- `nickname`
- `gender`
- `birthday`
- `region`

### 4.2 钱包与权益域

#### `wallets`

- `id`
- `user_id`
- `balance`
- `currency`
- `status`

#### `wallet_transactions`

- `id`
- `wallet_id`
- `transaction_type`
- `amount`
- `balance_after`
- `remark`
- `status`

#### `memberships`

- `id`
- `user_id`
- `level`
- `started_at`
- `expired_at`
- `status`

#### `benefits`

- `id`
- `code`
- `name`
- `description`
- `status`

#### `user_benefits`

- `id`
- `user_id`
- `benefit_id`
- `source_type`
- `started_at`
- `expired_at`
- `status`

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
- `spaces` 与 `posts` 由独立空间服务管理，账号服务只保留身份域数据

#### `posts`

- `id`
- `user_id`
- `space_id`
- `space_user_id`
- `title`
- `content`
- `media_type`
- `media_name`
- `media_mime`
- `media_data`
- `status`
- `visibility`

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

#### `chat_conversations`

- `id`
- `conversation_type`
- `created_by`
- `status`

#### `chat_participants`

- `id`
- `conversation_id`
- `user_id`
- `joined_at`
- `status`

#### `chat_messages`

- `id`
- `conversation_id`
- `sender_user_id`
- `message_type`
- `content`
- `media_name`
- `media_mime`
- `media_data`
- `sent_at`
- `expires_at`
- `status`

#### `message_reads`

- `id`
- `message_id`
- `user_id`
- `read_at`

### 4.6 外部身份扩展域

#### `external_accounts`

- `id`
- `user_id`
- `provider`
- `chain`
- `account_identifier`
- `account_address`
- `binding_status`
- `metadata`

## 5. 实体关系

- `users` 与 `auth_credentials` 为一对多或一对一扩展关系
- `users` 与 `user_profiles` 为一对一关系
- `users` 与 `wallets` 为一对一关系
- `wallets` 与 `wallet_transactions` 为一对多关系
- `users` 与 `memberships` 为一对多或当前有效一对一关系
- `users` 与 `user_benefits` 为一对多关系
- `benefits` 与 `user_benefits` 为一对多关系
- `users` 与 `posts` 为一对多关系
- `spaces` 与 `posts` 为一对多关系
- `posts` 与 `comments` 为一对多关系，`comments` 通过 `parent_comment_id` 构成树状回复 / `posts` and `comments` are one-to-many, and `comments` form a threaded reply tree through `parent_comment_id`.
- `posts` 与 `post_likes` 为一对多关系
- `posts` 与 `post_shares` 为一对多关系
- `posts.media_*` 用于承载图文和小视频附件 / `posts.media_*` carries image and short-video attachments.
- `chat_conversations` 与 `chat_participants` 为一对多关系
- `chat_conversations` 与 `chat_messages` 为一对多关系
- `chat_messages` 与 `message_reads` 为一对多关系
- `users` 与 `external_accounts` 为一对多关系

说明：

- `message_type` 用于区分 `text`、`image`、`video`、`audio`
- `media_data` 建议保存前端压缩后的 base64 payload，便于双端直接渲染
- `expires_at` 为空表示长期保存；不为空时由后台定期清理，过期即删除

## 6. 当前版本最小必需实体

### 6.1 P0

- `users`
- `auth_credentials`
- `user_profiles`
- `spaces`
- `posts`
- `comments`
- `post_likes`
- `post_shares`
- `chat_conversations`
- `chat_participants`
- `chat_messages`

### 6.2 P1

- `wallets`
- `wallet_transactions`
- `memberships`
- `benefits`
- `user_benefits`

### 6.3 P2

- `external_accounts`

## 7. 索引建议

- `users.account` 唯一索引
- `users.username` 唯一索引
- `spaces.subdomain` 唯一索引
- `spaces(user_id, type)` 普通索引
- `wallets.user_id` 唯一索引
- `posts.user_id` 普通索引
- `posts.space_id` 普通索引
- `comments.post_id` 普通索引
- `post_likes(post_id, user_id)` 唯一索引
- `chat_participants(conversation_id, user_id)` 唯一索引
- `chat_messages.conversation_id` 普通索引
- `external_accounts(provider, account_identifier)` 唯一索引

## 8. 兼容性注意事项

- JSON 扩展字段在 MySQL 与 PostgreSQL 上的处理要统一抽象
- 时间字段需要统一时区策略
- 文本长度与索引长度需要兼容两种数据库
- 自增或主键策略后续统一确定

## 9. 文档维护规则

- 新增模块时，必须补充实体与关系
- 字段调整影响接口时，必须同步更新 API 文档
- 字段调整影响页面时，必须同步更新设计文档

## 10. 变更日志

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
