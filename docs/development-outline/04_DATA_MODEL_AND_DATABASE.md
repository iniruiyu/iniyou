# 04 数据模型与数据库设计

## 1. 目标

完成核心领域模型和数据库结构设计，支持当前需求并为后续扩展预留空间。

## 2. 状态

<<<<<<< ours
- 状态：进行中
- 已完成：空间实体与文章所属空间关系已在实现层落地，`spaces.source` 与 `posts.space_id` 已接通；`spaces.user_id + type` 复合索引已接通；版本化迁移命令 `make migrate` 已接通；用户用户名与二级域名共享的 host label 约束已接通；账号/空间/消息服务已在启动时使用 GORM `AutoMigrate`；空间删除与文章删除的级联清理已接通；`docs/DATA_MODEL.md` 已按当前代码收口为“已实现实体 + 预留实体”口径，并修正 `posts.space_user_id` 的派生字段说明
- 进行中：版本化回滚脚本补齐、预留实体的落地优先级排序 / In progress: versioned rollback scripts and prioritizing which reserved entities should be implemented next

## 3. 任务清单

- 梳理用户域数据模型
- 梳理用户用户名与空间二级域名共享命名空间规则
- 梳理空间数据模型与文章所属空间关系
- 梳理钱包、会员、权益数据模型
- 梳理文章、点赞、评论、转发数据模型
- 梳理聊天会话与消息数据模型
- 预留区块链账号绑定模型
- 将实体与 `docs/API_SPEC.md` 建立映射关系
- 将实体与前端页面输入输出建立映射关系
- 设计表结构命名规范
- 设计公共字段规范
- 设计索引策略
- 设计显式迁移与回填方案
- 设计版本化回滚方案
- 评估 MySQL 与 PostgreSQL 差异并做兼容处理

## 4. 完成标准

- 数据模型覆盖现有需求
- 表结构可扩展
- 数据库迁移策略明确，且显式迁移命令可独立执行
- 版本化迁移台账可记录已执行步骤
- `docs/DATA_MODEL.md` 可作为数据库和后端建模基线

## 5. 下一步

- 继续收口版本化回滚脚本说明，明确哪些变更需要前向与回滚脚本 / Continue closing the versioned rollback-script plan and clarify which changes need explicit forward and rollback scripts.
- 如后续需要更完整的迁移框架，再把当前版本化脚本收口为正式迁移目录结构 / If a fuller migration framework is needed later, wrap the current versioned scripts into a formal migration-directory structure.
=======
- 状态：已完成
- 完成时间：2026-03-12

## 3. 任务清单

- [x] 梳理用户域数据模型
- [x] 梳理钱包、会员、权益数据模型
- [x] 梳理文章、点赞、评论、转发数据模型
- [x] 梳理聊天会话与消息数据模型
- [x] 预留区块链账号绑定模型
- [x] 将实体与 `docs/API_SPEC.md` 建立映射关系
- [x] 将实体与前端页面输入输出建立映射关系
- [x] 设计表结构命名规范
- [x] 设计公共字段规范
- [x] 设计索引策略
- [x] 设计迁移方案
- [x] 评估 MySQL 与 PostgreSQL 差异并做兼容处理

## 4. 执行记录

- 当前核心实体模型与关系已整理于 `docs/DATA_MODEL.md`。
- 实体与接口关系已通过 `docs/API_SPEC.md` 建立对齐。
- 后端模型已在 `backend/internal/models/` 落地，并支持自动迁移。
- 数据库兼容策略（MySQL / PostgreSQL）已在架构文档中明确。

## 5. 完成标准

- [x] 数据模型覆盖现有需求
- [x] 表结构可扩展
- [x] 数据库迁移策略明确
- [x] `docs/DATA_MODEL.md` 可作为数据库和后端建模基线
>>>>>>> theirs
