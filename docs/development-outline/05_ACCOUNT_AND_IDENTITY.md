# 05 用户、账号、登录注册体系

## 1. 目标

完成账号系统与身份基础能力，为用户域其他模块提供统一身份基础。

## 2. 状态

- 状态：进行中
- 已完成：注册、登录、基础资料、用户名设置、用户名登录别名、域名身份卡与资料可见范围已接通，认证态管理已接入 JWT + active 状态校验，密码修改已接通并会刷新 token 版本，个人主页中的个人资料/隐私设置摘要与弹窗编辑已接通，账号主页与用户主页已合并为单一个人主页入口，顶部重复英雄卡已收敛为 Vue 风格概览，用户 ID 已下移到个人资料摘要并拆分为资料/隐私按钮，Flutter 端修改资料/隐私设置弹窗已按入口拆分为各自独立内容
- 进行中：权限基础结构、密码找回/重置、账号停用/恢复管理、区块链账号绑定预留接口

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
- 用户可以配置手机号、邮箱、年龄、性别等个人信息的可见范围
- 身份认证流程稳定可用
- 为后续钱包、会员、社交功能提供统一账号基础

## 5. 进度记录

- 2026-03-20：继续对齐 Flutter 个人主页为 Vue 风格布局，收紧顶部重复英雄卡，并把用户 ID 留在个人资料摘要、将修改入口拆成资料/隐私两处 / Continued aligning the Flutter profile page with the Vue layout by tightening the duplicated top hero card, keeping the user ID in the personal info summary, and splitting the edit entry into personal-info and privacy actions.
- 2026-03-20：继续拆分 Flutter 个人主页修改资料/隐私设置弹窗，个人资料与隐私设置分别只显示自己的字段，并切换为区块化保存文案 / Continued splitting the Flutter personal-home edit/privacy dialogs so personal info and privacy settings each show only their own fields and use section-specific save labels.
