# 发布检查清单

## 1. 文档用途

本文件用于记录当前版本发布前必须完成的检查项，作为交付前最终核对清单。

## 2. 发布前检查

### 2.1 代码与提交

- [x] 当前开发任务已全部收口并完成提交
- [x] 关键模块代码注释保持英文中文双语
- [x] 远端主分支可同步最新提交

### 2.2 文档一致性

- [x] `docs/REQUIREMENTS.md` 已同步当前需求
- [x] `docs/API_SPEC.md` 已同步当前接口实现
- [x] `docs/DATA_MODEL.md` 已同步当前数据模型
- [x] `docs/development-outline/` 已同步当前阶段状态
- [x] `README.md` 已补充本地启动、测试和构建说明

### 2.3 构建与测试

- [x] `make test` 通过
- [x] `make build` 通过
- [x] `docker compose -f docker-compose.yml config` 校验通过
- [x] `make deploy` 在本地 Docker 环境可执行并已实跑
- [x] GitHub Actions CI 检查流水线已补充
- [x] GitHub Actions Release 远程部署流水线已补充
- [x] `build/account-service` 已生成
- [x] `build/space-service` 已生成
- [x] `build/message-service` 已生成
- [x] `build/migrate` 已生成
- [x] `scripts/local-smoke.sh` 已完成脚本语法检查

### 2.4 联调与运行

- [x] 本地数据库初始化流程已有文档
- [x] 本地服务启动顺序已有文档
- [x] 最小冒烟流程已有文档与脚本
- [x] `make migrate` 版本化迁移命令已提供
- [x] `make deploy` 容器化部署命令已提供
- [x] `make deploy-remote` 远程部署命令已提供
- [x] `make smoke` 在完整本地环境下实跑并留档

### 2.5 已知限制

- [x] 区块链账号绑定当前只做基础校验，未接入真实链上验签
- [x] 数据库迁移已提供版本化命令，服务启动仍保留 `AutoMigrate` 回退
- [x] 当前前端仍为本地静态页面联调方式，未引入正式前端构建发布链路

## 3. 当前发布结论

- 当前仓库已具备开发版交付条件
- 当前仓库已具备开发版容器化部署条件
- 当前仓库已具备基础 CI 检查流程
- 当前仓库已具备基础远程发布流程
- 已完成 `make smoke` 完整实跑并留档
- 已完成 `make deploy` 完整实跑并留档
- 若作为正式对外交付版本，仍建议先完成：
  - 前端正式构建发布链路
  - 滚动更新与回滚策略
