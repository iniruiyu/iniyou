package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"gorm.io/gorm"

	"account-service/internal/auth"
	"account-service/internal/models"
	"account-service/internal/ws"
)

type MessageHandler struct {
	DB        *gorm.DB
	JWTSecret string
	Hub       *ws.Hub
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type inboundMessage struct {
	To      string `json:"to"`
	Content string `json:"content"`
}

type outboundMessage struct {
	From      string    `json:"from"`
	To        string    `json:"to"`
	Content   string    `json:"content"`
	CreatedAt time.Time `json:"created_at"`
}

type conversationSummary struct {
	PeerID      string    `json:"peer_id"`
	LastMessage string    `json:"last_message"`
	LastAt      time.Time `json:"last_at"`
	UnreadCount int64     `json:"unread_count"`
}

type createMessageRequest struct {
	PeerID  string `json:"peer_id"`
	Content string `json:"content"`
}

func (h *MessageHandler) ListConversations(c *gin.Context) {
	// List conversation summaries for the current user.
	// 列出当前用户的会话摘要。
	uid := c.GetString("user_id")
	var messages []models.Message
	if err := h.DB.
		Where("sender_id = ? OR receiver_id = ?", uid, uid).
		Order("created_at desc").
		Find(&messages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
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

		item := conversationSummary{
			PeerID:      peerID,
			LastMessage: msg.Content,
			LastAt:      msg.CreatedAt,
			UnreadCount: 0,
		}
		if msg.ReceiverID == uid && msg.ReadAt == nil {
			item.UnreadCount = 1
		}
		seen[peerID] = len(summaries)
		summaries = append(summaries, item)
	}
	c.JSON(http.StatusOK, gin.H{"items": summaries})
}

func (h *MessageHandler) ListMessages(c *gin.Context) {
	// List messages for current user.
	// 列出当前用户的消息。
	uid := c.GetString("user_id")
	peerID := c.Query("peer_id")
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
	query := h.DB.Where("sender_id = ? OR receiver_id = ?", uid, uid)
	if peerID != "" {
		query = h.DB.Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)", uid, peerID, peerID, uid)
	}
	if err := query.Order("created_at asc").Limit(limit).Offset(offset).Find(&messages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	if peerID != "" {
		// Mark messages from this peer as read when opening the conversation.
		// 打开会话时将来自该好友的消息标记为已读。
		now := time.Now()
		_ = h.DB.Model(&models.Message{}).
			Where("sender_id = ? AND receiver_id = ? AND read_at IS NULL", peerID, uid).
			Update("read_at", &now).Error
	}
	c.JSON(http.StatusOK, gin.H{"items": messages})
}

func (h *MessageHandler) UnreadCount(c *gin.Context) {
	// Count unread messages for current user.
	// 统计当前用户未读消息数量。
	uid := c.GetString("user_id")
	var count int64
	if err := h.DB.Model(&models.Message{}).Where("receiver_id = ? AND read_at IS NULL", uid).Count(&count).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"unread": count})
}

func (h *MessageHandler) CreateMessage(c *gin.Context) {
	// Create a message with REST to keep conversation refresh consistent.
	// 通过 REST 创建消息，保证会话刷新链路一致。
	uid := c.GetString("user_id")
	var req createMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	msg, err := h.persistMessage(uid, req.PeerID, req.Content)
	if err != nil {
		status := http.StatusBadRequest
		if !errors.Is(err, gorm.ErrInvalidData) &&
			err.Error() != "peer id required" &&
			err.Error() != "content required" &&
			err.Error() != "cannot send to yourself" {
			status = http.StatusInternalServerError
		}
		c.JSON(status, gin.H{"error": err.Error()})
		return
	}

	h.pushMessage(msg, false)
	c.JSON(http.StatusCreated, gin.H{"item": msg})
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
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}
	client := &ws.Client{UserID: claims.UserID, Conn: conn}
	h.Hub.Register(client)
	defer func() {
		h.Hub.Unregister(claims.UserID)
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
		msg, err := h.persistMessage(claims.UserID, in.To, in.Content)
		if err != nil {
			continue
		}
		h.pushMessage(msg, true)
	}
}

func (h *MessageHandler) persistMessage(senderID string, receiverID string, content string) (models.Message, error) {
	// Validate and persist a single chat message.
	// 校验并持久化单条聊天消息。
	receiverID = strings.TrimSpace(receiverID)
	content = strings.TrimSpace(content)
	if receiverID == "" {
		return models.Message{}, errors.New("peer id required")
	}
	if content == "" {
		return models.Message{}, errors.New("content required")
	}
	if senderID == receiverID {
		return models.Message{}, errors.New("cannot send to yourself")
	}

	msg := models.Message{
		SenderID:   senderID,
		ReceiverID: receiverID,
		Content:    content,
		CreatedAt:  time.Now(),
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
		From:      msg.SenderID,
		To:        msg.ReceiverID,
		Content:   msg.Content,
		CreatedAt: msg.CreatedAt,
	}
	payload, _ := json.Marshal(out)
	h.Hub.SendTo(msg.ReceiverID, payload)
	if echoSender {
		h.Hub.SendTo(msg.SenderID, payload)
	}
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
