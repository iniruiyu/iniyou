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
)

func main() {
	// Account service entrypoint.
	// 账号服务入口。
	cfg := config.Load("account")

	database, err := db.Connect(cfg.DBDsn)
	if err != nil {
		log.Fatalf("db connect error: %v", err)
	}

	if err := database.AutoMigrate(&models.User{}, &models.Space{}, &models.Subscription{}, &models.Friend{}); err != nil {
		log.Fatalf("db migrate error: %v", err)
	}
	if err := database.AutoMigrate(&models.Post{}, &models.Comment{}, &models.PostLike{}, &models.PostShare{}); err != nil {
		log.Fatalf("db migrate error: %v", err)
	}

	h := &handler.AccountHandler{
		DB:        database,
		JWTSecret: cfg.JWTSecret,
		TokenTTL:  int64(cfg.TokenTTL / time.Minute),
	}
	postHandler := &handler.PostHandler{DB: database}

	// HTTP router.
	// HTTP 路由。
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

	// Public routes.
	// 公共路由。
	api := r.Group("/api/v1")
	api.POST("/register", h.Register)
	api.POST("/login", h.Login)
	api.POST("/logout", h.Logout)

	// Authenticated routes.
	// 需鉴权路由。
	authGroup := api.Group("")
	authGroup.Use(middleware.AuthMiddleware(cfg.JWTSecret))
	authGroup.GET("/me", h.Me)
	authGroup.PUT("/me", h.UpdateMe)
	authGroup.GET("/users/search", h.SearchUsers)
	authGroup.GET("/users/:id/profile", h.UserProfile)
	authGroup.GET("/spaces", h.ListSpaces)
	authGroup.POST("/spaces", h.CreateSpace)
	authGroup.GET("/posts", postHandler.ListPosts)
	authGroup.GET("/posts/:id", postHandler.GetPost)
	authGroup.GET("/users/:id/posts", postHandler.ListUserPosts)
	authGroup.POST("/posts", postHandler.CreatePost)
	authGroup.POST("/posts/:id/likes", postHandler.ToggleLike)
	authGroup.POST("/posts/:id/comments", postHandler.AddComment)
	authGroup.POST("/posts/:id/shares", postHandler.Share)
	authGroup.GET("/friends", h.ListFriends)
	authGroup.POST("/friends", h.AddFriend)
	authGroup.POST("/friends/accept", h.AcceptFriend)
	authGroup.GET("/subscriptions/current", h.CurrentSubscription)
	authGroup.POST("/subscriptions", h.CreateSubscription)

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
