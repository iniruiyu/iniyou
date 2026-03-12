package ws

import (
	"log"

	"github.com/gorilla/websocket"
)

type Client struct {
	UserID string
	Conn   *websocket.Conn
}

func (c *Client) Send(payload []byte) {
	// Write a text message to the socket.
	// 向连接写入文本消息。
	if err := c.Conn.WriteMessage(websocket.TextMessage, payload); err != nil {
		log.Printf("ws send error: %v", err)
	}
}
