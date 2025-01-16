@testable import ScalesStar
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import XCTest

final class ScoreTest: XCTestCase {
    let logger = Logger.shared
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

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let expectation = self.expectation(description: "Firebase write")
        func completedCallback(_ x:String) {
            expectation.fulfill()
        }

        func writeScaleCallback(_ scale:Scale, _ score:Score) {
            do {
                let scoreData = try JSONEncoder().encode(score)
                if let scoreJSON = String(data: scoreData, encoding: .utf8) {
                    let scaleKey = scale.scaleRoot.name + "_" + scale.scaleType.description + "_" + String(scale.octaves) + " "
                    let staffData: [String: Any] = [
                        "staff": scoreJSON, "octaves": scale.octaves]
                    firebase.writeToRealtimeDatabase(key: scaleKey, data:staffData, callback: completedCallback)
               }
            } catch {
                logger.reportError(self, "Error encoding user: \(error)")
            }
        }
        
        func readScales() {
            firebase.readAllScales { result in
                print("Received scales:")
                for (scaleKey, staffJSON) in result {
                    print("READ Scale Key: \(scaleKey)") //, Staff JSON: \(staffJSON)")
                }
            }
        }

        let scalesModel = ScalesModel.shared
        let write = false
        if write {
            scalesModel.setScaleByRootAndType(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major,
                                              scaleMotion: .similarMotion, minTempo: 40, octaves: 1, hands: [0],
                                              dynamicTypes: [.mf], articulationTypes: [.legato],
                                              debugOn: true, callback: writeScaleCallback)
        }
        else {
            readScales()
        }
        waitForExpectations(timeout: 15, handler: nil)
        print("===============================➡️➡️")
    }

    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
