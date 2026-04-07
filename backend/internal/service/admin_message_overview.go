package service

import (
	"fmt"
	"strings"
	"time"

	"gorm.io/gorm"

	"account-service/internal/models"
)

type AdminMessageSummary struct {
	ID           string     `json:"id"`
	SenderID     string     `json:"sender_id"`
	SenderName   string     `json:"sender_name"`
	ReceiverID   string     `json:"receiver_id"`
	ReceiverName string     `json:"receiver_name"`
	MessageType  string     `json:"message_type"`
	Preview      string     `json:"preview"`
	ReadAt       *time.Time `json:"read_at,omitempty"`
	ExpiresAt    *time.Time `json:"expires_at,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
}

type AdminConversationSummary struct {
	ParticipantAID   string    `json:"participant_a_id"`
	ParticipantAName string    `json:"participant_a_name"`
	ParticipantBID   string    `json:"participant_b_id"`
	ParticipantBName string    `json:"participant_b_name"`
	LastMessageType  string    `json:"last_message_type"`
	LastPreview      string    `json:"last_preview"`
	LastAt           time.Time `json:"last_at"`
	MessageCount     int64     `json:"message_count"`
	UnreadCount      int64     `json:"unread_count"`
}

type AdminMessageOverview struct {
	TotalMessages       int64                      `json:"total_messages"`
	UnreadMessages      int64                      `json:"unread_messages"`
	ActiveConversations int64                      `json:"active_conversations"`
	ConnectedFriends    int64                      `json:"connected_friends"`
	MediaMessages       int64                      `json:"media_messages"`
	EphemeralMessages   int64                      `json:"ephemeral_messages"`
	RecentMessages      []AdminMessageSummary      `json:"recent_messages"`
	RecentConversations []AdminConversationSummary `json:"recent_conversations"`
}

func BuildAdminMessageOverview(db *gorm.DB) (AdminMessageOverview, error) {
	// Aggregate one message-service administrator summary from the shared database.
	// 从共享数据库聚合一份消息服务管理员总览。
	var overview AdminMessageOverview
	now := time.Now()

	baseQuery := db.Model(&models.Message{}).Where("expires_at IS NULL OR expires_at > ?", now)
	if err := baseQuery.Count(&overview.TotalMessages).Error; err != nil {
		return AdminMessageOverview{}, err
	}
	if err := db.Model(&models.Message{}).
		Where("read_at IS NULL AND (expires_at IS NULL OR expires_at > ?)", now).
		Count(&overview.UnreadMessages).Error; err != nil {
		return AdminMessageOverview{}, err
	}
	if err := db.Model(&models.Friend{}).
		Where("status = ?", "accepted").
		Count(&overview.ConnectedFriends).Error; err != nil {
		return AdminMessageOverview{}, err
	}
	if err := db.Model(&models.Message{}).
		Where("message_type <> ? AND (expires_at IS NULL OR expires_at > ?)", "text", now).
		Count(&overview.MediaMessages).Error; err != nil {
		return AdminMessageOverview{}, err
	}
	if err := db.Model(&models.Message{}).
		Where("expires_at IS NOT NULL AND expires_at > ?", now).
		Count(&overview.EphemeralMessages).Error; err != nil {
		return AdminMessageOverview{}, err
	}
	if err := db.Table("messages").
		Where("expires_at IS NULL OR expires_at > ?", now).
		Select("COUNT(DISTINCT LEAST(sender_id, receiver_id) || ':' || GREATEST(sender_id, receiver_id))").
		Scan(&overview.ActiveConversations).Error; err != nil {
		return AdminMessageOverview{}, err
	}

	messages, err := listRecentAdminMessages(db, 8, now)
	if err != nil {
		return AdminMessageOverview{}, err
	}
	conversations, err := listRecentAdminConversations(db, 8, now)
	if err != nil {
		return AdminMessageOverview{}, err
	}
	overview.RecentMessages = messages
	overview.RecentConversations = conversations
	return overview, nil
}

func listRecentAdminMessages(db *gorm.DB, limit int, now time.Time) ([]AdminMessageSummary, error) {
	type messageRow struct {
		ID           string
		SenderID     string
		SenderName   string
		ReceiverID   string
		ReceiverName string
		MessageType  string
		Content      string
		MediaName    string
		ReadAt       *time.Time
		ExpiresAt    *time.Time
		CreatedAt    time.Time
	}

	rows := make([]messageRow, 0, limit)
	if err := db.Table("messages AS m").
		Select(`
			m.id,
			m.sender_id,
			COALESCE(NULLIF(sender.display_name, ''), NULLIF(sender.username, ''), NULLIF(sender.domain, ''), m.sender_id) AS sender_name,
			m.receiver_id,
			COALESCE(NULLIF(receiver.display_name, ''), NULLIF(receiver.username, ''), NULLIF(receiver.domain, ''), m.receiver_id) AS receiver_name,
			m.message_type,
			m.content,
			m.media_name,
			m.read_at,
			m.expires_at,
			m.created_at
		`).
		Joins("LEFT JOIN users AS sender ON sender.id = m.sender_id").
		Joins("LEFT JOIN users AS receiver ON receiver.id = m.receiver_id").
		Where("m.expires_at IS NULL OR m.expires_at > ?", now).
		Order("m.created_at desc").
		Limit(limit).
		Scan(&rows).Error; err != nil {
		return nil, err
	}

	items := make([]AdminMessageSummary, 0, len(rows))
	for _, row := range rows {
		items = append(items, AdminMessageSummary{
			ID:           row.ID,
			SenderID:     row.SenderID,
			SenderName:   row.SenderName,
			ReceiverID:   row.ReceiverID,
			ReceiverName: row.ReceiverName,
			MessageType:  adminMessageType(row.MessageType),
			Preview:      adminMessagePreview(row.Content, row.MessageType, row.MediaName),
			ReadAt:       row.ReadAt,
			ExpiresAt:    row.ExpiresAt,
			CreatedAt:    row.CreatedAt,
		})
	}
	return items, nil
}

func listRecentAdminConversations(db *gorm.DB, limit int, now time.Time) ([]AdminConversationSummary, error) {
	type conversationRow struct {
		ParticipantAID   string
		ParticipantAName string
		ParticipantBID   string
		ParticipantBName string
		LastMessageType  string
		LastContent      string
		LastMediaName    string
		LastAt           time.Time
		MessageCount     int64
		UnreadCount      int64
	}

	rows := make([]conversationRow, 0, limit)
	if err := db.Raw(`
		WITH ranked_messages AS (
			SELECT
				LEAST(m.sender_id, m.receiver_id) AS participant_a_id,
				GREATEST(m.sender_id, m.receiver_id) AS participant_b_id,
				m.message_type,
				m.content,
				m.media_name,
				m.created_at,
				ROW_NUMBER() OVER (
					PARTITION BY LEAST(m.sender_id, m.receiver_id), GREATEST(m.sender_id, m.receiver_id)
					ORDER BY m.created_at DESC
				) AS row_num
			FROM messages AS m
			WHERE m.expires_at IS NULL OR m.expires_at > ?
		),
		conversation_stats AS (
			SELECT
				LEAST(m.sender_id, m.receiver_id) AS participant_a_id,
				GREATEST(m.sender_id, m.receiver_id) AS participant_b_id,
				COUNT(*) AS message_count,
				COUNT(*) FILTER (WHERE m.read_at IS NULL) AS unread_count,
				MAX(m.created_at) AS last_at
			FROM messages AS m
			WHERE m.expires_at IS NULL OR m.expires_at > ?
			GROUP BY LEAST(m.sender_id, m.receiver_id), GREATEST(m.sender_id, m.receiver_id)
		)
		SELECT
			stats.participant_a_id,
			COALESCE(NULLIF(user_a.display_name, ''), NULLIF(user_a.username, ''), NULLIF(user_a.domain, ''), stats.participant_a_id) AS participant_a_name,
			stats.participant_b_id,
			COALESCE(NULLIF(user_b.display_name, ''), NULLIF(user_b.username, ''), NULLIF(user_b.domain, ''), stats.participant_b_id) AS participant_b_name,
			ranked.message_type AS last_message_type,
			ranked.content AS last_content,
			ranked.media_name AS last_media_name,
			stats.last_at,
			stats.message_count,
			stats.unread_count
		FROM conversation_stats AS stats
		JOIN ranked_messages AS ranked
			ON ranked.participant_a_id = stats.participant_a_id
			AND ranked.participant_b_id = stats.participant_b_id
			AND ranked.row_num = 1
		LEFT JOIN users AS user_a ON user_a.id = stats.participant_a_id
		LEFT JOIN users AS user_b ON user_b.id = stats.participant_b_id
		ORDER BY stats.last_at DESC
		LIMIT ?
	`, now, now, limit).Scan(&rows).Error; err != nil {
		return nil, err
	}

	items := make([]AdminConversationSummary, 0, len(rows))
	for _, row := range rows {
		items = append(items, AdminConversationSummary{
			ParticipantAID:   row.ParticipantAID,
			ParticipantAName: row.ParticipantAName,
			ParticipantBID:   row.ParticipantBID,
			ParticipantBName: row.ParticipantBName,
			LastMessageType:  adminMessageType(row.LastMessageType),
			LastPreview:      adminMessagePreview(row.LastContent, row.LastMessageType, row.LastMediaName),
			LastAt:           row.LastAt,
			MessageCount:     row.MessageCount,
			UnreadCount:      row.UnreadCount,
		})
	}
	return items, nil
}

func adminMessageType(raw string) string {
	normalized := strings.ToLower(strings.TrimSpace(raw))
	if normalized == "" {
		return "text"
	}
	return normalized
}

func adminMessagePreview(content, messageType, mediaName string) string {
	if trimmed := strings.TrimSpace(content); trimmed != "" {
		return trimmed
	}
	label := adminMessageType(messageType)
	if strings.TrimSpace(mediaName) != "" {
		return fmt.Sprintf("[%s] %s", label, strings.TrimSpace(mediaName))
	}
	return fmt.Sprintf("[%s]", label)
}
