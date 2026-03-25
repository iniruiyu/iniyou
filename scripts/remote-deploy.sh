#!/usr/bin/env bash
set -euo pipefail

# Remote deployment entrypoint / 远程部署入口
# This script updates a checked-out repository on the target host and then
# runs the local container stack deployment script.
# 该脚本会在目标主机上更新已检出的仓库，然后执行本地容器栈部署脚本。

DEPLOY_PATH="${DEPLOY_PATH:-}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-main}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

if [ -z "$DEPLOY_PATH" ]; then
  echo "DEPLOY_PATH is required / DEPLOY_PATH 为必填项" >&2
  exit 1
fi

if [ ! -d "$DEPLOY_PATH/.git" ]; then
  echo "DEPLOY_PATH must point to a git checkout / DEPLOY_PATH 必须指向 Git 检出目录" >&2
  exit 1
fi

cd "$DEPLOY_PATH"

if [ -n "$(git status --short)" ]; then
  echo "Working tree has local changes / 工作区存在本地修改" >&2
  git status --short >&2
  exit 1
fi

echo "Fetching branch / 拉取分支: $DEPLOY_BRANCH"
git fetch --all --prune
git checkout "$DEPLOY_BRANCH"
git pull --ff-only origin "$DEPLOY_BRANCH"

echo "Running deployment stack / 执行部署栈"
COMPOSE_FILE="$COMPOSE_FILE" bash ./scripts/deploy-stack.sh
