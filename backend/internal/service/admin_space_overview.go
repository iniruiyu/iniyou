package service

import (
	"time"

	"gorm.io/gorm"

	"account-service/internal/models"
)

type AdminSpaceSummary struct {
	ID         string    `json:"id"`
	Name       string    `json:"name"`
	Subdomain  string    `json:"subdomain"`
	Type       string    `json:"type"`
	Visibility string    `json:"visibility"`
	Status     string    `json:"status"`
	OwnerID    string    `json:"owner_id"`
	OwnerName  string    `json:"owner_name"`
	PostsCount int64     `json:"posts_count"`
	UpdatedAt  time.Time `json:"updated_at"`
	CreatedAt  time.Time `json:"created_at"`
}

type AdminPostSummary struct {
	ID         string    `json:"id"`
	Title      string    `json:"title"`
	Status     string    `json:"status"`
	Visibility string    `json:"visibility"`
	AuthorID   string    `json:"author_id"`
	AuthorName string    `json:"author_name"`
	SpaceID    string    `json:"space_id"`
	SpaceName  string    `json:"space_name"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type AdminSpaceOverview struct {
	TotalSpaces    int64               `json:"total_spaces"`
	ActiveSpaces   int64               `json:"active_spaces"`
	PrivateSpaces  int64               `json:"private_spaces"`
	PublicSpaces   int64               `json:"public_spaces"`
	TotalPosts     int64               `json:"total_posts"`
	DraftPosts     int64               `json:"draft_posts"`
	PublishedPosts int64               `json:"published_posts"`
	ArchivedPosts  int64               `json:"archived_posts"`
	RecentSpaces   []AdminSpaceSummary `json:"recent_spaces"`
	RecentPosts    []AdminPostSummary  `json:"recent_posts"`
}

func BuildAdminSpaceOverview(db *gorm.DB) (AdminSpaceOverview, error) {
	// Aggregate one space-service administrator summary from the shared database.
	// 从共享数据库聚合一份空间服务管理员总览。
	var overview AdminSpaceOverview

	if err := db.Model(&models.Space{}).Count(&overview.TotalSpaces).Error; err != nil {
		return AdminSpaceOverview{}, err
	}
	if err := db.Model(&models.Space{}).Where("status = ?", "active").Count(&overview.ActiveSpaces).Error; err != nil {
		return AdminSpaceOverview{}, err
	}
	if err := db.Model(&models.Space{}).Where("type = ?", "private").Count(&overview.PrivateSpaces).Error; err != nil {
		return AdminSpaceOverview{}, err
	}
	if err := db.Model(&models.Space{}).Where("type = ?", "public").Count(&overview.PublicSpaces).Error; err != nil {
		return AdminSpaceOverview{}, err
	}
	if err := db.Model(&models.Post{}).Count(&overview.TotalPosts).Error; err != nil {
		return AdminSpaceOverview{}, err
	}
	if err := db.Model(&models.Post{}).Where("status = ?", "draft").Count(&overview.DraftPosts).Error; err != nil {
		return AdminSpaceOverview{}, err
	}
	if err := db.Model(&models.Post{}).Where("status = ?", "published").Count(&overview.PublishedPosts).Error; err != nil {
		return AdminSpaceOverview{}, err
	}
	if err := db.Model(&models.Post{}).Where("status = ?", "archived").Count(&overview.ArchivedPosts).Error; err != nil {
		return AdminSpaceOverview{}, err
	}

	spaces, err := listRecentAdminSpaces(db, 8)
	if err != nil {
		return AdminSpaceOverview{}, err
	}
	posts, err := listRecentAdminPosts(db, 8)
	if err != nil {
		return AdminSpaceOverview{}, err
	}
	overview.RecentSpaces = spaces
	overview.RecentPosts = posts
	return overview, nil
}

func listRecentAdminSpaces(db *gorm.DB, limit int) ([]AdminSpaceSummary, error) {
	type spaceRow struct {
		ID         string
		Name       string
		Subdomain  string
		Type       string
		Visibility string
		Status     string
		OwnerID    string
		OwnerName  string
		PostsCount int64
		UpdatedAt  time.Time
		CreatedAt  time.Time
	}

	rows := make([]spaceRow, 0, limit)
	if err := db.Table("spaces AS s").
		Select(`
			s.id,
			s.name,
			s.subdomain,
			s.type,
			s.visibility,
			s.status,
			s.user_id AS owner_id,
			COALESCE(NULLIF(u.display_name, ''), NULLIF(u.username, ''), NULLIF(u.domain, ''), s.user_id) AS owner_name,
			COUNT(p.id) AS posts_count,
			s.updated_at,
			s.created_at
		`).
		Joins("LEFT JOIN users AS u ON u.id = s.user_id").
		Joins("LEFT JOIN posts AS p ON p.space_id = s.id").
		Group("s.id, u.display_name, u.username, u.domain").
		Order("s.updated_at desc").
		Limit(limit).
		Scan(&rows).Error; err != nil {
		return nil, err
	}

	items := make([]AdminSpaceSummary, 0, len(rows))
	for _, row := range rows {
		items = append(items, AdminSpaceSummary{
			ID:         row.ID,
			Name:       row.Name,
			Subdomain:  row.Subdomain,
			Type:       row.Type,
			Visibility: row.Visibility,
			Status:     row.Status,
			OwnerID:    row.OwnerID,
			OwnerName:  row.OwnerName,
			PostsCount: row.PostsCount,
			UpdatedAt:  row.UpdatedAt,
			CreatedAt:  row.CreatedAt,
		})
	}
	return items, nil
}

func listRecentAdminPosts(db *gorm.DB, limit int) ([]AdminPostSummary, error) {
	type postRow struct {
		ID         string
		Title      string
		Status     string
		Visibility string
		AuthorID   string
		AuthorName string
		SpaceID    string
		SpaceName  string
		CreatedAt  time.Time
		UpdatedAt  time.Time
	}

	rows := make([]postRow, 0, limit)
	if err := db.Table("posts AS p").
		Select(`
			p.id,
			p.title,
			p.status,
			p.visibility,
			p.user_id AS author_id,
			COALESCE(NULLIF(u.display_name, ''), NULLIF(u.username, ''), NULLIF(u.domain, ''), p.user_id) AS author_name,
			p.space_id,
			COALESCE(s.name, '') AS space_name,
			p.created_at,
			p.updated_at
		`).
		Joins("LEFT JOIN users AS u ON u.id = p.user_id").
		Joins("LEFT JOIN spaces AS s ON s.id = p.space_id").
		Order("p.updated_at desc").
		Limit(limit).
		Scan(&rows).Error; err != nil {
		return nil, err
	}

	items := make([]AdminPostSummary, 0, len(rows))
	for _, row := range rows {
		items = append(items, AdminPostSummary{
			ID:         row.ID,
			Title:      row.Title,
			Status:     row.Status,
			Visibility: row.Visibility,
			AuthorID:   row.AuthorID,
			AuthorName: row.AuthorName,
			SpaceID:    row.SpaceID,
			SpaceName:  row.SpaceName,
			CreatedAt:  row.CreatedAt,
			UpdatedAt:  row.UpdatedAt,
		})
	}
	return items, nil
}
