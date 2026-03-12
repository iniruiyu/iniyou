package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	ServiceName string
	Port        string
	DBDsn       string
	JWTSecret   string
	TokenTTL    time.Duration
}

func Load(serviceName string) Config {
	// Load configuration with environment fallbacks.
	// 读取环境变量并提供默认值。
	port := getenv("SERVICE_PORT", "8080")
	if serviceName == "message" {
		port = getenv("SERVICE_PORT", "8081")
	}

	// Token TTL in minutes.
	// Token 过期时间（分钟）。
	ttlMin := getenv("TOKEN_TTL_MIN", "120")
	ttlInt, _ := strconv.Atoi(ttlMin)
	if ttlInt <= 0 {
		ttlInt = 120
	}

	return Config{
		ServiceName: serviceName,
		Port:        port,
		DBDsn:       getenv("DB_DSN", "host=localhost user=postgres password=postgres dbname=account_service port=5432 sslmode=disable"),
		JWTSecret:   getenv("JWT_SECRET", "dev-secret"),
		TokenTTL:    time.Duration(ttlInt) * time.Minute,
	}
}

func getenv(key, fallback string) string {
	// Return env value or fallback.
	// 返回环境变量值或默认值。
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
