import Foundation
import MessageUI

public class LogMessage : Identifiable {
    public var id:UUID = UUID()
    public var number:Int
    public var message:String
    public let logTime = Date()
    var value:Double
    let isError:Bool
    
    init(num:Int, isError:Bool, _ msg:String, valueIn:Double) {
        self.message = msg //+ "  Val:"+String(format: "%.2f", valueIn)
        self.number = num
        self.value = valueIn
        self.isError = isError
    }
    
    public func getLogEvent() -> String {
        var out = ""
        if self.isError {
            out += "**** ERROR ***"
        }
        out += message
        return out
    }
}

public class Logger : ObservableObject {
    public static var shared = Logger()
    @Published var loggedMsg:String? = nil
    @Published var errorNo:Int = 0
    @Published public var errorMsg:String? = nil
    @Published public var loggedMsgs:[LogMessage] = []
    @Published var maxLogValue = 0.0
    @Published var minLogValue = 10.0
    @Published var hiliteLogValue = 0.0

    public init() {
    }
    
//    public func clearLog() {
//        DispatchQueue.main.async {
//            self.loggedMsgs = []
//            self.hiliteLogValue = 10000.0
//        }
//    }
    
    func hilite(val:Double) {
        DispatchQueue.main.async {
            self.hiliteLogValue = val
        }
    }
    
    func calcValueLimits() {
        var min = 100000000.0
        var max = 0.0
        for m in loggedMsgs {
            if m.value < min {
                min = m.value
            }
            if m.value > max {
                max = m.value
            }
        }
        DispatchQueue.main.async {
            self.maxLogValue = max
            self.minLogValue = min
            self.hiliteLogValue = min
        }
    }
    
    private func getTime() -> String {
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
        dateFormatter.dateFormat = "HH:mm:ss"
        let now = Date()
        let s = dateFormatter.string(from: now)
        return s
    }
    
    public func reportError(_ reporter:AnyObject, _ context:String, _ err:Error? = nil) {
        var msg = String("\(getTime()) 🛑 =========== ERROR =========== ErrNo:\(errorNo): " + String(describing: type(of: reporter))) + " " + context
        if let err = err {
            msg += ", "+err.localizedDescription
        }
        print(msg)
       
        DispatchQueue.main.async {
            self.loggedMsgs.append(LogMessage(num: self.loggedMsgs.count, isError: true, msg, valueIn: 0))
            self.errorMsg = msg
            self.errorNo += 1
        }
    }
        
    public func reportErrorString(_ context:String, _ err:Error? = nil) {
        reportError(self, context, err)
    }

    public func log(_ reporter:AnyObject, _ msg:String, _ value:Double? = nil) {
        let msg = String(describing: type(of: reporter)) + ":" + msg
        //let strVal = value == nil ? "_" : String(format: "%.2f", value!)
        print("\(getTime()) \(msg)")//  val:\(strVal)")
        DispatchQueue.main.async {
            let val:Double = value == nil ? 0 : value!
            self.loggedMsgs.append(LogMessage(num: self.loggedMsgs.count, isError: false, msg, valueIn: val * 100))
        }
    }
    
}



class LogExportViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    func exportLogFile() {
        // Check if the device can send emails
        guard MFMailComposeViewController.canSendMail() else {
            print("Device cannot send email")
            return
        }
        
        // Get the path to the log file
        guard let logFilePath = getLogFilePath() else {
            print("Log file not found")
            return
        }
        
        // Create the mail compose view controller
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        // Set email details
        mailComposer.setSubject("App Log File")
        mailComposer.setMessageBody("Please find the attached log file.", isHTML: false)
        
        // Attach the log file
        do {
            let logFileData = try Data(contentsOf: URL(fileURLWithPath: logFilePath))
            mailComposer.addAttachmentData(logFileData, mimeType: "text/plain", fileName: "app_log.txt")
            
            // Present the mail composer
            present(mailComposer, animated: true, completion: nil)
        } catch {
            print("Error reading log file: \(error)")
        }
    }
    
    func getLogFilePath() -> String? {
        // Implement this method to return the path to your log file
        // This is typically in the app's documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsDirectory?.appendingPathComponent("app_log.txt").path
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
