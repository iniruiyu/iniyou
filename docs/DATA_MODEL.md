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
- `account`
- `display_name`
- `avatar_url`
- `bio`
- `status`

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

### 4.3 内容与互动域

#### `posts`

- `id`
- `user_id`
- `title`
- `content`
- `status`
- `visibility`

#### `comments`

- `id`
- `post_id`
- `user_id`
- `parent_comment_id`
- `content`
- `status`

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

### 4.4 聊天域

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
- `sent_at`
- `status`

#### `message_reads`

- `id`
- `message_id`
- `user_id`
- `read_at`

### 4.5 外部身份扩展域

#### `external_accounts`

- `id`
- `user_id`
- `provider`
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
- `posts` 与 `comments` 为一对多关系
- `posts` 与 `post_likes` 为一对多关系
- `posts` 与 `post_shares` 为一对多关系
- `chat_conversations` 与 `chat_participants` 为一对多关系
- `chat_conversations` 与 `chat_messages` 为一对多关系
- `chat_messages` 与 `message_reads` 为一对多关系
- `users` 与 `external_accounts` 为一对多关系

## 6. 当前版本最小必需实体

### 6.1 P0

- `users`
- `auth_credentials`
- `user_profiles`
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
- `wallets.user_id` 唯一索引
- `posts.user_id` 普通索引
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
