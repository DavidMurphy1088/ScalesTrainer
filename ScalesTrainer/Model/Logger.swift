import Foundation
public class LogMessage : Identifiable {
    public var id:UUID = UUID()
    public var number:Int
    public var message:String
    public let logTime = Date()
    var value:Double
    
    init(num:Int, _ msg:String, valueIn:Double) {
        self.message = msg //+ "  Val:"+String(format: "%.2f", valueIn)
        self.number = num
        self.value = valueIn
    }
    
    public func getLogEvent() -> String {
        //var out = String(number)+" "
        var out = ""
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss"
//        let logTime = formatter.string(from: self.logTime)
//        out += logTime + "  " + message
        out = message
        return out
    }
}

public class Logger : ObservableObject {
    public static var shared = Logger()
    @Published var loggedMsg:String? = nil
    @Published var errorNo:Int = 0
    @Published public var errorMsg:String? = nil
    @Published public var loggedMsgs:[LogMessage] = []
    //var logLevel:LogLevel = .all
    @Published var maxLogValue = 0.0
    @Published var minLogValue = 10.0
    @Published var hiliteLogValue = 0.0

    public init() {
    }
    
    public func clearLog() {
        DispatchQueue.main.async {
            self.loggedMsgs = []
            self.hiliteLogValue = 10000.0
        }
    }
    
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
            self.loggedMsgs.append(LogMessage(num: self.loggedMsgs.count, msg, valueIn: 0))
            self.errorMsg = msg
            self.errorNo += 1
        }
    }
        
    public func reportErrorString(_ context:String, _ err:Error? = nil) {
        reportError(self, context, err)
    }

    public func log(_ reporter:AnyObject, _ msg:String, _ value:Double? = nil) {
        let msg = msg //String(describing: type(of: reporter)) + ":" + msg
        let strVal = value == nil ? "" : String(format: "%.2f", value!)
        print("\(getTime()) \(msg)  val:\(strVal)")
        DispatchQueue.main.async {
            let val:Double = (value == nil ? 0.0 : value)!
            self.loggedMsgs.append(LogMessage(num: self.loggedMsgs.count, msg, valueIn: val))
        }
    }
    
}

