import Foundation

public class Settings : Codable {
    static let shared = Settings()
    var recordDataMode = false
    
    func toJSON() -> String? {
        do {
            let jsonEncoder = JSONEncoder()
            //jsonEncoder.outputFormatting = .prettyPrinted  // Optional: to pretty-print the JSON
            let jsonData = try jsonEncoder.encode(self)
            
            // Step 4: Convert JSON data to a string (optional, for display purposes)
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
        UserDefaults.standard.set(str, forKey: "settings")
    }
    
    func load() {
        if let jsonData = UserDefaults.standard.string(forKey: "settings") {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(Settings.self, from: data)
                    shared = decoded
                    print(decoded.recordDataMode)
                } catch {
                    Logger.shared.reportError(self, "load:" + error.localizedDescription)
                }
            }
        }
    }

}
