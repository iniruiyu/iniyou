package service

import (
	"errors"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"account-service/internal/models"
)

var ErrInvalidCredentials = errors.New("invalid credentials")

type FriendView struct {
	// Friend relation view for API consumption.
	// 提供给接口层使用的好友关系视图。
	FriendID    string    `json:"friend_id"`
	DisplayName string    `json:"display_name"`
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
	Email          *string `json:"email"`
	Phone          *string `json:"phone"`
	RelationStatus string  `json:"relation_status,omitempty"`
	Direction      string  `json:"direction,omitempty"`
}

type SubscriptionView struct {
	// Subscription view returned to clients.
	// 返回给客户端的订阅视图。
	PlanID    string     `json:"plan_id"`
	Status    string     `json:"status"`
	StartedAt time.Time  `json:"started_at"`
	EndedAt   *time.Time `json:"ended_at"`
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

func Register(db *gorm.DB, email string, phone string, password string) (models.User, error) {
	// Register a new user with email or phone.
	// 使用邮箱或手机号注册新用户。
	email = strings.TrimSpace(email)
	phone = strings.TrimSpace(phone)
	if email == "" && phone == "" {
		return models.User{}, errors.New("email or phone required")
	}
	if len(password) < 8 {
		return models.User{}, errors.New("password too short")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return models.User{}, err
	}

	user := models.User{PasswordHash: string(hash)}
	if email != "" {
		user.Email = &email
	}
	if phone != "" {
		user.Phone = &phone
	}

	// Create user and default spaces in a transaction.
	// 在事务内创建用户及默认空间。
	if err := db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&user).Error; err != nil {
			return err
		}
		defaultSpaces := []models.Space{
			{UserID: user.ID, Type: "private", Name: "我的私人空间", Description: "默认私人空间"},
			{UserID: user.ID, Type: "public", Name: "我的公共空间", Description: "默认公共空间"},
		}
		return tx.Create(&defaultSpaces).Error
	}); err != nil {
		return models.User{}, err
	}
	return user, nil
}

func Login(db *gorm.DB, account string, password string) (models.User, error) {
	// Login using email or phone + password.
	// 使用邮箱或手机号 + 密码登录。
	if account == "" || password == "" {
		return models.User{}, ErrInvalidCredentials
	}
	var user models.User
	if err := db.Where("email = ?", account).Or("phone = ?", account).First(&user).Error; err != nil {
		return models.User{}, ErrInvalidCredentials
	}
	if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)) != nil {
		return models.User{}, ErrInvalidCredentials
	}
	return user, nil
}

func UpdateProfile(db *gorm.DB, userID string, displayName string) (models.User, error) {
	// Update user profile fields.
	// 更新用户资料字段。
	displayName = strings.TrimSpace(displayName)
	if displayName == "" {
		return models.User{}, errors.New("display name required")
	}
	if err := db.Model(&models.User{}).Where("id = ?", userID).Update("display_name", displayName).Error; err != nil {
		return models.User{}, err
	}
	return GetUser(db, userID)
}

func CreateSpace(db *gorm.DB, userID string, spaceType string, name string, desc string) (models.Space, error) {
	// Create a private/public space for a user.
	// 为用户创建私人/公共空间。
	spaceType = strings.ToLower(strings.TrimSpace(spaceType))
	name = strings.TrimSpace(name)
	if spaceType != "private" && spaceType != "public" {
		return models.Space{}, errors.New("space type must be private or public")
	}
	if name == "" {
		return models.Space{}, errors.New("space name required")
	}
	space := models.Space{UserID: userID, Type: spaceType, Name: name, Description: desc}
	if err := db.Create(&space).Error; err != nil {
		return models.Space{}, err
	}
	return space, nil
}

func ListSpaces(db *gorm.DB, userID string) ([]models.Space, error) {
	// List spaces of a user.
	// 列出用户的空间。
	var spaces []models.Space
	if err := db.Where("user_id = ?", userID).Find(&spaces).Error; err != nil {
		return nil, err
	}
	return spaces, nil
}

func SearchUsers(db *gorm.DB, userID string, query string, limit int) ([]UserSearchView, error) {
	// Search users by display name, email, phone, or user id.
	// 按展示名、邮箱、手机号或用户 ID 搜索用户。
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
	if err := db.Select("id", "display_name", "email", "phone").
		Where("id <> ?", userID).
		Where(
			"LOWER(display_name) LIKE ? OR LOWER(COALESCE(email, '')) LIKE ? OR LOWER(COALESCE(phone, '')) LIKE ? OR CAST(id AS TEXT) LIKE ?",
			likeQuery, likeQuery, likeQuery, "%"+query+"%",
		).
		Order("created_at desc").
		Limit(limit).
		Find(&users).Error; err != nil {
		return nil, err
	}

	peerIDs := make([]string, 0, len(users))
	for _, user := range users {
		peerIDs = append(peerIDs, user.ID)
	}

	relationsByPeer := map[string]models.Friend{}
	if len(peerIDs) > 0 {
		var relations []models.Friend
		if err := db.Where(
			"(user_id = ? AND friend_id IN ?) OR (friend_id = ? AND user_id IN ?)",
			userID, peerIDs, userID, peerIDs,
		).Find(&relations).Error; err != nil {
			return nil, err
		}
		for _, relation := range relations {
			peerID := relation.FriendID
			if relation.FriendID == userID {
				peerID = relation.UserID
			}
			relationsByPeer[peerID] = relation
		}
	}

	items := make([]UserSearchView, 0, len(users))
	for _, user := range users {
		item := UserSearchView{
			UserID:      user.ID,
			DisplayName: user.DisplayName,
			Email:       user.Email,
			Phone:       user.Phone,
		}
		if relation, ok := relationsByPeer[user.ID]; ok {
			item.RelationStatus = relation.Status
			if relation.UserID == userID {
				item.Direction = "outgoing"
			} else {
				item.Direction = "incoming"
			}
		}
		items = append(items, item)
	}
	return items, nil
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
	if err := db.Select("id").Where("id = ? OR email = ? OR phone = ?", lookup, lookup, lookup).First(&user).Error; err != nil {
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

		var friendUser models.User
		if err := db.Select("id", "display_name", "email", "phone").First(&friendUser, "id = ?", friendUserID).Error; err == nil {
			item.DisplayName = friendUser.DisplayName
			item.Email = friendUser.Email
			item.Phone = friendUser.Phone
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
