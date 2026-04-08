# 01 项目基础搭建与工程规范

## 1. 目标

建立前后端分离项目基础骨架，统一目录结构、代码规范、文档规范和开发约束。

## 2. 状态

<<<<<<< ours
- 状态：进行中
- 当前基线：前后端分离目录规范、代码规范、文档规范和依赖控制原则已建立 / The directory split, coding, documentation, and dependency-control baseline is in place.
- 进行中：补齐 `shared/` 目录、依赖登记流程和 Git 提交流程的最终收口 / In progress: finalizing the `shared/` directory, dependency registration flow, and Git workflow.
=======
- 状态：已完成
- 完成时间：2026-03-12
>>>>>>> theirs

## 3. 任务清单

- [x] 初始化 `frontend/`、`backend/`、`shared/` 目录
- [x] 建立前后端分离目录规范
- [x] 建立代码风格规范
- [x] 建立英文中文双语注释规范
- [x] 建立依赖引入登记流程
- [x] 建立纯 Go 与避免 CGO 的检查原则
- [x] 建立基础环境变量约定
- [x] 建立基础 Git 提交流程与分支规范

## 4. 执行记录

- 已建立项目核心目录：`frontend/`、`backend/`、`shared/`。
- 基础规范已固化到仓库根文档：
  - `README.md`：仓库结构与维护规则
  - `docs/ARCHITECTURE_DECISIONS.md`：架构约束、依赖与分层原则
  - `docs/PROJECT_PLAN.md`：项目阶段与工程边界
- 当前代码已按前后端分离方式落地，支持后续按模块继续扩展。

## 5. 完成标准

- [x] 项目目录结构清晰可用
- [x] 文档与目录规范一致
- [x] 后续开发可直接在此基础上推进
