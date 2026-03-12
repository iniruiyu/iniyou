package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"account-service/internal/auth"
)

func AuthMiddleware(secret string) gin.HandlerFunc {
	// Validate JWT and inject user_id into context.
	// 校验 JWT 并将 user_id 注入上下文。
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
			c.Abort()
			return
		}
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			c.Abort()
			return
		}
		claims, err := auth.ParseToken(parts[1], secret)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			c.Abort()
			return
		}
		c.Set("user_id", claims.UserID)
		c.Next()
	}
}
