import SwiftUI

@main
struct VitlApp: App {
    @StateObject private var preferences = UserPreferences()
    @StateObject private var subscription = StoreKitManager()
    @StateObject private var healthKit = HealthKitManager()
    @StateObject private var appState = AppStateStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(preferences)
                .environmentObject(subscription)
                .environmentObject(healthKit)
                .environmentObject(appState)
                .task { appState.attachSyncManager() }
        }
    }
}
