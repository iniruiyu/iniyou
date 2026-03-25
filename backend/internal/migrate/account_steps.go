package migrate

import (
	"gorm.io/gorm"

	"account-service/internal/models"
	"account-service/internal/service"
)

const (
	// accountBaselineVersion is the first versioned account migration.
	// accountBaselineVersion 是账号服务的首个版本化迁移。
	accountBaselineVersion = "20260325_01_account_baseline"
)

func accountMigrationSteps() []MigrationStep {
	// Account migrations are ordered by version and keep usernames backfilled.
	// 账号迁移按版本排序，并保持用户名回填逻辑。
	return []MigrationStep{
		{
			Version: accountBaselineVersion,
			Name:    "account baseline schema and username backfill",
			Apply: func(db *gorm.DB) error {
				if err := db.AutoMigrate(&models.User{}, &models.Subscription{}, &models.ExternalAccount{}, &models.Friend{}); err != nil {
					return err
				}
				return service.EnsureUserUsernames(db)
			},
		},
	}
}
