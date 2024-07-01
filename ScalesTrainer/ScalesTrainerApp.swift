import SwiftUI
import AudioKit
import AVFoundation
import SwiftUI
import Foundation
@main

struct ScalesTrainerApp: App {
    @State private var selectedTab = Settings.shared.CalibrationExists() ? 0 : (Settings.shared.settingsExists() ? 3 : 2)
    
    init() {
        #if os(iOS)
            do {
//                Settings.bufferLength = .short
//                try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let err {
                print(err)
            }
        #endif
    }
    
    func runningInXcode() -> Bool {
        return ProcessInfo.processInfo.environment["RUNNING_FROM_XCODE"] != nil
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
//                if runningInXcode() {
////                    CoinBankView(scale: 20)
////                        .tabItem {
////                            Label("TEST", systemImage: "scribble")
////                        }
////                        .tag(0)
//                    ScalesIntervalsView()
//                        .tabItem {
//                            Label("TEST", systemImage: "scribble")
//                        }
//                        .tag(0)
//                }
               
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(1)
                
                //ScreenA()
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(2)
                
                CalibrationView()
                    .tabItem {
                        Label("Calibration", systemImage: "lines.measurement.vertical")
                    }
                    .tag(3)

                LogView()
                    .tabItem {
                        Label("Log", systemImage: "book.pages")
                    }
                    .tag(4)
                    
                //                SpriteKitAudioView()
                //                    .tabItem {
                //                        Label("Game", systemImage: "house")
                //                    }
                }
                //.border(Color.red)
                .onAppear() {
//                    if ScalesModel.shared.requiredStartAmplitude == nil {
//                        self.selectedTab = 2
//                    }
                }
        }
    }
}
