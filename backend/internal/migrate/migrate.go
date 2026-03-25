package migrate

import (
	"fmt"
	"strings"

	"gorm.io/gorm"

	"account-service/internal/models"
	"account-service/internal/service"
)

const (
	// TargetAll runs every supported migration group.
	// TargetAll 会执行所有支持的迁移分组。
	TargetAll = "all"
	// TargetAccount runs account-service schema and backfill steps.
	// TargetAccount 会执行账号服务的表结构与回填步骤。
	TargetAccount = "account"
	// TargetSpace runs space-service schema and backfill steps.
	// TargetSpace 会执行空间服务的表结构与回填步骤。
	TargetSpace = "space"
	// TargetMessage runs message-service schema steps.
	// TargetMessage 会执行通讯服务的表结构步骤。
	TargetMessage = "message"
)

// Run applies one migration target by name.
// Run 按名称执行一个迁移目标。
func Run(db *gorm.DB, target string) error {
	switch strings.ToLower(strings.TrimSpace(target)) {
	case "", TargetAll:
		return ApplyAll(db)
	case TargetAccount:
		return ApplyAccount(db)
	case TargetSpace:
		return ApplySpace(db)
	case TargetMessage:
		return ApplyMessage(db)
	default:
		return fmt.Errorf("unknown migration target %q", target)
	}
}

// ApplyAll runs every migration group in a deterministic order.
// ApplyAll 会按稳定顺序执行所有迁移分组。
func ApplyAll(db *gorm.DB) error {
	if err := ApplyAccount(db); err != nil {
		return err
	}
	if err := ApplySpace(db); err != nil {
		return err
	}
	if err := ApplyMessage(db); err != nil {
		return err
	}
	return nil
}

// ApplyAccount migrates account-service tables and backfills usernames.
// ApplyAccount 会迁移账号服务表结构并回填用户名。
func ApplyAccount(db *gorm.DB) error {
	if err := db.AutoMigrate(&models.User{}, &models.Subscription{}, &models.ExternalAccount{}, &models.Friend{}); err != nil {
		return err
	}
	return service.EnsureUserUsernames(db)
}

// ApplySpace migrates space-service tables and backfills legacy space rows.
// ApplySpace 会迁移空间服务表结构并回填历史空间数据。
func ApplySpace(db *gorm.DB) error {
	if err := db.AutoMigrate(&models.Space{}, &models.Post{}, &models.Comment{}, &models.PostLike{}, &models.PostShare{}); err != nil {
		return err
	}
	if err := service.MarkLegacySystemSpaces(db); err != nil {
		return err
	}
	return service.BackfillLegacySpaceVisibility(db)
}

// ApplyMessage migrates the message-service table.
// ApplyMessage 会迁移通讯服务表。
func ApplyMessage(db *gorm.DB) error {
	return db.AutoMigrate(&models.Message{})
}
