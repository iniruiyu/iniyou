package service

import (
	"net/http"
	"net/url"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"

	"gorm.io/gorm"

	"account-service/internal/config"
	"account-service/internal/models"
)

const adminServiceProbeTimeout = 800 * time.Millisecond

type AdminConfigItem struct {
	Key   string `json:"key"`
	Value string `json:"value"`
}

type AdminSummary struct {
	TotalServices   int `json:"total_services"`
	OnlineServices  int `json:"online_services"`
	OfflineServices int `json:"offline_services"`
	TotalUsers      int `json:"total_users"`
	AdminUsers      int `json:"admin_users"`
	ActiveUsers     int `json:"active_users"`
	DisabledUsers   int `json:"disabled_users"`
}

type AdminServiceStatus struct {
	Key            string            `json:"key"`
	Title          string            `json:"title"`
	BaseURL        string            `json:"base_url"`
	Online         bool              `json:"online"`
	Required       bool              `json:"required"`
	ResponseTimeMs int64             `json:"response_time_ms"`
	ConfigItems    []AdminConfigItem `json:"config_items"`
}

type AdminDatabaseSummary struct {
	Driver             string `json:"driver"`
	Host               string `json:"host"`
	Port               string `json:"port"`
	Database           string `json:"database"`
	User               string `json:"user"`
	SSLMode            string `json:"ssl_mode"`
	MaskedDSN          string `json:"masked_dsn"`
	OpenConnections    int    `json:"open_connections"`
	InUseConnections   int    `json:"in_use_connections"`
	IdleConnections    int    `json:"idle_connections"`
	MaxOpenConnections int    `json:"max_open_connections"`
}

type AdminRuntimeSummary struct {
	GoVersion     string `json:"go_version"`
	GoOS          string `json:"go_os"`
	GoArch        string `json:"go_arch"`
	Goroutines    int    `json:"goroutines"`
	MemoryAllocMB int64  `json:"memory_alloc_mb"`
	MemorySysMB   int64  `json:"memory_sys_mb"`
	HeapObjects   uint64 `json:"heap_objects"`
	GCCount       uint32 `json:"gc_count"`
	UptimeSec     int64  `json:"uptime_sec"`
}

type AdminUserItem struct {
	ID          string     `json:"id"`
	DisplayName string     `json:"display_name"`
	Email       string     `json:"email"`
	Username    string     `json:"username"`
	Domain      string     `json:"domain"`
	Level       string     `json:"level"`
	Status      string     `json:"status"`
	CreatedAt   *time.Time `json:"created_at,omitempty"`
}

type AdminUserSummary struct {
	TotalUsers    int             `json:"total_users"`
	AdminUsers    int             `json:"admin_users"`
	ActiveUsers   int             `json:"active_users"`
	InactiveUsers int             `json:"inactive_users"`
	Items         []AdminUserItem `json:"items"`
}

type AdminOverview struct {
	GeneratedAt time.Time            `json:"generated_at"`
	Summary     AdminSummary         `json:"summary"`
	Services    []AdminServiceStatus `json:"services"`
	Database    AdminDatabaseSummary `json:"database"`
	Runtime     AdminRuntimeSummary  `json:"runtime"`
	Users       AdminUserSummary     `json:"users"`
}

func BuildAdminOverview(database *gorm.DB, startedAt time.Time) (AdminOverview, error) {
	// Aggregate the site-wide administrator dashboard payload.
	// 聚合站点级管理员后台载荷。
	learningCfg := config.Load("learning")
	services := buildAdminServiceStatuses(learningCfg.MarkdownStorageDir)
	users, err := buildAdminUserSummary(database)
	if err != nil {
		return AdminOverview{}, err
	}
	summary := buildAdminSummary(services, users)
	return AdminOverview{
		GeneratedAt: time.Now().UTC(),
		Summary:     summary,
		Services:    services,
		Database:    buildAdminDatabaseSummary(database, config.Load("admin").DBDsn),
		Runtime:     buildAdminRuntimeSummary(startedAt),
		Users:       users,
	}, nil
}

func UpdateAdminUser(database *gorm.DB, userID string, nextLevel string, nextStatus string) (AdminUserItem, error) {
	// Update one managed user's level or status from the administrator panel.
	// 在管理员面板中更新单个用户的等级或状态。
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return AdminUserItem{}, gorm.ErrRecordNotFound
	}
	updates := map[string]any{}
	if level := normalizeAdminManagedLevel(nextLevel); level != "" {
		updates["level"] = level
	}
	if status := normalizeAdminManagedStatus(nextStatus); status != "" {
		updates["status"] = status
	}
	if len(updates) == 0 {
		return AdminUserItem{}, gorm.ErrInvalidData
	}
	if err := database.Model(&models.User{}).Where("id = ?", userID).Updates(updates).Error; err != nil {
		return AdminUserItem{}, err
	}
	var user models.User
	if err := database.First(&user, "id = ?", userID).Error; err != nil {
		return AdminUserItem{}, err
	}
	return mapAdminUserItem(user), nil
}

func buildAdminServiceStatuses(learningMarkdownDir string) []AdminServiceStatus {
	// Build static service config blocks and enrich them with live probe results.
	// 构建静态服务配置块，并补充实时探测结果。
	type serviceDefinition struct {
		key        string
		title      string
		baseURL    string
		required   bool
		configs    []AdminConfigItem
		alwaysLive bool
	}
	definitions := []serviceDefinition{
		{
			key:      "account",
			title:    "Account microservice",
			baseURL:  serviceBaseURL("ACCOUNT_SERVICE_BASE", "http://localhost:8080/api/v1"),
			required: true,
			configs: []AdminConfigItem{
				{Key: "api_base", Value: serviceBaseURL("ACCOUNT_SERVICE_BASE", "http://localhost:8080/api/v1")},
				{Key: "health_path", Value: "/health"},
				{Key: "auth_scope", Value: "identity, profile, level"},
				{Key: "db_source", Value: "shared postgres"},
			},
		},
		{
			key:        "admin",
			title:      "Admin service",
			baseURL:    serviceBaseURL("ADMIN_SERVICE_BASE", "http://localhost:8084/api/v1"),
			required:   true,
			alwaysLive: true,
			configs: []AdminConfigItem{
				{Key: "api_base", Value: serviceBaseURL("ADMIN_SERVICE_BASE", "http://localhost:8084/api/v1")},
				{Key: "overview_path", Value: "/overview"},
				{Key: "user_manage_path", Value: "/users/{id}"},
				{Key: "runtime_scope", Value: "overview, performance, users"},
			},
		},
		{
			key:      "space",
			title:    "Space microservice",
			baseURL:  serviceBaseURL("SPACE_SERVICE_BASE", "http://localhost:8082/api/v1"),
			required: false,
			configs: []AdminConfigItem{
				{Key: "api_base", Value: serviceBaseURL("SPACE_SERVICE_BASE", "http://localhost:8082/api/v1")},
				{Key: "health_path", Value: "/health"},
				{Key: "workspace_scope", Value: "spaces, posts, media"},
				{Key: "write_scope", Value: "spaces, posts, comments"},
			},
		},
		{
			key:      "message",
			title:    "Message microservice",
			baseURL:  serviceBaseURL("MESSAGE_SERVICE_BASE", "http://localhost:8081/api/v1"),
			required: false,
			configs: []AdminConfigItem{
				{Key: "api_base", Value: serviceBaseURL("MESSAGE_SERVICE_BASE", "http://localhost:8081/api/v1")},
				{Key: "health_path", Value: "/health"},
				{Key: "ws_path", Value: "/ws"},
				{Key: "message_scope", Value: "conversations, unread, media"},
			},
		},
		{
			key:      "learning",
			title:    "Learning service",
			baseURL:  serviceBaseURL("LEARNING_SERVICE_BASE", "http://localhost:8083/api/v1"),
			required: false,
			configs: []AdminConfigItem{
				{Key: "api_base", Value: serviceBaseURL("LEARNING_SERVICE_BASE", "http://localhost:8083/api/v1")},
				{Key: "health_path", Value: "/health"},
				{Key: "markdown_dir", Value: learningMarkdownDir},
				{Key: "course_write_scope", Value: "markdown files, status"},
			},
		},
	}
	items := make([]AdminServiceStatus, 0, len(definitions))
	for _, definition := range definitions {
		online := definition.alwaysLive
		responseTimeMs := int64(0)
		if !definition.alwaysLive {
			online, responseTimeMs = probeServiceHealth(definition.baseURL)
		}
		items = append(items, AdminServiceStatus{
			Key:            definition.key,
			Title:          definition.title,
			BaseURL:        definition.baseURL,
			Online:         online,
			Required:       definition.required,
			ResponseTimeMs: responseTimeMs,
			ConfigItems:    definition.configs,
		})
	}
	return items
}

func buildAdminSummary(
	services []AdminServiceStatus,
	users AdminUserSummary,
) AdminSummary {
	// Consolidate top-line service and user totals for the dashboard hero.
	// 汇总站点管理面板头部所需的服务与用户摘要指标。
	onlineServices := 0
	for _, service := range services {
		if service.Online {
			onlineServices++
		}
	}
	return AdminSummary{
		TotalServices:   len(services),
		OnlineServices:  onlineServices,
		OfflineServices: len(services) - onlineServices,
		TotalUsers:      users.TotalUsers,
		AdminUsers:      users.AdminUsers,
		ActiveUsers:     users.ActiveUsers,
		DisabledUsers:   users.InactiveUsers,
	}
}

func buildAdminDatabaseSummary(database *gorm.DB, dsn string) AdminDatabaseSummary {
	// Parse one PostgreSQL DSN into a redacted administrator-facing summary.
	// 将 PostgreSQL DSN 解析为对管理员展示的脱敏摘要。
	values := parseDSNKeyValues(dsn)
	summary := AdminDatabaseSummary{
		Driver:    "postgres",
		Host:      values["host"],
		Port:      values["port"],
		Database:  values["dbname"],
		User:      values["user"],
		SSLMode:   values["sslmode"],
		MaskedDSN: redactDSN(dsn),
	}
	if database == nil {
		return summary
	}
	sqlDB, err := database.DB()
	if err != nil {
		return summary
	}
	stats := sqlDB.Stats()
	summary.OpenConnections = stats.OpenConnections
	summary.InUseConnections = stats.InUse
	summary.IdleConnections = stats.Idle
	summary.MaxOpenConnections = stats.MaxOpenConnections
	return summary
}

func buildAdminRuntimeSummary(startedAt time.Time) AdminRuntimeSummary {
	// Read one runtime snapshot for the administrator performance panel.
	// 读取一份运行时快照，供管理员性能面板展示。
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)
	return AdminRuntimeSummary{
		GoVersion:     runtime.Version(),
		GoOS:          runtime.GOOS,
		GoArch:        runtime.GOARCH,
		Goroutines:    runtime.NumGoroutine(),
		MemoryAllocMB: int64(memStats.Alloc / 1024 / 1024),
		MemorySysMB:   int64(memStats.Sys / 1024 / 1024),
		HeapObjects:   memStats.HeapObjects,
		GCCount:       memStats.NumGC,
		UptimeSec:     int64(time.Since(startedAt).Seconds()),
	}
}

func buildAdminUserSummary(database *gorm.DB) (AdminUserSummary, error) {
	// Build one user-management snapshot with counts and the newest users.
	// 构建一份用户管理快照，包含计数和最新用户列表。
	if database == nil {
		return AdminUserSummary{}, nil
	}
	totalUsers, err := countUsers(database, "")
	if err != nil {
		return AdminUserSummary{}, err
	}
	adminUsers, err := countUsers(database, "level = 'admin'")
	if err != nil {
		return AdminUserSummary{}, err
	}
	activeUsers, err := countUsers(database, "status = 'active'")
	if err != nil {
		return AdminUserSummary{}, err
	}
	var users []models.User
	if err := database.Order("created_at desc").Limit(24).Find(&users).Error; err != nil {
		return AdminUserSummary{}, err
	}
	items := make([]AdminUserItem, 0, len(users))
	for _, user := range users {
		items = append(items, mapAdminUserItem(user))
	}
	return AdminUserSummary{
		TotalUsers:    totalUsers,
		AdminUsers:    adminUsers,
		ActiveUsers:   activeUsers,
		InactiveUsers: totalUsers - activeUsers,
		Items:         items,
	}, nil
}

func countUsers(database *gorm.DB, query string) (int, error) {
	// Count users with an optional filter expression.
	// 按可选过滤条件统计用户数量。
	var total int64
	model := database.Model(&models.User{})
	if strings.TrimSpace(query) != "" {
		model = model.Where(query)
	}
	if err := model.Count(&total).Error; err != nil {
		return 0, err
	}
	return int(total), nil
}

func mapAdminUserItem(user models.User) AdminUserItem {
	// Convert one user row into the administrator table shape.
	// 将单个用户记录转换为管理员表格行结构。
	return AdminUserItem{
		ID:          user.ID,
		DisplayName: user.DisplayName,
		Email:       derefNullableString(user.Email),
		Username:    derefNullableString(user.Username),
		Domain:      derefNullableString(user.Domain),
		Level:       user.Level,
		Status:      user.Status,
		CreatedAt:   &user.CreatedAt,
	}
}

func normalizeAdminManagedLevel(level string) string {
	// Limit level mutations to the known administrator panel values.
	// 将等级变更限制在管理员面板认可的取值范围内。
	switch strings.ToLower(strings.TrimSpace(level)) {
	case "basic":
		return "basic"
	case "vip":
		return "vip"
	case "admin":
		return "admin"
	default:
		return ""
	}
}

func normalizeAdminManagedStatus(status string) string {
	// Limit status mutations to the known account status values.
	// 将状态变更限制在已知账号状态范围内。
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "active":
		return "active"
	case "disabled":
		return "disabled"
	default:
		return ""
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

func probeServiceHealth(baseURL string) (bool, int64) {
	// Probe one microservice health endpoint with a short timeout.
	// 用较短超时探测一个微服务健康检查接口。
	client := &http.Client{Timeout: adminServiceProbeTimeout}
	startedAt := time.Now()
	response, err := client.Get(strings.TrimRight(baseURL, "/") + "/health")
	if err != nil {
		return false, 0
	}
	defer response.Body.Close()
	return response.StatusCode >= 200 && response.StatusCode < 300, time.Since(startedAt).Milliseconds()
}

func parseDSNKeyValues(dsn string) map[string]string {
	// Parse a key=value PostgreSQL DSN into a small lookup table.
	// 将 key=value 形式的 PostgreSQL DSN 解析为小型查询表。
	values := map[string]string{}
	if strings.Contains(dsn, "://") {
		if parsed, err := url.Parse(strings.TrimSpace(dsn)); err == nil {
			values["host"] = parsed.Hostname()
			values["port"] = parsed.Port()
			values["dbname"] = strings.TrimPrefix(parsed.Path, "/")
			if parsed.User != nil {
				values["user"] = parsed.User.Username()
			}
			if sslMode := parsed.Query().Get("sslmode"); sslMode != "" {
				values["sslmode"] = sslMode
			}
		}
	}
	for _, part := range strings.Fields(strings.TrimSpace(dsn)) {
		key, value, found := strings.Cut(part, "=")
		if !found {
			continue
		}
		values[strings.ToLower(strings.TrimSpace(key))] = strings.Trim(strings.TrimSpace(value), `"'`)
	}
	if values["port"] == "" {
		values["port"] = inferredPortFromDSNURL(dsn)
	}
	if values["sslmode"] == "" {
		values["sslmode"] = "disable"
	}
	return values
}

func redactDSN(dsn string) string {
	// Remove the database password before returning a DSN to the frontend.
	// 在返回给前端前，先移除数据库密码。
	parts := strings.Fields(strings.TrimSpace(dsn))
	if len(parts) == 0 {
		return dsn
	}
	masked := make([]string, 0, len(parts))
	for _, part := range parts {
		key, value, found := strings.Cut(part, "=")
		if !found {
			masked = append(masked, part)
			continue
		}
		if strings.EqualFold(strings.TrimSpace(key), "password") {
			masked = append(masked, key+"=***")
			continue
		}
		masked = append(masked, key+"="+value)
	}
	return strings.Join(masked, " ")
}

func inferredPortFromDSNURL(dsn string) string {
	// Best-effort port parsing for URL-like DSNs.
	// 对 URL 风格 DSN 做尽力而为的端口解析。
	parsed, err := url.Parse(strings.TrimSpace(dsn))
	if err != nil {
		return ""
	}
	if parsed.Port() != "" {
		return parsed.Port()
	}
	return strconv.Itoa(5432)
}

func derefNullableString(value *string) string {
	// Safely dereference one nullable string column.
	// 安全解引用可空字符串字段。
	if value == nil {
		return ""
	}
	return *value
}
