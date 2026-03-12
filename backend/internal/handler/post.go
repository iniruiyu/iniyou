package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"account-service/internal/service"
)

type PostHandler struct {
	DB *gorm.DB
}

type createPostRequest struct {
	Title      string `json:"title"`
	Content    string `json:"content"`
	Visibility string `json:"visibility"`
}

type commentRequest struct {
	Content string `json:"content"`
}

func (h *PostHandler) ListPosts(c *gin.Context) {
	// List posts visible to the current user.
	// 列出当前用户可见的文章。
	uid := c.GetString("user_id")
	limit := 20
	if raw := c.Query("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}
	items, err := service.ListPosts(h.DB, uid, c.Query("visibility"), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *PostHandler) GetPost(c *gin.Context) {
	// Return one post with interaction info.
	// 返回单篇文章及互动信息。
	uid := c.GetString("user_id")
	item, err := service.GetPost(h.DB, uid, c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "post not found"})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *PostHandler) ListUserPosts(c *gin.Context) {
	// List posts for a given user.
	// 列出指定用户的文章。
	uid := c.GetString("user_id")
	limit := 20
	if raw := c.Query("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}
	items, err := service.ListPostsByUser(h.DB, uid, c.Param("id"), c.Query("visibility"), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *PostHandler) CreatePost(c *gin.Context) {
	// Create a social post.
	// 创建社交文章。
	uid := c.GetString("user_id")
	var req createPostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	item, err := service.CreatePost(h.DB, uid, req.Title, req.Content, req.Visibility)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *PostHandler) ToggleLike(c *gin.Context) {
	// Toggle like on a post.
	// 切换文章点赞。
	uid := c.GetString("user_id")
	item, err := service.ToggleLikePost(h.DB, uid, c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *PostHandler) AddComment(c *gin.Context) {
	// Add a comment to the target post.
	// 为目标文章新增评论。
	uid := c.GetString("user_id")
	var req commentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	item, err := service.AddComment(h.DB, uid, c.Param("id"), req.Content)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *PostHandler) Share(c *gin.Context) {
	// Record a repost action.
	// 记录一次转发动作。
	uid := c.GetString("user_id")
	item, err := service.SharePost(h.DB, uid, c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, item)
}
