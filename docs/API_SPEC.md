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

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/me`
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

- `GET /api/v1/chats`
- `POST /api/v1/chats`
- `GET /api/v1/chats/{id}`
- `GET /api/v1/chats/{id}/messages`
- `POST /api/v1/chats/{id}/messages`
- `PATCH /api/v1/messages/{id}/read`

### 5.6 区块链账号扩展

- `GET /api/v1/external-accounts`
- `POST /api/v1/external-accounts`
- `DELETE /api/v1/external-accounts/{id}`

## 6. 关键接口说明

### 6.1 注册

- `POST /api/v1/auth/register`
- 用途：创建本地账号
- 请求字段建议：`account`, `password`, `display_name`

### 6.2 登录

- `POST /api/v1/auth/login`
- 用途：用户登录并获取认证态
- 请求字段建议：`account`, `password`

### 6.3 发布文章

- `POST /api/v1/posts`
- 用途：创建文章
- 请求字段建议：`title`, `content`, `status`

### 6.4 评论文章

- `POST /api/v1/posts/{id}/comments`
- 用途：创建评论
- 请求字段建议：`content`, `parent_comment_id`

### 6.5 发送消息

- `POST /api/v1/chats/{id}/messages`
- 用途：发送聊天消息
- 请求字段建议：`content`, `message_type`

### 6.6 绑定外部账号

- `POST /api/v1/external-accounts`
- 用途：绑定区块链账号或其他外部身份
- 请求字段建议：`provider`, `account_address`, `signature_payload`

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

### 2026-03-11

- 新增 API 清单文档
- 建立认证、用户、钱包、内容、互动、聊天和外部账号接口草案
