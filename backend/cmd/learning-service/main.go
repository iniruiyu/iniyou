package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"

	"account-service/internal/config"
	"account-service/internal/db"
	"account-service/internal/handler"
	"account-service/internal/middleware"
	"account-service/internal/models"
	"account-service/internal/service"
)

func main() {
	// Learning service entrypoint.
	// 学习服务入口。
	cfg := config.Load("learning")
	service.SetMarkdownStorageDir(cfg.MarkdownStorageDir)
	if err := os.MkdirAll(cfg.MarkdownStorageDir, 0o755); err != nil {
		log.Fatalf("markdown storage dir create error: %v", err)
	}
	if err := service.EnsureDefaultLearningMarkdownFiles(); err != nil {
		log.Fatalf("learning markdown seed error: %v", err)
	}

	database, err := db.Connect(cfg.DBDsn)
	if err != nil {
		log.Fatalf("db connect error: %v", err)
	}

	markdownHandler := &handler.MarkdownHandler{}
	codeExecutionHandler := &handler.CodeExecutionHandler{}

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
	api.GET("/markdown-files", markdownHandler.ListMarkdownFiles)
	api.GET("/markdown-files/*path", markdownHandler.GetMarkdownFile)
	api.PUT("/markdown-files/*path", markdownHandler.PutMarkdownFile)
	api.POST("/code-executions/:language", codeExecutionHandler.ExecuteCodeSnippet)

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
