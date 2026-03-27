package main

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"account-service/internal/config"
	"account-service/internal/db"
	"account-service/internal/handler"
	"account-service/internal/middleware"
	"account-service/internal/migrate"
	"account-service/internal/models"
	"account-service/internal/service"
	"account-service/internal/ws"
)

func main() {
	// Message service entrypoint.
	// 通讯服务入口。
	cfg := config.Load("message")

	database, err := db.Connect(cfg.DBDsn)
	if err != nil {
		log.Fatalf("db connect error: %v", err)
	}

	// Apply the versioned message-service schema before serving requests.
	// 在对外提供请求前，先执行通讯服务的版本化表结构。
	if err := migrate.ApplyMessage(database); err != nil {
		log.Fatalf("message migration error: %v", err)
	}

	hub := ws.NewHub()
	h := &handler.MessageHandler{DB: database, JWTSecret: cfg.JWTSecret, Hub: hub}

	// Remove expired messages once on startup and then on a fixed interval.
	// 启动时先清理一次过期消息，之后再按固定间隔定时清理。
	if err := h.CleanupExpiredMessages(); err != nil {
		log.Printf("initial message cleanup error: %v", err)
	}
	go func() {
		ticker := time.NewTicker(10 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			if err := h.CleanupExpiredMessages(); err != nil {
				log.Printf("scheduled message cleanup error: %v", err)
			}
		}
	}()

	// HTTP router (WS only in this service).
	// HTTP 路由（仅 WebSocket）。
	r := gin.Default()
	r.Use(func(c *gin.Context) {
		// Basic CORS for local SPA development.
		// 为本地 SPA 开发提供基础 CORS 支持。
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})
	r.GET("/ws", h.WS)
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
	api.GET("/conversations", h.ListConversations)
	api.GET("/messages", h.ListMessages)
	api.POST("/messages", h.CreateMessage)
	api.GET("/unread", h.UnreadCount)

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
