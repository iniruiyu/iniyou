# New Project

这是一个新项目的初始化仓库，当前阶段先沉淀项目规划与前端设计基线。

## 文档结构

- `docs/PROJECT_PLAN.md`: 项目规划与阶段目标
- `docs/REQUIREMENTS.md`: 需求文档与功能范围记录
- `docs/design/FRONTEND_DESIGN.md`: 前端设计图与交互草案
- `docs/ARCHITECTURE_DECISIONS.md`: 架构选型与第三方依赖记录
- `docs/development-outline/`: 开发大纲与项目任务拆分

## 当前约束

- 需要同时支持网页端、Windows 桌面端和移动端
- 后端接口遵循 RESTful 规范
- 前端设计文档单独维护，便于后续持续迭代
- 前端技术栈采用 Flutter、HTML5、CSS3、JavaScript，可使用 Vue 3
- 后端技术栈采用 Golang、Gin、Gorm，数据库适配 MySQL 与 PostgreSQL
- 尽量不使用第三方库，如确需引入，必须补充到 `docs/ARCHITECTURE_DECISIONS.md`
- 前后端必须分离，架构边界保持清晰
- 后端尽量避免使用 CGO，优先采用纯 Go 方案
- 代码注释要求清晰，关键注释采用英文中文双语

## 文档维护规则

- `docs/PROJECT_PLAN.md` 记录项目规划与架构方向变化
- `docs/REQUIREMENTS.md` 记录功能需求、业务范围与需求变更
- `docs/design/FRONTEND_DESIGN.md` 记录界面、交互与跨端设计变化
- `docs/ARCHITECTURE_DECISIONS.md` 记录技术选型、约束与第三方依赖变化
- `docs/development-outline/` 记录项目实施任务，按序号推进
- 需求变化时，至少同步更新 `docs/REQUIREMENTS.md`，若影响规划、设计或技术实现，也要同步更新其他相关文档
- 当任务被拆分、调整、新增或合并时，要同步更新 `docs/development-outline/`
