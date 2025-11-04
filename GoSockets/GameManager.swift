import Foundation
import Combine

struct PlayerPosition: Codable {
  let x: Int
  let y: Int
}

class GameManager: ObservableObject {
  
  private var socketConnection: URLSessionWebSocketTask?
  private let decoder = JSONDecoder()
  
  @Published private(set) var position = PlayerPosition(x: 0, y: 0)
  
  
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
      print("Unexpected text message from ws: \(text)")
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
  
}
