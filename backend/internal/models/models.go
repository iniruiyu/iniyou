package models

import "time"

type User struct {
	// User core profile.
	// 用户核心信息。
	ID           string    `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	Email        *string   `gorm:"uniqueIndex"`
	Phone        *string   `gorm:"uniqueIndex"`
	DisplayName  string    `gorm:"type:varchar(80);default:''"`
	PasswordHash string
	Level        string    `gorm:"type:varchar(20);default:basic"`
	Status       string    `gorm:"type:varchar(20);default:active"`
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type Space struct {
	// Private or public space.
	// 私人或公共空间。
	ID          string    `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID      string    `gorm:"index"`
	Type        string    `gorm:"type:varchar(20)"`
	Name        string    `gorm:"type:varchar(100)"`
	Description string    `gorm:"type:text"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type Subscription struct {
	// Subscription plan for a user.
	// 用户订阅方案。
	ID        string    `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID    string    `gorm:"index"`
	PlanID    string    `gorm:"type:varchar(50)"`
	Status    string    `gorm:"type:varchar(20)"`
	StartedAt time.Time
	EndedAt   *time.Time
}

type Friend struct {
	// Friendship relation.
	// 好友关系。
	ID        string    `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID    string    `gorm:"index"`
	FriendID  string    `gorm:"index"`
	Status    string    `gorm:"type:varchar(20)"`
	CreatedAt time.Time
}

type Message struct {
	// Chat message.
	// 聊天消息。
	ID         string     `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	SenderID   string     `gorm:"index"`
	ReceiverID string     `gorm:"index"`
	Content    string     `gorm:"type:text"`
	CreatedAt  time.Time
	ReadAt     *time.Time
}
