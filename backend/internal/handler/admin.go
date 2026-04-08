package handler

import (
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"account-service/internal/service"
)

type AdminHandler struct {
	DB        *gorm.DB
	StartedAt time.Time
}

type updateAdminUserRequest struct {
	Role   string `json:"role"`
	Level  string `json:"level"`
	Status string `json:"status"`
}

type updateAdminDatabaseConfigRequest struct {
	Dsn string `json:"dsn"`
}

func (h *AdminHandler) Overview(c *gin.Context) {
	// Return the site-wide administrator overview payload.
	// 返回站点级管理员总览载荷。
	overview, err := service.BuildAdminOverview(h.DB, h.StartedAt)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "overview build failed")
		return
	}
	respondOK(c, overview)
}

func (h *AdminHandler) UpdateUser(c *gin.Context) {
	// Update one user from the site administrator panel.
	// 通过站点管理员面板更新单个用户。
	var req updateAdminUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	item, err := service.UpdateAdminUser(h.DB, c.Param("id"), req.Role, req.Level, req.Status)
	if err != nil {
		switch {
		case errors.Is(err, gorm.ErrRecordNotFound):
			respondError(c, http.StatusNotFound, "user not found")
		case errors.Is(err, gorm.ErrInvalidData):
			respondError(c, http.StatusBadRequest, "role, level, or status required")
		default:
			respondError(c, http.StatusBadRequest, err.Error())
		}
		return
	}
	respondOK(c, item)
}

func (h *AdminHandler) DatabaseConfig(c *gin.Context) {
	// Return the editable database connection configuration for the administrator panel.
	// 返回管理员面板可编辑的数据库连接配置。
	item, err := service.GetAdminDatabaseConfig()
	if err != nil {
		respondError(c, http.StatusInternalServerError, "database config load failed")
		return
	}
	respondOK(c, item)
}

func (h *AdminHandler) UpdateDatabaseConfig(c *gin.Context) {
	// Persist one database DSN update from the administrator panel.
	// 持久化管理员面板提交的数据库 DSN 更新。
	var req updateAdminDatabaseConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}
	item, err := service.UpdateAdminDatabaseConfig(req.Dsn)
	if err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	respondOK(c, item)
}
