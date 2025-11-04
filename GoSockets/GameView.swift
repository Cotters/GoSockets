import SwiftUI

struct GameView: View {
  @StateObject private var gameManager = GameManager()
  
  var body: some View {
    HStack(spacing: 20) {
      VStack(alignment: .leading, spacing: 20) {
        Text("Game Controls")
          .font(.title)
          .fontWeight(.bold)
        
        HStack {
          Circle()
            .fill(gameManager.isConnected ? Color.green : Color.red)
            .frame(width: 12, height: 12)
          Text(gameManager.isConnected ? "Connected" : "Disconnected")
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gameManager.isConnected ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
        
        HStack(spacing: 10) {
          Button(action: {
            gameManager.connect()
          }) {
            Text("Connect")
              .frame(maxWidth: .infinity)
              .padding()
              .background(gameManager.isConnected ? Color.gray : Color.blue)
              .foregroundColor(.white)
              .cornerRadius(8)
          }
          .disabled(gameManager.isConnected)
          
          Button(action: {
            gameManager.disconnect()
          }) {
            Text("Disconnect")
              .frame(maxWidth: .infinity)
              .padding()
              .background(gameManager.isConnected ? Color.red : Color.gray)
              .foregroundColor(.white)
              .cornerRadius(8)
          }
          .disabled(!gameManager.isConnected)
        }
        
        if let error = gameManager.connectionError {
          Text(error)
            .font(.caption)
            .foregroundColor(.red)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
        }
        
        Divider()
        
        Text("Movement")
          .font(.headline)
        
        Text("Click on the grid to move, or use the buttons below:")
          .font(.caption)
          .foregroundColor(.gray)
        
        VStack(spacing: 10) {
          Button(action: {
            gameManager.movePlayerBy(dx: 0, dy: -50)
          }) {
            Image(systemName: "arrow.up.circle.fill")
              .font(.system(size: 40))
          }
          .disabled(!gameManager.isConnected)
          
          HStack(spacing: 40) {
            Button(action: {
              gameManager.movePlayerBy(dx: -50, dy: 0)
            }) {
              Image(systemName: "arrow.left.circle.fill")
                .font(.system(size: 40))
            }
            .disabled(!gameManager.isConnected)
            
            Button(action: {
              gameManager.movePlayerBy(dx: 50, dy: 0)
            }) {
              Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 40))
            }
            .disabled(!gameManager.isConnected)
          }
          
          Button(action: {
            gameManager.movePlayerBy(dx: 0, dy: 50)
          }) {
            Image(systemName: "arrow.down.circle.fill")
              .font(.system(size: 40))
          }
          .disabled(!gameManager.isConnected)
        }
        .frame(maxWidth: .infinity)
        
        Divider()
        
        Text("Players (\(totalPlayerCount)/10)")
          .font(.headline)
        
        ScrollView {
          VStack(alignment: .leading, spacing: 8) {
            if let player = gameManager.currentPlayer {
              PlayerInfoRow(
                player: player,
                isCurrentPlayer: true
              )
            }
            
            ForEach(gameManager.otherPlayers) { player in
              PlayerInfoRow(
                player: player,
                isCurrentPlayer: false
              )
            }
          }
        }
        
        Spacer()
      }
      .frame(width: 300)
      .padding()
      .background(Color(.systemBackground))
      
      VStack {
        Text("Game Map (800x600)")
          .font(.title2)
          .fontWeight(.semibold)
          .padding(.bottom, 10)
        
        Text("Click anywhere on the grid to move your player")
          .font(.caption)
          .foregroundColor(.gray)
          .padding(.bottom, 5)
        
        GameGridView(gameManager: gameManager)
          .background(Color.white)
          .cornerRadius(8)
          .shadow(radius: 5)
      }
      .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGray6))
  }
  
  private var totalPlayerCount: Int {
    let current = gameManager.currentPlayer != nil ? 1 : 0
    return current + gameManager.otherPlayers.count
  }
}

struct PlayerInfoRow: View {
  let player: Player
  let isCurrentPlayer: Bool
  
  var body: some View {
    HStack {
      Circle()
        .fill(isCurrentPlayer ? Color.blue : Color.red)
        .frame(width: 10, height: 10)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(isCurrentPlayer ? "You" : String(player.id.prefix(10)))
          .font(.subheadline)
          .fontWeight(isCurrentPlayer ? .bold : .regular)
        
        Text("(\(Int(player.position.x)), \(Int(player.position.y)))")
          .font(.caption)
          .foregroundColor(.gray)
      }
      
      Spacer()
    }
    .padding(8)
    .background(isCurrentPlayer ? Color.blue.opacity(0.1) : Color(.systemGray6))
    .cornerRadius(6)
  }
}

struct GameView_Previews: PreviewProvider {
  static var previews: some View {
    GameView()
  }
}
