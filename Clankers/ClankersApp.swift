import SwiftUI

@main
struct ClankersApp: App {
    @State private var model = GameModel(fixedSeed: GameModel.seedFromLaunchArguments())

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
