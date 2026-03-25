package handler

import (
	"encoding/json"
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
	// Return a success envelope while flattening legacy payload fields for compatibility.
	// 返回成功包装结构，并平铺旧版载荷字段以保持兼容。
	respondJSON(c, http.StatusOK, "success", payload, "")
}

func respondCreated(c *gin.Context, payload any) {
	// Return a created envelope while flattening legacy payload fields for compatibility.
	// 返回创建成功包装结构，并平铺旧版载荷字段以保持兼容。
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
	// Build one compatibility response that serves both wrapped and legacy readers.
	// 构建同时兼容包装式读取与旧版字段读取的统一响应。
	body := gin.H{
		"code":    status,
		"message": message,
	}
	if payload != nil {
		body["data"] = payload
		if flattened, ok := flattenPayload(payload); ok {
			for key, value := range flattened {
				if _, exists := body[key]; exists {
					continue
				}
				body[key] = value
			}
		}
	}
	if errorMessage != "" {
		body["error"] = errorMessage
	}
	c.JSON(status, body)
}

func flattenPayload(payload any) (gin.H, bool) {
	// Flatten supported payload shapes so older clients can keep reading top-level fields.
	// 平铺受支持的载荷形状，让旧客户端继续读取顶层字段。
	switch value := payload.(type) {
	case gin.H:
		return value, true
	case map[string]any:
		return gin.H(value), true
	default:
		raw, err := json.Marshal(payload)
		if err != nil {
			return nil, false
		}
		var flattened map[string]any
		if err := json.Unmarshal(raw, &flattened); err != nil {
			return nil, false
		}
		return gin.H(flattened), true
	}
}
