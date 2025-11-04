package main

import (
	"errors"
	"log"
	"sync"
)

const MaxPlayers = 10

var (
	ErrRoomFull      = errors.New("room is full")
	ErrPlayerNotFound = errors.New("player not found")
)

// Room manages a game room with multiple players
type Room struct {
	Players map[string]*Player
	mu      sync.RWMutex
}

// NewRoom creates a new game room
func NewRoom() *Room {
	return &Room{
		Players: make(map[string]*Player),
	}
}

// AddPlayer adds a player to the room
func (r *Room) AddPlayer(player *Player) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if len(r.Players) >= MaxPlayers {
		return ErrRoomFull
	}

	r.Players[player.ID] = player
	log.Printf("Player %s joined. Current players: %d/%d", player.ID, len(r.Players), MaxPlayers)
	return nil
}

// RemovePlayer removes a player from the room
func (r *Room) RemovePlayer(playerID string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.Players[playerID]; exists {
		delete(r.Players, playerID)
		log.Printf("Player %s left. Current players: %d/%d", playerID, len(r.Players), MaxPlayers)
	}
}

// GetPlayer retrieves a player by ID
func (r *Room) GetPlayer(playerID string) (*Player, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	player, exists := r.Players[playerID]
	if !exists {
		return nil, ErrPlayerNotFound
	}
	return player, nil
}

// GetAllPlayers returns all players in the room
func (r *Room) GetAllPlayers() []*Player {
	r.mu.RLock()
	defer r.mu.RUnlock()

	players := make([]*Player, 0, len(r.Players))
	for _, player := range r.Players {
		players = append(players, player)
	}
	return players
}

// BroadcastPositionUpdate sends position update to all players
func (r *Room) BroadcastPositionUpdate(playerID string, position Position) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	msg := Message{
		Type:     "positionUpdate",
		PlayerID: playerID,
		Position: position,
	}

	for _, player := range r.Players {
		if err := player.Conn.WriteJSON(msg); err != nil {
			log.Printf("Error broadcasting to player %s: %v", player.ID, err)
		}
	}
}

// BroadcastPlayerJoined notifies all players of a new player
func (r *Room) BroadcastPlayerJoined(newPlayer *Player) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	msg := Message{
		Type:     "playerJoined",
		PlayerID: newPlayer.ID,
		Position: newPlayer.Position,
	}

	for _, player := range r.Players {
		if err := player.Conn.WriteJSON(msg); err != nil {
			log.Printf("Error broadcasting player joined to %s: %v", player.ID, err)
		}
	}
}

// BroadcastPlayerLeft notifies all players of a player leaving
func (r *Room) BroadcastPlayerLeft(playerID string) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	msg := Message{
		Type:     "playerLeft",
		PlayerID: playerID,
	}

	for _, player := range r.Players {
		if err := player.Conn.WriteJSON(msg); err != nil {
			log.Printf("Error broadcasting player left to %s: %v", player.ID, err)
		}
	}
}

// GetPlayerCount returns the current number of players
func (r *Room) GetPlayerCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.Players)
}
