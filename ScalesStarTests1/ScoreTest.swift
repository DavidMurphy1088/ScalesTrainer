@testable import ScalesStar
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import XCTest

final class ScoreTest: XCTestCase {
    let logger = AppLogger.shared
    let firebase = Firebase.shared
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    override func setUp() {
        super.setUp()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func areJSONObjectsEqual(goodJSON: String, testJSON: String) -> Bool {
        guard let data1 = goodJSON.data(using: .utf8),
              let data2 = testJSON.data(using: .utf8) else {
            return false
        }
        
        do {
            // Deserialize JSON strings into objects
            let object1 = try JSONSerialization.jsonObject(with: data1, options: [])
            let object2 = try JSONSerialization.jsonObject(with: data2, options: [])
            
            // Compare the deserialized objects
            if areJSONStructuresEqual(level: 0, object1, object2) {
                return true
            }
            else {
                return false
            }
        } catch {
            XCTFail("Error parsing JSON: \(error)")
            return false
        }
    }
    
    func areJSONStructuresEqual(level:Int, _ obj1: Any, _ obj2: Any) -> Bool {
        if let dict1 = obj1 as? [String: Any], let dict2 = obj2 as? [String: Any] {
            var match = true
            if dict1.keys != dict2.keys {
                match = false
            }
            if match {
                for key in dict1.keys {
                    if !areJSONStructuresEqual(level:level+1,dict1[key], dict2[key]) {
                        if [4,3].contains(level) {
                            print("======= \(level) ♦️ DICT key:\(key) \nCORRECT: \(String(describing: dict1[key])) \nWRONG: \(String(describing: dict2[key]))")
                        }
                        else {
                            if level == 0 {
                                
                            }
                            print("======= \(level) ♦️ DICT key:\(key) ") //" dict2[key])
                        }
                        match = false
                        break
                    }
                }
            }
            return match

        } else if let array1 = obj1 as? [Any], let array2 = obj2 as? [Any] {
            var match = true
            if array1.count != array2.count {
                match = false
            }
            if match {
                var ctr = 0
                for i in 0..<array1.count {
                    if !areJSONStructuresEqual(level:level+1, array1[i], array2[i]) {
                        print("======= \(level) ♦️ ARRAY ctr:\(i)") //, array1[i], array2[i])
                        match = false
                        break
                    }
                }
            }
            return match
        } else {
            // Compare primitive values (String, Number, Bool, etc.)
            if "\(obj1)" == "\(obj2)" {
                //print("=====PRIMITVE \(level) \(key) 🟢", obj1, obj2)
                return true
            }
            else {
                //print("=====PRIMITVE \(level) \(key)❗️", obj1, obj2)
                return false
            }
        }
    }
    
    func processBoard(musicBoard:MusicBoard, gradeFilter:[Int], typeFilter:[ScaleType]) {
        let grades = musicBoard.gradesOffered
        var totalMissingCnt = 0
        var totalProcessedCnt = 0
        var totalMatchedCnt = 0
        var totalMismatchedCnt = 0
        
        for grade in grades {
            if gradeFilter.count > 0 {
                if !gradeFilter.contains(grade) {
                    continue
                }
            }
            
            ///Read the stored known-correct scales for this grade
            let readExpectation = self.expectation(description: "Firebase read")
            ///Dictionary keyed with JSON data for score and scale
            var storedKnownCorrect:[String: (String, String)] = [:]
            firebase.readAllScales(board: musicBoard.name, grade:grade) { result in
                for (scaleKey, staffJSON, scaleJSON) in result {
                    storedKnownCorrect[scaleKey] =  (staffJSON, scaleJSON)
                }
                readExpectation.fulfill()
            }
            waitForExpectations(timeout: 15, handler: nil)

             ///Compare the score/staff just generated against the stored correct version
            func compareStaff(_ scale:Scale, _ score:Score) {
                let scaleKey = scale.getScaleIdentificationKey()
                var correctScoreJSON:String? = nil
                var correctScaleJSON:String? = nil
                if let dictionaryData = storedKnownCorrect[scaleKey] {
                    correctScoreJSON = dictionaryData.0
                    correctScaleJSON = dictionaryData.1
                }
                if let correctScoreJSON = correctScoreJSON, let correctScaleJSON = correctScaleJSON {
                    do {
                        ///Cant just compare JSON strings since the order of children is arbitrary (and could be different for otherwise equal JSON structures)
                        let scoreUnderTestData = try JSONEncoder().encode(score)
                        var errors = false
                        if let scoreUnderTestJSON = String(data: scoreUnderTestData, encoding: .utf8) {
                            if areJSONObjectsEqual(goodJSON: correctScoreJSON, testJSON: scoreUnderTestJSON) {
                                //logger.log(self, "✅ SCORE \(scaleKey)")
                            }
                            else {
                                totalMismatchedCnt += 1
                                logger.log(self, "❌ SCORE \(scaleKey) failed")
                                logger.log(self, "❌ SCALE \(scaleKey) failed")
                                errors = true
                                //print("==================CORRECT\n", correctScoreJSON, "\n")
                                //print("==================TESTING\n", scoreUnderTestJSON)

                            }
                        }
                        
                        let scaleUnderTestData = try JSONEncoder().encode(scale)
                        if let scaleUnderTestJSON = String(data: scaleUnderTestData, encoding: .utf8) {
                            if areJSONObjectsEqual(goodJSON: correctScaleJSON, testJSON: scaleUnderTestJSON) {
                                //logger.log(self, "✅ SCALE \(scaleKey)")
                                //totalMatchedCnt += 1
                            }
                            else {
                                totalMismatchedCnt += 1
                                logger.log(self, "❌ SCALE \(scaleKey) failed")
                                //print("==================CORRECT\n\n", correctScaleJSON, "\n")
                                //print("==================TESTING\n\n", scaleUnderTestJSON)
                                errors = true
                            }
                        }
                        if !errors {
                            logger.log(self, "✅ SCALE \(scaleKey)")
                            totalMatchedCnt += 1
                        }
                        
                     } catch {
                        XCTFail("Error encoding user: \(error)")
                    }
                }
                else {
                    XCTFail("No stored scale")
                }
            }
            
            ///Generate the scale scores and compare to the known good ones
            let musicBoardAndGrade = MusicBoardAndGrade(board: musicBoard, grade: grade)
            let scalesModel = ScalesModel.shared

            ///Compare all the scales in this grade
            logger.log(self, "➡️➡️➡️ Testing \(musicBoard.name) grade \(grade)")
            for scale in musicBoardAndGrade.enumerateAllScales() {
                if typeFilter.count > 0 {
                    if !typeFilter.contains(scale.scaleType) {
                        continue
                    }
                }
                let scaleKey = scale.getScaleIdentificationKey()
                if storedKnownCorrect.keys.contains(scaleKey) {
                    scalesModel.setScaleByRootAndType(scaleRoot: scale.scaleRoot, scaleType: scale.scaleType,
                                                      scaleMotion: scale.scaleMotion, minTempo: scale.minTempo, octaves: scale.octaves, hands: scale.hands,
                                                      dynamicTypes: scale.dynamicTypes, articulationTypes: scale.articulationTypes,
                                                      scaleCustomisation: scale.scaleCustomisation,
                                                      //debugOn: false, //DONT SET IT since it causes a match fail with the correct scale
                                                      callback: compareStaff)
                }
                else {
                    totalMissingCnt += 1
                    logger.log(self, "🥵 \(scaleKey) - missing correct version to test against")
                }
                totalProcessedCnt += 1
            }
        }
        if totalMissingCnt > 0 || totalMismatchedCnt > 0 {
            XCTFail("🥵🥵🥵🥵🥵🥵 Mismatched:\(totalMismatchedCnt) Missing:\(totalMissingCnt) Processed:\(totalProcessedCnt) Matched:\(totalMatchedCnt)")
        }
        else {
            logger.log(self, "✅✅✅✅✅✅ Processed:\(totalProcessedCnt) Matched:\(totalMatchedCnt)")
        }
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        var writtenStaffData = ""
        let musicBoard = MusicBoard(name: "Trinity")
        processBoard(musicBoard: musicBoard, gradeFilter: [], typeFilter: [])
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
