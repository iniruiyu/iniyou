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
	// accountProfileBirthdateVersion adds avatar and birth-date support to user profiles.
	// accountProfileBirthdateVersion 为用户资料补充头像与出生日期支持。
	accountProfileBirthdateVersion = "20260326_01_account_profile_avatar_birthdate"
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
		{
			Version: accountProfileBirthdateVersion,
			Name:    "account profile avatar and birthdate",
			Apply: func(db *gorm.DB) error {
				// Auto-migrate the user table again so existing installs receive the new profile columns.
				// 再次执行用户表自动迁移，让已有环境补齐新的资料字段列。
				return db.AutoMigrate(&models.User{})
			},
		},
	}
}
