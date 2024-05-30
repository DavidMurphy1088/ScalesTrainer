import Foundation

public class Settings : Codable  {    
    static var shared = Settings()
    var recordDataMode = false
    var requiredScaleRecordStartAmplitude:Double = 0.0
    var amplitudeFilter:Double = 0.0
    
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
    
    func save(_ log:Bool = true) {
        guard let str = toJSON() else {
            return
        }
        if log {
            Logger.shared.log(self, "Settings saved \(str)")
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
                    self.requiredScaleRecordStartAmplitude = loaded.requiredScaleRecordStartAmplitude
                    let str:String = String(data: data, encoding: .utf8) ?? "none"
                    Logger.shared.log(self, "Settings loaded \(str)")
                } catch {
                    Logger.shared.reportError(self, "load:" + error.localizedDescription)
                }
            }
        }
    }

}
