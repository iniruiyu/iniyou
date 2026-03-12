package ws

import (
	"sync"
)

type Hub struct {
	mu      sync.RWMutex
	clients map[string]*Client
}

func NewHub() *Hub {
	// Create a new hub.
	// 创建新的消息中心。
	return &Hub{clients: make(map[string]*Client)}
}

func (h *Hub) Register(client *Client) {
	// Register a client connection.
	// 注册客户端连接。
	h.mu.Lock()
	defer h.mu.Unlock()
	h.clients[client.UserID] = client
}

func (h *Hub) Unregister(userID string) {
	// Remove a client by user ID.
	// 按用户 ID 移除客户端。
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(h.clients, userID)
}

func (h *Hub) SendTo(userID string, payload []byte) bool {
	// Send payload to a user.
	// 向用户发送消息。
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()
	if !ok {
		return false
	}
	client.Send(payload)
	return true
}
