package main

import (
	"flag"
	"fmt"
	"log"
	"strings"

	"gorm.io/gorm"

	"account-service/internal/config"
	"account-service/internal/db"
	"account-service/internal/models"
)

func main() {
	// Command-line helper for promoting or demoting one account level.
	// 用于提升或降低单个账号等级的命令行工具。
	var (
		userID   = flag.String("user-id", "", "Target user id / 目标用户 ID")
		email    = flag.String("email", "", "Target email / 目标邮箱")
		username = flag.String("username", "", "Target username / 目标用户名")
		level    = flag.String("level", "admin", "Level to set, such as admin/basic/vip / 要设置的等级，例如 admin/basic/vip")
	)
	flag.Parse()

	if countNonEmpty(*userID, *email, *username) != 1 {
		log.Fatal("exactly one of --user-id, --email, or --username is required / --user-id、--email、--username 必须且只能传一个")
	}

	targetLevel := strings.TrimSpace(*level)
	if targetLevel == "" {
		log.Fatal("level is required / level 必填")
	}

	cfg := config.Load("account")
	database, err := db.Connect(cfg.DBDsn)
	if err != nil {
		log.Fatalf("db connect error: %v", err)
	}

	user, err := findUser(database, strings.TrimSpace(*userID), strings.TrimSpace(*email), strings.TrimSpace(*username))
	if err != nil {
		log.Fatalf("find user error: %v", err)
	}

	if err := database.Model(&models.User{}).
		Where("id = ?", user.ID).
		Update("level", targetLevel).Error; err != nil {
		log.Fatalf("update user level error: %v", err)
	}

	fmt.Printf(
		"user level updated / 用户等级已更新: id=%s email=%s username=%s old=%s new=%s\n",
		user.ID,
		derefString(user.Email),
		derefString(user.Username),
		user.Level,
		targetLevel,
	)
}

func countNonEmpty(values ...string) int {
	// Count non-empty identifier flags so the tool can reject ambiguous input.
	// 统计非空识别参数数量，避免工具接收歧义输入。
	total := 0
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			total++
		}
	}
	return total
}

func findUser(database *gorm.DB, userID string, email string, username string) (models.User, error) {
	// Resolve one user from exactly one stable identifier.
	// 根据唯一稳定标识解析单个用户。
	var user models.User
	var err error
	switch {
	case userID != "":
		err = database.First(&user, "id = ?", userID).Error
	case email != "":
		err = database.First(&user, "email = ?", email).Error
	case username != "":
		err = database.First(&user, "username = ?", username).Error
	default:
		return models.User{}, fmt.Errorf("missing target identifier / 缺少目标标识")
	}
	if err != nil {
		return models.User{}, err
	}
	return user, nil
}

func derefString(value *string) string {
	// Print nullable string fields safely in command output.
	// 在命令输出中安全打印可空字符串字段。
	if value == nil {
		return ""
	}
	return *value
}
