# 08 聊天系统

## 1. 目标

完成基础聊天能力，支持用户之间进行消息交流。

## 2. 状态

- 状态：已完成

## 3. 任务清单

- 设计聊天会话模型
- 设计消息模型
- 设计聊天列表与会话详情接口
- 实现基础消息发送与接收流程
- 建立前端聊天列表页与会话页
- 处理消息状态、时间排序和基础已读机制
- 为后续实时优化和扩展能力预留接口
- 优化聊天页全屏布局与消息滚动体验
- 提供表情/贴纸快捷插入入口

## 3.1 下一轮待办拆分

- `08A` 会话列表与消息预览
  - 当前状态：已完成
  - 新增会话列表接口
  - 展示最近消息、最近时间、未读数量
- `08B` 会话详情与消息发送
  - 当前状态：已完成
  - 完善会话详情页
  - 保证历史消息与实时消息一致
- `08C` 已读状态与排序规则
  - 当前状态：已完成
  - 统一未读计数、打开会话已读和会话排序
- `08D` 媒体附件与过期删除
  - 当前状态：已完成
  - 新增图片、视频、语音消息支持
  - 支持发送前压缩并在到期后自动删除
- `08E` 新好友提醒与未读提示
  - 当前状态：已完成
  - 新好友浮动提醒
  - 新消息图标角标提示
- `08F` 双端聊天布局优化
  - 当前状态：已完成
  - 桌面端双栏聊天布局
  - 移动端单栏收敛布局
- `08G` 表情与贴纸快捷插入
  - 当前状态：已完成
  - 常用表情一键插入
  - 贴纸快捷片段一键插入
- `08H` 回到底部按钮与滚动条美化
  - 当前状态：已完成
  - 提供回到底部浮动按钮
  - 美化右侧滚动条视觉样式

## 4. 完成标准

- 用户之间可以发起并完成基础聊天
- 聊天页面与接口可用
- 聊天模块可继续扩展
- 聊天页可全屏占满可用区域，消息记录支持滚动/滑动查看
- 表情与贴纸快捷入口可直接插入到聊天输入框
- 长历史聊天页提供回到底部浮动按钮，并优化滚动条视觉样式

## 5. 进度记录

- 2026-03-20：继续升级 Flutter 聊天好友资料弹层，改为打开即加载、宽屏双栏、失败可重试的公开空间入口面板 / Continued upgrading the Flutter chat friend-profile dialog into an open-immediately, dual-column, retryable public-space entry panel.
- 2026-03-20：将 Flutter 聊天好友资料弹层改成可滚动的响应式布局，避免小屏下空间卡片和进入按钮被裁切 / Made the Flutter chat friend-profile dialog scrollable and responsive so small screens no longer clip space cards or the enter button.
- 2026-03-20：继续收紧 Flutter 聊天好友资料弹层，改为轻量预览并移除自动拉取公开空间，避免点击资料时触发 Web 端卡死 / Continued tightening the Flutter chat friend-profile dialog into a lightweight preview and removed the automatic public-space fetch to avoid Web freezes when opening the profile.
- 2026-03-20：进一步简化 Flutter 聊天好友资料弹层，去掉公开空间列表和重绘链路，只保留好友资料轻量预览与“查看主页”入口 / Further simplified the Flutter chat friend-profile dialog by removing the public-space list and rebuild chain, leaving only a lightweight profile preview and an "open profile" entry.
- 2026-03-18：拆分聊天媒体附件、过期删除、新好友提醒与双端布局优化任务 / Split chat media attachments, expiry cleanup, new-friend reminders, and dual-end layout optimization tasks.
- 2026-03-18：完成聊天页全屏布局、消息滚动与表情/贴纸快捷插入 / Completed full-screen chat layout, message scrolling, and emoji/sticker quick inserts.
- 2026-03-18：补充 Vue 聊天页全高壳层，确保长消息列表下发送按钮始终可见 / Added a full-height Vue chat shell so the send box stays visible with long histories.
- 2026-03-18：补充 Vue 聊天页回到底部浮动按钮并美化右侧滚动条 / Added a back-to-bottom floating button and polished the right-side scrollbar in the Vue chat view.
