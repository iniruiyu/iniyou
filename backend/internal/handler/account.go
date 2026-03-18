package handler

import (
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"account-service/internal/auth"
	"account-service/internal/service"
)

type AccountHandler struct {
	DB        *gorm.DB
	JWTSecret string
	TokenTTL  int64
}

type registerRequest struct {
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Password string `json:"password"`
}

type loginRequest struct {
	Account  string `json:"account"`
	Password string `json:"password"`
}

type spaceRequest struct {
	Type        string `json:"type"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Subdomain   string `json:"subdomain"`
}

type updateSpaceRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Subdomain   string `json:"subdomain"`
}

type friendRequest struct {
	FriendID string `json:"friend_id"`
	Account  string `json:"account"`
}

type subscriptionRequest struct {
	PlanID string `json:"plan_id"`
}

type externalAccountRequest struct {
	Provider         string `json:"provider"`
	Chain            string `json:"chain"`
	AccountAddress   string `json:"account_address"`
	SignaturePayload string `json:"signature_payload"`
}

type updateProfileRequest struct {
	DisplayName string `json:"display_name"`
	Username    string `json:"username"`
}

func (h *AccountHandler) Register(c *gin.Context) {
	// Register endpoint.
	// 注册接口。
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	user, err := service.Register(h.DB, req.Email, req.Phone, req.Password)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	token, err := auth.SignToken(user.ID, h.JWTSecret, serviceTokenTTL(h.TokenTTL))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "token error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"user_id": user.ID, "token": token})
}

func (h *AccountHandler) Login(c *gin.Context) {
	// Login endpoint.
	// 登录接口。
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	user, err := service.Login(h.DB, req.Account, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}
	token, err := auth.SignToken(user.ID, h.JWTSecret, serviceTokenTTL(h.TokenTTL))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "token error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"user_id": user.ID, "token": token})
}

func (h *AccountHandler) Logout(c *gin.Context) {
	// Stateless logout endpoint for client-side token cleanup.
	// 无状态登出接口，用于客户端清理本地 token。
	c.JSON(http.StatusOK, gin.H{"message": "logged out"})
}

func (h *AccountHandler) Me(c *gin.Context) {
	// Return current user id.
	// 返回当前用户 ID。
	uid := c.GetString("user_id")
	user, err := service.GetUser(h.DB, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"user_id":      user.ID,
		"email":        user.Email,
		"phone":        user.Phone,
		"username":     user.Username,
		"display_name": user.DisplayName,
		"level":        user.Level,
		"status":       user.Status,
	})
}

func (h *AccountHandler) UpdateMe(c *gin.Context) {
	// Update current user profile.
	// 更新当前用户资料。
	uid := c.GetString("user_id")
	var req updateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	user, err := service.UpdateProfile(h.DB, uid, req.DisplayName, req.Username)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"user_id":      user.ID,
		"display_name": user.DisplayName,
		"username":     user.Username,
	})
}

func (h *AccountHandler) ListSpaces(c *gin.Context) {
	// List current user's spaces.
	// 列出当前用户空间。
	uid := c.GetString("user_id")
	spaces, err := service.ListSpaces(h.DB, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": spaces})
}

func (h *AccountHandler) CreateSpace(c *gin.Context) {
	// Create a new space.
	// 创建新空间。
	uid := c.GetString("user_id")
	var req spaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	space, err := service.CreateSpace(h.DB, uid, req.Type, req.Name, req.Description, req.Subdomain)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, space)
}

func (h *AccountHandler) UpdateSpace(c *gin.Context) {
	// Update an owned space.
	// 更新当前用户拥有的空间。
	uid := c.GetString("user_id")
	var req updateSpaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	space, err := service.UpdateSpace(h.DB, uid, c.Param("id"), req.Name, req.Description, req.Subdomain)
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		c.JSON(status, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, space)
}

func (h *AccountHandler) DeleteSpace(c *gin.Context) {
	// Delete an owned space.
	// 删除当前用户拥有的空间。
	uid := c.GetString("user_id")
	if err := service.DeleteSpace(h.DB, uid, c.Param("id")); err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		c.JSON(status, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

func (h *AccountHandler) ListFriends(c *gin.Context) {
	// List current user's friends.
	// 列出当前用户好友。
	uid := c.GetString("user_id")
	friends, err := service.ListFriends(h.DB, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": friends})
}

func (h *AccountHandler) AddFriend(c *gin.Context) {
	// Add a friend by ID.
	// 通过 ID 添加好友。
	uid := c.GetString("user_id")
	var req friendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	friend, err := service.AddFriend(h.DB, uid, req.FriendID, req.Account)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, friend)
}

func (h *AccountHandler) SearchUsers(c *gin.Context) {
	// Search users for friend requests.
	// 搜索可添加的用户。
	uid := c.GetString("user_id")
	query := c.Query("q")
	items, err := service.SearchUsers(h.DB, uid, query, 10)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *AccountHandler) UserProfile(c *gin.Context) {
	// Return public profile information for a specific user.
	// 返回指定用户的公开资料信息。
	uid := c.GetString("user_id")
	item, err := service.GetPublicUserProfile(h.DB, uid, c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *AccountHandler) UserProfileByUsername(c *gin.Context) {
	// Return public profile information for a specific username.
	// 返回指定用户名的公开资料信息。
	uid := c.GetString("user_id")
	item, err := service.GetPublicUserProfileByUsername(h.DB, uid, c.Param("username"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *AccountHandler) AcceptFriend(c *gin.Context) {
	// Accept an incoming friend request.
	// 接受收到的好友请求。
	uid := c.GetString("user_id")
	var req friendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	friend, err := service.AcceptFriend(h.DB, uid, req.FriendID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, friend)
}

func (h *AccountHandler) CreateSubscription(c *gin.Context) {
	// Create a subscription for the user.
	// 为用户创建订阅。
	uid := c.GetString("user_id")
	var req subscriptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	sub, err := service.CreateSubscription(h.DB, uid, req.PlanID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, sub)
}

func (h *AccountHandler) CurrentSubscription(c *gin.Context) {
	// Return the latest subscription of the current user.
	// 返回当前用户最新订阅。
	uid := c.GetString("user_id")
	sub, err := service.GetCurrentSubscription(h.DB, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, sub)
}

func (h *AccountHandler) ListExternalAccounts(c *gin.Context) {
	// Return current user's external account bindings.
	// 返回当前用户的外部账号绑定列表。
	uid := c.GetString("user_id")
	items, err := service.ListExternalAccounts(h.DB, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *AccountHandler) BindExternalAccount(c *gin.Context) {
	// Bind a new external account for the current user.
	// 为当前用户绑定新的外部账号。
	uid := c.GetString("user_id")
	var req externalAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	account, err := service.BindExternalAccount(h.DB, uid, req.Provider, req.Chain, req.AccountAddress, req.SignaturePayload)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, account)
}

func (h *AccountHandler) DeleteExternalAccount(c *gin.Context) {
	// Delete an existing external account binding.
	// 删除已有的外部账号绑定。
	uid := c.GetString("user_id")
	if err := service.RemoveExternalAccount(h.DB, uid, c.Param("id")); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}

func serviceTokenTTL(ttl int64) time.Duration {
	// Convert minutes to duration.
	// 将分钟转换为时长。
	if ttl <= 0 {
		return 120 * time.Minute
	}
	return time.Duration(ttl) * time.Minute
}
