package main

import (
	"sync"

	"github.com/gorilla/websocket"
)

// Position represents a player's position on the map
type Position struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

// Player represents a connected player
type Player struct {
	ID       string          `json:"id"`
	Position Position        `json:"position"`
	Conn     *websocket.Conn `json:"-"`
	mu       sync.Mutex
}

// UpdatePosition updates the player's position
func (p *Player) UpdatePosition(x, y float64) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.Position.X = x
	p.Position.Y = y
}

// GetPosition returns the player's current position
func (p *Player) GetPosition() Position {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.Position
}

// Message represents WebSocket messages
type Message struct {
	Type     string   `json:"type"`
	PlayerID string   `json:"playerId,omitempty"`
	Position Position `json:"position,omitempty"`
}
