import Foundation

public class Settings : Codable  {
    
    static var shared = Settings()
    var recordDataMode = false
    
    init() {
        load()
    }
    
    private func toJSON() -> String? {
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                return jsonString
            }
        } catch {
            Logger.shared.reportError(self, "save:" + error.localizedDescription)
        }
        return nil
    }
    
    func save() {
        let str = toJSON()
        print("Settings save ====", recordDataMode)
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
                    print("Settings load ====", decoded.recordDataMode)
                } catch {
                    Logger.shared.reportError(self, "load:" + error.localizedDescription)
                }
            }
        }
    }

}
