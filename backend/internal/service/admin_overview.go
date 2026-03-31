package service

import (
	"net/http"
	"os"
	"strings"
	"time"
)

const adminServiceProbeTimeout = 800 * time.Millisecond

type AdminServiceStatus struct {
	Key      string `json:"key"`
	Title    string `json:"title"`
	BaseURL  string `json:"base_url"`
	Online   bool   `json:"online"`
	Required bool   `json:"required"`
}

type AdminOverview struct {
	TotalServices   int                  `json:"total_services"`
	OnlineServices  int                  `json:"online_services"`
	OfflineServices int                  `json:"offline_services"`
	AdminWorkspaces int                  `json:"admin_workspaces"`
	Services        []AdminServiceStatus `json:"services"`
}

func BuildAdminOverview() AdminOverview {
	// Aggregate one site-wide service overview for the administrator panel.
	// 为管理员总管理面板聚合一份站点级服务总览。
	services := []AdminServiceStatus{
		{
			Key:      "account",
			Title:    "Account microservice",
			BaseURL:  serviceBaseURL("ACCOUNT_SERVICE_BASE", "http://localhost:8080/api/v1"),
			Online:   probeServiceHealth(serviceBaseURL("ACCOUNT_SERVICE_BASE", "http://localhost:8080/api/v1")),
			Required: true,
		},
		{
			Key:      "admin",
			Title:    "Admin service",
			BaseURL:  serviceBaseURL("ADMIN_SERVICE_BASE", "http://localhost:8084/api/v1"),
			Online:   true,
			Required: true,
		},
		{
			Key:      "space",
			Title:    "Space microservice",
			BaseURL:  serviceBaseURL("SPACE_SERVICE_BASE", "http://localhost:8082/api/v1"),
			Online:   probeServiceHealth(serviceBaseURL("SPACE_SERVICE_BASE", "http://localhost:8082/api/v1")),
			Required: false,
		},
		{
			Key:      "message",
			Title:    "Message microservice",
			BaseURL:  serviceBaseURL("MESSAGE_SERVICE_BASE", "http://localhost:8081/api/v1"),
			Online:   probeServiceHealth(serviceBaseURL("MESSAGE_SERVICE_BASE", "http://localhost:8081/api/v1")),
			Required: false,
		},
		{
			Key:      "learning",
			Title:    "Learning service",
			BaseURL:  serviceBaseURL("LEARNING_SERVICE_BASE", "http://localhost:8083/api/v1"),
			Online:   probeServiceHealth(serviceBaseURL("LEARNING_SERVICE_BASE", "http://localhost:8083/api/v1")),
			Required: false,
		},
	}

	onlineServices := 0
	for _, item := range services {
		if item.Online {
			onlineServices++
		}
	}

	adminWorkspaces := 1
	for _, item := range services {
		if item.Key == "learning" && item.Online {
			adminWorkspaces++
			break
		}
	}

	return AdminOverview{
		TotalServices:   len(services),
		OnlineServices:  onlineServices,
		OfflineServices: len(services) - onlineServices,
		AdminWorkspaces: adminWorkspaces,
		Services:        services,
	}
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

func probeServiceHealth(baseURL string) bool {
	// Probe one microservice health endpoint with a short timeout.
	// 用较短超时探测一个微服务健康检查接口。
	client := &http.Client{Timeout: adminServiceProbeTimeout}
	response, err := client.Get(strings.TrimRight(baseURL, "/") + "/health")
	if err != nil {
		return false
	}
	defer response.Body.Close()
	return response.StatusCode >= 200 && response.StatusCode < 300
}
