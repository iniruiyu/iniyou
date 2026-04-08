# 管理员课程后台设计 / Admin Learning Console Design

## 1. 目标 / Goal

- 管理员后台用于创建、编辑、审核与上架学习课程。 / The admin console is used to create, edit, review, and publish learning courses.
- 普通登录用户只可浏览已上架课程，不可直接修改课程文件。 / Regular signed-in users can only browse published lessons and cannot modify lesson files directly.
- 双前端共享同一套管理员能力边界。 / Both frontends share the same administrator capability boundary.
- 学习课程后台属于网站总管理面板下的专题工作区，而不是孤立入口。 / The learning course console belongs to the site-wide admin panel as a focused workspace instead of a standalone isolated entry.

## 2. 权限模型 / Permission Model

- 当前最小实现使用 `users.level = admin` 作为管理员判断。 / The current minimum implementation uses `users.level = admin` as the administrator switch.
- `learning-service` 的课程写入接口仅管理员可调用。 / Lesson write endpoints in `learning-service` are callable by administrators only.
- 普通用户可以继续访问学习服务健康检查、课程目录读取与课程正文读取接口。 / Regular users can continue to access the learning health probe, course catalog reads, and lesson content reads.

## 3. 后台职责 / Admin Console Responsibilities

- 创建课程：输入“课程系列 + 课程序号 + 课程名称”、语言版本与 Markdown 正文，生成 `courses/{series}-{order}-{title}.{locale}.md`。 / Create lessons by providing “course series + lesson order + lesson name”, locale, and Markdown content, producing `courses/{series}-{order}-{title}.{locale}.md`.
- 编辑课程：修改当前语言版本正文并保存。 / Edit lessons by updating the active locale variant content and saving it.
- 多语言管理：同一课程可维护 `zh-CN`、`en-US`、`zh-TW` 等多个版本。 / Locale management allows the same course to maintain multiple variants such as `zh-CN`, `en-US`, and `zh-TW`.
- 课程排序：同一系列内按 `order` 升序排列，系列之间按系列键稳定排序。 / Lesson ordering sorts ascending by `order` within the same series, and series groups keep a stable series-key order.
- 上架管理：后续应补课程元数据与状态管理，而不只依赖文件存在。 / Publishing management should later add lesson metadata and statuses instead of relying on file existence alone.

## 4. 课程状态建议 / Suggested Lesson Statuses

- `draft`: 仅管理员在后台可见。 / Visible only to administrators in the console.
- `reviewing`: 等待审核或复核。 / Waiting for review or approval.
- `published`: 对普通学习页可见。 / Visible to regular learning pages.
- `archived`: 保留历史版本，不再对普通用户展示。 / Kept for history and hidden from regular users.

## 5. 数据模型建议 / Suggested Data Model

建议新增课程元数据表，而不是长期只靠文件名推导课程。 / Add a lesson metadata table instead of relying on filenames forever.

建议字段： / Suggested fields:

- `id`
- `course_id`
- `series_key`
- `lesson_order`
- `locale`
- `title`
- `subtitle`
- `summary`
- `category`
- `status`
- `cover_theme`
- `published_at`
- `created_by`
- `updated_by`
- `created_at`
- `updated_at`

## 6. API 设计建议 / Suggested API Design

当前已实现： / Currently implemented:

- `GET /api/v1/markdown-files`
- `GET /api/v1/markdown-files/{path}`
- `PUT /api/v1/markdown-files/{path}` 管理员可写 / admin-only write

下一阶段建议新增： / Next phase recommendations:

- `GET /api/v1/admin/learning/courses`
- `POST /api/v1/admin/learning/courses`
- `PATCH /api/v1/admin/learning/courses/{id}`
- `POST /api/v1/admin/learning/courses/{id}/publish`
- `POST /api/v1/admin/learning/courses/{id}/archive`

## 7. 前端职责 / Frontend Responsibilities

- 普通学习页默认只展示 `published` 课程。 / The regular learning page should display only `published` lessons by default.
- 管理员登录后在学习服务内部显示“新建课程”“编辑 Markdown”“保存到服务”等后台动作，而不是在主导航或服务导航暴露独立入口。 / After an administrator signs in, show management actions such as “New lesson”, “Edit markdown”, and “Save to service” inside the learning service itself instead of exposing a standalone entry in global navigation.
- 课程后台应作为“网站管理面板”中的子工作区，由总控页统一承接服务状态、快捷入口与跨微服务跳转。 / The course console should become a child workspace inside the site admin panel, with the site-wide panel owning service status, quick actions, and cross-microservice routing.

## 8. 当前落地状态 / Current Applied State

- 后端课程写入已切到管理员权限。 / Backend lesson writes now require administrator permission.
- Flutter 与 Legacy Web 已根据用户等级隐藏课程管理入口。 / Flutter and Legacy Web now hide lesson management entry points based on user level.
- 课程后台入口现仅保留在学习服务内部，已从主导航、服务导航和网站总管理面板移除。 / The course console entry now remains only inside the learning service and has been removed from the main navigation, service navigation, and site-wide admin panel.
- 双前端课程目录已支持按系列分组、按序号排序，新建课程表单也已改为结构化生成课程 ID。 / Both frontends now group the lesson catalog by series, sort by lesson order, and create new lessons through a structured course-id generator.
- 当前“上架”仍等同于管理员直接写入课程文件。 / “Publishing” currently still equals an administrator writing lesson files directly.
- 下一步应补课程状态表、审核动作与批量发布能力。 / The next step should add a lesson status table, review actions, and bulk publishing support.
