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
import UIKit

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

//struct OrientationManager {
//    //    iPhone 15: 6.1-inch Super Retina XDR OLED display
//    //    iPhone 15 Plus: 6.7-inch Super Retina XDR OLED display
//    //    iPhone 15 Pro: 6.1-inch Super Retina XDR OLED display with ProMotion technology
//    //    iPhone 15 Pro Max: 6.7-inch Super Retina XDR OLED display with ProMotion technology
//    //    iPhone 16 Series (Released September 2024):
//    //    iPhone 16: 6.1-inch Super Retina XDR OLED display
//    //    iPhone 16 Plus: 6.7-inch Super Retina XDR OLED display
//    
//    static var appDelegate: AppDelegate?
//    
//    // Lock orientation and rotate
//    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
//        //self.lockOrientation(orientation)
//        if let delegate = appDelegate {
//            delegate.orientationLock = orientation
//        }
//        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
//        UINavigationController.attemptRotationToDeviceOrientation()
//    }
//
//    // Unlock orientation
//    static func unlockOrientation() {
//        if let delegate = appDelegate {
//            delegate.orientationLock = .all // Unlocks orientation lock
//        }
//        
//        // Explicitly rotate back to portrait after unlocking
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
//            UINavigationController.attemptRotationToDeviceOrientation()
//        }
//    }
//}

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
        
    func getImageSize(geo: GeometryProxy) -> Double {
        let imageSize:Double
        if UIDevice.current.userInterfaceIdiom == .phone {
            imageSize = min(geo.size.width, geo.size.height) * 0.80
        }
        else {
            imageSize = min(geo.size.width, geo.size.height) * 0.60
        }
        return imageSize
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
                        let imageSize = getImageSize(geo: geo)
                        Image("GrandPiano")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: imageSize )
                                .cornerRadius(imageSize * 0.1)
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
    let logger = AppLogger.shared
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


class AppDelegate: NSObject, UIApplicationDelegate {
    var orientationLock: UIInterfaceOrientationMask = UIInterfaceOrientationMask.landscape
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
#if targetEnvironment(simulator)
        ///Simulator asks for password every time even though its signed in with Apple ID. By design for IAP purchasing... :(
        ///Code to run on the Simulator
        AppLogger.shared.log(self, "Running on the Simulator, will not load IAP licenses")
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
        AppLogger.shared.log(self, "Version.Build \(appVersion).\(buildNumber)")
        
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
        AppLogger.shared.log(self, "Microphone access:\(statusMsg))")
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            //return [.portrait]
//            return [.portrait, .landscapeLeft, .landscapeRight]
//        } else {
//            return [.portrait, .landscapeLeft, .landscapeRight] // Allow both on iPad
//        }
        
        //return orientationLock
        return UIInterfaceOrientationMask.landscape
    }
}

///------------------------------------------------------------

class ViewManager: ObservableObject {
    static var shared = ViewManager()
    @Published var selectedTab: Int = 0
    @Published var titleUser: User?
    ///A board or grade change needs to force navigation away from Practice Chart and Spin Wheel if they are open since they still show the previous grade.
    @Published var isPracticeChartActive: Bool = false
    @Published var isSpinWheelActive: Bool = false

    init() {
        let settings  = Settings.shared
        settings.load()
        Settings.shared.load()
        DispatchQueue.main.async {
            self.titleUser = settings.getCurrentUser()
            if settings.noUserDefined() {
                self.selectedTab = MainContentView.TAB_USERS
            }
            else {
                self.selectedTab = MainContentView.TAB_ACTIVITES
            }
        }
    }
    
    func updateCurrentPublished(user:User) {
        DispatchQueue.main.async {
            self.titleUser = user
        }
    }
    
    func setTab(tab:Int) {
        DispatchQueue.main.async {
            self.objectWillChange.send() 
            self.selectedTab = tab
        }
    }
}

struct MainContentView: View {
    @ObservedObject private var viewManager = ViewManager.shared
    static let TAB_USERS = 10
    static let TAB_ACTIVITES = 20
    
    init() {
        // Customize tab bar appearance (System-wide)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() // Ensures the tab bar is solid
        appearance.backgroundColor = UIColor.white //
        
//        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
//        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor, .font: UIFont.systemFont(ofSize: 12, weight: .bold)] // **Bold, larger text**
//        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
//        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor, .font: UIFont.systemFont(ofSize: 12, weight: .medium)]

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    func setupDev() {
        //let hands = [0,1]
        //let scaleCustomisation = ScaleCustomisation(maxAccidentalLookback: nil)
        
        //                    ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "C"), scaleType: .major,
        //                        scaleMotion: .contraryMotion, minTempo: 50, octaves: 1, hands: hands)
        
        //                    ScalesModel.shared.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic,
        //                        scaleMotion: .contraryMotion, minTempo: 50, octaves: 1, hands: [0,1])
        let scaleCustomisation = ScaleCustomisation(startMidiRH: 64, startMidiLH: 48, clefSwitch: false,
                                               customScaleName: "Chromatic, Contrary Motion, LH starting C, RH starting E",
                                               customScaleNameWheel: "Chrom Contrary, LH C, RH E")
        //ScalesModel.shared = ScalesModel()
        let scalesModel = ScalesModel.shared
        if true {
            scalesModel.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "D♭"), scaleType: .major,
                                            scaleMotion: .similarMotion, minTempo: 50, octaves: 2, hands: [0,1],
                                            dynamicTypes: [.mf], articulationTypes: [.legato],
                                            //scaleCustomisation: scaleCustomisation,
                                            debugOn: true)
        }
    }
    var body: some View {
        TabView(selection: $viewManager.selectedTab) {
            if Settings.shared.isDeveloperMode1() {
                //HomeView()
                ScalesView(practiceChart: nil, practiceChartCell: nil, practiceModeHand: nil)
                //UserListView()
                //TestView()
                //FFTContentView()
                    .tabItem {
                        Label("SCALE", systemImage: "house")
                    }
                    .tag(1)
                    .environmentObject(viewManager)
            }
            
            UserListView()
                .tabItem {
                    Label {
                        Text(NSLocalizedString("Users", comment: "Menu")).background(.white).bold()
                    } icon: {
                        Image(systemName: "graduationcap.fill").renderingMode(.original).foregroundColor(.green)
                    }
                }
                .tag(MainContentView.TAB_USERS)
                .environmentObject(viewManager)
            
            //if let user = Settings.shared.getCurrentUser() {
                ActivitiesView()
                    .tabItem {
                        Label(NSLocalizedString("Activities", comment: "Menu"), systemImage: "house")
                    }
                    .tag(MainContentView.TAB_ACTIVITES)
                    .environmentObject(viewManager)
                
                SettingsView(user:Settings.shared.getCurrentUser())
                    .tabItem {
                        Label(NSLocalizedString("Settings", comment: "Menu"), systemImage: "gear")
                    }
                    .tag(30)
                    .environmentObject(viewManager)
            //}
            
            LicenseManagerView(contentSection: ContentSection(), email: "email.com")
                .tabItem {
                    Label(NSLocalizedString("Subscriptions", comment: "Menu"), systemImage: "checkmark.icloud")
                }
                .tag(40)
                .environmentObject(viewManager)
            
            FeatureReportView()
                .tabItem {
                    Label(NSLocalizedString("MessageUs", comment: "Menu"), systemImage: "arrow.up.message")
                }
                .tag(50)
                .environmentObject(viewManager)
            
            if Settings.shared.isDeveloperMode1() {
                MIDIView()
                    .tabItem {
                        Label("MIDI", systemImage: "house")
                    }
                    .tag(89)
                    .accessibilityIdentifier("app_log")
                    .environmentObject(viewManager)

                LogView()
                    .tabItem {
                        Label("Log", systemImage: "book.pages")
                    }
                    .tag(90)
                    .accessibilityIdentifier("app_log")
                    .environmentObject(viewManager)
                
//                ScalesLibraryView()
//                    .tabItem {
//                        Label(NSLocalizedString("ScaleLibrary", comment: "Menu"), systemImage: "book")
//                    }
//                    .tag(60)
//                    .environmentObject(viewManager)
                
                
                CalibrationView()
                    .tabItem {
                        Label("Calibration", systemImage: "lines.measurement.vertical")
                    }
                    .tag(70)
                    .environmentObject(viewManager)
                
//                ScalesLibraryView()
//                    .tabItem {
//                        Label("ScaleLibrary", systemImage: "book.pages")
//                    }
//                    .tag(80)
//                    .environmentObject(viewManager)
//                
                
                DeveloperView()
                    .tabItem {
                        Label("Dev", systemImage: "book.pages")
                    }
                    .tag(100)
                    .environmentObject(viewManager)
            }
        }      
        .background(Color.white)
        .tabViewStyle(DefaultTabViewStyle())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        ///required to stop iPad putting tabView at top and overwriting some of the app's UI
        .environment(\.horizontalSizeClass, .compact)
        .onAppear {
            if Settings.shared.isDeveloperMode1() {
                self.setupDev()
                ViewManager.shared.setTab(tab: 1)
            }
        }
    }
}

@main
struct ScalesTrainerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate ///Dont remove this ⬅️
    @ObservedObject private var viewManager = ViewManager.shared
    @StateObject var launchScreenState = LaunchScreenStateManager()
    //@StateObject private var orientationInfo = OrientationInfo()
    let launchTimeSecs = 3.0

    init() {
#if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            AppLogger.shared.reportError(AVAudioSession.sharedInstance(), err.localizedDescription)
        }
#endif
        //OrientationManager.appDelegate = appDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if launchScreenState.state == .finished || Settings.shared.isDeveloperMode1() {
                    MainContentView()
                        //.environmentObject(orientationInfo)
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
    
}

