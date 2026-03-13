SHELL := /bin/bash

BACKEND_DIR := backend
FRONTEND_DIR := frontend
FLUTTER_FRONTEND_DIR := flutter_frontend
FLUTTER_BIN := /root/flutter-sdk/bin/flutter

.PHONY: help test test-backend test-frontend test-flutter build build-backend build-flutter-web run-account run-message run-flutter-web smoke check

help:
	@echo "Available targets / 可用目标:"
	@echo "  make test           - Run all baseline checks / 运行基础检查"
	@echo "  make test-backend   - Run Go tests / 运行 Go 测试"
	@echo "  make test-frontend  - Run frontend syntax check / 运行前端语法检查"
	@echo "  make test-flutter   - Run Flutter analyze and tests / 运行 Flutter 检查与测试"
	@echo "  make build          - Build backend binaries / 构建后端二进制"
	@echo "  make build-flutter-web - Build Flutter web bundle / 构建 Flutter Web"
	@echo "  make run-account    - Run account service / 启动账号服务"
	@echo "  make run-message    - Run message service / 启动消息服务"
	@echo "  make run-flutter-web - Run Flutter web client / 启动 Flutter Web 前端"
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
	cd $(BACKEND_DIR) && CGO_ENABLED=0 go build -o ../build/message-service ./cmd/message-service

build-flutter-web:
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) pub get
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) build web

run-account:
	cd $(BACKEND_DIR) && go run ./cmd/account-service

run-message:
	cd $(BACKEND_DIR) && SERVICE_PORT=8081 go run ./cmd/message-service

run-flutter-web:
	cd $(FLUTTER_FRONTEND_DIR) && CI=true FLUTTER_SUPPRESS_ANALYTICS=true $(FLUTTER_BIN) run -d web-server --web-hostname 0.0.0.0 --web-port 3000

smoke:
	chmod +x scripts/local-smoke.sh
	./scripts/local-smoke.sh
