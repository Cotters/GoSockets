struct Player: Identifiable, Equatable {
  let id: String
  var position: Position

  static func == (lhs: Player, rhs: Player) -> Bool {
    lhs.id == rhs.id
  }
}
