import Foundation
import Combine


let CONNECTION_ERROR_MESSAGE = "Unable to connect to the game server."
let SERVER_ERROR_MESSAGE = "Error from the game server."
let ENCODING_ERROR_MESSAGE = "Failed to encode message."
let DECODING_ERROR_MESSAGE = "Failed to decode message."

class GameManager: ObservableObject {

  private var socketConnection: URLSessionWebSocketTask?
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  @Published private(set) var currentPlayer: Player?
  @Published private(set) var otherPlayers: [Player] = []
  @Published private(set) var isConnected = false
  @Published private(set) var connectionError: String?

  let gridWidth: Double = 200
  let gridHeight: Double = 150

  func connect() {
    guard let url = URL(string: "ws://localhost:8080/ws") else {
      connectionError = CONNECTION_ERROR_MESSAGE
      return
    }

    socketConnection = URLSession.shared.webSocketTask(with: url)
    socketConnection?.resume()
    isConnected = true
    connectionError = nil

    Task {
      await listenForMessages()
    }
  }

  func disconnect() {
    socketConnection?.cancel(with: .goingAway, reason: nil)
    socketConnection = nil
    isConnected = false
    currentPlayer = nil
    otherPlayers = []
  }

  func movePlayer(to position: Position) {
    guard isConnected else { return }

    if currentPlayer != nil {
      currentPlayer?.position = position
    }

    let message = PositionUpdateMessage(position: position)

    guard let jsonData = try? encoder.encode(message),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
      print(ENCODING_ERROR_MESSAGE)
      return
    }

    socketConnection?.send(.string(jsonString)) { error in
      if let error = error {
        print("Error sending position update: \(error)")
      }
    }
  }

  func movePlayerBy(dx: Double, dy: Double) {
    guard let current = currentPlayer else { return }

    let newX = max(0, min(gridWidth, current.position.x + dx))
    let newY = max(0, min(gridHeight, current.position.y + dy))

    movePlayer(to: Position(x: newX, y: newY))
  }

  private func listenForMessages() async {
    while isConnected {
      guard let message = try? await socketConnection?.receive() else {
        print("Failed to receive websocket message.")
        DispatchQueue.main.async {
          self.isConnected = false
          self.connectionError = "Connection lost"
        }
        return
      }

      switch message {
      case .string(let text):
        handleWebsocketMessage(text)
      case .data(let data):
        if let text = String(data: data, encoding: .utf8) {
          handleWebsocketMessage(text)
        }
      @unknown default:
        print("Unexpected websocket message type.")
      }
    }
  }

  private func handleWebsocketMessage(_ text: String) {
    print("Received message: \(text)")

    guard let data = text.data(using: .utf8),
          let message = try? decoder.decode(GameMessage.self, from: data) else {
      print(DECODING_ERROR_MESSAGE)
      return
    }

    DispatchQueue.main.async {
      switch message.type {
      case .welcome:
        if let playerId = message.playerId, let position = message.position {
          self.currentPlayer = Player(id: playerId, position: position)
        }

      case .playerJoined:
        if let playerId = message.playerId,
           let position = message.position,
           playerId != self.currentPlayer?.id {
          let newPlayer = Player(id: playerId, position: position)
          if !self.otherPlayers.contains(where: { $0.id == playerId }) {
            self.otherPlayers.append(newPlayer)
          }
        }

      case .playerLeft:
        if let playerId = message.playerId {
          self.otherPlayers.removeAll { $0.id == playerId }
        }

      case .positionUpdate:
        if let playerId = message.playerId, let position = message.position {
          if playerId != self.currentPlayer?.id {
            if let index = self.otherPlayers.firstIndex(where: { $0.id == playerId }) {
              self.otherPlayers[index].position = position
            }
          }
        }

      case .error:
        self.connectionError = SERVER_ERROR_MESSAGE
      }
    }
  }
}
