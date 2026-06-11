import SwiftUI

@main
struct VitlWatchApp: App {
    @StateObject private var preferences = UserPreferences()
    @StateObject private var appState = AppStateStore()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(preferences)
                .environmentObject(appState)
                .task { appState.attachSyncManager() }
        }
    }
}
