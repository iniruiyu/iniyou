package service

import (
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

const adminServiceProbeTimeout = 800 * time.Millisecond

type AdminWorkspaceStatus struct {
	Key        string `json:"key"`
	Title      string `json:"title"`
	ServiceKey string `json:"service_key"`
	Available  bool   `json:"available"`
}

type AdminServiceStatus struct {
	Key          string `json:"key"`
	Title        string `json:"title"`
	BaseURL      string `json:"base_url"`
	HealthURL    string `json:"health_url"`
	Online       bool   `json:"online"`
	Required     bool   `json:"required"`
	LatencyMS    int64  `json:"latency_ms"`
	WorkspaceKey string `json:"workspace_key,omitempty"`
}

type AdminOverview struct {
	TotalServices   int                    `json:"total_services"`
	OnlineServices  int                    `json:"online_services"`
	OfflineServices int                    `json:"offline_services"`
	AdminWorkspaces int                    `json:"admin_workspaces"`
	Degraded        bool                   `json:"degraded"`
	CheckedAt       string                 `json:"checked_at"`
	Services        []AdminServiceStatus   `json:"services"`
	Workspaces      []AdminWorkspaceStatus `json:"workspaces"`
}

func BuildAdminOverview() AdminOverview {
	// Aggregate one site-wide service overview for the administrator panel.
	// 为管理员总管理面板聚合一份站点级服务总览。
	checkedAt := time.Now().UTC().Format(time.RFC3339)
	services := []AdminServiceStatus{
		{
			Key:          "account",
			Title:        "Account microservice",
			BaseURL:      serviceBaseURL("ACCOUNT_SERVICE_BASE", "http://localhost:8080/api/v1"),
			Required:     true,
			WorkspaceKey: "profile",
		},
		{
			Key:          "admin",
			Title:        "Admin service",
			BaseURL:      serviceBaseURL("ADMIN_SERVICE_BASE", "http://localhost:8084/api/v1"),
			Online:       true,
			Required:     true,
			WorkspaceKey: "admin-panel",
		},
		{
			Key:          "space",
			Title:        "Space microservice",
			BaseURL:      serviceBaseURL("SPACE_SERVICE_BASE", "http://localhost:8082/api/v1"),
			Required:     false,
			WorkspaceKey: "space",
		},
		{
			Key:          "message",
			Title:        "Message microservice",
			BaseURL:      serviceBaseURL("MESSAGE_SERVICE_BASE", "http://localhost:8081/api/v1"),
			Required:     false,
			WorkspaceKey: "chat",
		},
		{
			Key:          "learning",
			Title:        "Learning service",
			BaseURL:      serviceBaseURL("LEARNING_SERVICE_BASE", "http://localhost:8083/api/v1"),
			Required:     false,
			WorkspaceKey: "learning",
		},
	}

	probeAdminServices(services)

	onlineServices := 0
	degraded := false
	for _, item := range services {
		if item.Online {
			onlineServices++
		}
		if item.Required && !item.Online {
			degraded = true
		}
	}

	workspaces := buildAdminWorkspaces(services)

	return AdminOverview{
		TotalServices:   len(services),
		OnlineServices:  onlineServices,
		OfflineServices: len(services) - onlineServices,
		AdminWorkspaces: countAvailableWorkspaces(workspaces),
		Degraded:        degraded,
		CheckedAt:       checkedAt,
		Services:        services,
		Workspaces:      workspaces,
	}
}

func probeAdminServices(services []AdminServiceStatus) {
	// Probe independent microservices concurrently so the overview stays fast.
	// 并发探测独立微服务，避免总览接口被串行等待拖慢。
	client := &http.Client{Timeout: adminServiceProbeTimeout}
	var wg sync.WaitGroup
	for index := range services {
		services[index].HealthURL = strings.TrimRight(services[index].BaseURL, "/") + "/health"
		if services[index].Key == "admin" {
			continue
		}
		wg.Add(1)
		go func(item *AdminServiceStatus) {
			defer wg.Done()
			item.Online, item.LatencyMS = probeServiceHealth(client, item.HealthURL)
		}(&services[index])
	}
	wg.Wait()
}

func buildAdminWorkspaces(services []AdminServiceStatus) []AdminWorkspaceStatus {
	// Expose admin-relevant workspace availability alongside raw service health.
	// 在原始服务健康状态之外，额外输出管理员关心的工作区可用性。
	serviceOnline := map[string]bool{}
	for _, item := range services {
		serviceOnline[item.Key] = item.Online
	}

	return []AdminWorkspaceStatus{
		{
			Key:        "account-admin",
			Title:      "Account admin workspace",
			ServiceKey: "account",
			Available:  serviceOnline["account"],
		},
		{
			Key:        "admin-panel",
			Title:      "Site admin panel",
			ServiceKey: "admin",
			Available:  serviceOnline["admin"],
		},
		{
			Key:        "space-admin",
			Title:      "Space admin workspace",
			ServiceKey: "space",
			Available:  serviceOnline["space"],
		},
		{
			Key:        "message-admin",
			Title:      "Message admin workspace",
			ServiceKey: "message",
			Available:  serviceOnline["message"],
		},
		{
			Key:        "learning-admin",
			Title:      "Learning admin workspace",
			ServiceKey: "learning",
			Available:  serviceOnline["learning"],
		},
	}
}

func countAvailableWorkspaces(workspaces []AdminWorkspaceStatus) int {
	count := 0
	for _, item := range workspaces {
		if item.Available {
			count++
		}
	}
	return count
}

func serviceBaseURL(envKey string, fallback string) string {
	// Resolve one service base URL from the environment with a local default.
	// 从环境变量解析服务基础地址，并提供本地默认值。
	value := strings.TrimSpace(os.Getenv(envKey))
	if value == "" {
		return fallback
	}
	return strings.TrimRight(value, "/")
}

func probeServiceHealth(client *http.Client, healthURL string) (bool, int64) {
	// Probe one microservice health endpoint with a short timeout.
	// 用较短超时探测一个微服务健康检查接口。
	startedAt := time.Now()
	response, err := client.Get(healthURL)
	if err != nil {
		return false, 0
	}
	defer response.Body.Close()
	return response.StatusCode >= 200 && response.StatusCode < 300, time.Since(startedAt).Milliseconds()
}
