//
//  ScalesAcademyTests.swift
//  ScalesAcademyTests
//
//  Created by David Murphy on 03/10/2025.
//

import Testing

//struct ScalesAcademyTests {
//
//    @Test func example() async throws {
//        print("============ TEST Swift 🟢🟢🟢🟢")
//    }
//
//}

import Testing
import Foundation
@testable import ScalesAcademy
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@Suite("Score Tests")
struct ScalesAcademyTests {
    let logger = AppLogger.shared
    let firebase = Firebase.shared
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    func log(_ m:String) {
        print("Log", m)
    }
    
    func areJSONObjectsEqual(goodJSON: String, testJSON: String) -> Bool {
        guard let data1 = goodJSON.data(using: .utf8),
              let data2 = testJSON.data(using: .utf8) else {
            return false
        }
        
        do {
            let object1 = try JSONSerialization.jsonObject(with: data1, options: [])
            let object2 = try JSONSerialization.jsonObject(with: data2, options: [])
            
            return areJSONStructuresEqual(level: 0, object1, object2)
        } catch {
            Issue.record("Error parsing JSON: \(error)")
            return false
        }
    }
    
    func areJSONStructuresEqual(level: Int, _ obj1: Any, _ obj2: Any) -> Bool {
        if let dict1 = obj1 as? [String: Any], let dict2 = obj2 as? [String: Any] {
            var match = true
            if dict1.keys != dict2.keys {
                match = false
            }
            if match {
                for key in dict1.keys {
                    if !areJSONStructuresEqual(level: level + 1, dict1[key], dict2[key]) {
                        if [4, 3].contains(level) {
                            print("======= level:\(level) ♦️ DICT key:\(key) \nCORRECT: \(String(describing: dict1[key])) \nWRONG: \(String(describing: dict2[key]))")
                        }
                        else {
                            print("======= level:\(level) ♦️ DICT key:\(key) ")
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
                for i in 0..<array1.count {
                    if !areJSONStructuresEqual(level: level + 1, array1[i], array2[i]) {
                        print("======= Level:\(level) ♦️ ARRAY ctr:\(i)")
                        match = false
                        break
                    }
                }
            }
            return match
        } else {
            return "\(obj1)" == "\(obj2)"
        }
    }
    
    func processBoard(musicBoard: MusicBoard, gradeFilter: [Int], keyFilter: [String], typeFilter: [ScaleType]) async throws {
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
            
            // Read the stored known-correct scales for this grade using async/await
            let storedKnownCorrect: [String: (String, String)] = await withCheckedContinuation { continuation in
                var results: [String: (String, String)] = [:]
                firebase.readAllScales(board: musicBoard.name, grade: grade) { result in
                    for (scaleKey, staffJSON, scaleJSON) in result {
                        results[scaleKey] = (staffJSON, scaleJSON)
                    }
                    continuation.resume(returning: results)
                }
            }

            // Compare the score/staff just generated against the stored correct version
            func compareStaff(_ scale: Scale, _ score: Score) {
                let scaleKey = scale.getScaleIdentificationKey()
                var correctScoreJSON: String? = nil
                var correctScaleJSON: String? = nil
                if let dictionaryData = storedKnownCorrect[scaleKey] {
                    correctScoreJSON = dictionaryData.0
                    correctScaleJSON = dictionaryData.1
                }
                if let correctScoreJSON = correctScoreJSON, let correctScaleJSON = correctScaleJSON {
                    do {
                        let scoreUnderTestData = try JSONEncoder().encode(score)
                        var errors = false
                        if let scoreUnderTestJSON = String(data: scoreUnderTestData, encoding: .utf8) {
                            if areJSONObjectsEqual(goodJSON: correctScoreJSON, testJSON: scoreUnderTestJSON) {
                                // Score matches
                            }
                            else {
                                totalMismatchedCnt += 1
                                log("❌ SCORE \(scaleKey) failed")
                                log("❌ SCALE \(scaleKey) failed")
                                errors = true
                            }
                        }
                        
                        let scaleUnderTestData = try JSONEncoder().encode(scale)
                        if let scaleUnderTestJSON = String(data: scaleUnderTestData, encoding: .utf8) {
                            if areJSONObjectsEqual(goodJSON: correctScaleJSON, testJSON: scaleUnderTestJSON) {
                                // Scale matches
                            }
                            else {
                                totalMismatchedCnt += 1
                                log("❌ SCALE \(scaleKey) failed")
                                print("\n----------Correct\n", correctScaleJSON, "\n\n----------Wrong\n", scaleUnderTestJSON)
                                errors = true
                            }
                        }
                        if !errors {
                            log("✅ SCALE \(scaleKey)")
                            totalMatchedCnt += 1
                        }
                        
                    } catch {
                        Issue.record("Error encoding user: \(error)")
                    }
                }
                else {
                    Issue.record("No stored scale for key: \(scaleKey)")
                }
            }
            
            // Generate the scale scores and compare to the known good ones
            let musicBoardAndGrade = MusicBoardAndGrade(board: musicBoard, grade: grade)
            let scalesModel = ScalesModel.shared

            let gradeScales: [Scale] = MusicBoardAndGrade.getScales(boardName: "Trinity", grade: grade)
            log("➡️➡️➡️ Testing:\(musicBoard.name) grade:\(grade) scaleCount:\(gradeScales.count)")
            
            for scale in gradeScales {
                print("=======Scales", scale.getScaleDescriptionHelpMessage())
                if keyFilter.count > 0 {
                    let scaleKeyName = scale.getScaleKeyName().components(separatedBy: " ").first?.uppercased() ?? ""
                    if !keyFilter.contains(scaleKeyName) {
                        continue
                    }
                }
                if typeFilter.count > 0 {
                    if !typeFilter.contains(scale.scaleType) {
                        continue
                    }
                }
                let scaleKey = scale.getScaleIdentificationKey()
                if storedKnownCorrect.keys.contains(scaleKey) {
                    let _ = scalesModel.setScaleByRootAndType(
                        scaleRoot: scale.scaleRoot,
                        scaleType: scale.scaleType,
                        scaleMotion: scale.scaleMotion,
                        minTempo: scale.minTempo,
                        octaves: scale.octaves,
                        hands: scale.hands,
                        dynamicTypes: scale.dynamicTypes,
                        articulationTypes: scale.articulationTypes,
                        scaleCustomisation: scale.scaleCustomisation,
                        callback: compareStaff
                    )
                }
                else {
                    totalMissingCnt += 1
                    log("🥵 \(scaleKey) - missing correct version to test against")
                }
                totalProcessedCnt += 1
            }
        }
        
        // Use #expect for assertions instead of XCTFail
        #expect(totalMissingCnt == 0 && totalMismatchedCnt == 0,
                "🥵🥵🥵 Mismatched:\(totalMismatchedCnt) Missing:\(totalMissingCnt) Processed:\(totalProcessedCnt) Matched:\(totalMatchedCnt)")
        
        if totalMissingCnt == 0 && totalMismatchedCnt == 0 {
            log("✅✅✅✅✅✅ Processed:\(totalProcessedCnt) Matched:\(totalMatchedCnt)")
        }
    }
    
    @Test("Trinity All Grades")
    func testTrinityGrade3CKey() async throws {
        let musicBoard = MusicBoard(name: "Trinity", fullName: "Trinity College London", imageName: "trinity")
        try await processBoard(
            musicBoard: musicBoard,
            gradeFilter: [],
            keyFilter: [],
            typeFilter: []
        )
    }
}
