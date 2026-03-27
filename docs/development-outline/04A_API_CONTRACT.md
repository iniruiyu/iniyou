# 04A RESTful API 契约整理与维护

## 1. 目标

完成 RESTful API 契约梳理，建立前后端联调和后端实现的统一接口基线。

## 2. 状态

- 状态：进行中
- 当前基线：API 契约清单、统一响应、鉴权边界和主要接口分组已建立 / API contract, unified responses, auth boundaries, and major endpoint groups are established.
- 当前基线补充：学习课程 Markdown 文件接口已从空间接口中拆分，独立归属 `learning-service` / Baseline update: learning-course Markdown file APIs are split out of the space APIs and now belong to `learning-service`.
- 进行中：与最新需求、数据模型和页面映射逐项复核 / In progress: reconciling the latest requirements, data model, and page mapping.

## 3. 任务清单

- 根据需求文档整理 API 资源清单
- 根据架构文档统一接口命名与版本规则
- 统一响应结构和错误结构
- 明确鉴权接口与免鉴权接口
- 明确分页、筛选、排序规则
- 将账户、资产、内容、互动、聊天、外部身份接口完整补齐
- 将学习课程 Markdown 文件的列表、读取、保存接口纳入 API 契约
- 确保 API 文档与数据模型文档相互对应
- 确保 API 文档与页面设计映射一致

## 4. 完成标准

- `docs/API_SPEC.md` 可作为联调和开发基线
- 核心模块接口覆盖完整
- 与需求、架构、设计文档口径一致
