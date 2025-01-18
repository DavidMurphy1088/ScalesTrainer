import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

public class Firebase  {
    public static var shared = Firebase()
    let logger = Logger.shared
    
    func signIn(email:String, pwd:String) {
        ///Not required, the info provides everything required
//        Auth.auth().signIn(withEmail: email, password: pwd) { result, error in
//            if let error = error {
//                self.logger.reportError(self, "Error signing in: \(error.localizedDescription)")
//            } else {
//                self.logger.log(self, "Firebase Successfully signed in")
//            }
//        }
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
    func readAllScales(board:String, grade:Int, completion: @escaping ([(String, String)]) -> Void) {
        let database = Database.database().reference() // Get a reference to the database

        database.child("SCALES").child("\(board)_\(grade)").observeSingleEvent(of: .value) { snapshot in
            var result: [(String, String)] = [] // Array to store the result

            if let scalesData = snapshot.value as? [String: Any] {
                for (scaleKey, scaleDetails) in scalesData {
                    if let details = scaleDetails as? [String: Any],
                       let staffJSON = details["staff"] as? String {
                        result.append((scaleKey, staffJSON)) // Append scaleKey and staffJSON to result
                    }
                }
            } else {
                //print("No data found at SCALES node.")
            }
            completion(result)
        } withCancel: { error in
            print("Error reading data: \(error.localizedDescription)")
            // Return an empty array in case of error
            completion([])
        }
    }
    
    func writeKnownCorrect(scale:Scale, score:Score, board:String, grade:Int) {
        func completedCallback1(_ x:String) {
            print("================ WRITE CALLBACK", x)
        }
        do {
            let scoreData = try JSONEncoder().encode(score)
            //score.debug1(ctx: "", handType: nil)
            //print(scoreData)
            let jsonString = String(data: scoreData, encoding: .utf8)
            print (jsonString)
            
            if let scoreJSON = String(data: scoreData, encoding: .utf8) {
                let scaleKey = scale.getScaleStorageKey()
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
                   // "octaves": scale.octaves
                ]
                self.writeToRealtimeDatabase(board: board, grade: grade, key: scaleKey, data:staffData, callback: completedCallback1)
           }
        } catch {
            logger.reportError(self, "Error encoding user: \(error)")
        }
    }

}

