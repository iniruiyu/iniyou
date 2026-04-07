package service

import (
	"errors"
	"strings"
	"time"

	"gorm.io/gorm"

	"account-service/internal/models"
)

type AdminAccountUserSummary struct {
	ID          string    `json:"id"`
	DisplayName string    `json:"display_name"`
	Username    string    `json:"username"`
	Domain      string    `json:"domain"`
	Level       string    `json:"level"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
}

type AdminExternalAccountSummary struct {
	ID             string    `json:"id"`
	UserID         string    `json:"user_id"`
	UserName       string    `json:"user_name"`
	Provider       string    `json:"provider"`
	Chain          string    `json:"chain"`
	AccountAddress string    `json:"account_address"`
	BindingStatus  string    `json:"binding_status"`
	CreatedAt      time.Time `json:"created_at"`
}

type AdminAccountOverview struct {
	TotalUsers           int64                         `json:"total_users"`
	AdminUsers           int64                         `json:"admin_users"`
	ActiveUsers          int64                         `json:"active_users"`
	InactiveUsers        int64                         `json:"inactive_users"`
	ActiveSubscriptions  int64                         `json:"active_subscriptions"`
	BoundExternalAccount int64                         `json:"bound_external_accounts"`
	RecentUsers          []AdminAccountUserSummary     `json:"recent_users"`
	RecentBindings       []AdminExternalAccountSummary `json:"recent_bindings"`
}

func BuildAdminAccountOverview(db *gorm.DB) (AdminAccountOverview, error) {
	// Aggregate one account-service administrator summary from the shared database.
	// 从共享数据库聚合一份账号服务管理员总览。
	var overview AdminAccountOverview

	if err := db.Model(&models.User{}).Count(&overview.TotalUsers).Error; err != nil {
		return AdminAccountOverview{}, err
	}
	if err := db.Model(&models.User{}).Where("LOWER(TRIM(level)) = ?", "admin").Count(&overview.AdminUsers).Error; err != nil {
		return AdminAccountOverview{}, err
	}
	if err := db.Model(&models.User{}).
		Where("status = ? OR status = '' OR status IS NULL", "active").
		Count(&overview.ActiveUsers).Error; err != nil {
		return AdminAccountOverview{}, err
	}
	overview.InactiveUsers = overview.TotalUsers - overview.ActiveUsers
	if err := db.Model(&models.Subscription{}).Where("status = ?", "active").Count(&overview.ActiveSubscriptions).Error; err != nil {
		return AdminAccountOverview{}, err
	}
	if err := db.Model(&models.ExternalAccount{}).
		Where("binding_status <> ?", "revoked").
		Count(&overview.BoundExternalAccount).Error; err != nil {
		return AdminAccountOverview{}, err
	}

	recentUsers, err := listRecentAdminUsers(db, 8)
	if err != nil {
		return AdminAccountOverview{}, err
	}
	recentBindings, err := listRecentAdminExternalBindings(db, 8)
	if err != nil {
		return AdminAccountOverview{}, err
	}
	overview.RecentUsers = recentUsers
	overview.RecentBindings = recentBindings
	return overview, nil
}

func listRecentAdminUsers(db *gorm.DB, limit int) ([]AdminAccountUserSummary, error) {
	var users []models.User
	if err := db.Select("id", "display_name", "username", "domain", "level", "status", "created_at").
		Order("created_at desc").
		Limit(limit).
		Find(&users).Error; err != nil {
		return nil, err
	}

	items := make([]AdminAccountUserSummary, 0, len(users))
	for _, user := range users {
		items = append(items, AdminAccountUserSummary{
			ID:          user.ID,
			DisplayName: strings.TrimSpace(user.DisplayName),
			Username:    stringValue(user.Username),
			Domain:      stringValue(user.Domain),
			Level:       strings.TrimSpace(user.Level),
			Status:      strings.TrimSpace(user.Status),
			CreatedAt:   user.CreatedAt,
		})
	}
	return items, nil
}

func listRecentAdminExternalBindings(db *gorm.DB, limit int) ([]AdminExternalAccountSummary, error) {
	type bindingRow struct {
		ID             string
		UserID         string
		UserName       string
		Provider       string
		Chain          string
		AccountAddress string
		BindingStatus  string
		CreatedAt      time.Time
	}

	rows := make([]bindingRow, 0, limit)
	if err := db.Table("external_accounts AS ea").
		Select(`
			ea.id,
			ea.user_id,
			COALESCE(NULLIF(u.display_name, ''), NULLIF(u.username, ''), NULLIF(u.domain, ''), ea.user_id) AS user_name,
			ea.provider,
			ea.chain,
			ea.account_address,
			ea.binding_status,
			ea.created_at
		`).
		Joins("LEFT JOIN users AS u ON u.id = ea.user_id").
		Where("ea.binding_status <> ?", "revoked").
		Order("ea.created_at desc").
		Limit(limit).
		Scan(&rows).Error; err != nil {
		return nil, err
	}

	items := make([]AdminExternalAccountSummary, 0, len(rows))
	for _, row := range rows {
		items = append(items, AdminExternalAccountSummary{
			ID:             row.ID,
			UserID:         row.UserID,
			UserName:       row.UserName,
			Provider:       row.Provider,
			Chain:          row.Chain,
			AccountAddress: row.AccountAddress,
			BindingStatus:  row.BindingStatus,
			CreatedAt:      row.CreatedAt,
		})
	}
	return items, nil
}

func AdminUpdateUser(db *gorm.DB, actorUserID string, targetUserID string, level string, status string) (AdminAccountUserSummary, error) {
	// Update one target account's administrator-managed level or status.
	// 更新单个目标账号的管理员控制等级或状态。
	targetUserID = strings.TrimSpace(targetUserID)
	if targetUserID == "" {
		return AdminAccountUserSummary{}, errors.New("user id required")
	}
	if strings.TrimSpace(actorUserID) == targetUserID {
		return AdminAccountUserSummary{}, errors.New("cannot modify your own admin account")
	}

	updates := map[string]any{}
	if normalizedLevel := normalizeAdminManagedLevel(level); normalizedLevel != "" {
		updates["level"] = normalizedLevel
	}
	if normalizedStatus := normalizeAdminManagedStatus(status); normalizedStatus != "" {
		updates["status"] = normalizedStatus
	}
	if len(updates) == 0 {
		return AdminAccountUserSummary{}, errors.New("level or status required")
	}

	var user models.User
	if err := db.First(&user, "id = ?", targetUserID).Error; err != nil {
		return AdminAccountUserSummary{}, err
	}
	if err := db.Model(&user).Updates(updates).Error; err != nil {
		return AdminAccountUserSummary{}, err
	}
	if err := db.First(&user, "id = ?", targetUserID).Error; err != nil {
		return AdminAccountUserSummary{}, err
	}
	return AdminAccountUserSummary{
		ID:          user.ID,
		DisplayName: strings.TrimSpace(user.DisplayName),
		Username:    stringValue(user.Username),
		Domain:      stringValue(user.Domain),
		Level:       strings.TrimSpace(user.Level),
		Status:      strings.TrimSpace(user.Status),
		CreatedAt:   user.CreatedAt,
	}, nil
}

func normalizeAdminManagedLevel(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "":
		return ""
	case "basic":
		return "basic"
	case "premium":
		return "premium"
	case "vip":
		return "vip"
	case "admin":
		return "admin"
	default:
		return ""
	}
}

func normalizeAdminManagedStatus(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "":
		return ""
	case "active":
		return "active"
	case "disabled":
		return "disabled"
	case "suspended":
		return "suspended"
	default:
		return ""
	}
}
