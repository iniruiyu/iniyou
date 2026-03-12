SHELL := /bin/bash

BACKEND_DIR := backend
FRONTEND_DIR := frontend

.PHONY: help test test-backend test-frontend build build-backend run-account run-message check

help:
	@echo "Available targets / 可用目标:"
	@echo "  make test           - Run all baseline checks / 运行基础检查"
	@echo "  make test-backend   - Run Go tests / 运行 Go 测试"
	@echo "  make test-frontend  - Run frontend syntax check / 运行前端语法检查"
	@echo "  make build          - Build backend binaries / 构建后端二进制"
	@echo "  make run-account    - Run account service / 启动账号服务"
	@echo "  make run-message    - Run message service / 启动消息服务"
	@echo "  make check          - Alias of test / test 的别名"

test: test-backend test-frontend

check: test

test-backend:
	cd $(BACKEND_DIR) && go test ./...

test-frontend:
	node --check $(FRONTEND_DIR)/app.js

build: build-backend

build-backend:
	mkdir -p build
	cd $(BACKEND_DIR) && CGO_ENABLED=0 go build -o ../build/account-service ./cmd/account-service
	cd $(BACKEND_DIR) && CGO_ENABLED=0 go build -o ../build/message-service ./cmd/message-service

run-account:
	cd $(BACKEND_DIR) && go run ./cmd/account-service

run-message:
	cd $(BACKEND_DIR) && SERVICE_PORT=8081 go run ./cmd/message-service
