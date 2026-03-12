package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
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
		if in.To == "" || in.Content == "" {
			continue
		}
		// Persist message.
		// 持久化消息。
		msg := models.Message{SenderID: claims.UserID, ReceiverID: in.To, Content: in.Content, CreatedAt: time.Now()}
		if err := h.DB.Create(&msg).Error; err != nil {
			continue
		}

		// Push to receiver and echo to sender.
		// 推送给接收者并回显给发送者。
		out := outboundMessage{From: claims.UserID, To: in.To, Content: in.Content, CreatedAt: msg.CreatedAt}
		payload, _ := json.Marshal(out)
		h.Hub.SendTo(in.To, payload)
		client.Send(payload)
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
