package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type apiEnvelope struct {
	// Code keeps the response status machine-readable.
	// Code 用于保持响应状态可机读。
	Code int `json:"code"`
	// Message provides a compact human-readable summary.
	// Message 提供简短的人类可读摘要。
	Message string `json:"message"`
	// Data stores the canonical wrapped payload.
	// Data 保存规范化包装后的载荷。
	Data any `json:"data,omitempty"`
	// Error keeps legacy clients working while exposing failures consistently.
	// Error 保留给旧客户端使用，同时统一失败表达。
	Error string `json:"error,omitempty"`
}

func respondOK(c *gin.Context, payload any) {
	// Return a success envelope.
	// 返回成功包装结构。
	respondJSON(c, http.StatusOK, "success", payload, "")
}

func respondCreated(c *gin.Context, payload any) {
	// Return a created envelope.
	// 返回创建成功包装结构。
	respondJSON(c, http.StatusCreated, "created", payload, "")
}

func respondError(c *gin.Context, status int, message string) {
	// Return a standardized error envelope.
	// 返回标准化错误包装结构。
	respondJSON(c, status, message, nil, message)
}

func respondDeleted(c *gin.Context) {
	// Return a standardized delete acknowledgement.
	// 返回标准化删除确认响应。
	respondJSON(c, http.StatusOK, "deleted", gin.H{"message": "deleted"}, "")
}

func respondJSON(c *gin.Context, status int, message string, payload any, errorMessage string) {
	// Build the canonical wrapped response shape.
	// 构建规范化的包装响应结构。
	body := apiEnvelope{
		Code:    status,
		Message: message,
		Data:    payload,
		Error:   errorMessage,
	}
	c.JSON(status, body)
}
