package service

import (
	"errors"
	"strings"

	"account-service/internal/config"
)

type AdminDatabaseConfig struct {
	// SourcePath shows which local override file the administrator is editing.
	// SourcePath 表示管理员当前编辑的是哪个本地覆盖配置文件。
	SourcePath string `json:"source_path"`
	// Dsn is the editable full database DSN used for local development overrides.
	// Dsn 是用于本地开发覆盖的可编辑完整数据库 DSN。
	Dsn string `json:"dsn"`
	// MaskedDsn is a safe preview for dashboards and audit-friendly confirmation text.
	// MaskedDsn 是用于面板展示和确认提示的安全脱敏预览。
	MaskedDsn string `json:"masked_dsn"`
	// Driver is the inferred database driver.
	// Driver 是推导出的数据库驱动名称。
	Driver string `json:"driver"`
	Host   string `json:"host"`
	Port   string `json:"port"`
	User   string `json:"user"`
	// Database is the parsed database name.
	// Database 是解析得到的数据库名称。
	Database string `json:"database"`
	SSLMode  string `json:"ssl_mode"`
	// RequiresRestart makes the runtime contract explicit for the development control panel.
	// RequiresRestart 明确告诉开发期总控：修改后需要重启服务。
	RequiresRestart bool `json:"requires_restart"`
}

func GetAdminDatabaseConfig() (AdminDatabaseConfig, error) {
	// Read the editable database configuration for the administrator control panel.
	// 读取管理员总控可编辑的数据库配置。
	dsn, path, err := config.ReadLocalOverrideValue("DB_DSN")
	if err != nil {
		return AdminDatabaseConfig{}, err
	}
	if strings.TrimSpace(dsn) == "" {
		dsn = config.Load("admin").DBDsn
	}
	return buildAdminDatabaseConfig(path, dsn), nil
}

func UpdateAdminDatabaseConfig(nextDSN string) (AdminDatabaseConfig, error) {
	// Persist a new database DSN into the shared local override file.
	// 将新的数据库 DSN 持久化到共享本地覆盖配置文件。
	nextDSN = strings.TrimSpace(nextDSN)
	if nextDSN == "" {
		return AdminDatabaseConfig{}, errors.New("db dsn required")
	}
	path, err := config.WriteLocalOverrideValue("DB_DSN", nextDSN)
	if err != nil {
		return AdminDatabaseConfig{}, err
	}
	return buildAdminDatabaseConfig(path, nextDSN), nil
}

func buildAdminDatabaseConfig(path string, dsn string) AdminDatabaseConfig {
	// Build the editable database config payload from one DSN string.
	// 根据单个 DSN 构建可编辑数据库配置载荷。
	values := parseDSNKeyValues(dsn)
	return AdminDatabaseConfig{
		SourcePath:      path,
		Dsn:             dsn,
		MaskedDsn:       redactDSN(dsn),
		Driver:          "postgres",
		Host:            values["host"],
		Port:            values["port"],
		User:            values["user"],
		Database:        values["dbname"],
		SSLMode:         values["sslmode"],
		RequiresRestart: true,
	}
}
