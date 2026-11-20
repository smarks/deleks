import SwiftUI

@main
struct deleksApp: App {
    @State private var model = GameModel(fixedSeed: GameModel.seedFromLaunchArguments())

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
