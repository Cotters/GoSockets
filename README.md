# Go Game WebSocket Server

A simple WebSocket server for multiplayer games built with Go. Supports up to 10 concurrent players per room with real-time position synchronization.

## Features

- WebSocket-based real-time communication
- Room management with max 10 players
- Player position tracking (x, y coordinates)
- Automatic broadcasting of position updates to all players
- Thread-safe concurrent operations
- iOS and Web test client

## Requirements

- Go 1.16 or higher
- XCode

## Running the Server

```bash
go run .
```

The server will start on port 8080 by default. You can override this with the PORT environment variable:

```bash
PORT=3000 go run .
```

## Testing

Run mulitple instances of any client to test multiple connections and see multiple players' positions and movements.

### App

While the server is running, run the XCode project on an iPad. (Current UI mimics web client and doesn't fit on a phone.)


### Browser

While the server is running, open your browser and navigate to:
```
http://localhost:8080
```

## WebSocket API

### Connection

Connect to: `ws://localhost:8080/ws`

### Message Types

**Client to Server:**

```json
{
  "type": "positionUpdate",
  "position": {
    "x": 100.5,
    "y": 200.3
  }
}
```

**Server to Client:**

1. Welcome message (sent on connection):
```json
{
  "type": "welcome",
  "playerId": "abc123",
  "position": { "x": 0, "y": 0 }
}
```

2. Player joined:
```json
{
  "type": "playerJoined",
  "playerId": "xyz789",
  "position": { "x": 0, "y": 0 }
}
```

3. Position update:
```json
{
  "type": "positionUpdate",
  "playerId": "abc123",
  "position": { "x": 150.5, "y": 250.3 }
}
```

4. Player left:
```json
{
  "type": "playerLeft",
  "playerId": "abc123"
}
```

## Project Structure

- `main.go` - Server entry point and HTTP handlers
- `player.go` - Player and Position data structures
- `room.go` - Room management and player coordination
- `handler.go` - WebSocket connection handling
- `utils.go` - Utility functions
- `client.go` - Embedded HTML test client

## Architecture

- **Gorilla WebSocket**: Industry-standard WebSocket library
- **Mutex Locks**: Thread-safe operations for concurrent player management
- **Broadcast System**: Efficient message distribution to all connected players

## Performance

The server is designed for high performance:
- Go's lightweight goroutines handle each player connection
- Minimal memory footprint per player
- Efficient broadcasting with RWMutex for optimal read operations
