import SwiftUI

struct GameGridView: View {
  @ObservedObject var gameManager: GameManager
  
  private let cellSize: CGFloat = 50
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.white
        
        GridLines(
          width: gameManager.gridWidth,
          height: gameManager.gridHeight,
          spacing: cellSize
        )
        
        ForEach(gameManager.otherPlayers) { player in
          PlayerMarker(
            position: player.position,
            color: .red,
            label: String(player.id.prefix(5))
          )
        }
        
        if let currentPlayer = gameManager.currentPlayer {
          PlayerMarker(
            position: currentPlayer.position,
            color: .blue,
            label: "You"
          )
        }
      }
      .frame(width: gameManager.gridWidth, height: gameManager.gridHeight)
      .border(Color.black, width: 2)
      .contentShape(Rectangle())
      .onTapGesture { location in
        handleTap(at: location, in: geometry)
      }
    }
    .frame(width: gameManager.gridWidth, height: gameManager.gridHeight)
  }
  
  private func handleTap(at location: CGPoint, in geometry: GeometryProxy) {
    guard gameManager.isConnected else { return }
    
    let position = Position(x: location.x, y: location.y)
    gameManager.movePlayer(to: position)
  }
}

struct GridLines: View {
  let width: Double
  let height: Double
  let spacing: CGFloat
  
  var body: some View {
    ZStack {
      // Vertical lines
      ForEach(0..<Int(width / spacing) + 1, id: \.self) { i in
        Path { path in
          let x = CGFloat(i) * spacing
          path.move(to: CGPoint(x: x, y: 0))
          path.addLine(to: CGPoint(x: x, y: height))
        }
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
      }
      
      // Horizontal lines
      ForEach(0..<Int(height / spacing) + 1, id: \.self) { i in
        Path { path in
          let y = CGFloat(i) * spacing
          path.move(to: CGPoint(x: 0, y: y))
          path.addLine(to: CGPoint(x: width, y: y))
        }
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
      }
    }
  }
}

struct PlayerMarker: View {
  let position: Position
  let color: Color
  let label: String
  
  var body: some View {
    ZStack {
      Circle()
        .fill(color)
        .frame(width: 20, height: 20)
      
      Text(label)
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.black)
        .offset(y: 20)
    }
    .position(x: position.x, y: position.y)
  }
}

struct GameGridView_Previews: PreviewProvider {
  static var previews: some View {
    let manager = GameManager()
    return GameGridView(gameManager: manager)
      .previewLayout(.sizeThatFits)
  }
}
