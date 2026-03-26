# 05 用户、账号、登录注册体系

## 1. 目标

完成账号系统与身份基础能力，为用户域其他模块提供统一身份基础。

## 2. 状态

- 状态：进行中
- 已完成：注册、登录、基础资料、用户名设置、用户名登录别名、域名身份卡与资料可见范围已接通，认证态管理已接入 JWT + active 状态校验，密码修改已接通并会刷新 token 版本，好友关系、当前订阅和外部账号绑定接口已接通，个人主页中的个人资料/隐私设置摘要与弹窗编辑已接通，账号主页与用户主页已合并为单一个人主页入口，顶部重复英雄卡已收敛为 Vue 风格概览，用户 ID 已下移到个人资料摘要并拆分为资料/隐私按钮，Flutter 端修改资料/隐私设置弹窗已按入口拆分为各自独立内容，顶部总览已继续收紧为仅保留空间/好友快速统计，登录页“记住账号和密码”开关已在双前端接入本地持久化，账号/空间/内容/聊天接口已统一到纯 `code/message/data` 响应包装，好友列表与好友主页预览已改为复用公开主页的可见性裁剪，`docs/API_SPEC.md` 已按当前实现更新接口边界
- 进行中：权限基础结构、密码找回/重置、账号停用/恢复管理、区块链账号绑定安全深化

## 3. 任务清单

- 实现用户注册
- 实现用户登录
- 实现基础账号资料管理
- 实现用户名设置与唯一性校验
- 实现用户名作为登录别名与个人主页入口
- 实现域名身份卡与登录入口
- 实现手机号、邮箱、年龄、性别的可见范围配置
- 实现认证态管理
- 设计并实现权限基础结构
- 设计密码与安全策略
- 设计账号状态管理
- 设计后续区块链账号绑定预留接口
- 提供对应 RESTful API
- 提供前端对应页面与交互

## 4. 完成标准

- 用户可以完成注册、登录和基础资料维护
- 用户可以设置唯一用户名，并通过用户名进入个人主页或作为登录别名使用
- 用户可以设置唯一域名，并把域名作为身份卡和登录入口使用
- 用户可以配置手机号、邮箱、生日/年龄、性别等个人信息的可见范围
- 身份认证流程稳定可用
- 为后续钱包、会员、社交功能提供统一账号基础

## 5. 进度记录

- 2026-03-25：把 Flutter 与 Legacy Web 的 API helper 调整为 `data` 优先读取，随后后端也收口为纯 `code/message/data` 包装，移除了标准接口的旧顶层字段 / Shifted the Flutter and Legacy Web API helpers to prefer `data`, then closed the backend to a pure `code/message/data` envelope and removed legacy top-level fields from standard APIs.
- 2026-03-25：补充登录页“记住账号和密码”能力，要求双前端登录成功后可回填账号与密码，并在未勾选时清理本地凭据 / Added login-page "remember account and password" support so both frontends can refill credentials after sign-in and clear local credentials when the option is off.
- 2026-03-24：按当前代码收口账号接口文档，补齐好友、订阅和外部账号接口，并移除尚未落地的用户管理/钱包权益接口口径 / Realigned the account API docs to the current code, adding friend, subscription, and external-account endpoints while removing undocumented user-management and wallet-entitlement APIs.
- 2026-03-20：继续对齐 Flutter 个人主页为 Vue 风格布局，收紧顶部重复英雄卡，并把用户 ID 留在个人资料摘要、将修改入口拆成资料/隐私两处 / Continued aligning the Flutter profile page with the Vue layout by tightening the duplicated top hero card, keeping the user ID in the personal info summary, and splitting the edit entry into personal-info and privacy actions.
- 2026-03-20：继续拆分 Flutter 个人主页修改资料/隐私设置弹窗，个人资料与隐私设置分别只显示自己的字段，并切换为区块化保存文案 / Continued splitting the Flutter personal-home edit/privacy dialogs so personal info and privacy settings each show only their own fields and use section-specific save labels.
- 2026-03-20：继续收紧 Flutter 个人主页顶部总览，移除会员等级与链上账号重复摘要，仅保留空间与好友快速统计 / Continued tightening the Flutter personal-home top summary by removing duplicated membership and chain snapshots and keeping only the space and friend quick stats.
- 2026-03-25：好友列表与好友主页预览改为复用公开主页的可见性裁剪，私密手机号和邮箱不再通过好友预览直接暴露 / Reused the public-profile visibility filter for the friends list and friend preview so private phone and email fields are no longer exposed directly in friend overlays.
- 2026-03-25：好友列表、好友搜索结果和会话侧栏的摘要字段进一步收口为公开身份信息，列表型入口不再把联系方式作为主展示内容 / Narrowed friend lists, friend search results, and chat-side summaries down to public identity fields so list-style entry points no longer surface contact details as the primary display content.
- 2026-03-25：Flutter 好友预览和聊天侧栏统一为卡片化摘要布局，与列表卡片保持同一视觉层级 / Unified the Flutter friend preview and chat sidebar into card-based summary layouts so they share the same visual hierarchy as the list cards.
- 2026-03-25：个人主页字段展示改为“本人显示真实值、他人显示未公开”，Flutter 与 Legacy Web 的非本人主页及好友资料弹层都已接入统一占位 / Updated profile field rendering so owners see real values while other viewers see "Not public", and wired the shared placeholder into the Flutter and Legacy Web non-owner profile pages plus friend profile overlays.
- 2026-03-25：继续收紧 Web 好友资料弹窗的字段行生成逻辑，去掉联系方式重复渲染，并保持隐藏字段只显示单条“未公开”占位 / Further tightened the Web friend profile modal row generation by removing duplicate contact rendering and keeping hidden fields on a single "Not public" placeholder row.
- 2026-03-25：帖子作者展示的后备名称改为仅使用昵称、用户名、域名或用户 ID，不再回退到邮箱或手机号，避免作者卡间接泄露联系方式 / Post author display fallback now uses only nickname, username, domain, or user ID instead of email or phone to avoid leaking contact details through author cards.
- 2026-03-25：把本人视角的个人资料摘要补回邮箱、手机号、年龄和性别，确保“自己看自己”时能直接看到真实值 / Restored email, phone, age, and gender to the owner-facing profile summary so users can see their real values when viewing their own profile.
- 2026-03-25：修正好友资料弹窗的字段标题，邮箱和手机号改用资料标签而不是输入占位键，避免展示文案和输入文案混用 / Fixed friend profile modal field titles so email and phone use profile labels instead of input placeholders, avoiding mixed display/input copy.
- 2026-03-25：补齐中文主分支的邮箱、手机号、年龄和性别资料标签，并把个人资料摘要说明同步扩展到联系方式与基本信息 / Filled in the missing Chinese labels for email, phone, age, and gender, and expanded the profile summary copy to cover contact details and basic info.
- 2026-03-25：把本人资料区拆成基础资料、联系方式和隐私三张并列卡片，减少单卡内容堆叠 / Split the owner profile area into three parallel cards for basic info, contact details, and privacy to reduce single-card clutter.
- 2026-03-25：补齐本人资料编辑入口中的年龄和性别字段，并让 Web 与 Flutter 的保存请求在更新后同步回写资料卡 / Added age and gender fields to the owner profile editor and synced both the Web and Flutter save flows back into the profile card after updates.
- 2026-03-26：个人资料新增头像地址与出生日期字段，双前端改为根据出生日期派生生日与年龄，并在主页摘要中显示头像预览 / Added avatar-URL and birth-date fields to profiles, switched both frontends to derive birthday and age from the birth date, and showed avatar previews in the profile summaries.
