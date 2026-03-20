package middleware

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"account-service/internal/auth"
	"account-service/internal/models"
)

func TestAuthMiddlewareAllowsActiveUser(t *testing.T) {
	// Active users should pass through the middleware and reach the handler.
	// active 用户应当通过中间件并进入后续处理器。
	gin.SetMode(gin.TestMode)

	const secret = "test-secret"
	var loadedID string
	var handlerCalled bool

	router := gin.New()
	router.Use(AuthMiddleware(secret, func(userID string) (models.User, error) {
		loadedID = userID
		return models.User{ID: userID, Status: "active", PasswordVersion: 1}, nil
	}))
	router.GET("/secure", func(c *gin.Context) {
		handlerCalled = true
		c.JSON(http.StatusOK, gin.H{"user_id": c.GetString("user_id")})
	})

	token, err := auth.SignToken("user-1", secret, time.Hour, 1)
	if err != nil {
		t.Fatalf("sign token: %v", err)
	}

	resp := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/secure", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	router.ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", resp.Code)
	}
	if !handlerCalled {
		t.Fatal("expected handler to be called")
	}
	if loadedID != "user-1" {
		t.Fatalf("expected loader to receive user-1, got %q", loadedID)
	}
	if !strings.Contains(resp.Body.String(), "user-1") {
		t.Fatalf("expected response to include user id, got %s", resp.Body.String())
	}
}

func TestAuthMiddlewareRejectsInactiveUser(t *testing.T) {
	// Inactive users should be rejected with a 403 before the handler runs.
	// 非活跃用户应在进入处理器前被 403 拒绝。
	gin.SetMode(gin.TestMode)

	const secret = "test-secret"
	var handlerCalled bool

	router := gin.New()
	router.Use(AuthMiddleware(secret, func(userID string) (models.User, error) {
		return models.User{ID: userID, Status: "disabled", PasswordVersion: 1}, nil
	}))
	router.GET("/secure", func(c *gin.Context) {
		handlerCalled = true
		c.Status(http.StatusOK)
	})

	token, err := auth.SignToken("user-1", secret, time.Hour, 1)
	if err != nil {
		t.Fatalf("sign token: %v", err)
	}

	resp := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/secure", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	router.ServeHTTP(resp, req)

	if resp.Code != http.StatusForbidden {
		t.Fatalf("expected status 403, got %d", resp.Code)
	}
	if handlerCalled {
		t.Fatal("expected handler not to be called")
	}
	if !strings.Contains(resp.Body.String(), "account inactive") {
		t.Fatalf("expected inactive-account message, got %s", resp.Body.String())
	}
}

func TestAuthMiddlewareRejectsStaleToken(t *testing.T) {
	// Tokens signed with an older password version should no longer pass.
	// 使用旧密码版本签发的 token 不应再通过。
	gin.SetMode(gin.TestMode)

	const secret = "test-secret"
	var handlerCalled bool

	router := gin.New()
	router.Use(AuthMiddleware(secret, func(userID string) (models.User, error) {
		return models.User{ID: userID, Status: "active", PasswordVersion: 2}, nil
	}))
	router.GET("/secure", func(c *gin.Context) {
		handlerCalled = true
		c.Status(http.StatusOK)
	})

	token, err := auth.SignToken("user-1", secret, time.Hour, 1)
	if err != nil {
		t.Fatalf("sign token: %v", err)
	}

	resp := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/secure", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	router.ServeHTTP(resp, req)

	if resp.Code != http.StatusUnauthorized {
		t.Fatalf("expected status 401, got %d", resp.Code)
	}
	if handlerCalled {
		t.Fatal("expected handler not to be called")
	}
	if !strings.Contains(resp.Body.String(), "invalid token") {
		t.Fatalf("expected invalid-token message, got %s", resp.Body.String())
	}
}

func TestAuthMiddlewareRejectsMissingToken(t *testing.T) {
	// Requests without an Authorization header should be rejected immediately.
	// 没有 Authorization 头的请求应当被立即拒绝。
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.Use(AuthMiddleware("test-secret", func(userID string) (models.User, error) {
		return models.User{ID: userID, Status: "active", PasswordVersion: 1}, nil
	}))
	router.GET("/secure", func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	resp := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/secure", nil)
	router.ServeHTTP(resp, req)

	if resp.Code != http.StatusUnauthorized {
		t.Fatalf("expected status 401, got %d", resp.Code)
	}
	if !strings.Contains(resp.Body.String(), "missing token") {
		t.Fatalf("expected missing-token message, got %s", resp.Body.String())
	}
}
