import Foundation

public class Settings : Codable  {    
    static var shared = Settings()
    var recordDataMode = false
    var firstName = ""
    var scaleLeadInBarCount:Int = 0
    var aFilter:Double = 0
    var wasLoaded = false
    
    init() {
        load()
    }
    
    private func toJSON() -> String? {
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            Logger.shared.reportError(self, "save:" + error.localizedDescription)
        }
        return nil
    }
    
    func toString() -> String {
        var str = "Settings amplitudeFilter:\(String(format: "%.4f", self.aFilter)) "
        //str += " RequireStartAmpl:\(String(format: "%.4f", self.requiredScaleRecordStartAmplitude)) "
        str += " LeadIn:\(self.scaleLeadInBarCount)"
        str += " RecordDataMode:\(self.recordDataMode)"
        str += " FirstName:\(self.firstName)"
        return str
    }
    
    func save(amplitudeFilter:Double, _ log:Bool = true) {
        self.aFilter = amplitudeFilter
        guard let str = toJSON() else {
            return
        }
        if log {
            Logger.shared.log(self, "Setting saved, \(toString())")
        }
        UserDefaults.standard.set(str, forKey: "settings")
        self.wasLoaded = true
    }
    
    func load() {
        if let jsonData = UserDefaults.standard.string(forKey: "settings") {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(Settings.self, from: data)
                    let loaded = decoded
                    self.recordDataMode = loaded.recordDataMode
                    self.aFilter = loaded.aFilter
                    self.firstName = loaded.firstName
                    self.scaleLeadInBarCount = loaded.scaleLeadInBarCount
                    //self.requiredScaleRecordStartAmplitude = loaded.requiredScaleRecordStartAmplitude
                    Logger.shared.log(self, "Settings loaded, \(toString())")
                    self.wasLoaded = true
                } catch {
                    Logger.shared.reportError(self, "Settings found but not loaded, data format has changed:" + error.localizedDescription)
                    //Logger.shared.reportError(self, "load:" + error.localizedDescription)
                }
            }
        }
    }

}
