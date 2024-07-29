import SwiftUI
import AudioKit
import AVFoundation
import SwiftUI
import Foundation

class TabSelectionManager: ObservableObject {
    @Published var selectedTab: Int = 0
    init() {
        nextNavigationTab()
    }
    
    func nextNavigationTab() {
        if Settings.shared.settingsExists() {
            if Settings.shared.calibrationIsSet() {
                if ScalesTrainerApp.runningInXcode() {
                    ScalesModel.shared.setScale(scale: Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .arpeggioDiminishedSeventh, octaves: 2, hand: 0))
                    selectedTab = 0
                }
                else {
                    selectedTab = 1
                }
            }
            else{
                selectedTab = 3
            }
        }
        else {
            selectedTab = 2
        }
    }
}

@main
struct ScalesTrainerApp: App {
    @StateObject private var tabSelectionManager = TabSelectionManager()
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
    
    static func runningInXcode() -> Bool {
        let running = ProcessInfo.processInfo.environment["RUNNING_FROM_XCODE"] != nil
        return running
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $tabSelectionManager.selectedTab) {

//                ScalesIntervalsView()
//                        .tabItem {
//                            Label("TEST", systemImage: "scribble")
//                        }
//                        .tag(0)
//                }


                ScalesView()
                //PracticeChartView(rows: 10, columns: 3)
                //SpinWheelView(practiceJournal: PracticeJournal.shared!)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
                
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(1)

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
                
                FFTContentView()
                     .tabItem {
                         Label("Home", systemImage: "house")
                     }
                     .tag(5)
                }
                //.border(Color.red)
                .onAppear() {
                }
                .environmentObject(tabSelectionManager)
        }
    }
}
