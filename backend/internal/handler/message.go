package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"gorm.io/gorm"

	"account-service/internal/auth"
	"account-service/internal/models"
	"account-service/internal/service"
	"account-service/internal/ws"
)

const defaultMediaTTL = 7 * 24 * time.Hour

type MessageHandler struct {
	DB        *gorm.DB
	JWTSecret string
	Hub       *ws.Hub
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type conversationSummary struct {
	PeerID             string    `json:"peer_id"`
	LastMessage        string    `json:"last_message"`
	LastMessageType    string    `json:"last_message_type"`
	LastMessagePreview string    `json:"last_message_preview"`
	LastAt             time.Time `json:"last_at"`
	UnreadCount        int64     `json:"unread_count"`
}

type createMessageRequest struct {
	PeerID           string `json:"peer_id"`
	Content          string `json:"content"`
	MessageType      string `json:"message_type"`
	MediaName        string `json:"media_name"`
	MediaMime        string `json:"media_mime"`
	MediaData        string `json:"media_data"`
	ExpiresInMinutes int    `json:"expires_in_minutes"`
}

type inboundMessage struct {
	To               string `json:"to"`
	PeerID           string `json:"peer_id"`
	Content          string `json:"content"`
	MessageType      string `json:"message_type"`
	MediaName        string `json:"media_name"`
	MediaMime        string `json:"media_mime"`
	MediaData        string `json:"media_data"`
	ExpiresInMinutes int    `json:"expires_in_minutes"`
}

type outboundMessage struct {
	ID          string     `json:"id"`
	From        string     `json:"from"`
	To          string     `json:"to"`
	MessageType string     `json:"message_type"`
	Content     string     `json:"content"`
	MediaName   string     `json:"media_name"`
	MediaMime   string     `json:"media_mime"`
	MediaData   string     `json:"media_data"`
	CreatedAt   time.Time  `json:"created_at"`
	ReadAt      *time.Time `json:"read_at,omitempty"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
}

func (h *MessageHandler) ListConversations(c *gin.Context) {
	// List conversation summaries for the current user.
	// 列出当前用户的会话摘要。
	uid := c.GetString("user_id")
	_ = h.cleanupExpiredMessages()
	var messages []models.Message
	if err := h.DB.
		Where("(sender_id = ? OR receiver_id = ?) AND (expires_at IS NULL OR expires_at > ?)", uid, uid, time.Now()).
		Order("created_at desc").
		Find(&messages).Error; err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}

	summaries := make([]conversationSummary, 0)
	seen := make(map[string]int)
	for _, msg := range messages {
		peerID := msg.SenderID
		if msg.SenderID == uid {
			peerID = msg.ReceiverID
		}
		if idx, ok := seen[peerID]; ok {
			if msg.ReceiverID == uid && msg.ReadAt == nil {
				summaries[idx].UnreadCount++
			}
			continue
		}

		preview := conversationPreview(msg)
		item := conversationSummary{
			PeerID:             peerID,
			LastMessage:        preview,
			LastMessageType:    messageTypeForResponse(msg.MessageType),
			LastMessagePreview: preview,
			LastAt:             msg.CreatedAt,
			UnreadCount:        0,
		}
		if msg.ReceiverID == uid && msg.ReadAt == nil {
			item.UnreadCount = 1
		}
		seen[peerID] = len(summaries)
		summaries = append(summaries, item)
	}
	respondOK(c, gin.H{"items": summaries})
}

func (h *MessageHandler) ListMessages(c *gin.Context) {
	// List messages for current user.
	// 列出当前用户的消息。
	uid := c.GetString("user_id")
	peerID := c.Query("peer_id")
	_ = h.cleanupExpiredMessages()
	limit := parseInt(c.Query("limit"), 50)
	offset := parseInt(c.Query("offset"), 0)
	if limit < 1 {
		limit = 1
	}
	if limit > 200 {
		limit = 200
	}
	if offset < 0 {
		offset = 0
	}

	var messages []models.Message
	if peerID != "" {
		// Mark messages from this peer as read when opening the conversation.
		// 打开会话时将来自该好友的消息标记为已读。
		now := time.Now()
		_ = h.DB.Model(&models.Message{}).
			Where("sender_id = ? AND receiver_id = ? AND read_at IS NULL AND (expires_at IS NULL OR expires_at > ?)", peerID, uid, now).
			Update("read_at", &now).Error
	}
	query := h.DB.Where("(sender_id = ? OR receiver_id = ?) AND (expires_at IS NULL OR expires_at > ?)", uid, uid, time.Now())
	if peerID != "" {
		query = h.DB.Where(
			"((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)) AND (expires_at IS NULL OR expires_at > ?)",
			uid,
			peerID,
			peerID,
			uid,
			time.Now(),
		)
	}
	if err := query.Order("created_at asc").Limit(limit).Offset(offset).Find(&messages).Error; err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, gin.H{"items": messages})
}

func (h *MessageHandler) UnreadCount(c *gin.Context) {
	// Count unread messages for current user.
	// 统计当前用户未读消息数量。
	uid := c.GetString("user_id")
	_ = h.cleanupExpiredMessages()
	var count int64
	if err := h.DB.Model(&models.Message{}).Where("receiver_id = ? AND read_at IS NULL AND (expires_at IS NULL OR expires_at > ?)", uid, time.Now()).Count(&count).Error; err != nil {
		respondError(c, http.StatusInternalServerError, "db error")
		return
	}
	respondOK(c, gin.H{"unread": count})
}

func (h *MessageHandler) AdminOverview(c *gin.Context) {
	// Return the administrator-only message-service overview payload.
	// 返回仅管理员可见的消息服务总览载荷。
	overview, err := service.BuildAdminMessageOverview(h.DB)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "message admin overview error")
		return
	}
	respondOK(c, overview)
}

func (h *MessageHandler) CreateMessage(c *gin.Context) {
	// Create a message with REST to keep conversation refresh consistent.
	// 通过 REST 创建消息，保证会话刷新链路一致。
	uid := c.GetString("user_id")
	var req createMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, "invalid request")
		return
	}

	msg, err := h.persistMessage(uid, req)
	if err != nil {
		status := http.StatusBadRequest
		if !errors.Is(err, gorm.ErrInvalidData) &&
			err.Error() != "peer id required" &&
			err.Error() != "content required" &&
			err.Error() != "media data required" &&
			err.Error() != "cannot send to yourself" {
			status = http.StatusInternalServerError
		}
		respondError(c, status, err.Error())
		return
	}

	h.pushMessage(msg, false)
	respondCreated(c, gin.H{"item": msg})
}

func (h *MessageHandler) WS(c *gin.Context) {
	// WebSocket endpoint for realtime chat.
	// 实时聊天的 WebSocket 入口。
	tokenStr := c.Query("token")
	if tokenStr == "" {
		tokenStr = c.GetHeader("Authorization")
	}

	claims, err := auth.ParseToken(extractBearer(tokenStr), h.JWTSecret)
	if err != nil {
		respondError(c, http.StatusUnauthorized, "invalid token")
		return
	}
	user, err := service.GetUser(h.DB, claims.UserID)
	if err != nil {
		respondError(c, http.StatusUnauthorized, "invalid token")
		return
	}
	if !service.IsAccountActive(user.Status) {
		respondError(c, http.StatusForbidden, "account inactive")
		return
	}
	// Reject stale WebSocket tokens after a password update.
	// 密码更新后拒绝旧版 WebSocket token。
	if claims.PasswordVersion != user.PasswordVersion {
		respondError(c, http.StatusUnauthorized, "invalid token")
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}
	client := &ws.Client{UserID: user.ID, Conn: conn}
	h.Hub.Register(client)
	defer func() {
		h.Hub.Unregister(user.ID)
		_ = conn.Close()
	}()

	for {
		// Read inbound message.
		// 读取客户端消息。
		_, data, err := conn.ReadMessage()
		if err != nil {
			return
		}
		var in inboundMessage
		if err := json.Unmarshal(data, &in); err != nil {
			continue
		}
		msg, err := h.persistMessage(claims.UserID, createMessageRequest{
			PeerID:           firstNonEmpty(in.PeerID, in.To),
			Content:          in.Content,
			MessageType:      in.MessageType,
			MediaName:        in.MediaName,
			MediaMime:        in.MediaMime,
			MediaData:        in.MediaData,
			ExpiresInMinutes: in.ExpiresInMinutes,
		})
		if err != nil {
			continue
		}
		h.pushMessage(msg, true)
	}
}

func (h *MessageHandler) persistMessage(senderID string, req createMessageRequest) (models.Message, error) {
	// Validate and persist a single chat message.
	// 校验并持久化单条聊天消息。
	receiverID := strings.TrimSpace(req.PeerID)
	messageType := normalizeMessageType(req.MessageType, req.MediaMime, req.MediaName)
	content := strings.TrimSpace(req.Content)
	mediaName := strings.TrimSpace(req.MediaName)
	mediaMime := strings.TrimSpace(req.MediaMime)
	mediaData := strings.TrimSpace(req.MediaData)

	if receiverID == "" {
		return models.Message{}, errors.New("peer id required")
	}
	if senderID == receiverID {
		return models.Message{}, errors.New("cannot send to yourself")
	}
	if messageType == "text" {
		if content == "" {
			return models.Message{}, errors.New("content required")
		}
	} else if mediaData == "" {
		return models.Message{}, errors.New("media data required")
	}

	var expiresAt *time.Time
	if messageType != "text" {
		ttl := defaultMediaTTL
		if req.ExpiresInMinutes > 0 {
			ttl = time.Duration(req.ExpiresInMinutes) * time.Minute
		}
		expiry := time.Now().Add(ttl)
		expiresAt = &expiry
	}

	msg := models.Message{
		SenderID:    senderID,
		ReceiverID:  receiverID,
		MessageType: messageType,
		Content:     content,
		MediaName:   mediaName,
		MediaMime:   mediaMime,
		MediaData:   mediaData,
		CreatedAt:   time.Now(),
		ExpiresAt:   expiresAt,
	}
	if err := h.DB.Create(&msg).Error; err != nil {
		return models.Message{}, err
	}
	return msg, nil
}

func (h *MessageHandler) pushMessage(msg models.Message, echoSender bool) {
	// Push a chat message to online users.
	// 将聊天消息推送给在线用户。
	out := outboundMessage{
		ID:          msg.ID,
		From:        msg.SenderID,
		To:          msg.ReceiverID,
		MessageType: msg.MessageType,
		Content:     msg.Content,
		MediaName:   msg.MediaName,
		MediaMime:   msg.MediaMime,
		MediaData:   msg.MediaData,
		CreatedAt:   msg.CreatedAt,
		ReadAt:      msg.ReadAt,
		ExpiresAt:   msg.ExpiresAt,
	}
	payload, _ := json.Marshal(out)
	h.Hub.SendTo(msg.ReceiverID, payload)
	if echoSender {
		h.Hub.SendTo(msg.SenderID, payload)
	}
}

func (h *MessageHandler) cleanupExpiredMessages() error {
	// Remove expired chat messages in the background / request path.
	// 在后台或请求路径中清理已过期聊天消息。
	return h.DB.Where("expires_at IS NOT NULL AND expires_at <= ?", time.Now()).Delete(&models.Message{}).Error
}

func (h *MessageHandler) CleanupExpiredMessages() error {
	// Exported cleanup hook for the message service entrypoint.
	// 面向消息服务入口导出的清理钩子。
	return h.cleanupExpiredMessages()
}

func normalizeMessageType(rawType, mediaMime, mediaName string) string {
	// Infer message type from explicit type or media metadata.
	// 依据显式类型或媒体元数据推断消息类型。
	normalized := strings.ToLower(strings.TrimSpace(rawType))
	switch normalized {
	case "text", "image", "video", "audio":
		return normalized
	}

	mime := strings.ToLower(strings.TrimSpace(mediaMime))
	switch {
	case strings.HasPrefix(mime, "image/"):
		return "image"
	case strings.HasPrefix(mime, "video/"):
		return "video"
	case strings.HasPrefix(mime, "audio/"):
		return "audio"
	}

	name := strings.ToLower(strings.TrimSpace(mediaName))
	switch ext := filepath.Ext(name); ext {
	case ".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp":
		return "image"
	case ".mp4", ".mov", ".m4v", ".webm", ".mkv":
		return "video"
	case ".mp3", ".wav", ".ogg", ".m4a", ".aac":
		return "audio"
	}

	return "text"
}

func messageTypeForResponse(messageType string) string {
	// Normalize response message type.
	// 规范化响应中的消息类型。
	normalized := strings.ToLower(strings.TrimSpace(messageType))
	if normalized == "" {
		return "text"
	}
	return normalized
}

func conversationPreview(msg models.Message) string {
	// Build a compact preview for conversation cards.
	// 为会话卡片生成紧凑预览文案。
	if content := strings.TrimSpace(msg.Content); content != "" {
		return content
	}
	label := messageTypeForResponse(msg.MessageType)
	if msg.MediaName != "" {
		return fmt.Sprintf("[%s] %s", label, msg.MediaName)
	}
	return fmt.Sprintf("[%s]", label)
}

func firstNonEmpty(values ...string) string {
	// Return the first non-empty string.
	// 返回第一个非空字符串。
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func extractBearer(raw string) string {
	// Extract token from Authorization header.
	// 从 Authorization 头提取 token。
	if raw == "" {
		return ""
	}
	if len(raw) > 7 && raw[:7] == "Bearer " {
		return raw[7:]
	}
	return raw
}

func parseInt(raw string, fallback int) int {
	// Parse int with fallback.
	// 解析整数并提供默认值。
	if raw == "" {
		return fallback
	}
	val, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return val
}
