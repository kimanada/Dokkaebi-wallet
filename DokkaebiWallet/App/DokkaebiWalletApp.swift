import SwiftUI

@main
struct DokkaebiWalletApp: App {
    @State private var container = AppContainer.live()

    init() {
        DWAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(container.session)
                .environment(container.router)
                .tint(DWColor.primary)
        }
    }
}
