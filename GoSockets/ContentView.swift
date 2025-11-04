import SwiftUI

struct ContentView: View {
  
  @State private var gameManager = GameManager()
  
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
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
