import Foundation
import Combine

enum GameResponseType: String, Codable {
  case welcome = "welcome"
}

struct GameResponse: Codable {
  let type: GameResponseType
  let playerId: String
  let position: PlayerPosition
}

struct PlayerPosition: Codable {
  let x: Int
  let y: Int
}

struct Player: Codable {
  let id: String
  let position: PlayerPosition
}

class GameManager: ObservableObject {
  
  private var socketConnection: URLSessionWebSocketTask?
  private let decoder = JSONDecoder()
  
  @Published private(set) var player: Player?
  
  func connect() {
    guard let url = URL(string: "ws://localhost:8080/ws") else {
      print("Unable to create game URL.")
      return
    }
    
    socketConnection = URLSession.shared.webSocketTask(with: url)
    socketConnection?.resume()
    
    Task {
      await setupListeners()
    }
  }
  
  private func setupListeners() async {
    guard let message = try? await socketConnection?.receive() else {
      print("Failed handling websocket message.")
      return
    }
    switch message {
    case .data(let data):
      handleWebsocketMessage(data)
    case .string(let text):
      handleWebsocketMessage(text)
    default:
      print("Unexpected websocket message type.")
      break
    }
  }
  
  private func handleWebsocketMessage(_ data: Data) {
    guard let decodedData = try? decoder.decode(PlayerPosition.self, from: data) else {
      print("Unable to decode data.")
      return
    }
    print("Found data: \(decodedData)")
  }
  
  private func handleWebsocketMessage(_ text: String) {
    print("Handling message: \(text)")
    let data = text.data(using: .utf8)
    guard let response = try? JSONDecoder().decode(GameResponse.self, from: data ?? Data()) else {
      print("Unable to decode data.")
      return
    }
    player = Player(id: response.playerId, position: response.position)
  }
}
