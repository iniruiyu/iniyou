package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"account-service/internal/config"
	"account-service/internal/db"
	"account-service/internal/handler"
	"account-service/internal/middleware"
	"account-service/internal/models"
	"account-service/internal/service"
)

func main() {
	// Admin service entrypoint.
	// 管理员服务入口。
	cfg := config.Load("admin")

	database, err := db.Connect(cfg.DBDsn)
	if err != nil {
		log.Fatalf("db connect error: %v", err)
	}

	adminHandler := &handler.AdminHandler{}

	// HTTP router.
	// HTTP 路由。
	r := gin.Default()
	r.Use(func(c *gin.Context) {
		// Basic CORS for local SPA development.
		// 为本地 SPA 开发提供基础 CORS 支持。
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	api := r.Group("/api/v1")
	// Health endpoint stays public so frontends can probe service availability without auth.
	// 健康检查接口保持公开，方便前端在未鉴权时探测服务是否可用。
	api.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service": cfg.ServiceName,
			"status":  "ok",
		})
	})
	api.Use(middleware.AuthMiddleware(cfg.JWTSecret, func(userID string) (models.User, error) {
		return service.GetUser(database, userID)
	}))
	admin := api.Group("")
	admin.Use(middleware.RequireAdminMiddleware())
	admin.GET("/overview", adminHandler.Overview)

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
