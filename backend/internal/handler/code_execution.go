package handler

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"account-service/internal/service"
)

type executeGoSnippetRequest struct {
	// Source carries the runnable Go program body.
	// Source 承载待运行的 Go 程序正文。
	Source string `json:"source"`
}

type CodeExecutionHandler struct{}

func (h *CodeExecutionHandler) ExecuteCodeSnippet(c *gin.Context) {
	// Execute one guarded code snippet and return stdout/stderr to the learning UI.
	// 执行一段受限代码，并将 stdout/stderr 返回给学习界面。
	var request executeGoSnippetRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}

	result, err := service.ExecuteCodeSnippet(c.Param("language"), request.Source)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidCodeSnippet):
			respondError(c, http.StatusBadRequest, err.Error())
			return
		case errors.Is(err, service.ErrUnsupportedExecutionLanguage):
			respondError(c, http.StatusBadRequest, err.Error())
			return
		case errors.Is(err, service.ErrUnavailableExecutionRuntime):
			respondError(c, http.StatusServiceUnavailable, err.Error())
			return
		}
		respondError(c, http.StatusInternalServerError, "code execution error")
		return
	}
	respondOK(c, result)
}
