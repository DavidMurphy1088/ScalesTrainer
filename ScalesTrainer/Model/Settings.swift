import Foundation

public class Settings : Codable  {    
    static var shared = Settings()
    var recordDataMode = false
    var firstName = ""
    var amplitudeFilter:Double = 0.0
    var scaleLeadInBarCount:Int = 0
    
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
        var str = "Settings amplitudeFilter:\(String(format: "%.4f", self.amplitudeFilter)) "
        //str += " RequireStartAmpl:\(String(format: "%.4f", self.requiredScaleRecordStartAmplitude)) "
        str += " LeadIn:\(self.scaleLeadInBarCount)"
        str += " RecordDataMode:\(self.recordDataMode)"
        str += " FirstName:\(self.firstName)"
        return str
    }
    
    func save(_ log:Bool = true) {
        guard let str = toJSON() else {
            return
        }
        if log {
            Logger.shared.log(self, "Setting saved, \(toString())")
        }
        UserDefaults.standard.set(str, forKey: "settings")
    }
    
    func load() {
        if let jsonData = UserDefaults.standard.string(forKey: "settings") {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(Settings.self, from: data)
                    let loaded = decoded
                    self.recordDataMode = loaded.recordDataMode
                    self.amplitudeFilter = loaded.amplitudeFilter
                    self.firstName = loaded.firstName
                    self.scaleLeadInBarCount = loaded.scaleLeadInBarCount
                    //self.requiredScaleRecordStartAmplitude = loaded.requiredScaleRecordStartAmplitude
                    //let str:String = String(data: data, encoding: .utf8) ?? "none"
                    Logger.shared.log(self, "Settings loaded, \(toString())")
                } catch {
                    Logger.shared.reportError(self, "load:" + error.localizedDescription)
                }
            }
        }
    }

}
