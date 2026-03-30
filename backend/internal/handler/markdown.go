package handler

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"account-service/internal/service"
)

type MarkdownHandler struct{}

type saveMarkdownRequest struct {
	// Content carries the raw UTF-8 markdown source.
	// Content 承载原始 UTF-8 Markdown 源文本。
	Content string `json:"content"`
}

func (h *MarkdownHandler) ListMarkdownFiles(c *gin.Context) {
	// List all stored markdown files for the learning service.
	// 列出学习服务当前已存储的 Markdown 文件。
	items, err := service.ListMarkdownFiles()
	if err != nil {
		respondError(c, http.StatusInternalServerError, "markdown list error")
		return
	}
	respondOK(c, gin.H{"items": items})
}

func (h *MarkdownHandler) GetMarkdownFile(c *gin.Context) {
	// Return a single markdown file by its normalized relative path.
	// 按规范化相对路径返回单个 Markdown 文件。
	item, err := service.GetMarkdownFile(c.Param("path"))
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidMarkdownPath):
			respondError(c, http.StatusBadRequest, err.Error())
		case errors.Is(err, service.ErrMarkdownFileNotFound):
			respondError(c, http.StatusNotFound, err.Error())
		default:
			respondError(c, http.StatusInternalServerError, "markdown read error")
		}
		return
	}
	respondOK(c, item)
}

func (h *MarkdownHandler) PutMarkdownFile(c *gin.Context) {
	// Create or update a markdown file beneath the configured storage root.
	// 在配置的存储根目录下创建或更新 Markdown 文件。
	var req saveMarkdownRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}

	item, created, err := service.SaveMarkdownFile(c.Param("path"), req.Content)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidMarkdownPath):
			respondError(c, http.StatusBadRequest, err.Error())
		default:
			respondError(c, http.StatusInternalServerError, "markdown write error")
		}
		return
	}
	if created {
		respondCreated(c, item)
		return
	}
	respondOK(c, item)
}

func (h *MarkdownHandler) DeleteMarkdownFile(c *gin.Context) {
	// Delete one markdown file beneath the configured storage root.
	// 删除配置存储根目录下的单个 Markdown 文件。
	err := service.DeleteMarkdownFile(c.Param("path"))
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidMarkdownPath):
			respondError(c, http.StatusBadRequest, err.Error())
		case errors.Is(err, service.ErrMarkdownFileNotFound):
			respondError(c, http.StatusNotFound, err.Error())
		default:
			respondError(c, http.StatusInternalServerError, "markdown delete error")
		}
		return
	}
	respondDeleted(c)
}
