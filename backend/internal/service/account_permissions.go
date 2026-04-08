package service

import "strings"

func NormalizeUserRole(role string) string {
	// Normalize one persisted role value and keep `member` as the safe default.
	// 规范化持久化角色值，并将 `member` 作为安全默认值。
	switch strings.ToLower(strings.TrimSpace(role)) {
	case "admin":
		return "admin"
	default:
		return "member"
	}
}

func IsAdminRole(role string) bool {
	// Use the dedicated role field for administrator permission checks.
	// 使用独立角色字段作为管理员权限判断依据。
	return NormalizeUserRole(role) == "admin"
}
