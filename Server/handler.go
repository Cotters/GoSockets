package main

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for development
	},
}

// HandleWebSocket handles WebSocket connections
func HandleWebSocket(room *Room) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Check if room is full before upgrading connection
		if room.GetPlayerCount() >= MaxPlayers {
			log.Println("Room is full, rejecting connection")
			http.Error(w, "Room is full", http.StatusServiceUnavailable)
			return
		}

		// Upgrade HTTP connection to WebSocket
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Printf("Failed to upgrade connection: %v", err)
			return
		}

		// Create new player
		player := &Player{
			ID:   generatePlayerID(),
			Conn: conn,
			Position: Position{
				X: 0,
				Y: 0,
			},
		}

		// Add player to room
		if err := room.AddPlayer(player); err != nil {
			log.Printf("Failed to add player: %v", err)
			conn.WriteJSON(Message{Type: "error", PlayerID: "Room is full"})
			conn.Close()
			return
		}

		// Send welcome message with player ID
		welcomeMsg := Message{
			Type:     "welcome",
			PlayerID: player.ID,
			Position: player.Position,
		}
		if err := conn.WriteJSON(welcomeMsg); err != nil {
			log.Printf("Failed to send welcome message: %v", err)
			room.RemovePlayer(player.ID)
			conn.Close()
			return
		}

		// Send current players to new player
		for _, p := range room.GetAllPlayers() {
			if p.ID != player.ID {
				msg := Message{
					Type:     "playerJoined",
					PlayerID: p.ID,
					Position: p.GetPosition(),
				}
				conn.WriteJSON(msg)
			}
		}

		// Notify other players of new player
		room.BroadcastPlayerJoined(player)

		// Start handling player messages
		go handlePlayerMessages(player, room)
	}
}

// handlePlayerMessages reads messages from player connection
func handlePlayerMessages(player *Player, room *Room) {
	defer func() {
		room.RemovePlayer(player.ID)
		room.BroadcastPlayerLeft(player.ID)
		player.Conn.Close()
		log.Printf("Player %s disconnected", player.ID)
	}()

	for {
		var msg Message
		err := player.Conn.ReadJSON(&msg)
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error for player %s: %v", player.ID, err)
			}
			break
		}

		// Handle position updates
		if msg.Type == "positionUpdate" {
			player.UpdatePosition(msg.Position.X, msg.Position.Y)
			room.BroadcastPositionUpdate(player.ID, msg.Position)
			log.Printf("Player %s moved to (%.2f, %.2f)", player.ID, msg.Position.X, msg.Position.Y)
		}
	}
}
