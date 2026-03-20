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

	if err := database.AutoMigrate(&models.Message{}); err != nil {
		log.Fatalf("db migrate error: %v", err)
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
