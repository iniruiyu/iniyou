#!/usr/bin/env bash

set -euo pipefail

# Minimal local API smoke test.
# 最小本地接口冒烟测试。

ACCOUNT_API_BASE="${ACCOUNT_API_BASE:-http://localhost:8080/api/v1}"
MESSAGE_API_BASE="${MESSAGE_API_BASE:-http://localhost:8081/api/v1}"
LEARNING_API_BASE="${LEARNING_API_BASE:-http://localhost:8083/api/v1}"

timestamp="$(date +%s)"
user1_email="smoke-${timestamp}-a@example.com"
user2_email="smoke-${timestamp}-b@example.com"
password="smoke-pass-123"

extract_json_value() {
  # Extract a top-level JSON string field from a compact response.
  # 从紧凑 JSON 响应中提取顶层字符串字段。
  local body="$1"
  local key="$2"
  printf '%s' "$body" | sed -n "s/.*\"${key}\":\"\\([^\"]*\\)\".*/\\1/p"
}

post_json() {
  # Send a JSON POST request and capture response body.
  # 发送 JSON POST 请求并获取响应内容。
  local url="$1"
  local payload="$2"
  shift 2
  curl -fsS -X POST "$url" \
    -H 'Content-Type: application/json' \
    "$@" \
    -d "$payload"
}

get_json() {
  # Send an authenticated GET request and capture response body.
  # 发送带鉴权的 GET 请求并获取响应内容。
  local url="$1"
  local token="$2"
  curl -fsS "$url" -H "Authorization: Bearer ${token}"
}

put_json() {
  # Send a JSON PUT request and capture response body.
  # 发送 JSON PUT 请求并获取响应内容。
  local url="$1"
  local payload="$2"
  shift 2
  curl -fsS -X PUT "$url" \
    -H 'Content-Type: application/json' \
    "$@" \
    -d "$payload"
}

echo "1. Register first user / 注册第一个用户"
register_one="$(post_json "${ACCOUNT_API_BASE}/register" "{\"email\":\"${user1_email}\",\"password\":\"${password}\"}")"
token_one="$(extract_json_value "$register_one" "token")"
user_one="$(extract_json_value "$register_one" "user_id")"

echo "2. Register second user / 注册第二个用户"
register_two="$(post_json "${ACCOUNT_API_BASE}/register" "{\"email\":\"${user2_email}\",\"password\":\"${password}\"}")"
token_two="$(extract_json_value "$register_two" "token")"
user_two="$(extract_json_value "$register_two" "user_id")"

if [[ -z "${token_one}" || -z "${token_two}" || -z "${user_one}" || -z "${user_two}" ]]; then
  echo "Smoke test failed: missing tokens or user ids / 冒烟测试失败：缺少 token 或 user id" >&2
  exit 1
fi

echo "3. Load self profile / 读取当前用户资料"
get_json "${ACCOUNT_API_BASE}/me" "${token_one}" >/dev/null

echo "4. Create friend request / 发起好友请求"
post_json "${ACCOUNT_API_BASE}/friends" "{\"friend_id\":\"${user_two}\"}" \
  -H "Authorization: Bearer ${token_one}" >/dev/null

echo "5. Accept friend request / 接受好友请求"
curl -fsS -X POST "${ACCOUNT_API_BASE}/friends/accept" \
  -H "Authorization: Bearer ${token_two}" \
  -H 'Content-Type: application/json' \
  -d "{\"friend_id\":\"${user_one}\"}" >/dev/null

echo "6. Send message / 发送消息"
curl -fsS -X POST "${MESSAGE_API_BASE}/messages" \
  -H "Authorization: Bearer ${token_one}" \
  -H 'Content-Type: application/json' \
  -d "{\"peer_id\":\"${user_two}\",\"content\":\"smoke message\"}" >/dev/null

echo "7. Load conversations / 读取会话摘要"
get_json "${MESSAGE_API_BASE}/conversations" "${token_two}" >/dev/null

echo "8. Save markdown lesson / 保存 Markdown 课程文件"
put_json "${LEARNING_API_BASE}/markdown-files/smoke/lesson.md" "{\"content\":\"# smoke lesson\"}" \
  -H "Authorization: Bearer ${token_one}" >/dev/null

echo "9. Load markdown lesson / 读取 Markdown 课程文件"
get_json "${LEARNING_API_BASE}/markdown-files/smoke/lesson.md" "${token_one}" >/dev/null

echo "Smoke test passed / 冒烟测试通过"
