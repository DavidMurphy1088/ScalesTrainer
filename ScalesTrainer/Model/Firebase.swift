import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

public class Firebase  {
    public static var shared = Firebase()
    let logger = AppLogger.shared
    //let dbName = "Scales"
    let dbName = "Scales_2025_09"
    
    // MARK: - Authentication Methods
    
    /// Sign in anonymously with Firebase Auth
    func signInAnonymously(completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                self.logger.reportError(self, "Anonymous sign-in failed: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            if let user = authResult?.user {
                //self.logger.reportInfo(self, "Anonymous user signed in with UID: \(user.uid)")
                completion(true, nil)
            } else {
                completion(false, "Unknown authentication error")
            }
        }
    }
    
    /// Check if user is currently authenticated
    func isUserAuthenticated() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    /// Get current user UID (returns nil if not authenticated)
    func getCurrentUserUID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Sign out current user
    func signOut(completion: @escaping (Bool, String?) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true, nil)
        } catch let signOutError as NSError {
            self.logger.reportError(self, "Sign out failed: \(signOutError.localizedDescription)")
            completion(false, signOutError.localizedDescription)
        }
    }
    
    // MARK: - Database Methods (with Auth Check)
    
    /// Ensure user is authenticated before performing database operations
    private func ensureAuthenticated(completion: @escaping (Bool) -> Void) {
        if isUserAuthenticated() {
            completion(true)
            return
        }
        
        // If not authenticated, try to sign in anonymously
        signInAnonymously { success, error in
            if success {
                completion(true)
            } else {
                self.logger.reportError(self, "Failed to authenticate user: \(error ?? "Unknown error")")
                completion(false)
            }
        }
    }
    
    func writeToRealtimeDatabase(board:String, grade:Int, key:String, data: [String: Any], callback: ((String) -> Void)?) {
        ensureAuthenticated { [weak self] authenticated in
            guard let self = self, authenticated else {
                callback?("error: Authentication failed")
                return
            }
            
            let database = Database.database().reference()
            
            // Optional: Include user UID in the data path for user-specific data
            // let userUID = self.getCurrentUserUID() ?? "anonymous"
            // let dataPath = "\(self.dbName)/\(userUID)/\(board)_\(grade)/\(key)"
            
            database.child(self.dbName).child("\(board)_\(grade)").child(key).setValue(data) { error, ref in
                if let error = error {
                    self.logger.reportError(self, "Error writing to database: \(error.localizedDescription)")
                    callback?("error:\(error.localizedDescription)")
                } else {
                    callback?("Callback for write OK")
                }
            }
        }
    }
    
    func deleteFromRealtimeDatabase(board:String, grade:Int, key:String, callback: ((String) -> Void)?) {
        ensureAuthenticated { [weak self] authenticated in
            guard let self = self, authenticated else {
                callback?("error: Authentication failed")
                return
            }
            
            let database = Database.database().reference()
            
            database.child(self.dbName).child("\(board)_\(grade)").child(key).removeValue { error, _ in
                if let error = error {
                    self.logger.reportError(self, "Error deleting from database: \(error.localizedDescription)")
                    callback?("error:\(error.localizedDescription)")
                } else {
                    callback?("OK")
                }
            }
        }
    }
    
    ///Return the scale key and staff JSON for each scale in the grade
    func readAllScales(board:String, grade:Int, completion: @escaping ([(String, String, String)]) -> Void) {
        ensureAuthenticated { [weak self] authenticated in
            guard let self = self, authenticated else {
                completion([])
                return
            }
            
            let database = Database.database().reference()

            database.child(self.dbName).child("\(board)_\(grade)").observeSingleEvent(of: .value) { snapshot in
                var result: [(String, String, String)] = []

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
                }
                completion(result)
            } withCancel: { error in
                self.logger.reportError(self, "Error reading known-correct data, error:\(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    ///Write the known-correct scale and score to the cloud Firebase Realtime db
    ///Write the score for note placements, note accidentals, clef swaps etc
    ///Write the scale to record fingering and (Sept 2025) finger breaks
    func writeKnownCorrect(scale:Scale, score:Score, board:String, grade:Int) {
        ensureAuthenticated { [weak self] authenticated in
            guard let self = self, authenticated else {
                if let self = self {
                    self.logger.reportError(self, "Authentication failed for writeKnownCorrect")
                }
                return
            }
            
            func completedCallback1(_ x:String) {
                // Handle completion if needed
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
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    let formattedDate = formatter.string(from: Date())
                    
                    var version = ""
                    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        version = "Version \(appVersion) (Build \(buildNumber))"
                    }
                    
                    // Optional: Include user UID in the data
                    let userUID = self.getCurrentUserUID() ?? "anonymous"
                    
                    let staffData: [String: Any] = [
                        "version": version,
                        "date": formattedDate,
                        "userUID": userUID,
                        "staff": scoreJSON,
                        "scale": scaleJSON
                    ]
                    
                    self.writeToRealtimeDatabase(board: board, grade: grade, key: scaleKey, data: staffData, callback: completedCallback1)
                } else {
                    self.logger.reportError(self, "Cannot encode score to JSON  \(scaleKey)")
                }
                
            } catch {
                self.logger.reportError(self, "Error encoding user: \(error)")
            }
        }
    }
}
