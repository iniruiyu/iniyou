SHELL := /bin/bash

BACKEND_DIR := backend
FRONTEND_DIR := frontend
FLUTTER_FRONTEND_DIR := flutter_frontend
FLUTTER_BIN := /root/flutter-sdk/bin/flutter
MIGRATE_SERVICE ?= all
COMPOSE_FILE ?= docker-compose.yml

.PHONY: help test test-backend test-frontend test-flutter build build-backend build-flutter-web run-account run-space run-message run-flutter-web smoke migrate deploy deploy-remote deploy-down deploy-logs deploy-status check

help:
	@echo "Available targets / 可用目标:"
	@echo "  make test           - Run all baseline checks / 运行基础检查"
	@echo "  make test-backend   - Run Go tests / 运行 Go 测试"
	@echo "  make test-frontend  - Run frontend syntax check / 运行前端语法检查"
	@echo "  make test-flutter   - Run Flutter analyze and tests / 运行 Flutter 检查与测试"
	@echo "  make build          - Build backend binaries / 构建后端二进制"
	@echo "  make build-flutter-web - Build Flutter web bundle / 构建 Flutter Web"
	@echo "  make run-account    - Run account service / 启动账号服务"
	@echo "  make run-space      - Run space service / 启动空间服务"
	@echo "  make run-message    - Run message service / 启动消息服务"
	@echo "  make run-flutter-web - Run Flutter web client / 启动 Flutter Web 前端"
	@echo "  make migrate        - Run versioned schema/backfill migration / 运行版本化迁移与回填"
	@echo "  make migrate MIGRATE_SERVICE=account - Run one service migration / 仅运行单服务迁移"
	@echo "  make migrate-account - Run account migration / 运行账号迁移"
	@echo "  make migrate-space   - Run space migration / 运行空间迁移"
	@echo "  make migrate-message - Run message migration / 运行通讯迁移"
	@echo "  make deploy         - Build and start the container stack / 构建并启动容器栈"
	@echo "  make deploy-remote  - Run remote deploy helper / 运行远程部署助手"
	@echo "  make deploy-down    - Stop and remove the container stack / 停止并移除容器栈"
	@echo "  make deploy-logs    - Stream container logs / 查看容器日志"
	@echo "  make deploy-status  - Show container status / 查看容器状态"
	@echo "  make smoke          - Run local API smoke script / 运行本地接口冒烟脚本"
	@echo "  make check          - Alias of test / test 的别名"

test: test-backend test-frontend

check: test

test-backend:
	cd $(BACKEND_DIR) && go test ./...

test-frontend:
	node --check $(FRONTEND_DIR)/app.js
	node --check $(FRONTEND_DIR)/components/settings-menu.js
	node --check $(FRONTEND_DIR)/components/auth-panel.js
	node --check $(FRONTEND_DIR)/components/landing-page.js

test-flutter:
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) pub get
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) analyze
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) test

build: build-backend

build-backend:
	mkdir -p build
	cd $(BACKEND_DIR) && CGO_ENABLED=0 go build -o ../build/account-service ./cmd/account-service
	cd $(BACKEND_DIR) && CGO_ENABLED=0 go build -o ../build/space-service ./cmd/space-service
	cd $(BACKEND_DIR) && CGO_ENABLED=0 go build -o ../build/message-service ./cmd/message-service
	cd $(BACKEND_DIR) && CGO_ENABLED=0 go build -o ../build/migrate ./cmd/migrate

build-flutter-web:
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) pub get
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) build web

run-account:
	cd $(BACKEND_DIR) && go run ./cmd/account-service

run-space:
	cd $(BACKEND_DIR) && SERVICE_PORT=8082 go run ./cmd/space-service

run-message:
	cd $(BACKEND_DIR) && SERVICE_PORT=8081 go run ./cmd/message-service

run-flutter-web:
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) run -d web-server --web-hostname 0.0.0.0 --web-port 3000

migrate:
	cd $(BACKEND_DIR) && go run ./cmd/migrate -service $(MIGRATE_SERVICE)

migrate-account:
	cd $(BACKEND_DIR) && go run ./cmd/migrate -service account

migrate-space:
	cd $(BACKEND_DIR) && go run ./cmd/migrate -service space

migrate-message:
	cd $(BACKEND_DIR) && go run ./cmd/migrate -service message

deploy:
	bash ./scripts/deploy-stack.sh

deploy-remote:
	bash ./scripts/remote-deploy.sh

deploy-down:
	docker compose -f $(COMPOSE_FILE) down

deploy-logs:
	docker compose -f $(COMPOSE_FILE) logs -f --tail=100

deploy-status:
	docker compose -f $(COMPOSE_FILE) ps

smoke:
	chmod +x scripts/local-smoke.sh
	./scripts/local-smoke.sh
