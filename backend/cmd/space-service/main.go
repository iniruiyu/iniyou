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
)

func main() {
	// Space service entrypoint.
	// 空间服务入口。
	cfg := config.Load("space")

	database, err := db.Connect(cfg.DBDsn)
	if err != nil {
		log.Fatalf("db connect error: %v", err)
	}

	if err := database.AutoMigrate(&models.Space{}, &models.Post{}, &models.Comment{}, &models.PostLike{}, &models.PostShare{}); err != nil {
		log.Fatalf("db migrate error: %v", err)
	}
	if err := service.MarkLegacySystemSpaces(database); err != nil {
		log.Fatalf("legacy space migration error: %v", err)
	}
	if err := service.BackfillLegacySpaceVisibility(database); err != nil {
		log.Fatalf("legacy visibility backfill error: %v", err)
	}

	spaceHandler := &handler.AccountHandler{
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
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(cfg.JWTSecret))
	api.GET("/spaces", spaceHandler.ListSpaces)
	api.POST("/spaces", spaceHandler.CreateSpace)
	api.PATCH("/spaces/:id", spaceHandler.UpdateSpace)
	api.DELETE("/spaces/:id", spaceHandler.DeleteSpace)
	api.GET("/posts", postHandler.ListPosts)
	api.GET("/posts/:id", postHandler.GetPost)
	api.GET("/users/:id/posts", postHandler.ListUserPosts)
	api.POST("/posts", postHandler.CreatePost)
	api.PATCH("/posts/:id", postHandler.UpdatePost)
	api.DELETE("/posts/:id", postHandler.DeletePost)
	api.POST("/posts/:id/likes", postHandler.ToggleLike)
	api.POST("/posts/:id/comments", postHandler.AddComment)
	api.POST("/posts/:id/shares", postHandler.Share)

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
