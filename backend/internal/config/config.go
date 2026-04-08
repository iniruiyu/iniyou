package config

import (
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"time"
)

type Config struct {
	ServiceName        string
	Port               string
	DBDsn              string
	JWTSecret          string
	MediaStorageDir    string
	MarkdownStorageDir string
	TokenTTL           time.Duration
}

func Load(serviceName string) Config {
	// Load configuration with environment fallbacks.
	// 读取环境变量并提供默认值。
	port := getenv("SERVICE_PORT", "8080")
	if serviceName == "message" {
		port = getenv("SERVICE_PORT", "8081")
	} else if serviceName == "space" {
		port = getenv("SERVICE_PORT", "8082")
	} else if serviceName == "learning" {
		port = getenv("SERVICE_PORT", "8083")
	} else if serviceName == "admin" {
		port = getenv("SERVICE_PORT", "8084")
	}

	// Token TTL in minutes.
	// Token 过期时间（分钟）。
	ttlMin := getenv("TOKEN_TTL_MIN", "120")
	ttlInt, _ := strconv.Atoi(ttlMin)
	if ttlInt <= 0 {
		ttlInt = 120
	}

	mediaStorageDir := filepath.Clean(getenv("MEDIA_STORAGE_DIR", defaultMediaStorageDir()))
	markdownStorageDir := filepath.Clean(getenv("MARKDOWN_STORAGE_DIR", defaultMarkdownStorageDir(serviceName, mediaStorageDir)))

	return Config{
		ServiceName:        serviceName,
		Port:               port,
		DBDsn:              getenv("DB_DSN", "host=localhost user=postgres password=postgres dbname=account_service port=5432 sslmode=disable"),
		JWTSecret:          getenv("JWT_SECRET", "dev-secret"),
		MediaStorageDir:    mediaStorageDir,
		MarkdownStorageDir: markdownStorageDir,
		TokenTTL:           time.Duration(ttlInt) * time.Minute,
	}
}

func defaultMediaStorageDir() string {
	// Use a Windows-friendly path locally and a Linux-friendly path in containers.
	// 本地 Windows 使用友好路径，容器和 Linux 环境使用 Linux 友好路径。
	if runtime.GOOS == "windows" {
		return filepath.FromSlash("D:/codeX/iniyou/uploads/space-service")
	}
	return "/data/uploads/space-service"
}

func defaultMarkdownStorageDir(serviceName string, mediaStorageDir string) string {
	// Keep markdown storage service-specific while preserving the shared fallback for existing services.
	// 让 Markdown 存储保持服务级隔离，同时为现有服务保留共享回退路径。
	if serviceName == "learning" {
		if runtime.GOOS == "windows" {
			return filepath.FromSlash("D:/codeX/iniyou/uploads/learning-service/markdown-files")
		}
		return "/data/uploads/learning-service/markdown-files"
	}
	return filepath.Join(mediaStorageDir, "markdown-files")
}

func getenv(key, fallback string) string {
	// Return env value or fallback.
	// 返回环境变量值或默认值。
	if v := os.Getenv(key); v != "" {
		return v
	}
	if v, ok := readLocalOverrideValue(key); ok {
		return v
	}
	return fallback
}
