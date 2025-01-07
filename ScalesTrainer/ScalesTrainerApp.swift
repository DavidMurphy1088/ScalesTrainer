import SwiftUI
import AudioKit
import AVFoundation
import SwiftUI
import Foundation
import StoreKit

enum LaunchScreenStep {
    case firstStep
    case secondStep
    case finished
}

final class LaunchScreenStateManager: ObservableObject {
    @MainActor @Published private(set) var state: LaunchScreenStep = .firstStep

    @MainActor func dismiss() {
        Task {
            state = .secondStep
            sleep(1)
            self.state = .finished
        }
    }
}

class Opacity : ObservableObject {
    @Published var imageOpacity: Double = 0.0
    var launchTimeSecs:Double
    var timer:Timer?
    var ticksPerSec = 30.0
    var duration = 0.0
    
    init(launchTimeSecs:Double) {
        self.launchTimeSecs = launchTimeSecs
        let timeInterval = 1.0 / ticksPerSec
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                let opacity = sin((self.duration * Double.pi * 1.0) / self.launchTimeSecs)
                self.imageOpacity = opacity
                if self.duration >= self.launchTimeSecs {
                    self.timer?.invalidate()
                }
                self.duration += timeInterval
            }
        }
    }
}

struct LaunchScreenView: View {
    static var staticId = 0
    var id = 0
    @ObservedObject var opacity:Opacity
    @State var durationSeconds:Double
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager // Mark 1
    
    init(launchTimeSecs:Double) {
        self.opacity = Opacity(launchTimeSecs: launchTimeSecs)
        self.durationSeconds = launchTimeSecs
        self.id = LaunchScreenView.staticId
        LaunchScreenView.staticId += 1
    }

    func appVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(appVersion).\(buildNumber)"
    }
        
    @ViewBuilder
    private var image: some View {  // Mark 3
        GeometryReader { geo in
            //hack: for some reason there are 2 instances of LaunchScreenView. The first starts showing too early ??
            VStack {
                ///Image causes title to be truncated on phone
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("trinity")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geo.size.width * 0.40)
                                .cornerRadius(10) // Adjust the radius value to your preference
                                .opacity(self.opacity.imageOpacity)
                        Spacer()
                    }
                    Spacer()
                }
                VStack(alignment: .center) {
                    Text("Scales Academy").font(.title)
                    Text("")
                    Text("© 2025 Musicmaster Education LLC.")//.font(.title3)
                    //.position(x: geo.size.width * 0.5, y: geo.size.height * 0.85)
                    //.opacity(self.opacity.imageOpacity)
                    Text("Version \(appVersion())")
                    Text("")
                    Text("")
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            image
        }
    }
}

struct DeveloperView: View {
    let scalesModel = ScalesModel.shared
    @State var showingTapData = false

    var body: some View {
        VStack {
            Spacer()
//            Button("READ_TEST_DATA") {
//                scalesModel.setRunningProcess(.recordScaleWithFileData)
//            }.padding()
            //if scalesModel.tapHandlerEventSetPublished  {

            Button("Show Tap Data") {
                //self.showScaleStart()
                showingTapData = true
            }
                
            //}
//            if scalesModel.recordedTapsFileName != nil {
//                Spacer()
//                if MFMailComposeViewController.canSendMail() {
//                    Button("Send Tap Data") {
//                        activeSheet = .emailRecording
//                    }
//                }
//                else {
//                    Text("No mail")
//                }
//            }
            Spacer()
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.sharedRH)
        }
    }
}

class TabSelectionManager: ObservableObject {
    @Published var selectedTab: Int = 0
    init() {
        nextNavigationTab()
    }
    
    func nextNavigationTab() {
        //if Settings.shared.calibrationIsSet() {
        if Settings.shared.isDeveloperMode() {
            let hands = [0,1]
            let scaleCustomisation = ScaleCustomisation(maxAccidentalLookback: nil)
            
            //                    ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "C"), scaleType: .major,
            //                        scaleMotion: .contraryMotion, minTempo: 50, octaves: 1, hands: hands)
            
            //                    ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic,
            //                        scaleMotion: .contraryMotion, minTempo: 50, octaves: 1, hands: [0,1])
            if true {
                ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "G#"), scaleType: .harmonicMinor,
                                                         scaleMotion: .similarMotion, minTempo: 50, octaves: 2, hands: [0],
                                                         dynamicTypes: [.mf], articulationTypes: [.legato], debugOn: true)
            }
            else {
                ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "E"), scaleType: .melodicMinor,
                                                         scaleMotion: .similarMotion, minTempo: 50, octaves: 1, hands: [0,1],
                                                         dynamicTypes: [.mf], articulationTypes: [.legato],
                                                         scaleCustomisation: scaleCustomisation)
            }
            
            let testNotes = TestMidiNotes(scale: ScalesModel.shared.scale, hands: hands, noteSetWait: 1.5)
            //testNotes.debug("Start")
            //MIDIManager.shared.setTestMidiNotesNotes(testNotes)
            selectedTab = 0
        }
        else {
            if MusicBoardAndGrade.shared == nil {
                selectedTab = 10
            }
            else {
                selectedTab = 20
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
#if targetEnvironment(simulator)
        ///Simulator asks for password every time even though its signed in with Apple ID. By design for IAP purchasing... :(
        ///Code to run on the Simulator
        Logger.shared.log(self, "Running on the Simulator, will not load IAP licenses")
#else
        SKPaymentQueue.default().add(LicenceManager.shared) ///Do this as early as possible so manager is a queue observer
        LicenceManager.shared.verifyStoredSubscriptionReceipt(ctx: "App starting") ///Get the current validity of any locally stored subscription receipt
        LicenceManager.shared.requestProducts() ///Get products
        ///LicenceManager.shared.restoreTransactions() ///No need - the last subscription receipt received is stored locally. If not (e.g. nmew device) user does 'Restore Subscriptions'
#endif
        if !Settings.shared.isDeveloperMode() {
            LicenceManager.shared.getFreeLicenses()
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        Logger.shared.log(self, "Version.Build \(appVersion).\(buildNumber)")
        
        //Make navigation titles at top larger font
//        let appearance = UINavigationBarAppearance()
//        appearance.titleTextAttributes = [.font : UIFont.systemFont(ofSize: 24, weight: .bold)]
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
//        UINavigationBar.appearance().standardAppearance = appearance
        
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        var statusMsg = ""
        switch status {
        case .authorized:
            statusMsg = "The user has previously granted access to the microphone."
        case .notDetermined:
            statusMsg = "The user has not yet been asked to grant microphone access."
        case .denied:
            statusMsg = "The user has previously denied access."
        case .restricted:
            statusMsg = "The user can't grant access due to restrictions."
        @unknown default:
            statusMsg = "unknown \(status)"
        }
        Logger.shared.log(self, "Microphone access:\(statusMsg))")

        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            //return .portrait // Lock to portrait on iPhone
            return [.portrait, .landscapeLeft, .landscapeRight]
        } else {
            return [.portrait, .landscapeLeft, .landscapeRight] // Allow both on iPad
        }
    }
}

///Used for an indepenet view to back out a navigations tack
//class NavigationState2: ObservableObject {
//    @Published var navigationChildIsActive: Bool = false
//    func setNavigationChildIsActive(_ state:Bool) {
//        print("====================== NavigationState2, navigationChildIsActive", state)
//        self.navigationChildIsActive = state
//    }
//}

@main
struct ScalesTrainerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tabSelectionManager = TabSelectionManager()
    @StateObject var launchScreenState = LaunchScreenStateManager()
    @StateObject private var orientationInfo = OrientationInfo()
    let launchTimeSecs = 3.0
    
    init() {
#if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            Logger.shared.reportError(AVAudioSession.sharedInstance(), err.localizedDescription)
        }
#endif
    }
    
    //    static func runningInXcode1() -> Bool {
    //        let running = ProcessInfo.processInfo.environment["RUNNING_FROM_XCODE"] != nil
    //        return running
    //        //return false
    //    }
    
    //    func getDataLoadedStatus() -> RequestStatus {
    //        return .waiting //self.exampleData.dataStatus
    //    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if launchScreenState.state == .finished || Settings.shared.isDeveloperMode() {
                    MainContentView()
                        .environmentObject(orientationInfo)
                }
                else {
                    if launchScreenState.state != .finished {
                        LaunchScreenView(launchTimeSecs: self.launchTimeSecs)
                    }
                }
            }
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + launchTimeSecs) {
                    self.launchScreenState.dismiss()
                }
            }
        }
    }
    
    func MainContentView() -> some View {
        TabView(selection: $tabSelectionManager.selectedTab) {
            if Settings.shared.isDeveloperMode() {

                //MIDIView()
                //PracticeChartView(rows: 10, columns: 3)
                //HomeView()
                ScalesView(practiceChartCell: nil)
                //TestView()
                //FFTContentView()
                    .tabItem {
                        Label("Activities", systemImage: "house")
                        //Label("MIDI", systemImage: "house")
                    }
                    .tag(1)
            }
            
            UserDetailsView()
                .tabItem {
                    Label(NSLocalizedString("Grade", comment: "Menu"), systemImage: "graduationcap.fill")
                }
                .tag(10)
                .environmentObject(tabSelectionManager)
            
            HomeView()
                .tabItem {
                    Label(NSLocalizedString("Activities", comment: "Menu"), systemImage: "house")
                }
                .tag(20)
            
            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("Settings", comment: "Menu"), systemImage: "gear")
                }
                .tag(30)
                .environmentObject(tabSelectionManager)
            
            LicenseManagerView(contentSection: ContentSection(), email: "email.com")
                .tabItem {
                    Label(NSLocalizedString("Subscriptions", comment: "Menu"), systemImage: "checkmark.icloud")
                }
                .tag(40)
            
            FeatureReportView()
                .tabItem {
                    Label(NSLocalizedString("MessageUs", comment: "Menu"), systemImage: "arrow.up.message")
                }
                .tag(50)
                .environmentObject(tabSelectionManager)
            
            if Settings.shared.isDeveloperMode() {
                MIDIView()
                    .tabItem {
                        Label("MIDI", systemImage: "house")
                    }
                    .tag(89)
                    .accessibilityIdentifier("app_log")
                    .environmentObject(tabSelectionManager)

                LogView()
                    .tabItem {
                        Label("Log", systemImage: "book.pages")
                    }
                    .tag(90)
                    .accessibilityIdentifier("app_log")
                    .environmentObject(tabSelectionManager)
                
                ScalesLibraryView()
                    .tabItem {
                        Label(NSLocalizedString("ScaleLibrary", comment: "Menu"), systemImage: "book")
                    }
                    .tag(60)
                    .environmentObject(tabSelectionManager)
                
                
                CalibrationView()
                    .tabItem {
                        Label("Calibration", systemImage: "lines.measurement.vertical")
                    }
                    .tag(70)
                    .environmentObject(tabSelectionManager)
                
                ScalesLibraryView()
                    .tabItem {
                        Label("ScaleLibrary", systemImage: "book.pages")
                    }
                    .tag(80)
                    .environmentObject(tabSelectionManager)
                
                
                DeveloperView()
                    .tabItem {
                        Label("Dev", systemImage: "book.pages")
                    }
                    .tag(100)
                    .environmentObject(tabSelectionManager)
            }
        }
    }
}

