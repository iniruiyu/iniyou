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
- `GET /api/v1/users/username/{username}/profile`
- `GET /api/v1/users/domain/{domain}/profile`
- `PATCH /api/v1/users/{id}`
- `GET /api/v1/users/{id}`
- `GET /api/v1/users/{id}/profile`

### 5.3 空间

- `GET /api/v1/spaces`
- `POST /api/v1/spaces`
- `PATCH /api/v1/spaces/{id}`
- `DELETE /api/v1/spaces/{id}`

说明：

- 空间与内容接口由独立的 `space-service` 提供，默认监听 `http://localhost:8082/api/v1`
- 账号服务仅保留身份、资料与账号管理接口，空间归属与内容上下文由空间服务维护

### 5.4 钱包、会员、权益

- `GET /api/v1/wallets/me`
- `GET /api/v1/wallet-transactions`
- `GET /api/v1/memberships/me`
- `GET /api/v1/benefits`
- `GET /api/v1/benefits/me`

### 5.5 内容与互动

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

### 5.6 聊天

- `GET /api/v1/conversations`
- `GET /api/v1/messages`
- `POST /api/v1/messages`
- `GET /api/v1/unread`

说明：

- 聊天消息支持 `text`、`image`、`video`、`audio` 四种消息类型
- 媒体消息在发送前由前端压缩后再提交，服务端保存压缩后的 payload
- 过期消息会由服务端自动清理，前端无需额外调用删除接口

### 5.7 区块链账号扩展

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
- 说明：`account` 可以是邮箱、手机号、用户名或域名

### 6.2.1 个人资料更新

- `PUT /api/v1/me`
- 用途：修改当前用户的昵称、用户名、域名、签名和资料可见范围
- 请求字段建议：`display_name`, `username`, `domain`, `signature`, `phone_visibility`, `email_visibility`, `age_visibility`, `gender_visibility`
- 说明：
  - `username` 仅允许英文字母和数字，且需要全局唯一
  - `username` 同时作为个人主页和二级域名入口句柄
  - `domain` 仅允许英文字母和数字，且需要全局唯一
  - `domain` 同时作为身份卡、登录入口与二级域名句柄

### 6.3 搜索用户

- `GET /api/v1/users/search?q=keyword`
- 用途：按展示名、邮箱、手机号或用户 ID 搜索用户
- 返回字段建议：`user_id`, `display_name`, `username`, `domain`, `signature`, `email`, `phone`, `age`, `gender`, `relation_status`, `direction`
- 说明：用户名同样应参与搜索与展示，便于按子域名句柄反查用户

### 6.4 用户公开资料

- `GET /api/v1/users/{id}/profile`
- 用途：获取作者主页所需的公开资料与当前关系状态
- 返回字段建议：`user_id`, `display_name`, `username`, `domain`, `signature`, `email`, `phone`, `age`, `gender`, `status`, `relation_status`, `direction`
- `GET /api/v1/users/username/{username}/profile`
- 用途：通过用户名或二级域名句柄获取同一份作者公开资料
- `GET /api/v1/users/domain/{domain}/profile`
- 用途：通过域名身份卡句柄获取同一份作者公开资料

### 6.5 用户文章列表

- `GET /api/v1/users/{id}/posts?visibility=public|private|all&limit=50`
- 用途：获取指定用户的文章列表
- 说明：
  - 公开主页使用 `visibility=public`
  - 当前用户自己的内容列表可使用 `visibility=all`
  - 返回建议补充 `space_id`, `space_user_id`, `space_name`, `space_subdomain`, `space_type`, `space_visibility`，便于页面展示文章所属空间、创建者和可见范围

- `GET /api/v1/users/{id}/spaces?visibility=public|friends|private|all`
- 用途：获取指定用户的空间列表
- 说明：
  - 个人主页仅应使用 `visibility=public`
  - 当前用户自己的空间列表可使用 `visibility=all`
  - 返回结果用于个人主页展示公开空间和空间入口

### 6.6 发布文章

- `POST /api/v1/posts`
- 用途：创建文章
- 请求字段建议：`title`, `content`, `visibility`, `status`, `space_id`, `media_type`, `media_name`, `media_mime`, `media_data`
- 说明：
  - `space_id` 用于记录当前文章所属空间
  - `space_user_id` 应由服务端根据 `space_id` 自动补全
  - 如果前端已进入空间上下文，发布时应优先携带当前空间 ID
  - `visibility` 应与空间可见范围保持一致，避免跨空间发布
  - `media_type` 支持 `image` 和 `video`
  - `media_data` 为图文或小视频的 base64 载荷

### 6.7 更新文章

- `PATCH /api/v1/posts/{id}`
- 用途：更新当前用户自己的文章
- 请求字段建议：`title`, `content`, `visibility`, `status`, `space_id`, `media_type`, `media_name`, `media_mime`, `media_data`
- 状态建议：`draft`, `published`, `hidden`
- 说明：更新文章时应保持空间归属字段可见，便于前端展示当前内容上下文，媒体字段也应原样回传

### 6.8 删除文章

- `DELETE /api/v1/posts/{id}`
- 用途：删除当前用户自己的文章
- 说明：
  - 删除后应同步清理评论、点赞与转发记录
  - 删除入口应由前端在文章卡片或详情页显式触发

### 6.9 评论文章

- `POST /api/v1/posts/{id}/comments`
- 用途：创建评论
- 请求字段建议：`content`, `parent_comment_id`
- 说明：
  - `parent_comment_id` 为空时表示一级评论
  - `parent_comment_id` 不为空时表示对指定评论的楼中楼回复 / When `parent_comment_id` is set, the request creates a threaded reply to that comment

### 6.10 点赞文章

- `POST /api/v1/posts/{id}/likes`
- 用途：切换文章点赞状态
- 返回字段建议：文章对象 + `liked_by_me` + 聚合计数

### 6.11 转发文章

- `POST /api/v1/posts/{id}/shares`
- 用途：记录一次文章转发
- 返回字段建议：文章对象 + 聚合计数

### 6.12 会话列表

- `GET /api/v1/conversations`
- 用途：获取当前用户的聊天会话摘要
- 返回字段建议：`peer_id`, `last_message`, `last_message_type`, `last_message_preview`, `last_at`, `unread_count`
- 排序规则建议：按 `last_at` 倒序返回最近活跃会话
- 说明：
  - `last_message_preview` 优先显示文本内容，媒体消息可降级为 `image` / `video` / `audio` 标签或简短说明
  - 会话摘要仅保留未过期消息

### 6.13 会话消息列表

- `GET /api/v1/messages?peer_id={user_id}&limit=100&offset=0`
- 用途：获取与指定用户的历史消息
- 说明：
  - 指定 `peer_id` 时按当前会话查询
  - 打开会话时先将来自对方的未读消息标记为已读，再返回当前会话历史
  - 返回字段建议：`id`, `sender_id`, `receiver_id`, `message_type`, `content`, `media_name`, `media_mime`, `media_data`, `created_at`, `read_at`, `expires_at`

### 6.14 发送消息

- `POST /api/v1/messages`
- 用途：发送聊天消息并写入会话历史
- 请求字段建议：`peer_id`, `message_type`, `content`, `media_name`, `media_mime`, `media_data`, `expires_in_minutes`
- 说明：
  - `message_type` 默认 `text`
  - `media_data` 为前端压缩后的 base64 payload
  - `expires_in_minutes` 可选；媒体消息未传时由服务端使用默认过期时长

### 6.15 未读统计

- `GET /api/v1/unread`
- 用途：获取当前用户未读消息总数
- 说明：
  - 统计口径仅包含未过期消息
  - 会话列表未读角标应与该接口保持一致

### 6.16 外部账号列表

- `GET /api/v1/external-accounts`
- 用途：获取当前用户已绑定的外部账号列表
- 返回字段建议：`id`, `provider`, `chain`, `account_address`, `binding_status`, `metadata`, `created_at`
- 前端联动建议：
  - 账号主页可展示已绑定账号数量
  - 可按 `chain` 聚合为“已连接链”摘要

### 6.17 绑定外部账号

- `POST /api/v1/external-accounts`
- 用途：绑定区块链账号或其他外部身份
- 请求字段建议：`provider`, `chain`, `account_address`, `signature_payload`
- 当前校验规则：
  - `provider` 与 `chain` 必须命中当前允许列表
  - `account_address` 按不同链做基础格式校验
  - `signature_payload` 为必填，当前按最小长度做基础校验
  - 重复绑定同一活跃账号会返回错误，已解绑账号可由原用户重新激活

### 6.18 解绑外部账号

- `DELETE /api/v1/external-accounts/{id}`
- 用途：解除当前用户自己的外部账号绑定

### 6.19 空间创建与进入

- `GET /api/v1/spaces`
- 用途：获取当前用户可见的空间列表
- 返回字段建议：`id`, `user_id`, `type`, `visibility`, `subdomain`, `name`, `description`, `status`, `created_at`, `updated_at`
- 说明：`subdomain` 仅允许英文字母和数字，且最长 63 个字符
- 说明：前端应统一以“空间”作为入口名称，不再拆分私人/公共页面
- 前端联动建议：
  - 空间列表页用于选择当前进入的空间
  - 空间卡片应展示 `subdomain` 和 `visibility`，并将其作为子域名入口与可见范围标识
  - 空间页应在进入后统一展示单一“空间”入口，并在当前空间上下文内发布内容

- `POST /api/v1/spaces`
- 用途：创建新的空间并设置可见范围
- 请求字段建议：`type`, `visibility`, `name`, `description`, `subdomain`
- 说明：
  - `subdomain` 可由前端预填或由后端根据名称自动生成
  - `subdomain` 只能包含英文字母和数字，且最长 63 个字符
  - 创建成功后返回空间完整信息，前端应将其作为当前进入空间

- `PATCH /api/v1/spaces/{id}`
- 用途：更新当前用户自己的空间名称、描述、二级域名和可见范围
- 请求字段建议：`name`, `description`, `subdomain`, `visibility`
- 说明：
  - 名称、二级域名和可见范围独立修改，二级域名变更后应立即影响子域名入口
  - 仅允许英文字母和数字作为二级域名前缀，且最长 63 个字符

- `DELETE /api/v1/spaces/{id}`
- 用途：删除当前用户自己的空间
- 说明：
  - 删除空间时应级联清理该空间下的文章与互动记录
  - 删除后个人空间列表应立即移除该空间

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
- 补充外部账号绑定的基础安全校验和解绑状态规则
- 补充外部账号在主页和资料页的联动展示建议

### 2026-03-11

- 新增 API 清单文档
- 建立认证、用户、钱包、内容、互动、聊天和外部账号接口草案
