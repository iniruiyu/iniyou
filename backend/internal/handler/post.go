package handler

import (
	"errors"
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
	Status     string `json:"status"`
	SpaceID    string `json:"space_id"`
	MediaType  string `json:"media_type"`
	MediaName  string `json:"media_name"`
	MediaMime  string `json:"media_mime"`
	MediaData  string `json:"media_data"`
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

func (h *PostHandler) ListSpacePosts(c *gin.Context) {
	// List posts inside a specific space.
	// 列出指定空间内的文章。
	uid := c.GetString("user_id")
	limit := 20
	if raw := c.Query("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}
	items, err := service.ListSpacePosts(h.DB, uid, c.Param("id"), c.Query("visibility"), limit)
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		c.JSON(status, gin.H{"error": err.Error()})
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
	item, err := service.CreatePostWithStatus(
		h.DB,
		uid,
		req.Title,
		req.Content,
		req.Visibility,
		req.Status,
		req.SpaceID,
		req.MediaType,
		req.MediaName,
		req.MediaMime,
		req.MediaData,
	)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *PostHandler) UpdatePost(c *gin.Context) {
	// Update a social post owned by the current user.
	// 更新当前用户拥有的社交文章。
	uid := c.GetString("user_id")
	var req createPostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	item, err := service.UpdatePost(
		h.DB,
		uid,
		c.Param("id"),
		req.Title,
		req.Content,
		req.Visibility,
		req.Status,
		req.SpaceID,
		req.MediaType,
		req.MediaName,
		req.MediaMime,
		req.MediaData,
	)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *PostHandler) DeletePost(c *gin.Context) {
	// Delete a social post owned by the current user.
	// 删除当前用户拥有的社交文章。
	uid := c.GetString("user_id")
	if err := service.DeletePost(h.DB, uid, c.Param("id")); err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		c.JSON(status, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
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
