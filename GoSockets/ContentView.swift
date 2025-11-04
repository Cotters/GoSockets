import SwiftUI

struct ContentView: View {
  
  @ObservedObject private var gameManager = GameManager()
  
  var body: some View {
    VStack {
      if let player = gameManager.player {
        Image(systemName: "globe")
          .imageScale(.large)
          .foregroundStyle(.tint)
        Text("Hello, \(player.id)!")
      } else {
        ProgressView()
      }
    }
    .onAppear {
      gameManager.connect()
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
