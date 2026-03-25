package config

import (
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"time"
)

type Config struct {
	ServiceName     string
	Port            string
	DBDsn           string
	JWTSecret       string
	MediaStorageDir string
	TokenTTL        time.Duration
}

func Load(serviceName string) Config {
	// Load configuration with environment fallbacks.
	// 读取环境变量并提供默认值。
	port := getenv("SERVICE_PORT", "8080")
	if serviceName == "message" {
		port = getenv("SERVICE_PORT", "8081")
	} else if serviceName == "space" {
		port = getenv("SERVICE_PORT", "8082")
	}

	// Token TTL in minutes.
	// Token 过期时间（分钟）。
	ttlMin := getenv("TOKEN_TTL_MIN", "120")
	ttlInt, _ := strconv.Atoi(ttlMin)
	if ttlInt <= 0 {
		ttlInt = 120
	}

	return Config{
		ServiceName:     serviceName,
		Port:            port,
		DBDsn:           getenv("DB_DSN", "host=localhost user=postgres password=postgres dbname=account_service port=5432 sslmode=disable"),
		JWTSecret:       getenv("JWT_SECRET", "dev-secret"),
		MediaStorageDir: filepath.Clean(getenv("MEDIA_STORAGE_DIR", defaultMediaStorageDir())),
		TokenTTL:        time.Duration(ttlInt) * time.Minute,
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

func getenv(key, fallback string) string {
	// Return env value or fallback.
	// 返回环境变量值或默认值。
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
