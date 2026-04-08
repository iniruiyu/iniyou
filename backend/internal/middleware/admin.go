package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"account-service/internal/service"
)

func RequireAdminMiddleware() gin.HandlerFunc {
	// Allow only administrator-role accounts to pass through.
	// 仅允许管理员角色账号继续访问。
	return func(c *gin.Context) {
		userRole := c.GetString("user_role")
		if !service.IsAdminRole(userRole) {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "admin required"})
			return
		}
		c.Next()
	}
}
