package service

import (
	"crypto/rand"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"account-service/internal/models"
)

var ErrInvalidCredentials = errors.New("invalid credentials")

// ErrAccountInactive means the account exists but is not allowed to authenticate.
// ErrAccountInactive 表示账号存在，但不允许继续认证。
var ErrAccountInactive = errors.New("account inactive")

var (
	evmAddressPattern     = regexp.MustCompile(`^0x[0-9a-fA-F]{40}$`)
	solanaAddressPattern  = regexp.MustCompile(`^[1-9A-HJ-NP-Za-km-z]{32,44}$`)
	tronAddressPattern    = regexp.MustCompile(`^T[1-9A-HJ-NP-Za-km-z]{33}$`)
	spaceSubdomainPattern = regexp.MustCompile(`^[a-z0-9]+$`)
	usernamePattern       = regexp.MustCompile(`^[a-z0-9]+$`)
)

func defaultSpaceVisibility(spaceType string) string {
	// Pick the default visibility based on the space type.
	// 根据空间类型选择默认可见范围。
	switch strings.ToLower(strings.TrimSpace(spaceType)) {
	case "private":
		return "private"
	default:
		return "public"
	}
}

func normalizeSpaceVisibilityValue(spaceType string, requested string, current string) (string, error) {
	// Normalize the requested space visibility and fall back safely when omitted.
	// 规范化请求的空间可见范围，并在未填写时安全回退。
	value := strings.ToLower(strings.TrimSpace(requested))
	if value == "" {
		value = strings.ToLower(strings.TrimSpace(current))
	}
	if value == "" {
		value = defaultSpaceVisibility(spaceType)
	}
	switch value {
	case "public", "friends", "private":
		return value, nil
	default:
		return "", errors.New("space visibility must be public, friends, or private")
	}
}

func spaceVisibilityValue(space models.Space) string {
	// Resolve a stored visibility value with legacy-safe defaults.
	// 读取空间可见范围时兼容历史数据默认值。
	visibility := strings.ToLower(strings.TrimSpace(space.Visibility))
	if visibility == "" {
		return defaultSpaceVisibility(space.Type)
	}
	switch visibility {
	case "public", "friends", "private":
		return visibility
	default:
		return defaultSpaceVisibility(space.Type)
	}
}

func loadAcceptedFriendIDs(db *gorm.DB, userID string) (map[string]struct{}, error) {
	// Load accepted friend IDs for a viewer so visibility checks stay local.
	// 载入当前用户的已通过好友 ID，便于本地完成可见性校验。
	var friends []models.Friend
	if err := db.Where(
		"status = ? AND (user_id = ? OR friend_id = ?)",
		"accepted",
		userID,
		userID,
	).Find(&friends).Error; err != nil {
		return nil, err
	}

	items := make(map[string]struct{}, len(friends))
	for _, friend := range friends {
		if friend.UserID == userID {
			items[friend.FriendID] = struct{}{}
			continue
		}
		items[friend.UserID] = struct{}{}
	}
	return items, nil
}

func canViewSpace(viewerID string, friendIDs map[string]struct{}, space models.Space) bool {
	// Decide whether the current viewer can see a space.
	// 判断当前查看者是否可以看到某个空间。
	if strings.ToLower(strings.TrimSpace(space.Status)) != "active" {
		return false
	}
	if strings.TrimSpace(space.UserID) == strings.TrimSpace(viewerID) {
		return true
	}
	switch spaceVisibilityValue(space) {
	case "public":
		return true
	case "friends":
		_, ok := friendIDs[space.UserID]
		return ok
	default:
		return false
	}
}

type FriendView struct {
	// Friend relation view for API consumption.
	// 提供给接口层使用的好友关系视图。
	FriendID    string    `json:"friend_id"`
	DisplayName string    `json:"display_name"`
	AvatarURL   string    `json:"avatar_url,omitempty"`
	Username    string    `json:"username,omitempty"`
	Domain      string    `json:"domain,omitempty"`
	Signature   string    `json:"signature,omitempty"`
	Email       *string   `json:"email"`
	Phone       *string   `json:"phone"`
	Status      string    `json:"status"`
	Direction   string    `json:"direction"`
	CreatedAt   time.Time `json:"created_at"`
}

type UserSearchView struct {
	// User search result for adding friends.
	// 用于添加好友的用户搜索结果。
	UserID         string  `json:"user_id"`
	DisplayName    string  `json:"display_name"`
	AvatarURL      string  `json:"avatar_url,omitempty"`
	Username       string  `json:"username,omitempty"`
	Domain         string  `json:"domain,omitempty"`
	Signature      string  `json:"signature,omitempty"`
	Email          *string `json:"email"`
	Phone          *string `json:"phone"`
	Age            *int    `json:"age,omitempty"`
	Gender         *string `json:"gender,omitempty"`
	RelationStatus string  `json:"relation_status,omitempty"`
	Direction      string  `json:"direction,omitempty"`
}

type PublicUserProfileView struct {
	// Public-facing user profile for author pages.
	// 面向作者主页的公开用户资料。
	UserID         string  `json:"user_id"`
	DisplayName    string  `json:"display_name"`
	AvatarURL      string  `json:"avatar_url,omitempty"`
	Username       string  `json:"username,omitempty"`
	Domain         string  `json:"domain,omitempty"`
	Signature      string  `json:"signature,omitempty"`
	Email          *string `json:"email"`
	Phone          *string `json:"phone"`
	Birthday       string  `json:"birthday,omitempty"`
	Age            *int    `json:"age,omitempty"`
	Gender         *string `json:"gender,omitempty"`
	Status         string  `json:"status"`
	RelationStatus string  `json:"relation_status,omitempty"`
	Direction      string  `json:"direction,omitempty"`
}

type CurrentUserView struct {
	// Owner-facing current-user profile payload shared by /me endpoints.
	// 提供给 /me 接口的本人资料载荷。
	UserID           string  `json:"user_id"`
	Email            *string `json:"email"`
	Phone            *string `json:"phone"`
	Username         string  `json:"username,omitempty"`
	Domain           string  `json:"domain,omitempty"`
	DisplayName      string  `json:"display_name"`
	AvatarURL        string  `json:"avatar_url,omitempty"`
	Signature        string  `json:"signature"`
	BirthDate        string  `json:"birth_date,omitempty"`
	Birthday         string  `json:"birthday,omitempty"`
	Age              *int    `json:"age,omitempty"`
	Gender           *string `json:"gender,omitempty"`
	PhoneVisibility  string  `json:"phone_visibility"`
	EmailVisibility  string  `json:"email_visibility"`
	AgeVisibility    string  `json:"age_visibility"`
	GenderVisibility string  `json:"gender_visibility"`
	Role             string  `json:"role"`
	IsAdmin          bool    `json:"is_admin"`
	Level            string  `json:"level"`
	Status           string  `json:"status"`
}

type SubscriptionView struct {
	// Subscription view returned to clients.
	// 返回给客户端的订阅视图。
	PlanID    string     `json:"plan_id"`
	Status    string     `json:"status"`
	StartedAt time.Time  `json:"started_at"`
	EndedAt   *time.Time `json:"ended_at"`
}

type ExternalAccountView struct {
	// External account view returned to clients.
	// 返回给客户端的外部账号视图。
	ID             string    `json:"id"`
	Provider       string    `json:"provider"`
	Chain          string    `json:"chain"`
	AccountAddress string    `json:"account_address"`
	BindingStatus  string    `json:"binding_status"`
	Metadata       string    `json:"metadata"`
	CreatedAt      time.Time `json:"created_at"`
}

func GetUser(db *gorm.DB, userID string) (models.User, error) {
	// Fetch user by ID.
	// 根据用户 ID 获取用户信息。
	var user models.User
	if err := db.First(&user, "id = ?", userID).Error; err != nil {
		return models.User{}, err
	}
	return user, nil
}

func GetUserByUsername(db *gorm.DB, username string) (models.User, error) {
	// Fetch user by username.
	// 根据用户名获取用户信息。
	username = strings.ToLower(strings.TrimSpace(username))
	if username == "" {
		return models.User{}, gorm.ErrRecordNotFound
	}

	var user models.User
	if err := db.First(&user, "LOWER(COALESCE(username, '')) = ?", username).Error; err != nil {
		return models.User{}, err
	}
	return user, nil
}

func GetUserByDomain(db *gorm.DB, domain string) (models.User, error) {
	// Fetch user by domain handle.
	// 根据域名身份句柄获取用户信息。
	domain = strings.ToLower(strings.TrimSpace(domain))
	if domain == "" {
		return models.User{}, gorm.ErrRecordNotFound
	}

	var user models.User
	if err := db.First(&user, "LOWER(COALESCE(domain, '')) = ?", domain).Error; err != nil {
		return models.User{}, err
	}
	return user, nil
}

func normalizeAvatarURL(raw string) string {
	// Keep avatar URLs trim-normalized so both frontends can render the same source string.
	// 统一裁剪头像地址，保证双前端拿到一致的来源字符串。
	return strings.TrimSpace(raw)
}

func normalizeBirthDate(raw string) (*time.Time, error) {
	// Parse a date-only birthday string and reject future dates.
	// 解析纯日期格式的出生日期，并拒绝未来日期。
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return nil, nil
	}
	parsed, err := time.Parse("2006-01-02", trimmed)
	if err != nil {
		return nil, errors.New("birth date must use YYYY-MM-DD")
	}
	now := time.Now().UTC()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	birthDate := time.Date(parsed.Year(), parsed.Month(), parsed.Day(), 0, 0, 0, 0, time.UTC)
	if birthDate.After(today) {
		return nil, errors.New("birth date cannot be in the future")
	}
	return &birthDate, nil
}

func birthDateString(value *time.Time) string {
	// Format stored dates into a stable YYYY-MM-DD payload value.
	// 将存储日期格式化为稳定的 YYYY-MM-DD 接口值。
	if value == nil || value.IsZero() {
		return ""
	}
	return value.UTC().Format("2006-01-02")
}

func birthdayString(value *time.Time) string {
	// Expose a month-day birthday label derived from the stored birth date.
	// 基于出生日期导出月-日生日标签。
	if value == nil || value.IsZero() {
		return ""
	}
	return value.UTC().Format("01-02")
}

func calculateAgeFromBirthDate(value *time.Time, now time.Time) *int {
	// Derive age from a stored birth date so the backend stays authoritative.
	// 根据出生日期推导年龄，让后端保持唯一口径。
	if value == nil || value.IsZero() {
		return nil
	}
	now = now.UTC()
	birthDate := value.UTC()
	age := now.Year() - birthDate.Year()
	if now.Month() < birthDate.Month() ||
		(now.Month() == birthDate.Month() && now.Day() < birthDate.Day()) {
		age--
	}
	if age < 0 {
		return nil
	}
	return &age
}

func derivedProfileAge(user models.User) *int {
	// Prefer the birth-date-derived age while keeping legacy manual ages readable.
	// 优先生日推导年龄，同时兼容历史手填年龄数据。
	if age := calculateAgeFromBirthDate(user.BirthDate, time.Now()); age != nil {
		return age
	}
	return user.Age
}

func BuildCurrentUserView(user models.User) CurrentUserView {
	// Build the owner-facing profile payload in one place so /me stays consistent.
	// 统一构建本人资料载荷，确保 /me 接口字段保持一致。
	return CurrentUserView{
		UserID:           user.ID,
		Email:            user.Email,
		Phone:            user.Phone,
		Username:         stringValue(user.Username),
		Domain:           stringValue(user.Domain),
		DisplayName:      fallbackDisplayName(user),
		AvatarURL:        normalizeAvatarURL(user.AvatarURL),
		Signature:        strings.TrimSpace(user.Signature),
		BirthDate:        birthDateString(user.BirthDate),
		Birthday:         birthdayString(user.BirthDate),
		Age:              derivedProfileAge(user),
		Gender:           user.Gender,
		PhoneVisibility:  normalizeProfileVisibility(user.PhoneVisibility),
		EmailVisibility:  normalizeProfileVisibility(user.EmailVisibility),
		AgeVisibility:    normalizeProfileVisibility(user.AgeVisibility),
		GenderVisibility: normalizeProfileVisibility(user.GenderVisibility),
		Role:             NormalizeUserRole(user.Role),
		IsAdmin:          IsAdminRole(user.Role),
		Level:            user.Level,
		Status:           user.Status,
	}
}

func IsAccountActive(status string) bool {
	// Treat the legacy empty value as active so old data keeps working during rollout.
	// 将历史空值视为 active，避免旧数据在功能上线时被误拦截。
	normalized := strings.ToLower(strings.TrimSpace(status))
	return normalized == "" || normalized == "active"
}

func validatePasswordLength(password string) error {
	// Keep password length checks consistent across registration and password updates.
	// 统一注册与密码修改的长度校验规则。
	if len(password) < 8 {
		return errors.New("password too short")
	}
	return nil
}

func Register(db *gorm.DB, email string, phone string, password string) (models.User, error) {
	// Register a new user with email or phone.
	// 使用邮箱或手机号注册新用户。
	email = strings.TrimSpace(email)
	phone = strings.TrimSpace(phone)
	if email == "" && phone == "" {
		return models.User{}, errors.New("email or phone required")
	}
	if err := validatePasswordLength(password); err != nil {
		return models.User{}, err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return models.User{}, err
	}

	user := models.User{PasswordHash: string(hash), PasswordVersion: 1}
	if email != "" {
		user.Email = &email
	}
	if phone != "" {
		user.Phone = &phone
	}

	// Create the user record in a transaction.
	// 在事务内创建用户记录。
	if err := db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&user).Error; err != nil {
			return err
		}
		username, err := buildUserUsername(tx, user.ID, "")
		if err != nil {
			return err
		}
		if err := tx.Model(&user).Update("username", username).Error; err != nil {
			return err
		}
		user.Username = &username
		user.Domain = &username
		if err := tx.Model(&user).Update("domain", username).Error; err != nil {
			return err
		}
		return nil
	}); err != nil {
		return models.User{}, err
	}
	return user, nil
}

func Login(db *gorm.DB, account string, password string) (models.User, error) {
	// Login using email, phone, username, or domain + password; inactive accounts are rejected too.
	// 使用邮箱、手机号、用户名或域名 + 密码登录；停用账号同样会被拒绝。
	if account == "" || password == "" {
		return models.User{}, ErrInvalidCredentials
	}
	normalizedUsername := strings.ToLower(strings.TrimSpace(account))
	var user models.User
	if err := db.Where("email = ?", account).
		Or("phone = ?", account).
		Or("LOWER(COALESCE(username, '')) = ?", normalizedUsername).
		Or("LOWER(COALESCE(domain, '')) = ?", normalizedUsername).
		First(&user).Error; err != nil {
		return models.User{}, ErrInvalidCredentials
	}
	if !IsAccountActive(user.Status) {
		return models.User{}, ErrAccountInactive
	}
	if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)) != nil {
		return models.User{}, ErrInvalidCredentials
	}
	return user, nil
}

func ChangePassword(db *gorm.DB, userID string, currentPassword string, newPassword string) (models.User, error) {
	// Update the password hash and bump the password version so old JWTs stop working.
	// 更新密码哈希并提升密码版本，使旧 JWT 失效。
	if currentPassword == "" || newPassword == "" {
		return models.User{}, errors.New("password required")
	}
	if err := validatePasswordLength(newPassword); err != nil {
		return models.User{}, err
	}

	var updatedUser models.User
	if err := db.Transaction(func(tx *gorm.DB) error {
		var user models.User
		if err := tx.First(&user, "id = ?", userID).Error; err != nil {
			return err
		}
		if !IsAccountActive(user.Status) {
			return ErrAccountInactive
		}
		if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(currentPassword)) != nil {
			return ErrInvalidCredentials
		}

		hash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
		if err != nil {
			return err
		}

		nextVersion := user.PasswordVersion + 1
		if nextVersion <= 0 {
			nextVersion = 1
		}
		if err := tx.Model(&models.User{}).
			Where("id = ?", userID).
			Updates(map[string]any{
				"password_hash":    string(hash),
				"password_version": nextVersion,
			}).Error; err != nil {
			return err
		}

		user.PasswordHash = string(hash)
		user.PasswordVersion = nextVersion
		updatedUser = user
		return nil
	}); err != nil {
		return models.User{}, err
	}

	updatedUser.PasswordHash = ""
	return updatedUser, nil
}

func UpdateProfile(
	db *gorm.DB,
	userID string,
	displayName string,
	username string,
	domain string,
	avatarURL *string,
	signature string,
	birthDate *string,
	age *int,
	gender *string,
	phoneVisibility string,
	emailVisibility string,
	ageVisibility string,
	genderVisibility string,
) (models.User, error) {
	// Update user profile fields, including the identity handles.
	// 更新用户资料字段，并同步身份句柄。
	displayName = strings.TrimSpace(displayName)
	if displayName == "" {
		return models.User{}, errors.New("display name required")
	}
	signature = strings.TrimSpace(signature)
	var user models.User
	if err := db.First(&user, "id = ?", userID).Error; err != nil {
		return models.User{}, err
	}

	username = strings.TrimSpace(username)
	if username == "" {
		if user.Username != nil && strings.TrimSpace(*user.Username) != "" {
			username = strings.TrimSpace(*user.Username)
		} else {
			username = ""
		}
	}
	domain = strings.TrimSpace(domain)
	if domain == "" {
		if user.Domain != nil && strings.TrimSpace(*user.Domain) != "" {
			domain = strings.TrimSpace(*user.Domain)
		} else if username != "" {
			domain = username
		} else {
			domain = ""
		}
	}

	resolvedUsername := ""
	if username != "" {
		var err error
		resolvedUsername, err = normalizeAndValidateUsername(db, username, userID)
		if err != nil {
			return models.User{}, err
		}
	}
	resolvedDomain := ""
	if domain != "" {
		var err error
		resolvedDomain, err = normalizeAndValidateUsername(db, domain, userID)
		if err != nil {
			return models.User{}, err
		}
	}

	updates := map[string]any{
		"display_name": displayName,
		"signature":    signature,
	}
	if avatarURL != nil {
		updates["avatar_url"] = normalizeAvatarURL(*avatarURL)
	}
	// Keep optional identity fields writable without forcing the viewer-facing visibility rules to change.
	// 保留可选身份字段的写入能力，同时不影响查看端的可见性规则。
	if birthDate != nil {
		normalizedBirthDate, err := normalizeBirthDate(*birthDate)
		if err != nil {
			return models.User{}, err
		}
		if normalizedBirthDate == nil {
			updates["birth_date"] = nil
			updates["age"] = nil
		} else {
			updates["birth_date"] = *normalizedBirthDate
			if derivedAge := calculateAgeFromBirthDate(normalizedBirthDate, time.Now()); derivedAge != nil {
				updates["age"] = *derivedAge
			}
		}
	} else if age != nil {
		updates["age"] = *age
	}
	if gender != nil {
		trimmedGender := strings.TrimSpace(*gender)
		if trimmedGender == "" {
			updates["gender"] = nil
		} else {
			updates["gender"] = trimmedGender
		}
	}
	if resolvedUsername != "" {
		updates["username"] = resolvedUsername
	}
	if resolvedDomain != "" {
		updates["domain"] = resolvedDomain
	}
	if strings.TrimSpace(phoneVisibility) != "" {
		updates["phone_visibility"] = normalizeProfileVisibility(phoneVisibility)
	}
	if strings.TrimSpace(emailVisibility) != "" {
		updates["email_visibility"] = normalizeProfileVisibility(emailVisibility)
	}
	if strings.TrimSpace(ageVisibility) != "" {
		updates["age_visibility"] = normalizeProfileVisibility(ageVisibility)
	}
	if strings.TrimSpace(genderVisibility) != "" {
		updates["gender_visibility"] = normalizeProfileVisibility(genderVisibility)
	}
	if err := db.Model(&models.User{}).Where("id = ?", userID).Updates(updates).Error; err != nil {
		return models.User{}, err
	}
	return GetUser(db, userID)
}

func normalizeHostLabel(value string) string {
	// Convert arbitrary text into a lowercase alphanumeric host label.
	// 将任意文本转换为小写英数字主机标识。
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return ""
	}

	var builder strings.Builder
	for _, r := range value {
		switch {
		case r >= 'a' && r <= 'z':
			builder.WriteRune(r)
		case r >= '0' && r <= '9':
			builder.WriteRune(r)
		}
	}

	label := strings.TrimSpace(builder.String())
	if label == "" {
		return ""
	}
	return label
}

func buildUniqueHostLabel(db *gorm.DB, base string, excludeUserID string, excludeSpaceID string) (string, error) {
	// Generate a unique host label within the shared user/domain/space namespace.
	// 在用户、域名与空间共享的命名空间中生成唯一主机标识。
	base = normalizeHostLabel(base)
	if base == "" {
		return "", errors.New("host label required")
	}
	if len(base) > 63 {
		base = base[:63]
	}

	available, err := isHostLabelAvailable(db, base, excludeUserID, excludeSpaceID)
	if err != nil {
		return "", err
	}
	if available {
		return base, nil
	}

	prefix := base
	if len(prefix) > 57 {
		prefix = prefix[:57]
	}
	for attempt := 0; attempt < 8; attempt++ {
		suffix, err := randomHexString(3)
		if err != nil {
			return "", err
		}
		candidate := prefix + suffix
		if len(candidate) > 63 {
			candidate = candidate[:63]
		}
		available, err := isHostLabelAvailable(db, candidate, excludeUserID, excludeSpaceID)
		if err != nil {
			return "", err
		}
		if available {
			return candidate, nil
		}
	}
	return "", errors.New("failed to generate host label")
}

func isHostLabelAvailable(db *gorm.DB, label string, excludeUserID string, excludeSpaceID string) (bool, error) {
	// Check whether a username, domain, or space subdomain is already in use.
	// 检查用户名、域名或空间二级域名是否已被占用。
	var userCount int64
	userQuery := db.Model(&models.User{}).Where("LOWER(COALESCE(username, '')) = ? OR LOWER(COALESCE(domain, '')) = ?", label, label)
	if excludeUserID != "" {
		userQuery = userQuery.Where("id <> ?", excludeUserID)
	}
	if err := userQuery.Count(&userCount).Error; err != nil {
		return false, err
	}
	if userCount > 0 {
		return false, nil
	}

	var spaceCount int64
	spaceQuery := db.Model(&models.Space{}).Where("subdomain = ?", label)
	if excludeSpaceID != "" {
		spaceQuery = spaceQuery.Where("id <> ?", excludeSpaceID)
	}
	if err := spaceQuery.Count(&spaceCount).Error; err != nil {
		return false, err
	}
	return spaceCount == 0, nil
}

func normalizeAndValidateUsername(db *gorm.DB, requested string, excludeUserID string) (string, error) {
	// Normalize a requested username/domain handle and ensure it is available.
	// 规范化请求的用户名/域名句柄并检查是否可用。
	requested = strings.ToLower(strings.TrimSpace(requested))
	if requested == "" {
		return "", errors.New("username or domain required")
	}
	if len(requested) > 63 {
		return "", errors.New("username or domain too long")
	}
	if !usernamePattern.MatchString(requested) {
		return "", errors.New("username or domain may only contain letters and numbers")
	}
	available, err := isHostLabelAvailable(db, requested, excludeUserID, "")
	if err != nil {
		return "", err
	}
	if !available {
		return "", errors.New("username or domain already exists")
	}
	return requested, nil
}

func buildUserUsername(db *gorm.DB, userID string, seed string) (string, error) {
	// Build a stable username handle and keep it unique across host labels.
	// 为用户构建稳定的用户名句柄，并确保与主机标识命名空间唯一。
	base := normalizeHostLabel(seed)
	if base == "" {
		base = "u" + normalizeHostLabel(strings.ReplaceAll(userID, "-", ""))
	}
	if base == "" {
		base = "user"
	}
	return buildUniqueHostLabel(db, base, userID, "")
}

func CreateSpace(db *gorm.DB, userID string, spaceType string, visibility string, name string, desc string, subdomain string) (models.Space, error) {
	// Create a private/public space for a user.
	// 为用户创建私人/公共空间。
	spaceType = strings.ToLower(strings.TrimSpace(spaceType))
	visibility = strings.ToLower(strings.TrimSpace(visibility))
	name = strings.TrimSpace(name)
	desc = strings.TrimSpace(desc)
	if spaceType != "private" && spaceType != "public" {
		return models.Space{}, errors.New("space type must be private or public")
	}
	if name == "" {
		return models.Space{}, errors.New("space name required")
	}

	resolvedVisibility, err := normalizeSpaceVisibilityValue(spaceType, visibility, "")
	if err != nil {
		return models.Space{}, err
	}
	if spaceType == "private" {
		resolvedVisibility = "private"
	}

	resolvedSubdomain, err := buildSpaceSubdomain(db, userID, spaceType, name, subdomain)
	if err != nil {
		return models.Space{}, err
	}

	space := models.Space{
		UserID:      userID,
		Type:        spaceType,
		Source:      "user",
		Visibility:  resolvedVisibility,
		Subdomain:   resolvedSubdomain,
		Name:        name,
		Description: desc,
		Status:      "active",
	}
	if err := db.Create(&space).Error; err != nil {
		return models.Space{}, err
	}
	return space, nil
}

func ListSpaces(db *gorm.DB, userID string) ([]models.Space, error) {
	// List the spaces owned by the current user.
	// 列出当前用户自己创建的空间。
	var spaces []models.Space
	if err := db.Where(
		"user_id = ? AND COALESCE(source, '') <> ?",
		userID,
		"system",
	).Order("created_at asc").Find(&spaces).Error; err != nil {
		return nil, err
	}
	return spaces, nil
}

func ListUserSpaces(db *gorm.DB, viewerID string, targetUserID string, visibility string) ([]models.Space, error) {
	// List the spaces shown on a user's profile page.
	// 列出个人主页上展示的空间。
	targetUserID = strings.TrimSpace(targetUserID)
	if targetUserID == "" {
		return []models.Space{}, nil
	}
	visibility = strings.ToLower(strings.TrimSpace(visibility))
	if visibility == "" {
		visibility = "public"
	}
	if visibility == "all" && viewerID == targetUserID {
		return ListSpaces(db, targetUserID)
	}
	if visibility != "public" {
		visibility = "public"
	}

	var spaces []models.Space
	if err := db.Where(
		"user_id = ? AND visibility = ? AND COALESCE(source, '') <> ? AND status = ?",
		targetUserID,
		visibility,
		"system",
		"active",
	).Order("created_at asc").Find(&spaces).Error; err != nil {
		return nil, err
	}
	return spaces, nil
}

func buildSpaceSubdomain(db *gorm.DB, userID string, spaceType string, name string, requested string) (string, error) {
	// Normalize or generate a stable subdomain for a space.
	// 为空间规范化或生成稳定的二级域名。
	requested = strings.ToLower(strings.TrimSpace(requested))
	if requested != "" {
		if len(requested) > 63 {
			return "", errors.New("space subdomain too long")
		}
		if !spaceSubdomainPattern.MatchString(requested) {
			return "", errors.New("space subdomain may only contain letters and numbers")
		}
		available, err := isSpaceSubdomainAvailable(db, requested, "")
		if err != nil {
			return "", err
		}
		if !available {
			return "", errors.New("space subdomain already exists")
		}
		return requested, nil
	}

	base := normalizeSpaceSubdomain(name)
	if base == "" {
		base = normalizeSpaceSubdomain(spaceType)
	}
	if base == "" {
		base = "space"
	}
	if len(base) > 57 {
		base = base[:57]
	}

	for attempt := 0; attempt < 8; attempt++ {
		suffix, err := randomHexString(3)
		if err != nil {
			return "", err
		}
		candidate := fmt.Sprintf("%s%s", base, suffix)
		available, err := isSpaceSubdomainAvailable(db, candidate, "")
		if err != nil {
			return "", err
		}
		if available {
			return candidate, nil
		}
	}

	return "", errors.New("failed to generate space subdomain")
}

func normalizeSpaceSubdomain(value string) string {
	// Convert free-form text into a lowercase alphanumeric slug.
	// 将自由文本转换为小写的英文字母和数字 slug。
	return normalizeHostLabel(value)
}

func randomHexString(byteCount int) (string, error) {
	// Generate a short random hex suffix for subdomain uniqueness.
	// 生成用于二级域名唯一化的短随机十六进制后缀。
	if byteCount < 1 {
		byteCount = 1
	}
	buf := make([]byte, byteCount)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return fmt.Sprintf("%x", buf), nil
}

func isSpaceSubdomainAvailable(db *gorm.DB, subdomain string, excludeSpaceID string) (bool, error) {
	// Check whether a subdomain is already in use.
	// 检查二级域名是否已经被占用。
	return isHostLabelAvailable(db, subdomain, "", excludeSpaceID)
}

func firstSpaceByType(db *gorm.DB, userID string, spaceType string) (models.Space, error) {
	// Load the earliest space of a specific type for fallback usage.
	// 加载指定类型的最早空间，作为回退选择。
	var space models.Space
	if err := db.Where("user_id = ? AND type = ? AND COALESCE(source, '') <> ?", userID, spaceType, "system").Order("created_at asc").First(&space).Error; err != nil {
		return models.Space{}, err
	}
	return space, nil
}

func loadOwnedSpaceByID(db *gorm.DB, userID string, spaceID string) (models.Space, error) {
	// Load a space owned by the current user.
	// 加载当前用户拥有的空间。
	var space models.Space
	if err := db.Where("id = ? AND user_id = ?", spaceID, userID).First(&space).Error; err != nil {
		return models.Space{}, err
	}
	return space, nil
}

func UpdateSpace(db *gorm.DB, userID string, spaceID string, name string, desc string, subdomain string, visibility string) (models.Space, error) {
	// Update an existing space owned by the current user.
	// 更新当前用户拥有的空间。
	name = strings.TrimSpace(name)
	desc = strings.TrimSpace(desc)
	subdomain = strings.TrimSpace(subdomain)
	if name == "" {
		return models.Space{}, errors.New("space name required")
	}
	if subdomain == "" {
		return models.Space{}, errors.New("space subdomain required")
	}

	var space models.Space
	if err := db.First(&space, "id = ? AND user_id = ?", spaceID, userID).Error; err != nil {
		return models.Space{}, err
	}

	resolvedSubdomain, err := normalizeAndValidateSpaceSubdomain(db, subdomain, space.ID)
	if err != nil {
		return models.Space{}, err
	}
	resolvedVisibility, err := normalizeSpaceVisibilityValue(space.Type, visibility, space.Visibility)
	if err != nil {
		return models.Space{}, err
	}
	if space.Type == "private" {
		resolvedVisibility = "private"
	}

	updates := map[string]any{
		"name":        name,
		"description": desc,
		"visibility":  resolvedVisibility,
		"subdomain":   resolvedSubdomain,
		"updated_at":  time.Now(),
	}
	if err := db.Model(&space).Updates(updates).Error; err != nil {
		return models.Space{}, err
	}
	if err := db.First(&space, "id = ?", space.ID).Error; err != nil {
		return models.Space{}, err
	}
	return space, nil
}

func normalizeAndValidateSpaceSubdomain(db *gorm.DB, requested string, excludeSpaceID string) (string, error) {
	// Normalize a requested subdomain and ensure it is available.
	// 规范化请求的二级域名并检查是否可用。
	requested = strings.ToLower(strings.TrimSpace(requested))
	if requested == "" {
		return "", errors.New("space subdomain required")
	}
	if len(requested) > 63 {
		return "", errors.New("space subdomain too long")
	}
	if !spaceSubdomainPattern.MatchString(requested) {
		return "", errors.New("space subdomain may only contain letters and numbers")
	}
	available, err := isHostLabelAvailable(db, requested, "", excludeSpaceID)
	if err != nil {
		return "", err
	}
	if !available {
		return "", errors.New("space subdomain already exists")
	}
	return requested, nil
}

func DeleteSpace(db *gorm.DB, userID string, spaceID string) error {
	// Delete one owned space and all its posts.
	// 删除一个空间及其下属全部文章。
	var mediaRefs []postMediaFileRef
	err := db.Transaction(func(tx *gorm.DB) error {
		var space models.Space
		if err := tx.First(&space, "id = ? AND user_id = ?", spaceID, userID).Error; err != nil {
			return err
		}

		var posts []models.Post
		if err := tx.Select("id").Where("space_id = ?", spaceID).Find(&posts).Error; err != nil {
			return err
		}
		postIDs := make([]string, 0, len(posts))
		for _, post := range posts {
			postIDs = append(postIDs, post.ID)
		}
		refs, err := deletePostCascade(tx, postIDs)
		if err != nil {
			return err
		}
		mediaRefs = refs
		if err := tx.Delete(&space).Error; err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return err
	}
	cleanupPostMediaFiles(mediaRefs, true)
	return nil
}

func MarkLegacySystemSpaces(db *gorm.DB) error {
	// Mark legacy seeded spaces by their original name and subdomain pattern.
	// 按旧版默认名称和二级域名特征标记历史种子空间。
	return db.Model(&models.Space{}).
		Where("((name = ? AND subdomain LIKE ?) OR (name = ? AND subdomain LIKE ?))",
			"我的私人空间", "private-%", "我的公共空间", "public-%").
		Update("source", "system").Error
}

func BackfillLegacySpaceVisibility(db *gorm.DB) error {
	// Backfill visibility for legacy rows so space routing stays deterministic.
	// 为历史记录回填可见范围，确保空间路由结果稳定。
	if err := db.Model(&models.Space{}).
		Where("COALESCE(visibility, '') = '' AND type = ?", "private").
		Update("visibility", "private").Error; err != nil {
		return err
	}
	if err := db.Model(&models.Space{}).
		Where("COALESCE(visibility, '') = '' AND type = ?", "public").
		Update("visibility", "public").Error; err != nil {
		return err
	}
	return nil
}

func SearchUsers(db *gorm.DB, userID string, query string, limit int) ([]UserSearchView, error) {
	// Search users by display name, username, email, phone, or user id.
	// 按展示名、用户名、邮箱、手机号或用户 ID 搜索用户。
	query = strings.TrimSpace(query)
	if query == "" {
		return []UserSearchView{}, nil
	}
	if limit < 1 {
		limit = 1
	}
	if limit > 20 {
		limit = 20
	}

	likeQuery := "%" + strings.ToLower(query) + "%"
	var users []models.User
	if err := db.Select("id").
		Where("id <> ?", userID).
		Where(
			"LOWER(display_name) LIKE ? OR LOWER(COALESCE(username, '')) LIKE ? OR LOWER(COALESCE(domain, '')) LIKE ? OR LOWER(COALESCE(email, '')) LIKE ? OR LOWER(COALESCE(phone, '')) LIKE ? OR LOWER(COALESCE(signature, '')) LIKE ? OR CAST(id AS TEXT) LIKE ?",
			likeQuery, likeQuery, likeQuery, likeQuery, likeQuery, likeQuery, "%"+query+"%",
		).
		Order("created_at desc").
		Limit(limit).
		Find(&users).Error; err != nil {
		return nil, err
	}

	items := make([]UserSearchView, 0, len(users))
	for _, user := range users {
		view, err := GetPublicUserProfile(db, userID, user.ID)
		if err != nil {
			continue
		}
		item := UserSearchView{
			UserID:         view.UserID,
			DisplayName:    view.DisplayName,
			AvatarURL:      view.AvatarURL,
			Username:       view.Username,
			Domain:         view.Domain,
			Signature:      view.Signature,
			Email:          view.Email,
			Phone:          view.Phone,
			Age:            view.Age,
			Gender:         view.Gender,
			RelationStatus: view.RelationStatus,
			Direction:      view.Direction,
		}
		items = append(items, item)
	}
	return items, nil
}

func GetPublicUserProfile(db *gorm.DB, viewerID string, targetUserID string) (PublicUserProfileView, error) {
	// Load a user's public profile with relation metadata.
	// 加载用户公开资料，并补充关系元数据。
	user, err := GetUser(db, targetUserID)
	if err != nil {
		return PublicUserProfileView{}, err
	}
	view := PublicUserProfileView{
		UserID:      user.ID,
		DisplayName: fallbackDisplayName(user),
		AvatarURL:   normalizeAvatarURL(user.AvatarURL),
		Username:    stringValue(user.Username),
		Domain:      stringValue(user.Domain),
		Signature:   strings.TrimSpace(user.Signature),
		Status:      user.Status,
	}
	if viewerID == "" || viewerID == targetUserID {
		view.Email = user.Email
		view.Phone = user.Phone
		view.Birthday = birthdayString(user.BirthDate)
		view.Age = derivedProfileAge(user)
		view.Gender = user.Gender
		return view, nil
	}

	isFriend := false
	var relation models.Friend
	if err := db.Where(
		"(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)",
		viewerID, targetUserID, targetUserID, viewerID,
	).First(&relation).Error; err == nil {
		view.RelationStatus = relation.Status
		if relation.UserID == viewerID {
			view.Direction = "outgoing"
		} else {
			view.Direction = "incoming"
		}
		isFriend = relation.Status == "accepted"
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return PublicUserProfileView{}, err
	}
	if isProfileFieldVisible(user.EmailVisibility, isFriend) {
		view.Email = user.Email
	}
	if isProfileFieldVisible(user.PhoneVisibility, isFriend) {
		view.Phone = user.Phone
	}
	if isProfileFieldVisible(user.AgeVisibility, isFriend) {
		view.Birthday = birthdayString(user.BirthDate)
		view.Age = derivedProfileAge(user)
	}
	if isProfileFieldVisible(user.GenderVisibility, isFriend) {
		view.Gender = user.Gender
	}
	return view, nil
}

func GetPublicUserProfileByUsername(db *gorm.DB, viewerID string, username string) (PublicUserProfileView, error) {
	// Load a user's public profile by username.
	// 根据用户名加载用户公开资料。
	user, err := GetUserByUsername(db, username)
	if err != nil {
		return PublicUserProfileView{}, err
	}
	return GetPublicUserProfile(db, viewerID, user.ID)
}

func GetPublicUserProfileByDomain(db *gorm.DB, viewerID string, domain string) (PublicUserProfileView, error) {
	// Load a user's public profile by domain handle.
	// 根据域名身份句柄加载用户公开资料。
	user, err := GetUserByDomain(db, domain)
	if err != nil {
		return PublicUserProfileView{}, err
	}
	return GetPublicUserProfile(db, viewerID, user.ID)
}

func normalizeProfileVisibility(raw string) string {
	// Normalize field visibility labels used by profile privacy controls.
	// 规范化资料隐私控制中使用的可见范围标签。
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "public":
		return "public"
	case "friends":
		return "friends"
	default:
		return "private"
	}
}

func isProfileFieldVisible(raw string, isFriend bool) bool {
	// Decide whether a profile field can be exposed to another viewer.
	// 判断资料字段是否可以向其他查看者公开。
	switch normalizeProfileVisibility(raw) {
	case "public":
		return true
	case "friends":
		return isFriend
	default:
		return false
	}
}

func EnsureUserUsernames(db *gorm.DB) error {
	// Backfill usernames and domains for users that do not have them yet.
	// 为尚未设置用户名和域名的用户回填默认值。
	var users []models.User
	if err := db.Where("COALESCE(username, '') = '' OR COALESCE(domain, '') = ''").Order("created_at asc").Find(&users).Error; err != nil {
		return err
	}
	for _, user := range users {
		username, err := buildUserUsername(db, user.ID, fallbackDisplayName(user))
		if err != nil {
			return err
		}
		if err := db.Model(&models.User{}).Where("id = ?", user.ID).Update("username", username).Error; err != nil {
			return err
		}
		if err := db.Model(&models.User{}).Where("id = ?", user.ID).Update("domain", username).Error; err != nil {
			return err
		}
	}
	return nil
}

func AddFriend(db *gorm.DB, userID string, friendID string, account string) (models.Friend, error) {
	// Send a friend request.
	// 发送好友请求。
	friendID, err := resolveFriendID(db, userID, friendID, account)
	if err != nil {
		return models.Friend{}, err
	}
	if friendID == "" {
		return models.Friend{}, errors.New("friend id required")
	}
	if userID == friendID {
		return models.Friend{}, errors.New("cannot add yourself")
	}
	var existing models.Friend
	if err := db.Where(
		"(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)",
		userID, friendID, friendID, userID,
	).First(&existing).Error; err == nil {
		return models.Friend{}, errors.New("friend request already exists")
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return models.Friend{}, err
	}
	friend := models.Friend{UserID: userID, FriendID: friendID, Status: "pending", CreatedAt: time.Now()}
	if err := db.Create(&friend).Error; err != nil {
		return models.Friend{}, err
	}
	return friend, nil
}

func resolveFriendID(db *gorm.DB, userID string, friendID string, account string) (string, error) {
	// Resolve a target user from explicit id or account identifier.
	// 从显式 ID 或账号标识解析目标用户。
	friendID = strings.TrimSpace(friendID)
	account = strings.TrimSpace(account)
	if friendID == "" && account == "" {
		return "", errors.New("friend id or account required")
	}

	lookup := friendID
	if lookup == "" {
		lookup = account
	}

	var user models.User
	if err := db.Select("id").Where("id = ? OR email = ? OR phone = ? OR LOWER(COALESCE(username, '')) = ? OR LOWER(COALESCE(domain, '')) = ?", lookup, lookup, lookup, strings.ToLower(lookup), strings.ToLower(lookup)).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", errors.New("friend account not found")
		}
		return "", err
	}
	if user.ID == userID {
		return "", errors.New("cannot add yourself")
	}
	return user.ID, nil
}

func ListFriends(db *gorm.DB, userID string) ([]FriendView, error) {
	// List user's outgoing and incoming friend relations.
	// 列出用户发起和收到的好友关系。
	var relations []models.Friend
	if err := db.Where("user_id = ? OR friend_id = ?", userID, userID).Order("created_at desc").Find(&relations).Error; err != nil {
		return nil, err
	}

	items := make([]FriendView, 0, len(relations))
	for _, relation := range relations {
		friendUserID := relation.UserID
		item := FriendView{
			Status:    relation.Status,
			CreatedAt: relation.CreatedAt,
		}
		if relation.UserID == userID {
			friendUserID = relation.FriendID
			item.FriendID = relation.FriendID
			item.Direction = "outgoing"
		} else {
			friendUserID = relation.UserID
			item.FriendID = relation.UserID
			item.Direction = "incoming"
		}

		// Reuse the public profile visibility rules so friend previews do not leak private fields.
		// 复用公开主页的可见性规则，避免好友预览泄露私密字段。
		if view, err := GetPublicUserProfile(db, userID, friendUserID); err == nil {
			item.DisplayName = view.DisplayName
			item.AvatarURL = view.AvatarURL
			item.Username = view.Username
			item.Domain = view.Domain
			item.Signature = view.Signature
			item.Email = view.Email
			item.Phone = view.Phone
		} else {
			var friendUser models.User
			if err := db.Select("id", "display_name", "avatar_url", "username", "domain", "signature", "email", "phone").First(&friendUser, "id = ?", friendUserID).Error; err == nil {
				item.DisplayName = friendUser.DisplayName
				item.AvatarURL = normalizeAvatarURL(friendUser.AvatarURL)
				item.Username = stringValue(friendUser.Username)
				item.Domain = stringValue(friendUser.Domain)
				item.Signature = strings.TrimSpace(friendUser.Signature)
				item.Email = friendUser.Email
				item.Phone = friendUser.Phone
			}
		}

		items = append(items, item)
	}
	return items, nil
}

func AcceptFriend(db *gorm.DB, userID string, friendID string) (models.Friend, error) {
	// Accept an incoming friend request.
	// 接受收到的好友请求。
	friendID = strings.TrimSpace(friendID)
	if friendID == "" {
		return models.Friend{}, errors.New("friend id required")
	}

	var relation models.Friend
	if err := db.Where("user_id = ? AND friend_id = ?", friendID, userID).First(&relation).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return models.Friend{}, errors.New("friend request not found")
		}
		return models.Friend{}, err
	}
	if relation.Status == "accepted" {
		return relation, nil
	}
	if relation.Status == "blocked" {
		return models.Friend{}, errors.New("blocked relation cannot be accepted")
	}
	if err := db.Model(&relation).Update("status", "accepted").Error; err != nil {
		return models.Friend{}, err
	}
	relation.Status = "accepted"
	return relation, nil
}

func CreateSubscription(db *gorm.DB, userID string, planID string) (models.Subscription, error) {
	// Create a subscription entry.
	// 创建订阅记录。
	planID = strings.TrimSpace(planID)
	if planID == "" {
		return models.Subscription{}, errors.New("plan id required")
	}
	now := time.Now()
	endedAt := now.Add(30 * 24 * time.Hour)
	sub := models.Subscription{UserID: userID, PlanID: planID, Status: "active", StartedAt: now, EndedAt: &endedAt}
	if err := db.Transaction(func(tx *gorm.DB) error {
		// Expire previous active subscriptions before creating the new one.
		// 创建新订阅前将旧的激活订阅设为过期。
		if err := tx.Model(&models.Subscription{}).
			Where("user_id = ? AND status = ?", userID, "active").
			Updates(map[string]any{
				"status":   "expired",
				"ended_at": now,
			}).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.User{}).
			Where("id = ?", userID).
			Update("level", normalizeUserLevel(planID)).Error; err != nil {
			return err
		}
		return tx.Create(&sub).Error
	}); err != nil {
		return models.Subscription{}, err
	}
	return sub, nil
}

func normalizeUserLevel(planID string) string {
	// Map a plan identifier to the user's membership level.
	// 将订阅方案标识映射为用户会员等级。
	switch strings.ToLower(strings.TrimSpace(planID)) {
	case "vip":
		return "vip"
	case "premium", "monthly":
		return "premium"
	default:
		return "basic"
	}
}

func GetCurrentSubscription(db *gorm.DB, userID string) (SubscriptionView, error) {
	// Fetch the latest subscription of the current user.
	// 获取当前用户最新的一条订阅记录。
	var sub models.Subscription
	if err := db.Where("user_id = ?", userID).Order("started_at desc").First(&sub).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return SubscriptionView{}, nil
		}
		return SubscriptionView{}, err
	}
	return SubscriptionView{
		PlanID:    sub.PlanID,
		Status:    sub.Status,
		StartedAt: sub.StartedAt,
		EndedAt:   sub.EndedAt,
	}, nil
}

func ListExternalAccounts(db *gorm.DB, userID string) ([]ExternalAccountView, error) {
	// List the current user's external account bindings.
	// 列出当前用户的外部账号绑定。
	var accounts []models.ExternalAccount
	if err := db.Where("user_id = ? AND binding_status <> ?", userID, "revoked").Order("created_at desc").Find(&accounts).Error; err != nil {
		return nil, err
	}

	items := make([]ExternalAccountView, 0, len(accounts))
	for _, account := range accounts {
		items = append(items, ExternalAccountView{
			ID:             account.ID,
			Provider:       account.Provider,
			Chain:          account.Chain,
			AccountAddress: account.AccountAddress,
			BindingStatus:  account.BindingStatus,
			Metadata:       account.Metadata,
			CreatedAt:      account.CreatedAt,
		})
	}
	return items, nil
}

func BindExternalAccount(db *gorm.DB, userID string, provider string, chain string, accountAddress string, signaturePayload string) (models.ExternalAccount, error) {
	// Bind an external account to the current user.
	// 将外部账号绑定到当前用户。
	provider, chain, accountAddress, identifier, metadata, err := normalizeExternalAccountBinding(provider, chain, accountAddress, signaturePayload)
	if err != nil {
		return models.ExternalAccount{}, err
	}
	var existing models.ExternalAccount
	if err := db.Where("provider = ? AND account_identifier = ?", provider, identifier).First(&existing).Error; err == nil {
		if existing.UserID == userID && existing.BindingStatus == "revoked" {
			updates := map[string]any{
				"chain":           chain,
				"account_address": accountAddress,
				"binding_status":  "active",
				"metadata":        metadata,
				"updated_at":      time.Now(),
			}
			if err := db.Model(&existing).Updates(updates).Error; err != nil {
				return models.ExternalAccount{}, err
			}
			existing.Chain = chain
			existing.AccountAddress = accountAddress
			existing.BindingStatus = "active"
			existing.Metadata = metadata
			return existing, nil
		}
		if existing.UserID == userID {
			return models.ExternalAccount{}, errors.New("external account already bound")
		}
		return models.ExternalAccount{}, errors.New("external account already in use")
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return models.ExternalAccount{}, err
	}

	account := models.ExternalAccount{
		UserID:            userID,
		Provider:          provider,
		Chain:             chain,
		AccountIdentifier: identifier,
		AccountAddress:    accountAddress,
		BindingStatus:     "active",
		Metadata:          metadata,
	}
	if err := db.Create(&account).Error; err != nil {
		return models.ExternalAccount{}, err
	}
	return account, nil
}

func RemoveExternalAccount(db *gorm.DB, userID string, externalAccountID string) error {
	// Remove a bound external account from the current user.
	// 删除当前用户已绑定的外部账号。
	externalAccountID = strings.TrimSpace(externalAccountID)
	if externalAccountID == "" {
		return errors.New("external account id required")
	}
	var account models.ExternalAccount
	if err := db.Where("id = ? AND user_id = ?", externalAccountID, userID).First(&account).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("external account not found")
		}
		return err
	}
	if account.BindingStatus == "revoked" {
		return errors.New("external account already removed")
	}
	return db.Model(&account).Updates(map[string]any{
		"binding_status": "revoked",
		"updated_at":     time.Now(),
	}).Error
}

func stringValue(value *string) string {
	// Safely unwrap a nullable string pointer.
	// 安全解包可空字符串指针。
	if value == nil {
		return ""
	}
	return strings.TrimSpace(*value)
}

func normalizeExternalAccountBinding(provider string, chain string, accountAddress string, signaturePayload string) (string, string, string, string, string, error) {
	// Normalize provider, chain, address, and signature payload before binding.
	// 在绑定前统一规范化提供方、链、地址和签名载荷。
	provider = strings.ToLower(strings.TrimSpace(provider))
	chain = strings.ToLower(strings.TrimSpace(chain))
	accountAddress = strings.TrimSpace(accountAddress)
	signaturePayload = strings.TrimSpace(signaturePayload)

	if provider == "" {
		return "", "", "", "", "", errors.New("provider required")
	}
	if chain == "" {
		return "", "", "", "", "", errors.New("chain required")
	}
	if accountAddress == "" {
		return "", "", "", "", "", errors.New("account address required")
	}
	if len(signaturePayload) < 16 {
		return "", "", "", "", "", errors.New("signature payload required")
	}
	if !isSupportedChain(provider, chain) {
		return "", "", "", "", "", errors.New("unsupported provider or chain")
	}
	if err := validateExternalAccountAddress(provider, accountAddress); err != nil {
		return "", "", "", "", "", err
	}

	identifier := strings.ToLower(accountAddress)
	metadata := fmt.Sprintf("verification=client_signature_payload;payload_length=%d", len(signaturePayload))
	return provider, chain, accountAddress, identifier, metadata, nil
}

func isSupportedChain(provider string, chain string) bool {
	// Validate the provider-chain combination against the current allowlist.
	// 按当前允许列表校验提供方与链的组合。
	allowed := map[string]map[string]struct{}{
		"evm": {
			"ethereum": {},
			"base":     {},
			"bsc":      {},
			"polygon":  {},
		},
		"solana": {
			"solana": {},
		},
		"tron": {
			"tron": {},
		},
	}
	chains, ok := allowed[provider]
	if !ok {
		return false
	}
	_, ok = chains[chain]
	return ok
}

func validateExternalAccountAddress(provider string, accountAddress string) error {
	// Apply basic address format validation per provider.
	// 按提供方应用基础地址格式校验。
	switch provider {
	case "evm":
		if !evmAddressPattern.MatchString(accountAddress) {
			return errors.New("invalid evm address")
		}
	case "solana":
		if !solanaAddressPattern.MatchString(accountAddress) {
			return errors.New("invalid solana address")
		}
	case "tron":
		if !tronAddressPattern.MatchString(accountAddress) {
			return errors.New("invalid tron address")
		}
	default:
		return errors.New("unsupported provider or chain")
	}
	return nil
}
