package db

import (
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func Connect(dsn string) (*gorm.DB, error) {
	// Connect to PostgreSQL using GORM.
	// 使用 GORM 连接 PostgreSQL。
	return gorm.Open(postgres.Open(dsn), &gorm.Config{})
}
