package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"account-service/internal/auth"
	"account-service/internal/models"
	"account-service/internal/service"
)

func AuthMiddleware(secret string, loadUserByID func(string) (models.User, error)) gin.HandlerFunc {
	// Validate JWT, load the current user, and reject inactive accounts.
	// 校验 JWT、加载当前用户，并拒绝非活跃账号。
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
			return
		}
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}
		claims, err := auth.ParseToken(parts[1], secret)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}
		if loadUserByID == nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "auth loader missing"})
			return
		}
		user, err := loadUserByID(claims.UserID)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}
		if !service.IsAccountActive(user.Status) {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "account inactive"})
			return
		}
		// Reject tokens that were signed before the latest password change.
		// 拒绝在最近一次密码变更之前签发的 token。
		if claims.PasswordVersion != user.PasswordVersion {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}
		c.Set("user_id", user.ID)
		c.Next()
	}
}
