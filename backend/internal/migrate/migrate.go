package migrate

import (
	"fmt"
	"log"
	"sort"
	"strings"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
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
	return applyGroup(db, TargetAccount, accountMigrationSteps())
}

// ApplySpace migrates space-service tables and backfills legacy space rows.
// ApplySpace 会迁移空间服务表结构并回填历史空间数据。
func ApplySpace(db *gorm.DB) error {
	return applyGroup(db, TargetSpace, spaceMigrationSteps())
}

// ApplyMessage migrates the message-service table.
// ApplyMessage 会迁移通讯服务表。
func ApplyMessage(db *gorm.DB) error {
	return applyGroup(db, TargetMessage, messageMigrationSteps())
}

func applyGroup(db *gorm.DB, serviceName string, steps []MigrationStep) error {
	// Ensure the migration ledger exists before checking or writing steps.
	// 在检查和写入迁移步骤前，先确保迁移台账表存在。
	if err := db.AutoMigrate(&AppliedMigration{}); err != nil {
		return err
	}

	applied, err := loadAppliedVersions(db, serviceName)
	if err != nil {
		return err
	}

	ordered := append([]MigrationStep(nil), steps...)
	sort.SliceStable(ordered, func(i, j int) bool {
		return ordered[i].Version < ordered[j].Version
	})

	for _, step := range ordered {
		if _, ok := applied[step.Version]; ok {
			continue
		}
		if err := applyStep(db, serviceName, step); err != nil {
			return fmt.Errorf("apply migration %s/%s: %w", serviceName, step.Version, err)
		}
	}

	return nil
}

func loadAppliedVersions(db *gorm.DB, serviceName string) (map[string]struct{}, error) {
	// Load applied migration versions for one service scope.
	// 载入某个服务作用域内已执行的迁移版本。
	var records []AppliedMigration
	if err := db.Where("service = ?", serviceName).Order("version asc").Find(&records).Error; err != nil {
		return nil, err
	}

	applied := make(map[string]struct{}, len(records))
	for _, record := range records {
		applied[record.Version] = struct{}{}
	}
	return applied, nil
}

func applyStep(db *gorm.DB, serviceName string, step MigrationStep) error {
	// Run the migration step inside one transaction and record it once complete.
	// 在一个事务中执行迁移步骤，并在完成后记录到台账。
	log.Printf("Applying migration step / 执行迁移步骤: service=%s version=%s name=%s", serviceName, step.Version, step.Name)
	return db.Transaction(func(tx *gorm.DB) error {
		if err := step.Apply(tx); err != nil {
			return err
		}
		record := AppliedMigration{
			Service: serviceName,
			Version: step.Version,
			Name:    step.Name,
		}
		return tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&record).Error
	})
}
