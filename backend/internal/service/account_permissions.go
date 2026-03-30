package service

import "strings"

func IsAdminLevel(level string) bool {
	// Treat the persisted `admin` level as the switch for privileged management actions.
	// 将持久化的 `admin` 等级视为特权管理动作的开关。
	return strings.EqualFold(strings.TrimSpace(level), "admin")
}
