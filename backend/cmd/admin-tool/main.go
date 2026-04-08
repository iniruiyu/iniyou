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
	// Command-line helper for updating one account role or membership level.
	// 用于更新单个账号角色或会员等级的命令行工具。
	var (
		userID   = flag.String("user-id", "", "Target user id / 目标用户 ID")
		email    = flag.String("email", "", "Target email / 目标邮箱")
		username = flag.String("username", "", "Target username / 目标用户名")
		role     = flag.String("role", "", "Role to set, such as admin/member / 要设置的角色，例如 admin/member")
		level    = flag.String("level", "", "Membership level to set, such as basic/premium/vip / 要设置的会员等级，例如 basic/premium/vip")
	)
	flag.Parse()

	if countNonEmpty(*userID, *email, *username) != 1 {
		log.Fatal("exactly one of --user-id, --email, or --username is required / --user-id、--email、--username 必须且只能传一个")
	}

	targetRole := strings.ToLower(strings.TrimSpace(*role))
	targetLevel := strings.ToLower(strings.TrimSpace(*level))
	if targetRole == "" && targetLevel == "" {
		log.Fatal("role or level is required / role 或 level 必填")
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

	updates := map[string]any{}
	if targetRole != "" {
		if targetRole != "admin" && targetRole != "member" {
			log.Fatal("role must be admin or member / role 只能是 admin 或 member")
		}
		updates["role"] = targetRole
	}
	if targetLevel != "" {
		switch targetLevel {
		case "basic", "premium", "vip":
			updates["level"] = targetLevel
		default:
			log.Fatal("level must be basic, premium, or vip / level 只能是 basic、premium 或 vip")
		}
	}

	if err := database.Model(&models.User{}).
		Where("id = ?", user.ID).
		Updates(updates).Error; err != nil {
		log.Fatalf("update user role or level error: %v", err)
	}

	fmt.Printf(
		"user account updated / 用户账号已更新: id=%s email=%s username=%s old_role=%s new_role=%s old_level=%s new_level=%s\n",
		user.ID,
		derefString(user.Email),
		derefString(user.Username),
		user.Role,
		defaultPrintedValue(targetRole, user.Role),
		user.Level,
		defaultPrintedValue(targetLevel, user.Level),
	)
}

func defaultPrintedValue(next string, current string) string {
	// Reuse the current value in output when the operator only changed one dimension.
	// 当操作者只修改一个维度时，在输出里回填当前值。
	if strings.TrimSpace(next) != "" {
		return next
	}
	return current
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
