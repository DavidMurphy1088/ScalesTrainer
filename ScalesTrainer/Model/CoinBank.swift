import Foundation
import Combine

class CoinBank: ObservableObject, Codable {
    static let storageName = "coinbank"
    static let shared = CoinBank()
    
    @Published var total: Int = 0
    var lastBet: Int = 0
    var existsInStorage = false
    
    enum CodingKeys: String, CodingKey {
        case total
        case existsInStorage
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(total, forKey: .total)
        try container.encode(existsInStorage, forKey: .existsInStorage)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        existsInStorage = try container.decode(Bool.self, forKey: .existsInStorage)
    }
    
    init() {
        if !didLoad() {
            total = 12
        }
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
    
    func save() {
        guard let str = toJSON() else {
            return
        }
        self.existsInStorage = true
        UserDefaults.standard.set(str, forKey: CoinBank.storageName)
    }
    
    func didLoad() -> Bool {
        if let jsonData = UserDefaults.standard.string(forKey: CoinBank.storageName) {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(CoinBank.self, from: data)
                    self.total = decoded.total
                    self.existsInStorage = decoded.existsInStorage
                    Logger.shared.log(self, "CoinBank loaded")
                    return true
                } catch {
                    Logger.shared.reportError(self, "CoinBank found but not loaded, data format has changed:" + error.localizedDescription)
                }
            }
        }
        return false
    }
}
