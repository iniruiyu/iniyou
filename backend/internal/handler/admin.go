package handler

import (
	"github.com/gin-gonic/gin"

	"account-service/internal/service"
)

type AdminHandler struct{}

func (h *AdminHandler) Overview(c *gin.Context) {
	// Return the site-wide administrator overview payload.
	// 返回站点级管理员总览载荷。
	respondOK(c, buildAdminOverviewPayload())
}

func buildAdminOverviewPayload() any {
	// Keep the overview payload behind one helper so the envelope stays stable.
	// 使用单独辅助函数生成总览载荷，保证响应包装结构稳定。
	return service.BuildAdminOverview()
}
