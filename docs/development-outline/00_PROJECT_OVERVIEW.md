# 00 项目开发总览

## 1. 文档用途

本目录用于记录项目开发大纲。目录内所有任务文件共同构成项目实施清单。完成本目录中定义的全部任务，即视为完成当前版本项目。

## 2. 使用规则

- 任务按序号推进
- 后续需求变化时，可以新增新的序号文件，或补充现有文件
- 已存在任务如果发生调整，需要直接更新对应文件
- 若某项任务完成，应在对应文件中更新状态
- 新需求提出后，必须先记录到对应 `md` 文档，再进入评估或开发
- 若当前任务未完成，优先收口当前任务并提交代码，再拆分后续需求
- 需求拆分完成后，需要把新增待办同步记录到开发大纲，再开始开发

## 3. 当前任务列表

- `01_FOUNDATION_SETUP.md`: 项目基础搭建与工程规范
- `02_FRONTEND_ARCHITECTURE.md`: 前端架构与工程初始化
- `03_BACKEND_ARCHITECTURE.md`: 后端架构与工程初始化
- `04_DATA_MODEL_AND_DATABASE.md`: 数据模型与数据库设计
- `04A_API_CONTRACT.md`: RESTful API 契约整理与维护
- `05_ACCOUNT_AND_IDENTITY.md`: 用户、账号、登录注册体系
- `06_WALLET_MEMBERSHIP_BENEFITS.md`: 钱包、会员、权益体系
- `07_SOCIAL_CONTENT.md`: 社交内容与互动体系
- `08_CHAT_SYSTEM.md`: 聊天系统
- `09_BLOCKCHAIN_ACCOUNT_EXTENSION.md`: 区块链账号接入扩展
- `10_TESTING_DEPLOYMENT_AND_DELIVERY.md`: 测试、部署与交付

## 4. 完成标准

- 本目录中的所有任务都已完成
- 各任务产出与当前需求文档保持一致
- 各任务产出与 API 文档、数据模型文档保持一致
- 若新增需求影响项目范围，需先更新需求文档，再补充本目录任务

## 5. 当前状态

- 状态：进行中
- 更新时间：2026-03-20

当前仓库已经进入收口与交付准备阶段，当前重点是数据模型、账号安全、内容状态和 `make smoke` 留档 / The project is now in wrap-up and delivery-prep, with data model, account security, content status, and `make smoke` evidence as current priorities.

## 6. 下一步任务

- 优先收口 `04_DATA_MODEL_AND_DATABASE.md`
- 优先收口 `05_ACCOUNT_AND_IDENTITY.md`
- 继续补完 `07_SOCIAL_CONTENT.md` 中的 `07C` 内容状态与审核预留
- 完整实跑 `make smoke` 并回写 `RELEASE_CHECKLIST.md`
