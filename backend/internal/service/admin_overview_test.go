package service

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func TestBuildAdminOverviewCountsOnlineAndOfflineServices(t *testing.T) {
	// Count online and offline services from independent health endpoints.
	// 根据独立健康检查接口统计在线与离线服务数量。
	accountServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/health" {
			t.Fatalf("unexpected account path: %s", r.URL.Path)
		}
		w.WriteHeader(http.StatusOK)
	}))
	defer accountServer.Close()

	learningServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/v1/health" {
			t.Fatalf("unexpected learning path: %s", r.URL.Path)
		}
		w.WriteHeader(http.StatusOK)
	}))
	defer learningServer.Close()

	t.Setenv("ACCOUNT_SERVICE_BASE", accountServer.URL+"/api/v1")
	t.Setenv("SPACE_SERVICE_BASE", "http://127.0.0.1:1/api/v1")
	t.Setenv("MESSAGE_SERVICE_BASE", "http://127.0.0.1:2/api/v1")
	t.Setenv("LEARNING_SERVICE_BASE", learningServer.URL+"/api/v1")
	t.Setenv("ADMIN_SERVICE_BASE", "http://localhost:8084/api/v1")

	overview := BuildAdminOverview()
	if overview.TotalServices != 5 {
		t.Fatalf("total services = %d, want 5", overview.TotalServices)
	}
	if overview.OnlineServices != 3 {
		t.Fatalf("online services = %d, want 3", overview.OnlineServices)
	}
	if overview.OfflineServices != 2 {
		t.Fatalf("offline services = %d, want 2", overview.OfflineServices)
	}
	if overview.AdminWorkspaces != 3 {
		t.Fatalf("admin workspaces = %d, want 3", overview.AdminWorkspaces)
	}
	if overview.Degraded {
		t.Fatalf("degraded = %v, want false", overview.Degraded)
	}
	if overview.CheckedAt == "" {
		t.Fatal("checked_at should not be blank")
	}
	if len(overview.Services) != 5 {
		t.Fatalf("services length = %d, want 5", len(overview.Services))
	}
	if overview.Services[0].HealthURL == "" {
		t.Fatal("health_url should be populated")
	}
	if overview.Services[0].Key != "account" {
		t.Fatalf("first service key = %s, want account", overview.Services[0].Key)
	}
	if len(overview.Workspaces) != 5 {
		t.Fatalf("workspaces length = %d, want 5", len(overview.Workspaces))
	}
	if !overview.Workspaces[0].Available {
		t.Fatal("account-admin workspace should be available when account is online")
	}
	if !overview.Workspaces[4].Available {
		t.Fatal("learning-admin workspace should be available when learning is online")
	}
}

func TestServiceBaseURLFallsBackWhenEnvBlank(t *testing.T) {
	// Ignore blank environment overrides and keep the documented fallback.
	// 空白环境变量覆盖应被忽略，继续使用文档化默认值。
	t.Setenv("ACCOUNT_SERVICE_BASE", "")
	if got := serviceBaseURL("ACCOUNT_SERVICE_BASE", "http://localhost:8080/api/v1"); got != "http://localhost:8080/api/v1" {
		t.Fatalf("fallback = %s", got)
	}
}

func TestBuildAdminOverviewMarksLearningWorkspaceUnavailableWhenOffline(t *testing.T) {
	t.Setenv("ACCOUNT_SERVICE_BASE", "http://127.0.0.1:1/api/v1")
	t.Setenv("SPACE_SERVICE_BASE", "http://127.0.0.1:2/api/v1")
	t.Setenv("MESSAGE_SERVICE_BASE", "http://127.0.0.1:3/api/v1")
	t.Setenv("LEARNING_SERVICE_BASE", "http://127.0.0.1:4/api/v1")
	t.Setenv("ADMIN_SERVICE_BASE", "http://localhost:8084/api/v1")

	overview := BuildAdminOverview()
	if overview.AdminWorkspaces != 1 {
		t.Fatalf("admin workspaces = %d, want 1", overview.AdminWorkspaces)
	}
	if overview.Workspaces[4].Available {
		t.Fatal("learning-admin workspace should be unavailable when learning is offline")
	}
}

func TestMain(m *testing.M) {
	// Ensure tests never inherit the host machine service URLs.
	// 确保测试不会继承宿主机上的服务地址。
	os.Exit(m.Run())
}
