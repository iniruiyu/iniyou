package migrate

import (
	"time"

	"gorm.io/gorm"
)

// MigrationStep describes one versioned migration script.
// MigrationStep 描述一个版本化迁移脚本。
type MigrationStep struct {
	Version string
	Name    string
	Apply   func(*gorm.DB) error
}

// AppliedMigration records a step that already ran for one service.
// AppliedMigration 记录某个服务已经执行过的迁移步骤。
type AppliedMigration struct {
	Service   string    `gorm:"primaryKey;type:varchar(32)"`
	Version   string    `gorm:"primaryKey;type:varchar(64)"`
	Name      string    `gorm:"type:varchar(160);not null"`
	AppliedAt time.Time `gorm:"autoCreateTime"`
}

// TableName keeps the migration ledger on a stable table name.
// TableName 将迁移台账固定为稳定的表名。
func (AppliedMigration) TableName() string {
	return "schema_migrations"
}
