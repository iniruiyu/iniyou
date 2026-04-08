# 02 前端架构与工程初始化

## 1. 目标

完成前端工程的基础架构设计与初始化，支持 Web、Windows 和移动端，并保持前端内部结构清晰。

## 2. 状态

<<<<<<< ours
- 状态：进行中
- 当前基线：Flutter 与 Vue 3 的职责边界、页面映射和 API 对接关系已定义，Vue 的服务导航页和个人主页相关浮层已拆成独立组件 / Flutter vs. Vue responsibilities, page mapping, and API linkage are already defined, and the Vue service navigation page plus profile-related overlays have been split into standalone components.
- 进行中：前端工程初始化、公共组件目录和页面骨架补齐 / In progress: frontend bootstrapping, shared component folders, and page scaffolding.

## 3. 任务清单

- 明确 Flutter 与 Vue 3 的职责边界
- 定义前端应用结构、路由结构与状态管理边界
- 定义跨端页面复用策略
- 初始化前端工程目录
- 建立公共组件目录与页面目录
- 建立 API 请求封装规范
- 建立设计稿到页面实现的映射关系
- 建立页面与 `docs/API_SPEC.md` 的对接映射
- 继续把 Vue 大页面/大区块拆成职责单一的小组件，减少 `app.js` 和根模板的膨胀 / Continue splitting large Vue pages and blocks into single-responsibility components to keep `app.js` and the root template lean.
- 继续把 Vue 个人主页相关页面、弹层和卡片拆成职责单一的小组件，避免个人资料编辑和会员切换继续堆在主页面里 / Continue splitting Vue profile pages, overlays, and cards into single-responsibility components so profile editing and membership switching do not keep piling into the main page.
- 为登录、注册、首页、文章、聊天、个人中心预留页面结构

## 4. 完成标准

- 前端工程可启动
- 页面结构可持续扩展
- 跨端实现策略清晰
=======
- 状态：已完成
- 完成时间：2026-03-12

## 3. 任务清单

- [x] 明确 Flutter 与 Vue 3 的职责边界
- [x] 定义前端应用结构、路由结构与状态管理边界
- [x] 定义跨端页面复用策略
- [x] 初始化前端工程目录
- [x] 建立公共组件目录与页面目录
- [x] 建立 API 请求封装规范
- [x] 建立设计稿到页面实现的映射关系
- [x] 建立页面与 `docs/API_SPEC.md` 的对接映射
- [x] 为登录、注册、首页、文章、聊天、个人中心预留页面结构

## 4. 执行记录

- 前端工程已初始化在 `frontend/`，并完成基础页面与交互实现。
- 前端跨端策略、页面结构、交互映射已沉淀在 `docs/design/FRONTEND_DESIGN.md`。
- 页面功能边界与接口契约由 `docs/API_SPEC.md` 对齐维护。
- 前端已内建多语言机制和 `dir` 方向切换能力（含 RTL 预留）。

## 5. 完成标准

- [x] 前端工程可启动
- [x] 页面结构可持续扩展
- [x] 跨端实现策略清晰
>>>>>>> theirs
