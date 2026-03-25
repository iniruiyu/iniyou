package migrate

import (
	"gorm.io/gorm"

	"account-service/internal/models"
)

const (
	// messageBaselineVersion is the first versioned message migration.
	// messageBaselineVersion 是通讯服务的首个版本化迁移。
	messageBaselineVersion = "20260325_01_message_baseline"
)

func messageMigrationSteps() []MigrationStep {
	// Message migrations are currently a single baseline schema step.
	// 通讯迁移当前只包含一个基础表结构步骤。
	return []MigrationStep{
		{
			Version: messageBaselineVersion,
			Name:    "message baseline schema",
			Apply: func(db *gorm.DB) error {
				return db.AutoMigrate(&models.Message{})
			},
		},
	}
}
