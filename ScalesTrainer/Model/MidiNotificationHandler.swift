//import Foundation
//import AudioKit
//import SoundpipeAudioKit
//import AVFoundation
//import Foundation
//import AudioKitEX
//import Foundation
//import UIKit
//
//class MidiNotificationHandlerOldUNUSUED : TapHandlerProtocol {
//    var tapHandlerEventSet:TapEventSet
//    let scale:Scale?
//    var notifyFunction: ((Int, TapEventStatus) -> Void)?
//
//    required init(bufferSize: Int, scale: Scale, amplitudeFilter: Double?) {
//        self.tapHandlerEventSet = TapEventSet(bufferSize: bufferSize, events: [])
//        self.scale = scale
//        let midiManager = MIDIManager.shared
//        midiManager.installNotificationTarget(target: self.MIDIManagerNotificationTarget(msg:))
//    }
//    
//    func setNotifyFunction(notifyFunction: @escaping (Int, TapEventStatus) -> Void) {
//        self.notifyFunction = notifyFunction
//    }
//    
//    ///The function this class tells the MIDI manage to use to send MIDI notifications to.
//    ///
//    func MIDIManagerNotificationTarget(msg:MIDIMessage) {
//        //print("========== Handler NotificationTarget", msg.messageType, msg.midi)
//        if let notify = self.notifyFunction {
//            notify(msg.midi, .inScale)
//        }
//    }
//    
//    ///Never called
//    func tapUpdate(_ frequency: [AudioKit.AUValue], _ amplitude: [AudioKit.AUValue]) {
//    }
//    
//    func stopTappingProcess() -> TapEventSet {
//        return self.tapHandlerEventSet
//    }
//    
//    func getBufferSize() -> Int {
//        return 0
//    }
//    
//}
