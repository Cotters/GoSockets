struct PositionUpdateMessage: Encodable {
  let type: String = "positionUpdate"
  let position: Position
}
