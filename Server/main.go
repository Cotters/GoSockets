package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	// Create game room
	room := NewRoom()

	// Setup routes
	http.HandleFunc("/ws", HandleWebSocket(room))
	http.HandleFunc("/", serveHome)

	// Get port from environment or default to 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting WebSocket game server on :%s", port)
	log.Printf("Max players per room: %d", MaxPlayers)
	log.Printf("WebSocket endpoint: ws://localhost:%s/ws", port)
	log.Printf("Test client: http://localhost:%s", port)

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal("ListenAndServe error: ", err)
	}
}

// serveHome serves the test client HTML page
func serveHome(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(testClientHTML))
}
