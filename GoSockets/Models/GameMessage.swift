struct GameMessage: Codable {
  let type: GameMessageType
  let playerId: String?
  let position: Position?

  enum CodingKeys: String, CodingKey {
    case type, playerId, position
  }
}

enum GameMessageType: String, Codable {
  case welcome
  case playerJoined
  case playerLeft
  case positionUpdate
  case error
}
