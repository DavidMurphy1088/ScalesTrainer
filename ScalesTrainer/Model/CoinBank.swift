import Foundation
import Combine

class CoinBank: ObservableObject, Codable {
    static let storageName = "coinbank"
    static let shared = CoinBank()
    static let initialCoins = 12
    
    @Published private(set) var totalCoinsInBank: Int = 0
    func setTotalCoinsInBank(_ value:Int) {
        DispatchQueue.main.async {
            self.totalCoinsInBank = value
        }
    }

    @Published private(set) var lastBet: Int = 0
    func setLastBet(_ value:Int) {
        DispatchQueue.main.async {
            self.lastBet = value
        }
    }

    var pileCoinCounts:[Int] = []
    var pileDrawingHeights:[Double] = []
    
    var coinHeight:Double = 0
    var coinWidth:Double = 0
    var drawingOrder:[Int] = []
    
    var existsInStorage = false
    
    enum CodingKeys: String, CodingKey {
        case total
        case existsInStorage
    }
    
    func adjustAfterResult(noErrors:Bool) {
        if lastBet > 0 {
            DispatchQueue.main.async {
                if noErrors {
                    self.totalCoinsInBank += self.lastBet
                }
                else {
                    self.totalCoinsInBank -= self.lastBet
                }
                self.lastBet = 0
                self.save()
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalCoinsInBank, forKey: .total)
        try container.encode(existsInStorage, forKey: .existsInStorage)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalCoinsInBank = try container.decode(Int.self, forKey: .total)
        existsInStorage = try container.decode(Bool.self, forKey: .existsInStorage)
    }
    
    init() {
        if !didLoad() {
            totalCoinsInBank = CoinBank.initialCoins
        }
    }
    
    func getCountMsg() -> String {
        if totalCoinsInBank == 0 {
            return "No coins"
        }
        if totalCoinsInBank == 1 {
            return "There is only one coin"
        }
        else {
            return "There are \(totalCoinsInBank) coins"
        }
    }
    
    func getBetMsg() -> String {
        if lastBet == 0 {
            return "no coins"
        }
        if lastBet == 1 {
            return "one coin"
        }
        else {
            return "\(lastBet) coins"
        }
    }

    func getCountFace() -> String {
        if totalCoinsInBank == 0 {
            return "🥵"
        }
        if totalCoinsInBank < CoinBank.initialCoins / 2 {
            return "🙁"
        }
        return "😊"
    }
    
    func getCoinsStatusMsg() -> String {
        var m = getCountMsg()
        //m += " left"
        m += " in your bank"
        if lastBet > 0 {
            m += " and you bet \(getBetMsg())"
        }
        return m
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
        Logger.shared.log(self, "saved:"+str)
    }
    
    func didLoad() -> Bool {
        if let jsonData = UserDefaults.standard.string(forKey: CoinBank.storageName) {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(CoinBank.self, from: data)
                    self.totalCoinsInBank = decoded.totalCoinsInBank
                    //self.totalCoinsInBank = 500
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
