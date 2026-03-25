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
)

func main() {
	// Account service entrypoint.
	// 账号服务入口。
	cfg := config.Load("account")

	database, err := db.Connect(cfg.DBDsn)
	if err != nil {
		log.Fatalf("db connect error: %v", err)
	}

	// Apply the versioned account-service schema and backfill before serving requests.
	// 在对外提供请求前，先执行账号服务的版本化表结构与回填。
	if err := migrate.ApplyAccount(database); err != nil {
		log.Fatalf("account migration error: %v", err)
	}

	h := &handler.AccountHandler{
		DB:        database,
		JWTSecret: cfg.JWTSecret,
		TokenTTL:  int64(cfg.TokenTTL / time.Minute),
	}

	// HTTP router.
	// HTTP 路由。
	r := gin.Default()
	r.Use(func(c *gin.Context) {
		// Basic CORS for local SPA development.
		// 为本地 SPA 开发提供基础 CORS 支持。
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	// Public routes.
	// 公共路由。
	api := r.Group("/api/v1")
	api.POST("/register", h.Register)
	api.POST("/login", h.Login)
	api.POST("/logout", h.Logout)

	// Authenticated routes.
	// 需鉴权路由。
	authGroup := api.Group("")
	authGroup.Use(middleware.AuthMiddleware(cfg.JWTSecret, func(userID string) (models.User, error) {
		return service.GetUser(database, userID)
	}))
	authGroup.GET("/me", h.Me)
	authGroup.PUT("/me", h.UpdateMe)
	authGroup.PUT("/me/password", h.ChangePassword)
	authGroup.GET("/users/search", h.SearchUsers)
	authGroup.GET("/users/:id/profile", h.UserProfile)
	authGroup.GET("/users/username/:username/profile", h.UserProfileByUsername)
	authGroup.GET("/users/domain/:domain/profile", h.UserProfileByDomain)
	authGroup.GET("/friends", h.ListFriends)
	authGroup.POST("/friends", h.AddFriend)
	authGroup.POST("/friends/accept", h.AcceptFriend)
	authGroup.GET("/subscriptions/current", h.CurrentSubscription)
	authGroup.POST("/subscriptions", h.CreateSubscription)
	authGroup.GET("/external-accounts", h.ListExternalAccounts)
	authGroup.POST("/external-accounts", h.BindExternalAccount)
	authGroup.DELETE("/external-accounts/:id", h.DeleteExternalAccount)

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
