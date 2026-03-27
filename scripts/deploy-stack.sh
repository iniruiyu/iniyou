#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
DB_SERVICE="${DB_SERVICE:-db}"
DB_NAME="${DB_NAME:-account_service}"

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

echo "Building deployment images / 构建部署镜像"
compose build migrate account-service space-service message-service learning-service legacy-web

echo "Starting database / 启动数据库"
compose up -d "$DB_SERVICE"

echo "Waiting for database readiness / 等待数据库就绪"
for attempt in $(seq 1 30); do
  if compose exec -T "$DB_SERVICE" pg_isready -U postgres -d "$DB_NAME" >/dev/null 2>&1; then
    echo "Database is ready / 数据库已就绪"
    break
  fi
  sleep 2
done

if ! compose exec -T "$DB_SERVICE" pg_isready -U postgres -d "$DB_NAME" >/dev/null 2>&1; then
  echo "Database did not become ready in time / 数据库未在预期时间内就绪" >&2
  exit 1
fi

echo "Running versioned migrations / 运行版本化迁移"
compose run --rm migrate

echo "Starting application services / 启动应用服务"
compose up -d account-service space-service message-service learning-service legacy-web

echo "Deployment stack is up / 部署栈已启动"
compose ps
