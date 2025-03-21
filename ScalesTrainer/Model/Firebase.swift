import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

public class Firebase  {
    public static var shared = Firebase()
    let logger = AppLogger.shared
    
    init() {
        var username:String? = nil
        var pwd:String? = nil
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) {
            if let apiKey = plist["PWD"] as? String {
                pwd = apiKey
            }
            if let apiKey = plist["USERNAME"] as? String {
                username = apiKey
            }
        }
        if username == nil || pwd == nil {
            AppLogger.shared.reportError(self, "No user for Firebase RealTime DB")
        }
        signIn(username: username!, pwd: pwd!)
    }

    func signIn(username:String, pwd:String) {
//        guard let defaultApp = FirebaseApp.app() else {
//            return
//        }
        Auth.auth().signIn(withEmail: username, password: pwd) { authResult, error in
           if let error = error {
               AppLogger.shared.reportError(self, "Firebase sign in: \(error.localizedDescription)")
                return
            }
         }
    }
     
    func writeToRealtimeDatabase(board:String, grade:Int, key:String, data: [String: Any], callback: ((String) -> Void)?) {
        let database = Database.database().reference() // Reference to the root of the database
        database.child("SCALES").child("\(board)_\(grade)").child(key).setValue(data) { error, ref in
            if let error = error {
                self.logger.reportError(self, "Error writing to database: \(error.localizedDescription)")
                if let callback {
                    callback("error:\(error.localizedDescription)")
                }
            } else {
                if let callback = callback {
                    callback("OK")
                }
            }
        }
    }
    
    func deleteFromRealtimeDatabase(board:String, grade:Int, key:String, callback: ((String) -> Void)?) {
        let database = Database.database().reference()
        database.child("SCALES").child("\(board)_\(grade)").child(key).removeValue { error, _ in
            if let error = error {
                self.logger.reportError(self, "Error deleting from database: \(error.localizedDescription)")
                if let callback {
                    callback("error:\(error.localizedDescription)")
                }
            } else {
                if let callback = callback {
                    callback("OK")
                }
            }
        }
    }
    
    ///Return the scale key and staff JSON for each scale in the grade
    func readAllScales(board:String, grade:Int, completion: @escaping ([(String, String, String)]) -> Void) {
        let database = Database.database().reference() // Get a reference to the database

        database.child("SCALES").child("\(board)_\(grade)").observeSingleEvent(of: .value) { snapshot in
            var result: [(String, String, String)] = [] // Array to store the result

            if let scalesData = snapshot.value as? [String: Any] {
                for (scaleKey, scaleDetails) in scalesData {
                    if let details = scaleDetails as? [String: Any] {
                        let staffJSON = details["staff"] as? String
                        let scaleJSON = details["scale"] as? String
                        if let staffJSON = staffJSON, let scaleJSON = scaleJSON {
                            result.append((scaleKey, staffJSON, scaleJSON)) 
                        }
                    }
                }
            } else {
                //print("No data found at SCALES node.")
            }
            completion(result)
        } withCancel: { error in
            self.logger.reportError(self, "Error reading known-correct data, error:\(error.localizedDescription)")
            completion([])
        }
    }
    
    ///Write the known-correct scale and score to the cloud Firebase Realtime db
    ///Write the score for note placements, note accidentals, clef swaps etc
    ///Write the scale to record fingering.
    func writeKnownCorrect(scale:Scale, score:Score, board:String, grade:Int) {
        func completedCallback1(_ x:String) {
        }
        do {
            ///Scale
            let scaleKey = scale.getScaleIdentificationKey()
            let scaleData = try JSONEncoder().encode(scale)
            let scaleJSON = String(data: scaleData, encoding: .utf8)
            /// Score
            let scoreData = try JSONEncoder().encode(score)
            let scoreJSON = String(data: scoreData, encoding: .utf8)
                
            if let scoreJSON = scoreJSON, let scaleJSON = scaleJSON {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium // Choose a predefined date style
                formatter.timeStyle = .short // Choose a predefined time style
                let formattedDate = formatter.string(from: Date())
                var version = ""
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    version = "Version \(appVersion) (Build \(buildNumber))"
                }
                let staffData: [String: Any] = [
                    "version": version,
                    "date": formattedDate ,
                    "staff": scoreJSON,
                    "scale": scaleJSON
                ]
                self.writeToRealtimeDatabase(board: board, grade: grade, key: scaleKey, data:staffData, callback: completedCallback1)
            }
            else {
                logger.reportError(self, "Cannot encode score to JSON  \(scaleKey)")
            }
            
        } catch {
            logger.reportError(self, "Error encoding user: \(error)")
        }
    }

}

