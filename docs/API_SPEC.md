# RESTful API 清单

## 1. 文档用途

本文件用于记录当前版本的 RESTful API 草案，作为前后端联调、后端接口实现和前端页面对接的基线文档。

## 2. 全局规则

- API 统一使用 `/api/v1` 作为版本前缀
- 资源命名采用复数名词
- 请求与响应使用 JSON
- 接口返回结构保持统一
- 后续新增字段尽量向后兼容

## 3. 统一响应结构

成功响应：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

失败响应：

```json
{
  "code": 1000,
  "message": "error message",
  "error": {
    "type": "validation_error",
    "details": {}
  }
}
```

## 4. 鉴权规则

- 注册、登录接口默认无需登录
- 大多数用户信息、钱包、社交互动、聊天接口需要登录
- 后续区块链账号绑定接口需要登录后发起

## 5. 接口分组

### 5.1 健康检查

- `GET /api/v1/health`

### 5.2 认证与账号

- `POST /api/v1/register`
- `POST /api/v1/login`
- `POST /api/v1/logout`
- `GET /api/v1/me`
- `PUT /api/v1/me`
- `GET /api/v1/users/search`
- `PATCH /api/v1/users/{id}`
- `GET /api/v1/users/{id}`
- `GET /api/v1/users/{id}/profile`

### 5.3 钱包、会员、权益

- `GET /api/v1/wallets/me`
- `GET /api/v1/wallet-transactions`
- `GET /api/v1/memberships/me`
- `GET /api/v1/benefits`
- `GET /api/v1/benefits/me`

### 5.4 内容与互动

- `GET /api/v1/posts`
- `POST /api/v1/posts`
- `GET /api/v1/posts/{id}`
- `PATCH /api/v1/posts/{id}`
- `DELETE /api/v1/posts/{id}`
- `GET /api/v1/users/{id}/posts`
- `POST /api/v1/posts/{id}/likes`
- `DELETE /api/v1/posts/{id}/likes`
- `GET /api/v1/posts/{id}/comments`
- `POST /api/v1/posts/{id}/comments`
- `PATCH /api/v1/comments/{id}`
- `DELETE /api/v1/comments/{id}`
- `POST /api/v1/posts/{id}/shares`

### 5.5 聊天

- `GET /api/v1/conversations`
- `GET /api/v1/messages`
- `POST /api/v1/messages`
- `GET /api/v1/unread`

### 5.6 区块链账号扩展

- `GET /api/v1/external-accounts`
- `POST /api/v1/external-accounts`
- `DELETE /api/v1/external-accounts/{id}`

## 6. 关键接口说明

### 6.1 注册

- `POST /api/v1/register`
- 用途：创建本地账号
- 请求字段建议：`email`, `phone`, `password`

### 6.2 登录

- `POST /api/v1/login`
- 用途：用户登录并获取认证态
- 请求字段建议：`account`, `password`

### 6.3 搜索用户

- `GET /api/v1/users/search?q=keyword`
- 用途：按展示名、邮箱、手机号或用户 ID 搜索用户
- 返回字段建议：`user_id`, `display_name`, `email`, `phone`, `relation_status`, `direction`

### 6.4 用户公开资料

- `GET /api/v1/users/{id}/profile`
- 用途：获取作者主页所需的公开资料与当前关系状态
- 返回字段建议：`user_id`, `display_name`, `email`, `phone`, `status`, `relation_status`, `direction`

### 6.5 用户文章列表

- `GET /api/v1/users/{id}/posts?visibility=public|private|all&limit=50`
- 用途：获取指定用户的文章列表
- 说明：
  - 公开主页使用 `visibility=public`
  - 当前用户自己的内容列表可使用 `visibility=all`

### 6.6 发布文章

- `POST /api/v1/posts`
- 用途：创建文章
- 请求字段建议：`title`, `content`, `visibility`, `status`

### 6.7 更新文章

- `PATCH /api/v1/posts/{id}`
- 用途：更新当前用户自己的文章
- 请求字段建议：`title`, `content`, `visibility`, `status`
- 状态建议：`draft`, `published`, `hidden`

### 6.8 评论文章

- `POST /api/v1/posts/{id}/comments`
- 用途：创建评论
- 请求字段建议：`content`

### 6.9 点赞文章

- `POST /api/v1/posts/{id}/likes`
- 用途：切换文章点赞状态
- 返回字段建议：文章对象 + `liked_by_me` + 聚合计数

### 6.10 转发文章

- `POST /api/v1/posts/{id}/shares`
- 用途：记录一次文章转发
- 返回字段建议：文章对象 + 聚合计数

### 6.11 会话列表

- `GET /api/v1/conversations`
- 用途：获取当前用户的聊天会话摘要
- 返回字段建议：`peer_id`, `last_message`, `last_at`, `unread_count`
- 排序规则建议：按 `last_at` 倒序返回最近活跃会话

### 6.12 会话消息列表

- `GET /api/v1/messages?peer_id={user_id}&limit=100&offset=0`
- 用途：获取与指定用户的历史消息
- 说明：
  - 指定 `peer_id` 时按当前会话查询
  - 打开会话时先将来自对方的未读消息标记为已读，再返回当前会话历史

### 6.13 发送消息

- `POST /api/v1/messages`
- 用途：发送聊天消息并写入会话历史
- 请求字段建议：`peer_id`, `content`

### 6.14 未读统计

- `GET /api/v1/unread`
- 用途：获取当前用户未读消息总数

### 6.15 外部账号列表

- `GET /api/v1/external-accounts`
- 用途：获取当前用户已绑定的外部账号列表
- 返回字段建议：`id`, `provider`, `chain`, `account_address`, `binding_status`, `metadata`, `created_at`

### 6.16 绑定外部账号

- `POST /api/v1/external-accounts`
- 用途：绑定区块链账号或其他外部身份
- 请求字段建议：`provider`, `chain`, `account_address`, `signature_payload`

### 6.17 解绑外部账号

- `DELETE /api/v1/external-accounts/{id}`
- 用途：解除当前用户自己的外部账号绑定

## 7. 分页与筛选规则

- 列表接口优先支持 `page`、`page_size`
- 可选支持 `sort_by`、`sort_order`
- 条件筛选使用 query 参数

## 8. 状态码建议

- `200 OK`: 查询成功
- `201 Created`: 创建成功
- `400 Bad Request`: 参数错误
- `401 Unauthorized`: 未登录或认证失败
- `403 Forbidden`: 无权限
- `404 Not Found`: 资源不存在
- `409 Conflict`: 状态冲突
- `500 Internal Server Error`: 服务异常

## 9. 文档维护规则

- 新增模块时，必须补充对应 API 分组
- 页面新增或调整涉及接口时，必须同步更新本文件
- 数据模型或权限规则变化影响接口时，必须同步更新本文件

## 10. 变更日志

### 2026-03-12

- 同步当前已实现的认证接口路径
- 补充 `PUT /api/v1/me`、文章点赞和转发接口说明
- 更新文章发布与评论请求字段说明
- 补充作者主页使用的公开资料接口与用户文章列表接口
- 补充文章更新接口与文章状态字段说明
- 将聊天接口清单同步为 `conversations`、`messages`、`unread` 的实际实现
- 明确聊天会话排序与打开会话已读规则
- 新增外部账号列表、绑定、解绑接口的当前实现说明

### 2026-03-11

- 新增 API 清单文档
- 建立认证、用户、钱包、内容、互动、聊天和外部账号接口草案
