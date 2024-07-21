import Foundation

public class Settings : Codable  {    
    static var shared = Settings()
    var recordDataMode = true
    var firstName = ""
    var defaultOctaves = 2
    var scaleLeadInBarCount:Int = 0
    var tapMinimunAmplificationFilter:Double = 0
    var tapBufferSize = 4096
    var scaleNoteValue = 4 // What note values the score is wrtiewn with  1/4, 1/87 or 1/16
    
    private var wasLoaded = false
    
    init() {
        load()
    }
    
    public func settingsExists() -> Bool {
       return wasLoaded
    }
    
    public func calibrationIsSet() -> Bool {
       return tapMinimunAmplificationFilter > 0
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
        var str = "Settings amplitudeFilter:\(String(format: "%.4f", self.tapMinimunAmplificationFilter)) "
        //str += " RequireStartAmpl:\(String(format: "%.4f", self.requiredScaleRecordStartAmplitude)) "
        str += " LeadIn:\(self.scaleLeadInBarCount)"
        str += " RecordDataMode:\(self.recordDataMode)"
        str += " FirstName:\(self.firstName)"
        str += " Octaves:\(self.defaultOctaves)"
        str += " ScaleNoteValue:\(self.scaleNoteValue)"
        str += " TapBuffer:\(self.tapBufferSize)"
        return str
    }
    
    func save(amplitudeFilter:Double) {
        self.tapMinimunAmplificationFilter = amplitudeFilter
        guard let str = toJSON() else {
            return
        }
        //if log {
            Logger.shared.log(self, "Setting saved, \(toString())")
        //}
        UserDefaults.standard.set(str, forKey: "settings")
        self.wasLoaded = true
    }
    
    func getScaleNoteValue() -> Double {
        return self.scaleNoteValue == 0 ? 1.0 : 0.5
    }
    
    func load() {
        if let jsonData = UserDefaults.standard.string(forKey: "settings") {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(Settings.self, from: data)
                    let loaded = decoded
                    self.recordDataMode = loaded.recordDataMode
                    self.tapMinimunAmplificationFilter = loaded.tapMinimunAmplificationFilter
                    self.firstName = loaded.firstName
                    self.scaleLeadInBarCount = loaded.scaleLeadInBarCount
                    self.defaultOctaves = loaded.defaultOctaves
                    self.scaleNoteValue = loaded.scaleNoteValue
                    self.tapBufferSize = loaded.tapBufferSize
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
