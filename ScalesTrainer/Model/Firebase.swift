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
     
    func writeToRealtimeDatabase(key:String, data: [String: Any], callback: ((String) -> Void)?) {
        let database = Database.database().reference() // Reference to the root of the database

        database.child("SCALES").child("Trinity_Grade1").child(key).setValue(data) { error, ref in
            if let error = error {
                self.logger.reportError(self, "🥵🥵🥵🥵🥵🥵🥵🥵🥵🥵 Error writing to database: \(error.localizedDescription)")
                if let callback {
                    callback("error")
                }
            } else {
                self.logger.log(self, "🔯🔯🔯🔯🔯🔯🔯🔯🔯🔯🔯🔯🔯🔯🔯 🔯🔯🔯🔯🔯 Data written successfully!")
                if let callback = callback {
                    callback("OK")
                }
            }
        }
    }
    
//    func readAllUsers(callback: ((String) -> Void)?) {
//        let db = Firestore.firestore() // Get a Firestore reference
//
//        db.child("SCALES").getDocuments { (querySnapshot, error) in
//            if let error = error {
//                print("Error getting documents: \(error.localizedDescription)")
//            } else {
//                for document in querySnapshot!.documents {
//                    let data = document.data() // Dictionary of the document data
//                    print("====➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️", data)
//
////                    let name = data["name"] as? String ?? "No name"
////                    let age = data["age"] as? Int ?? 0
////                    let email = data["email"] as? String ?? "No email"
////                    print("User: \(name), Age: \(age), Email: \(email)")
//                }
//            }
//            if let callback = callback {
//                callback("OK")
//            }
//
//        }
//    }
    
//    func readAllScales(callback: (([(String,String)]) -> Void)?)  {
//        let database = Database.database().reference() // Get a reference to the database
//
//        database.child("SCALES").child("Trinity_Grade1").observeSingleEvent(of: .value) { snapshot in
//            var result:[(String,String)] = []
//            if let scalesData = snapshot.value as? [String: Any] {
//                for (scaleKey, scaleDetails) in scalesData {
//                    print("Scale: \(scaleKey)")
//                    if let details = scaleDetails as? [String: Any] {
//                        print("Details: \(details)")
//                        let staffJSON = details["staff"]
//                        if let callback = callback {
//                           //callback(staffJSON)
//                        }
//                    }
//                }
//            } else {
//                print("No data found at SCALES node.")
//            }
//            if let callback = callback {
//                //callback("OK")
//            }
//
//        } withCancel: { error in
//            print("Error reading data: \(error.localizedDescription)")
//        }
//    }
    
    func readAllScales(completion: @escaping ([(String, String)]) -> Void) {
        let database = Database.database().reference() // Get a reference to the database

        database.child("SCALES").child("Trinity_Grade1").observeSingleEvent(of: .value) { snapshot in
            var result: [(String, String)] = [] // Array to store the result

            if let scalesData = snapshot.value as? [String: Any] {
                for (scaleKey, scaleDetails) in scalesData {
                    if let details = scaleDetails as? [String: Any],
                       let staffJSON = details["staff"] as? String {
                        result.append((scaleKey, staffJSON)) // Append scaleKey and staffJSON to result
                    }
                }
            } else {
                print("No data found at SCALES node.")
            }

            // Call the completion handler with the result
            completion(result)

        } withCancel: { error in
            print("Error reading data: \(error.localizedDescription)")
            // Return an empty array in case of error
            completion([])
        }
    }


}

