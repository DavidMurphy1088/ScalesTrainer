import SwiftUI
import AudioKit
import AVFoundation
import SwiftUI
import Foundation
import StoreKit

import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

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
    let email = "Fred1@gmail.com"
    @State private var password = "Password1"
    @State private var isLoggedIn = false
    @State var status = ""
    let logger = Logger.shared
    @State var ctr = 0
    let firebase = Firebase.shared
    
    var body: some View {
        VStack {
            Spacer()

            Button("Firebase Signin") {
//                firebase.signIn(email: email, pwd: password)
            }
            Spacer()
            
            Button(action: {
                //firebase.writeDataToRealtimeDatabase(key: "TESTVIEW", jsonString: "FRED", callback: nil)
            }) {
                Text("Firebase Write")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()
            
            Text(status)
            
            Spacer()
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
        .onAppear() {
            status = "Firebase not connected"
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.sharedRH)
        }
    }
}

///------------------------------------------------------------

//class BackgroundTaskManager: ObservableObject {
//    private var timer: Timer?
//    private var startDate: Date
//    private var loopCtr: Int = 0
//    
//    init() {
//        startDate = Date()
//        startTimer()
//    }
//
//    private func startTimer() {
//        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
//            self?.performTask()
//        }
//    }
//
//    ///Reload the practice chart on day or month change. The active day column must change on day of mon change.
//    private func performTask() {
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            guard let self = self else { return }
//            let calendar = Calendar.current
//            let startDay = calendar.component(.day, from: self.startDate)
//            let currentDay = calendar.component(.day, from: Date())
//            loopCtr += 1
//            if loopCtr > 3 || currentDay != startDay {
//                DispatchQueue.main.async {
//                    exit(0)
//                }
//            } else {
//                print("Day-of-month remains the same (\(currentDay)) at \(Date()).")
//            }
//        }
//    }
//    deinit {
//        timer?.invalidate()
//    }
//}

class TabSelectionManager: ObservableObject {
    @Published var selectedTab: Int = 0
    ///A board or grade change needs to force navigation away from Practice Chart and Spin Wheel if they are open since they still show the previous grade.
    @Published var isPracticeChartActive: Bool = false
    @Published var isSpinWheelActive: Bool = false

    init() {
        nextNavigationTab()
    }
    
    func nextNavigationTab() {
        if Settings.shared.isDeveloperMode1() {
            let hands = [0,1]
            //let scaleCustomisation = ScaleCustomisation(maxAccidentalLookback: nil)
            
            //                    ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "C"), scaleType: .major,
            //                        scaleMotion: .contraryMotion, minTempo: 50, octaves: 1, hands: hands)
            
            //                    ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic,
            //                        scaleMotion: .contraryMotion, minTempo: 50, octaves: 1, hands: [0,1])
            let scaleCustomisation = ScaleCustomisation(startMidiRH: 64, startMidiLH: 48, clefSwitch: false,
                                                   customScaleName: "Chromatic, Contrary Motion, LH starting C, RH starting E",
                                                   customScaleNameWheel: "Chrom Contrary, LH C, RH E")
            ScalesModel.shared = ScalesModel()
            let scalesModel = ScalesModel.shared
            if true {
                scalesModel.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "C"), scaleType: .trinityBrokenTriad,
                                                scaleMotion: .similarMotion, minTempo: 80, octaves: 1, hands: [0],
                                                dynamicTypes: [.mf], articulationTypes: [.legato],
                                                //scaleCustomisation: scaleCustomisation,
                                                debugOn: true)
            }
            else {
                scalesModel.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "F#"), scaleType: .melodicMinor,
                                                         scaleMotion: .similarMotion, minTempo: 50, octaves: 1, hands: [0],
                                                         dynamicTypes: [.mf], articulationTypes: [.legato],
                                                         scaleCustomisation: scaleCustomisation)
            }

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
        FirebaseApp.configure()
        if !Settings.shared.isDeveloperMode1() {
            LicenceManager.shared.getFreeLicenses()
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        Logger.shared.log(self, "Version.Build \(appVersion).\(buildNumber)")
        
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
            //return [.portrait, .landscapeLeft, .landscapeRight]
            return [.portrait]
            //return [.landscape]
        } else {
            return [.portrait, .landscapeLeft, .landscapeRight] // Allow both on iPad
        }
    }
}

@main
struct ScalesTrainerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tabSelectionManager = TabSelectionManager()
    @StateObject var launchScreenState = LaunchScreenStateManager()
    @StateObject private var orientationInfo = OrientationInfo()
    //@StateObject private var backgroundTaskManager = BackgroundTaskManager()
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
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if launchScreenState.state == .finished || Settings.shared.isDeveloperMode1() {
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
            if Settings.shared.isDeveloperMode1() {

                //MIDIView()
                //PracticeChartView(rows: 10, columns: 3)
                //HomeView()
                ScalesView(practiceChartCell: nil, practiceModeHand: nil)
                //TestView()
                //FFTView()
                //FFTContentView()
                    .tabItem {
                        Label("SCALE", systemImage: "house")
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
                .environmentObject(tabSelectionManager)
            
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
                .environmentObject(tabSelectionManager)
            
            FeatureReportView()
                .tabItem {
                    Label(NSLocalizedString("MessageUs", comment: "Menu"), systemImage: "arrow.up.message")
                }
                .tag(50)
                .environmentObject(tabSelectionManager)
            
            if Settings.shared.isDeveloperMode1() {
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

