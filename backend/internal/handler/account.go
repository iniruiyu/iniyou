package handler

import (
	"errors"
	"net/http"
	"strings"
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
	Visibility  string `json:"visibility"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Subdomain   string `json:"subdomain"`
}

type updateSpaceRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Subdomain   string `json:"subdomain"`
	Visibility  string `json:"visibility"`
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
	DisplayName      string  `json:"display_name"`
	Username         string  `json:"username"`
	Domain           string  `json:"domain"`
	AvatarURL        *string `json:"avatar_url"`
	Signature        string  `json:"signature"`
	BirthDate        *string `json:"birth_date"`
	Age              *int    `json:"age"`
	Gender           *string `json:"gender"`
	PhoneVisibility  string  `json:"phone_visibility"`
	EmailVisibility  string  `json:"email_visibility"`
	AgeVisibility    string  `json:"age_visibility"`
	GenderVisibility string  `json:"gender_visibility"`
}

type changePasswordRequest struct {
	// Password change request payload.
	// 密码修改请求载荷。
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

type adminUpdateUserRequest struct {
	Level  string `json:"level"`
	Status string `json:"status"`
}

func (h *AccountHandler) Register(c *gin.Context) {
	// Register endpoint.
	// 注册接口。
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	user, err := service.Register(h.DB, req.Email, req.Phone, req.Password)
	if err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	token, err := auth.SignToken(user.ID, h.JWTSecret, serviceTokenTTL(h.TokenTTL), user.PasswordVersion)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "token error")
		return
	}
	respondOK(c, gin.H{"user_id": user.ID, "token": token})
}

func (h *AccountHandler) Login(c *gin.Context) {
	// Login endpoint.
	// 登录接口。
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	user, err := service.Login(h.DB, req.Account, req.Password)
	if err != nil {
		if errors.Is(err, service.ErrAccountInactive) {
			respondError(c, http.StatusForbidden, "account inactive")
			return
		}
		respondError(c, http.StatusUnauthorized, "invalid credentials")
		return
	}
	token, err := auth.SignToken(user.ID, h.JWTSecret, serviceTokenTTL(h.TokenTTL), user.PasswordVersion)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "token error")
		return
	}
	respondOK(c, gin.H{"user_id": user.ID, "token": token})
}

func (h *AccountHandler) Logout(c *gin.Context) {
	// Stateless logout endpoint for client-side token cleanup.
	// 无状态登出接口，用于客户端清理本地 token。
	respondOK(c, gin.H{"message": "logged out"})
}

func (h *AccountHandler) Me(c *gin.Context) {
	// Return current user id.
	// 返回当前用户 ID。
	uid := c.GetString("user_id")
	user, err := service.GetUser(h.DB, uid)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, service.BuildCurrentUserView(user))
}

func (h *AccountHandler) UpdateMe(c *gin.Context) {
	// Update current user profile.
	// 更新当前用户资料。
	uid := c.GetString("user_id")
	var req updateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	user, err := service.UpdateProfile(
		h.DB,
		uid,
		req.DisplayName,
		req.Username,
		req.Domain,
		req.AvatarURL,
		req.Signature,
		req.BirthDate,
		req.Age,
		req.Gender,
		req.PhoneVisibility,
		req.EmailVisibility,
		req.AgeVisibility,
		req.GenderVisibility,
	)
	if err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	respondOK(c, service.BuildCurrentUserView(user))
}

func (h *AccountHandler) ChangePassword(c *gin.Context) {
	// Change the current user's password and return a fresh token.
	// 修改当前用户密码并返回新的 token。
	uid := c.GetString("user_id")
	var req changePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}

	user, err := service.ChangePassword(h.DB, uid, req.CurrentPassword, req.NewPassword)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidCredentials):
			respondError(c, http.StatusUnauthorized, "invalid credentials")
		case errors.Is(err, service.ErrAccountInactive):
			respondError(c, http.StatusForbidden, "account inactive")
		default:
			respondError(c, http.StatusBadRequest, err.Error())
		}
		return
	}

	token, err := auth.SignToken(user.ID, h.JWTSecret, serviceTokenTTL(h.TokenTTL), user.PasswordVersion)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "token error")
		return
	}
	respondOK(c, gin.H{"user_id": user.ID, "token": token})
}

func (h *AccountHandler) ListSpaces(c *gin.Context) {
	// List current user's owned spaces.
	// 列出当前用户自己创建的空间。
	uid := c.GetString("user_id")
	spaces, err := service.ListSpaces(h.DB, uid)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, gin.H{"items": spaces})
}

func (h *AccountHandler) ListUserSpaces(c *gin.Context) {
	// List public spaces for a user profile.
	// 列出某个用户个人主页展示的公开空间。
	uid := c.GetString("user_id")
	targetUserID := c.Param("id")
	visibility := strings.ToLower(strings.TrimSpace(c.DefaultQuery("visibility", "public")))
	spaces, err := service.ListUserSpaces(h.DB, uid, targetUserID, visibility)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, gin.H{"items": spaces})
}

func (h *AccountHandler) CreateSpace(c *gin.Context) {
	// Create a new space.
	// 创建新空间。
	uid := c.GetString("user_id")
	var req spaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	space, err := service.CreateSpace(h.DB, uid, req.Type, req.Visibility, req.Name, req.Description, req.Subdomain)
	if err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	respondCreated(c, space)
}

func (h *AccountHandler) UpdateSpace(c *gin.Context) {
	// Update an owned space.
	// 更新当前用户拥有的空间。
	uid := c.GetString("user_id")
	var req updateSpaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	space, err := service.UpdateSpace(h.DB, uid, c.Param("id"), req.Name, req.Description, req.Subdomain, req.Visibility)
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		respondError(c, status, err.Error())
		return
	}
	respondOK(c, space)
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
		respondError(c, status, err.Error())
		return
	}
	respondDeleted(c)
}

func (h *AccountHandler) AdminSpaceOverview(c *gin.Context) {
	// Return the administrator-only space-service overview payload.
	// 返回仅管理员可见的空间服务总览载荷。
	overview, err := service.BuildAdminSpaceOverview(h.DB)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "space admin overview error")
		return
	}
	respondOK(c, overview)
}

func (h *AccountHandler) AdminAccountOverview(c *gin.Context) {
	// Return the administrator-only account-service overview payload.
	// 返回仅管理员可见的账号服务总览载荷。
	overview, err := service.BuildAdminAccountOverview(h.DB)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "account admin overview error")
		return
	}
	respondOK(c, overview)
}

func (h *AccountHandler) AdminUpdateUser(c *gin.Context) {
	// Update one administrator-managed account field set.
	// 更新一组由管理员控制的账号字段。
	actorID := c.GetString("user_id")
	var req adminUpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	item, err := service.AdminUpdateUser(h.DB, actorID, c.Param("id"), req.Level, req.Status)
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		respondError(c, status, err.Error())
		return
	}
	respondOK(c, gin.H{"item": item})
}

func (h *AccountHandler) ListFriends(c *gin.Context) {
	// List current user's friends.
	// 列出当前用户好友。
	uid := c.GetString("user_id")
	friends, err := service.ListFriends(h.DB, uid)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, gin.H{"items": friends})
}

func (h *AccountHandler) AddFriend(c *gin.Context) {
	// Add a friend by ID.
	// 通过 ID 添加好友。
	uid := c.GetString("user_id")
	var req friendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	friend, err := service.AddFriend(h.DB, uid, req.FriendID, req.Account)
	if err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	respondCreated(c, friend)
}

func (h *AccountHandler) SearchUsers(c *gin.Context) {
	// Search users for friend requests.
	// 搜索可添加的用户。
	uid := c.GetString("user_id")
	query := c.Query("q")
	items, err := service.SearchUsers(h.DB, uid, query, 10)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, gin.H{"items": items})
}

func (h *AccountHandler) UserProfile(c *gin.Context) {
	// Return public profile information for a specific user.
	// 返回指定用户的公开资料信息。
	uid := c.GetString("user_id")
	item, err := service.GetPublicUserProfile(h.DB, uid, c.Param("id"))
	if err != nil {
		respondError(c, http.StatusNotFound, "user not found")
		return
	}
	respondOK(c, item)
}

func (h *AccountHandler) UserProfileByUsername(c *gin.Context) {
	// Return public profile information for a specific username.
	// 返回指定用户名的公开资料信息。
	uid := c.GetString("user_id")
	item, err := service.GetPublicUserProfileByUsername(h.DB, uid, c.Param("username"))
	if err != nil {
		respondError(c, http.StatusNotFound, "user not found")
		return
	}
	respondOK(c, item)
}

func (h *AccountHandler) UserProfileByDomain(c *gin.Context) {
	// Return public profile information for a specific domain handle.
	// 返回指定域名身份句柄的公开资料信息。
	uid := c.GetString("user_id")
	item, err := service.GetPublicUserProfileByDomain(h.DB, uid, c.Param("domain"))
	if err != nil {
		respondError(c, http.StatusNotFound, "user not found")
		return
	}
	respondOK(c, item)
}

func (h *AccountHandler) AcceptFriend(c *gin.Context) {
	// Accept an incoming friend request.
	// 接受收到的好友请求。
	uid := c.GetString("user_id")
	var req friendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	friend, err := service.AcceptFriend(h.DB, uid, req.FriendID)
	if err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	respondOK(c, friend)
}

func (h *AccountHandler) CreateSubscription(c *gin.Context) {
	// Create a subscription for the user.
	// 为用户创建订阅。
	uid := c.GetString("user_id")
	var req subscriptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	sub, err := service.CreateSubscription(h.DB, uid, req.PlanID)
	if err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	respondCreated(c, sub)
}

func (h *AccountHandler) CurrentSubscription(c *gin.Context) {
	// Return the latest subscription of the current user.
	// 返回当前用户最新订阅。
	uid := c.GetString("user_id")
	sub, err := service.GetCurrentSubscription(h.DB, uid)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, sub)
}

func (h *AccountHandler) ListExternalAccounts(c *gin.Context) {
	// Return current user's external account bindings.
	// 返回当前用户的外部账号绑定列表。
	uid := c.GetString("user_id")
	items, err := service.ListExternalAccounts(h.DB, uid)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, gin.H{"items": items})
}

func (h *AccountHandler) BindExternalAccount(c *gin.Context) {
	// Bind a new external account for the current user.
	// 为当前用户绑定新的外部账号。
	uid := c.GetString("user_id")
	var req externalAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	account, err := service.BindExternalAccount(h.DB, uid, req.Provider, req.Chain, req.AccountAddress, req.SignaturePayload)
	if err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	respondCreated(c, account)
}

func (h *AccountHandler) DeleteExternalAccount(c *gin.Context) {
	// Delete an existing external account binding.
	// 删除已有的外部账号绑定。
	uid := c.GetString("user_id")
	if err := service.RemoveExternalAccount(h.DB, uid, c.Param("id")); err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	respondDeleted(c)
}

func serviceTokenTTL(ttl int64) time.Duration {
	// Convert minutes to duration.
	// 将分钟转换为时长。
	if ttl <= 0 {
		return 120 * time.Minute
	}
	return time.Duration(ttl) * time.Minute
}
