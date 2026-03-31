# RESTful API 清单

## 1. 文档用途

本文件用于记录当前版本已落地的 RESTful API 与少量已确认预留项，作为前后端联调、后端接口实现和前端页面对接的基线文档。
Flutter 前端与 Legacy Web 前端共用同一套后端接口，所有字段和状态语义都应保持一致。

## 2. 全局规则

- API 统一使用 `/api/v1` 作为版本前缀
- 资源命名采用复数名词
- 请求与响应使用 JSON
- 当前实现统一到 `code/message/data` 包装，业务载荷都放在 `data` 中 / The current implementation uses a `code/message/data` envelope, with all business payloads placed in `data`.
- Flutter 前端与 Legacy Web 前端共享同一套后端 RESTful API，接口变更要同时考虑双端兼容
- 后续新增字段尽量向后兼容

## 3. 统一响应结构

当前实现示例：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "user_id": "uuid",
    "token": "jwt"
  },
  "user_id": "uuid",
  "token": "jwt"
}
```

错误响应示例：

```json
{
  "code": 400,
  "message": "invalid request",
  "error": "invalid request"
}
```

说明：

- 新接口语义以 `data` 为准，列表资源通常读取 `data.items`
- 删除接口当前返回 `200 + {code,message,data}` 风格确认对象，不再返回空 `204`

## 4. 鉴权规则

- 注册、登录接口默认无需登录
- 大多数用户信息、钱包、社交互动、聊天接口需要登录
- 后续区块链账号绑定接口需要登录后发起
- 登录态校验会在中间件层检查账号状态，非 `active` 账号即使持有有效 JWT 也会被拒绝 / The auth middleware also checks account status, so non-`active` accounts are rejected even with a valid JWT.
- 聊天 WebSocket 入口在握手前也会做同样的 JWT + 账号状态校验 / The chat WebSocket entrypoint performs the same JWT + account-status check before upgrade.
- 登录不依赖空间或消息服务在线状态，前端可以先完成账号服务登录，再按健康检查决定是否展示空间/消息入口 / Login does not depend on space or message service availability; the frontend can complete account-service sign-in first and then use health checks to decide whether to show space/message entry points.
- `GET /api/v1/health` 由账号、空间、消息等服务公开，用于前端服务导航与启动刷新时探测在线状态 / `GET /api/v1/health` is exposed by the account, space, and message services for frontend service navigation and startup refresh availability checks.

## 5. 接口分组

### 5.1 认证与账号

- `POST /api/v1/register`
- `POST /api/v1/login`
- `POST /api/v1/logout`
- `GET /api/v1/me`
- `PUT /api/v1/me`
- `PUT /api/v1/me/password`
- `GET /api/v1/users/search`
- `GET /api/v1/users/{id}/profile`
- `GET /api/v1/users/username/{username}/profile`
- `GET /api/v1/users/domain/{domain}/profile`
- `GET /api/v1/friends`
- `POST /api/v1/friends`
- `POST /api/v1/friends/accept`
- `GET /api/v1/subscriptions/current`
- `POST /api/v1/subscriptions`
- `GET /api/v1/external-accounts`
- `POST /api/v1/external-accounts`
- `DELETE /api/v1/external-accounts/{id}`

### 5.2 空间

- `GET /api/v1/spaces`
- `GET /api/v1/users/{id}/spaces`
- `POST /api/v1/spaces`
- `PATCH /api/v1/spaces/{id}`
- `DELETE /api/v1/spaces/{id}`

说明：

- 空间与内容接口由独立的 `space-service` 提供，默认监听 `http://localhost:8082/api/v1`
- 账号服务仅保留身份、资料与账号管理接口，空间归属与内容上下文由空间服务维护

### 5.3 内容与互动

- `GET /api/v1/posts`
- `POST /api/v1/posts`
- `GET /api/v1/posts/{id}`
- `PATCH /api/v1/posts/{id}`
- `DELETE /api/v1/posts/{id}`
- `GET /api/v1/users/{id}/posts`
- `GET /api/v1/spaces/{id}/posts`
- `POST /api/v1/posts/{id}/likes`
- `POST /api/v1/posts/{id}/comments`
- `POST /api/v1/posts/{id}/shares`

说明：

- 文章与互动接口由 `space-service` 提供，默认监听 `http://localhost:8082/api/v1`

### 5.4 学习课程文件

- `GET /api/v1/markdown-files`
- `GET /api/v1/markdown-files/{path}`
- `PUT /api/v1/markdown-files/{path}`
- `DELETE /api/v1/markdown-files/{path}`

说明：

- 学习课程文件接口由独立 `learning-service` 提供，默认监听 `http://localhost:8083/api/v1`
- 仅允许访问与写入 `.md` 文件，`{path}` 为相对存储根目录的多级路径
- 文件内容通过 JSON `content` 字段传输，响应中返回规范化相对路径、内容、大小和更新时间
- `PUT /api/v1/markdown-files/{path}` 当前仅管理员可调用，管理员判断基于 `users.level = admin`
- `DELETE /api/v1/markdown-files/{path}` 当前仅管理员可调用，用于下架某个课程语言版本文件
- 另提供 `POST /api/v1/code-executions/{language}`，用于执行受限示例代码并返回 `stdout`、`stderr`、`exit_code`、`duration_ms` 与 `timed_out`

### 5.5 聊天

- `GET /api/v1/conversations`
- `GET /api/v1/messages`
- `POST /api/v1/messages`
- `GET /api/v1/unread`
- `GET /ws`

说明：

- 当前聊天实现基于 `messages` 单表聚合对话摘要，没有独立 `chat_conversations`、`chat_participants`、`message_reads` 表 / Chat currently derives conversation summaries directly from the `messages` table instead of separate conversation, participant, and read tables.
- 聊天消息支持 `text`、`image`、`video`、`audio` 四种消息类型
- 媒体消息在发送前由前端压缩后再提交，服务端保存压缩后的 payload
- 过期消息会由服务端自动清理，前端无需额外调用删除接口

### 5.6 预留未实现

- 钱包、权益、通用会员资源接口
- 评论编辑与删除接口
- 文章取消点赞独立接口（当前为 `POST /posts/{id}/likes` 切换）
- 用户管理类 `PATCH /users/{id}`、`GET /users/{id}`

### 5.7 健康探针

- `GET /api/v1/health`
- 说明：账号、空间、学习与消息服务均公开该探针，前端服务导航和登录后的服务状态刷新会用它判断入口是否可见 / The account, space, learning, and message services all expose this public probe, and the frontend service navigator plus the post-login refresh flow use it to decide whether an entry should be visible.
- 运维补充：管理员等级设置当前通过本地命令行工具 `backend/cmd/admin-tool` 完成，不暴露公开 REST 接口 / Operations note: administrator level assignment is currently handled by the local CLI tool `backend/cmd/admin-tool` rather than a public REST endpoint.

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
- 说明补充：停用、冻结或其他非 `active` 账号即使密码正确也会被拒绝，接口返回 `403 Forbidden` / Additional note: suspended, frozen, or otherwise non-`active` accounts are rejected even with the correct password, returning `403 Forbidden`.

### 6.2.1 个人资料更新

- `PUT /api/v1/me`
- 用途：修改当前用户的昵称、用户名、域名、头像、出生日期、签名和资料可见范围
- 请求字段建议：`display_name`, `username`, `domain`, `avatar_url`, `birth_date`, `signature`, `phone_visibility`, `email_visibility`, `age_visibility`, `gender_visibility`
- 说明：
  - `display_name` 为必填
  - `username` 仅允许英文字母和数字，且需要全局唯一
  - `username` 同时作为个人主页和二级域名入口句柄
  - `domain` 仅允许英文字母和数字，且需要全局唯一
  - `domain` 同时作为身份卡、登录入口与二级域名句柄
  - `avatar_url` 当前先以图片 URL 接入，后续可无缝切换到上传资源地址
  - `birth_date` 使用 `YYYY-MM-DD`，服务端会基于它推导 `birthday` 与 `age`

### 6.2.2 密码修改

- `PUT /api/v1/me/password`
- 用途：修改当前用户密码并刷新登录态
- 请求字段建议：`current_password`, `new_password`
- 说明：
  - 当前密码校验失败时返回 `401 Unauthorized`
  - 新密码至少应满足最小长度要求，当前实现为 8 个字符
  - 修改成功后服务端会返回新的 `token`
  - 新 token 会携带更新后的密码版本，旧 token 会失效

### 6.3 搜索用户

- `GET /api/v1/users/search?q=keyword`
- 用途：按展示名、用户名、域名、邮箱、手机号、签名或用户 ID 搜索用户
- 返回字段建议：`user_id`, `display_name`, `avatar_url`, `username`, `domain`, `signature`, `email`, `phone`, `age`, `gender`, `relation_status`, `direction`
- 说明：用户名同样应参与搜索与展示，便于按子域名句柄反查用户

### 6.4 用户公开资料

- `GET /api/v1/users/{id}/profile`
- 用途：获取作者主页所需的公开资料与当前关系状态
- 返回字段建议：`user_id`, `display_name`, `avatar_url`, `username`, `domain`, `signature`, `email`, `phone`, `birthday`, `age`, `gender`, `status`, `relation_status`, `direction`
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
- 请求字段建议：`title`, `content`, `visibility`, `status`, `space_id`, `media_type`, `media_name`, `media_mime`, `media_data`, `media_items`
- 说明：
  - `space_id` 用于记录当前文章所属空间
  - `space_user_id` 应由服务端根据 `space_id` 自动补全
  - 发布时必须携带当前用户拥有的 `space_id`
  - 当前实现只接受 `public` 或 `private` 两种文章可见范围
  - `media_type` 支持 `image` 和 `video`
  - `media_items` 支持按顺序提交多张图片或单个视频，服务端会把第一项同步到单图字段
  - 图片上传前应优先等比缩放并压缩，前端可使用随机文件名避免重名
  - `media_data` 为图文或小视频的 base64 载荷
  - `MEDIA_STORAGE_DIR` 用于配置文章媒体的真实落盘目录，默认值为 `D:/codeX/iniyou/uploads/space-service`
  - 服务端会按文章 ID 将媒体写入独立子目录，`media_name` 会被视为服务端存储文件名而不是原始上传名
  - 文章删除、空间删除以及媒体替换时，服务端会同步物理删除不用的文件

### 6.7 更新文章

- `PATCH /api/v1/posts/{id}`
- 用途：更新当前用户自己的文章
- 请求字段建议：`title`, `content`, `visibility`, `status`, `space_id`, `media_type`, `media_name`, `media_mime`, `media_data`, `media_items`, `clear_media`
- 状态建议：`draft`, `published`, `hidden`
- 说明：更新文章时应保持空间归属字段可见，便于前端展示当前内容上下文，媒体字段也应原样回传；当 `clear_media=true` 时，服务端应显式清除旧媒体，而不是沿用已有媒体
- 说明补充：
  - 当前实现只接受 `public` 或 `private` 两种文章可见范围
  - `media_items` 为空且未传 `clear_media=true` 时，服务端会继续沿用现有媒体
  - `media_items` 非空时，服务端会以数组第一项同步 `media_*` 字段
  - `clear_media=true` 时，服务端会显式清除旧媒体并删除对应磁盘文件
  - `media_items` 发生替换后，已移除的媒体文件会在保存成功后被物理删除

### 6.8 删除文章

- `DELETE /api/v1/posts/{id}`
- 用途：删除当前用户自己的文章
- 说明：
  - 删除后应同步清理评论、点赞与转发记录
  - 删除后应同步清理该文章对应的媒体文件
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
- 用途：获取当前用户拥有的空间列表
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
  - `type` 当前必须为 `private` 或 `public`
  - `visibility` 当前支持 `public`、`friends`、`private`，但 `type=private` 时会被强制收口为 `private`
  - 创建成功后返回空间完整信息，前端应将其作为当前进入空间

- `GET /api/v1/spaces/{id}/posts?visibility=public|private|all&limit=50`
- 用途：获取指定空间下的文章列表
- 说明：
  - 空间创建者可使用 `visibility=all` 查看该空间全部文章，包括 `draft` 与 `hidden`
  - 非创建者只能读取当前空间下 `public + published` 的文章

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
  - 删除空间时应同步清理该空间下文章对应的媒体文件
  - 删除后个人空间列表应立即移除该空间

### 6.20 学习课程文件列表

- `GET /api/v1/markdown-files`
- 用途：列出当前学习服务中已落盘的 Markdown 课程文件
- 返回字段建议：`items[].path`, `items[].size`, `items[].updated_at`
- 说明：
  - 接口由 `learning-service` 提供
  - 仅返回 `.md` 文件
  - 路径统一使用相对存储根目录的 `/` 风格分隔

### 6.21 读取学习课程文件

- `GET /api/v1/markdown-files/{path}`
- 用途：按相对路径读取单个 Markdown 课程文件
- 返回字段建议：`path`, `content`, `size`, `updated_at`
- 说明：
  - `{path}` 仅允许安全的多级 `.md` 相对路径
  - 非法路径返回 `400 Bad Request`
  - 文件不存在时返回 `404 Not Found`

### 6.22 保存学习课程文件

- `PUT /api/v1/markdown-files/{path}`
- 用途：创建或覆盖指定路径下的 Markdown 课程文件
- 请求字段建议：`content`
- 返回字段建议：`path`, `content`, `size`, `updated_at`
- 说明：
  - 新文件创建成功返回 `201 Created`
  - 既有文件覆盖成功返回 `200 OK`
  - 服务端只允许写入 `.md` 文件，并将文件落盘到 `MARKDOWN_STORAGE_DIR`（默认位于 `D:/codeX/iniyou/uploads/learning-service/markdown-files`）

### 6.23 执行学习页代码块

- `POST /api/v1/code-executions/{language}`
- 用途：执行学习页中的受限示例代码，并把运行结果回传给前端
- 请求字段建议：`source`
- 返回字段建议：`stdout`, `stderr`, `exit_code`, `duration_ms`, `timed_out`
- 说明：
  - 接口由 `learning-service` 提供，默认监听 `http://localhost:8083/api/v1`
  - 当前仅用于学习示例运行，不是通用远程代码执行平台
  - 当前 `language` 支持 `go`、`javascript`、`python`
  - 当前限制为 32 KB 代码体积、Go 8 秒执行超时、JavaScript/Python 5 秒执行超时、16 KB 输出上限
  - Go 当前会拒绝 `os`、`os/exec`、`net`、`net/http`、`net/url`、`syscall`、`unsafe` 等高风险导入
  - JavaScript 当前会拒绝 `child_process`、`fs`、`net`、`http` 和 `process.exit(...)` 等高风险能力
  - Python 当前会拒绝 `os`、`sys`、`subprocess`、`socket`、`http`、`urllib`、`open(...)` 与 `__import__(...)` 等高风险能力

## 7. 分页与筛选规则

- 列表接口优先支持 `page`、`page_size`
- 可选支持 `sort_by`、`sort_order`
- 条件筛选使用 query 参数

## 8. 状态码建议

- `200 OK`: 查询成功
- `201 Created`: 创建成功
- `400 Bad Request`: 参数错误
- `401 Unauthorized`: 未登录或认证失败
- `403 Forbidden`: 无权限或账号已停用
- `404 Not Found`: 资源不存在
- `409 Conflict`: 状态冲突
- `500 Internal Server Error`: 服务异常

## 9. 文档维护规则

- 新增模块时，必须补充对应 API 分组
- 页面新增或调整涉及接口时，必须同步更新本文件
- 数据模型或权限规则变化影响接口时，必须同步更新本文件

## 10. 变更日志

### 2026-03-24

- 将文档口径从“目标草案”收口为“当前实现 + 预留项” / Refocused the document from aspirational API draft to current implementation plus reserved items.
- 明确当前响应结构为直接 JSON，而非统一包装 / Clarified that current responses are direct JSON objects rather than a unified envelope.
- 对齐好友、订阅、空间文章、WebSocket 与未实现接口边界 / Aligned friend, subscription, space-post, WebSocket, and unimplemented interface boundaries.

### 2026-03-25

- 后端统一返回 `code/message/data` 包装，业务载荷都放在 `data` 中 / The backend now emits a `code/message/data` envelope with business payloads placed in `data`.

### 2026-03-27

- 新增独立 `learning-service` 的 Markdown 文件列表、读取与保存接口，并明确默认服务地址为 `http://localhost:8083/api/v1` / Added independent `learning-service` Markdown file list, read, and save endpoints, and clarified the default service base as `http://localhost:8083/api/v1`.

### 2026-03-30

- 新增 `POST /api/v1/code-executions/go`，供学习页内的 Go 代码块点击执行并内嵌展示输出 / Added `POST /api/v1/code-executions/go` so the learning page can run Go code blocks on click and show inline output.
- 将学习页代码执行扩展为 `go`、`javascript`、`python` 三种语言，并统一到 `POST /api/v1/code-executions/{language}` / Expanded learning-page code execution to `go`, `javascript`, and `python`, unified behind `POST /api/v1/code-executions/{language}`.

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

### 2026-03-20

- 补充文章媒体真实落盘目录配置 `MEDIA_STORAGE_DIR`
- 明确文章删除、空间删除与媒体替换时会同步物理删除磁盘文件

### 2026-03-11

- 新增 API 清单文档
- 建立认证、用户、钱包、内容、互动、聊天和外部账号接口草案
