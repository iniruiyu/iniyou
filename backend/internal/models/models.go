package models

import "time"

type User struct {
	// User core profile.
	// 用户核心信息。
	ID               string     `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	Email            *string    `gorm:"uniqueIndex"`
	Phone            *string    `gorm:"uniqueIndex"`
	Username         *string    `gorm:"type:varchar(63);uniqueIndex"`
	Domain           *string    `gorm:"type:varchar(63);uniqueIndex"`
	DisplayName      string     `gorm:"type:varchar(80);default:''"`
	AvatarURL        string     `gorm:"type:text;default:''"`
	Signature        string     `gorm:"type:text;default:''"`
	Age              *int       `gorm:"default:null"`
	BirthDate        *time.Time `gorm:"type:date;default:null"`
	Gender           *string    `gorm:"type:varchar(20);default:null"`
	PhoneVisibility  string     `gorm:"type:varchar(20);default:private"`
	EmailVisibility  string     `gorm:"type:varchar(20);default:private"`
	AgeVisibility    string     `gorm:"type:varchar(20);default:private"`
	GenderVisibility string     `gorm:"type:varchar(20);default:private"`
	PasswordHash     string
	// PasswordVersion invalidates older JWTs after a password change.
	// PasswordVersion 用于在密码变更后使旧 JWT 失效。
	PasswordVersion int64  `gorm:"default:1"`
	Role            string `gorm:"type:varchar(20);default:member"`
	Level           string `gorm:"type:varchar(20);default:basic"`
	Status          string `gorm:"type:varchar(20);default:active"`
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type Space struct {
	// Space metadata with subdomain entry support.
	// 支持二级域名入口的空间元数据。
	ID string `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	// UserID and Type share a composite lookup index for owned-space queries.
	// UserID 和 Type 共用复合查询索引，便于按用户与空间类型检索。
	UserID      string    `gorm:"index:idx_space_user_type,priority:1" json:"user_id"`
	Type        string    `gorm:"type:varchar(20);index:idx_space_user_type,priority:2" json:"type"`
	Source      string    `gorm:"type:varchar(20);default:user" json:"source,omitempty"`
	Visibility  string    `gorm:"type:varchar(20);default:public" json:"visibility"`
	Subdomain   string    `gorm:"type:varchar(120);uniqueIndex" json:"subdomain"`
	Name        string    `gorm:"type:varchar(100)" json:"name"`
	Description string    `gorm:"type:text" json:"description"`
	Status      string    `gorm:"type:varchar(20);default:active" json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Subscription struct {
	// Subscription plan for a user.
	// 用户订阅方案。
	ID        string    `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID    string    `gorm:"index:idx_subscription_user_started_at,priority:1"`
	PlanID    string    `gorm:"type:varchar(50)"`
	Status    string    `gorm:"type:varchar(20)"`
	StartedAt time.Time `gorm:"index:idx_subscription_user_started_at,priority:2"`
	EndedAt   *time.Time
}

type ExternalAccount struct {
	// External identity binding, such as a blockchain address.
	// 外部身份绑定，例如区块链地址。
	ID                string `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID            string `gorm:"index"`
	Provider          string `gorm:"type:varchar(40);index:idx_external_provider_identifier,unique"`
	Chain             string `gorm:"type:varchar(40);default:''"`
	AccountIdentifier string `gorm:"type:varchar(160);index:idx_external_provider_identifier,unique"`
	AccountAddress    string `gorm:"type:varchar(160)"`
	BindingStatus     string `gorm:"type:varchar(20);default:active"`
	Metadata          string `gorm:"type:text"`
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type Friend struct {
	// Friendship relation.
	// 好友关系。
	ID        string `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID    string `gorm:"index"`
	FriendID  string `gorm:"index"`
	Status    string `gorm:"type:varchar(20)"`
	CreatedAt time.Time
}

type Message struct {
	// Chat message.
	// 聊天消息。
	// Message payload metadata.
	// 消息载荷元数据。
	ID          string     `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	SenderID    string     `gorm:"index" json:"sender_id"`
	ReceiverID  string     `gorm:"index" json:"receiver_id"`
	MessageType string     `gorm:"type:varchar(20);default:text;index" json:"message_type"`
	Content     string     `gorm:"type:text" json:"content"`
	MediaName   string     `gorm:"type:varchar(255);default:''" json:"media_name"`
	MediaMime   string     `gorm:"type:varchar(120);default:''" json:"media_mime"`
	MediaData   string     `gorm:"type:text" json:"media_data,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	ReadAt      *time.Time `gorm:"index" json:"read_at,omitempty"`
	ExpiresAt   *time.Time `gorm:"index" json:"expires_at,omitempty"`
}

type Post struct {
	// Social post content.
	// 社交文章内容。
	ID        string `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID    string `gorm:"index"`
	SpaceID   string `gorm:"type:uuid;index"`
	Title     string `gorm:"type:varchar(160)"`
	Content   string `gorm:"type:text"`
	MediaType string `gorm:"type:varchar(20);default:text"`
	MediaName string `gorm:"type:varchar(255);default:''"`
	MediaMime string `gorm:"type:varchar(120);default:''"`
	MediaData string `gorm:"type:text;default:''"`
	// Serialized media gallery payload stored alongside the legacy single-media fields.
	// 与旧版单媒体字段并存的序列化媒体集合载荷。
	MediaItems string `gorm:"type:text;default:''"`
	Status     string `gorm:"type:varchar(20);default:published"`
	Visibility string `gorm:"type:varchar(20);default:public"`
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type Comment struct {
	// Post comment.
	// 文章评论。
	ID              string  `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	PostID          string  `gorm:"index"`
	UserID          string  `gorm:"index"`
	ParentCommentID *string `gorm:"index"`
	Content         string  `gorm:"type:text"`
	Status          string  `gorm:"type:varchar(20);default:published"`
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type PostLike struct {
	// Like relation between user and post.
	// 用户与文章的点赞关系。
	ID        string `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	PostID    string `gorm:"index:idx_post_like_user,unique"`
	UserID    string `gorm:"index:idx_post_like_user,unique"`
	Status    string `gorm:"type:varchar(20);default:active"`
	CreatedAt time.Time
}

type PostShare struct {
	// Share record of a post.
	// 文章转发记录。
	ID        string `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	PostID    string `gorm:"index"`
	UserID    string `gorm:"index"`
	ShareType string `gorm:"type:varchar(20);default:repost"`
	Status    string `gorm:"type:varchar(20);default:active"`
	CreatedAt time.Time
}
