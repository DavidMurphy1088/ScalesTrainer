
import SwiftUI

@main
struct ScalesTrainerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ScalesView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            StaveView()
                .tabItem {
                    Label("Notes", systemImage: "house")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}



struct SettingsView: View {
    var body: some View {
        Text("Settings Screen")
            .padding()
    }
}
