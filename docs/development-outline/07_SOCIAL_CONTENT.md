# 07 社交内容与互动体系

## 1. 目标

完成文章发布、浏览和互动能力，建立社交内容核心闭环。

## 2. 状态

- 状态：进行中
- 已完成：
  - 文章发布
  - 公共文章列表
  - 文章详情接口
  - 点赞功能
  - 评论功能
  - 转发功能
  - 基础 RESTful API
  - 前端公共内容流与互动组件
  - 个人主页内容展示
  - 空间创建、进入、改名、改域名与删除
  - 空间二级域名展示与当前上下文记录
  - 空间入口统一为“空间”，私人/公共作为页面内分区展示
  - 内容删除
  - 文章编辑弹窗化，支持媒体清除与图片等比缩放
  - Vue 文章发布与编辑支持多图片上传、可删除画廊和随机文件名
  - 文章媒体真实落盘到可配置目录，并在删除文章、删除空间或替换媒体时物理清理服务器文件
  - Flutter 文章发布与编辑支持多图画廊，双前端文章正文统一按 Markdown 渲染
- 双前端空间工作台折叠为顶部按钮，进入具体空间后自动收起，Vue 空间内容流移除冗余说明 / Collapsed the dual-frontend space workspace into a top button that auto-collapses after entering a specific space, and removed redundant Vue feed copy
- 双前端空间页移除内容流 / 当前空间设置说明卡，并把文章图片缩放上限明确为 1600px / Removed the space feed/current-space-settings info cards in both frontends and made the 1600px article image scaling cap explicit
- Vue 从主页导航进入“空间”时保持侧边导航可见，空间首页不再展示空状态卡 / Vue now keeps the sidebar visible when entering “Space” from home navigation, and the space home no longer shows the empty-state card
- Vue 主页“空间”按钮改为显式空参调用，避免事件对象误判为具体空间 / Vue home “Space” button now uses an explicit no-arg call to avoid misreading the click event as a space object
- Vue 进入具体空间后改为全宽主容器铺满窗口，避免左侧保留空白列 / Vue specific-space pages now use a full-width main container to avoid leaving a blank left column.
- Vue 具体空间页进一步改为视口级固定主容器，并通过样式版本号避免浏览器继续命中旧布局缓存 / Vue specific-space pages now use a viewport-fixed main container, and the stylesheet version is bumped to avoid stale layout caching.
- Vue 从好友资料弹窗进入好友空间时会先关闭资料层，弹窗内“进入空间”按钮也统一走好友空间专用入口，再切换到空间页 / Vue now closes the friend profile layer before entering a friend's space, and the modal's "enter space" button also uses the dedicated friend-space entry path.
- Flutter 聊天好友资料弹窗进入好友空间时也会先关闭弹窗，并通过根导航器确保空间页切换后不残留资料层 / Flutter now also closes the chat friend-profile dialog before entering a friend space, using the root navigator so no profile layer remains after switching pages.
- 双前端个人主页已收敛为摘要页，只展示个人资料、隐私设置、会员等级与公开空间入口，不再展示内容流 / Both frontends' profile pages are now summary pages that only show personal info, privacy settings, membership level, and public space entrances, without a content feed.
- Vue 进入好友空间或自己创建的空间后，空间壳层会收为单列并固定铺满整个视口，样式地址也会通过版本号刷新以避免浏览器命中旧布局缓存 / After entering a friend's space or one of your own spaces, Vue now collapses the shell into a single column and pins the main content to the full viewport, with a versioned stylesheet URL to avoid stale layout caching.
- 主导航“主页”入口已固定进入当前登录用户自己的主页，他人主页保留独立打开路径 / The main-nav "Profile" entry now always opens the current user's own profile, while other profiles keep a separate open path.
- 进行中：
  - 内容状态与审核预留
- 待完成：
  - 内容审核流与后台处理

## 3.1 下一轮待办拆分

- `07D` 空间体系与空间内内容
  - 当前状态：已完成
  - 创建私人空间与公共空间
  - 生成并展示空间二级域名
  - 在统一空间上下文内发布和浏览内容
  - 文章记录所属空间
  - 修改空间名称与二级域名
  - 删除空间
  - 删除文章
- `07A` 个人主页内容展示
  - 当前状态：已完成
  - 新增按用户查询文章列表接口
  - 提供当前用户内容列表与他人主页内容列表
  - 前端补充个人内容展示区
  - 已实现：从公共内容流进入作者主页并查看其公开文章
  - 已实现：作者主页头部信息、文章数量、好友聊天入口
  - 已实现：作者主页中的加好友、接受好友与状态刷新
- `07B` 文章详情与编辑
  - 当前状态：已完成
  - `07B-1` 文章详情页视图
    - 从内容流进入文章详情
    - 展示文章正文、互动计数、评论列表
    - 支持从详情页执行点赞、评论、转发
    - 当前状态：已完成
  - `07B-2` 文章编辑能力
    - 当前用户可编辑自己的文章
    - 支持更新标题、正文、可见范围与媒体清除
    - 当前状态：已完成（弹窗编辑、clear_media、多图上传、Markdown 正文渲染、图片等比缩放、随机命名、真实落盘与物理删除清理）
  - `07B-3` 可见范围细化
    - 在详情与列表中统一公开/私密文章访问规则
    - 当前状态：已完成
- `07C` 内容状态与审核预留
  - 细化 `draft`、`published`、`hidden` 等状态
  - 为审核字段和后台处理预留结构
  - 当前状态：基础完成
  - 已实现：文章创建与编辑支持 `draft`、`published`、`hidden`
  - 已实现：列表与详情按状态执行基础可见性控制

## 3.2 当前建议优先级

- 优先处理：`07C` 内容状态与审核预留
- 原因：空间主链路已经收口，当前剩余工作更集中在内容状态细化与审核能力预留上

## 3. 任务清单

- 实现文章发布
- 实现文章列表与详情
- 实现个人主页内容展示
- 实现空间创建、进入与空间上下文记录
- 实现空间名称、二级域名和删除能力
- 实现文章删除
- 实现空间入口合并与页面内分区展示
- 实现点赞功能
- 实现评论功能
- 实现转发功能
- 设计内容审核与状态字段预留
- 建立对应 RESTful API
- 建立前端内容流、详情页和互动组件

## 4. 完成标准

- 用户可以发布和浏览文章
- 用户可以进行点赞、评论、转发互动
- 内容模块具备后续扩展能力
