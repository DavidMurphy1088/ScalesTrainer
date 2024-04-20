
import SwiftUI

@main
struct ScalesTrainerApp: App {
    @State private var selectedTab = 0
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ScalesView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
                StaveView()
                    .tabItem {
                        Label("Notes", systemImage: "house")
                    }
                    .tag(1)
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(2)
                LogView()
                    .tabItem {
                        Label("Log", systemImage: "gear")
                    }
                    .tag(3)
            }
            .onAppear() {
                if ScalesModel.shared.requiredStartAmplitude == nil {
                    self.selectedTab = 2
                }
            }
        }
    }
}
