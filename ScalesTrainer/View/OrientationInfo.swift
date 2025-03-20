//import SwiftUI
//import Combine
//import UIKit
//
//// Extension on UIDeviceOrientation to check for landscape mode
//extension UIDeviceOrientation {
//    var isAnyLandscape: Bool {
//        return self == .landscapeLeft || self == .landscapeRight
//        //above excludes faceup
//        //return !isPortrait
//    }
//    
//    var isPortrait: Bool {
//        return self == .portrait || self == .portraitUpsideDown
//    }
//}
//
//// ObservableObject to monitor device orientation changes
//class DeviceOrientationObserver: ObservableObject {
//    @Published var orientation: UIDeviceOrientation = UIDevice.current.orientation
//    private var orientationDidChangeNotification: AnyCancellable?
//    
//    init() {
//        orientationDidChangeNotification = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//            .compactMap { _ in
//                return UIDevice.current.orientation
//            }
//            .assign(to: \.orientation, on: self)
//        
//        // Begin generating device orientation notifications
//        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
//    }
//    
//    deinit {
//        // Stop generating device orientation notifications
//        UIDevice.current.endGeneratingDeviceOrientationNotifications()
//        orientationDidChangeNotification?.cancel()
//    }
//}

import SwiftUI
import Combine

//public class OrientationInfo: ObservableObject {
//    @Published var isPortrait: Bool = UIDevice.current.orientation.isPortrait || UIDevice.current.orientation.isFlat
//    private var cancellable: AnyCancellable?
//
//    init() {
//        // Start generating device orientation notifications
//        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
//
//        // Subscribe to orientation change notifications
//        cancellable = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//            .receive(on: RunLoop.main)
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                let orientation = UIDevice.current.orientation
//                self.isPortrait = orientation.isPortrait || orientation.isFlat
//            }
//    }
//
//    deinit {
//        UIDevice.current.endGeneratingDeviceOrientationNotifications()
//    }
//}
