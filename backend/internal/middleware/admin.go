package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"account-service/internal/service"
)

func RequireAdminMiddleware() gin.HandlerFunc {
	// Allow only administrator-level accounts to pass through.
	// 仅允许管理员等级账号继续访问。
	return func(c *gin.Context) {
		userLevel := c.GetString("user_level")
		if !service.IsAdminLevel(userLevel) {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "admin required"})
			return
		}
		c.Next()
	}
}
