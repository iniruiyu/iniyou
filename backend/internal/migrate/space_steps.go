package migrate

import (
	"gorm.io/gorm"

	"account-service/internal/models"
	"account-service/internal/service"
)

const (
	// spaceBaselineVersion is the first versioned space migration.
	// spaceBaselineVersion 是空间服务的首个版本化迁移。
	spaceBaselineVersion = "20260325_01_space_baseline"
)

func spaceMigrationSteps() []MigrationStep {
	// Space migrations are ordered by version and keep legacy visibility fixed.
	// 空间迁移按版本排序，并继续修复历史可见范围。
	return []MigrationStep{
		{
			Version: spaceBaselineVersion,
			Name:    "space baseline schema and legacy visibility backfill",
			Apply: func(db *gorm.DB) error {
				if err := db.AutoMigrate(&models.Space{}, &models.Post{}, &models.Comment{}, &models.PostLike{}, &models.PostShare{}); err != nil {
					return err
				}
				if err := service.MarkLegacySystemSpaces(db); err != nil {
					return err
				}
				return service.BackfillLegacySpaceVisibility(db)
			},
		},
	}
}
