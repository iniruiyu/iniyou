package main

import (
	"flag"
	"log"

	"account-service/internal/config"
	"account-service/internal/db"
	"account-service/internal/migrate"
)

func main() {
	// Explicit versioned schema and backfill migration entrypoint.
	// 显式的版本化表结构与回填迁移入口。
	target := flag.String("service", migrate.TargetAll, "migration target: all, account, space, or message")
	flag.Parse()

	// Reuse the shared database DSN because all backend services point to the same database.
	// 复用共享数据库连接串，因为所有后端服务都指向同一个数据库。
	cfg := config.Load("account")
	database, err := db.Connect(cfg.DBDsn)
	if err != nil {
		log.Fatalf("db connect error: %v", err)
	}

	if err := migrate.Run(database, *target); err != nil {
		log.Fatalf("migration error: %v", err)
	}
	log.Printf("migration completed for target %q", *target)
}
