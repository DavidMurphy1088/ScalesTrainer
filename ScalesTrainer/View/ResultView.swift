import SwiftUI

struct ResultView: View {
    let parentScore:Score
    let spacingVertical:CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 0 : UIScreen.main.bounds.size.height * 0.02

    let scalesModel = ScalesModel.shared
    let callback: (_ retry:Bool) -> Void
    
    @State var score:Score?
    enum Section: String, CaseIterable {
        case overview = "Rhythm Accuracy"
        case details = "Dynamics Accuracy"
        case settings = "Articulation Accuracy"
    }

    @State private var selectedSection: Section = .overview
    
    private func openWebPage(urlString: String) {
        guard let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }

    struct ScaleSubmission: Codable {
        let student: String
        let scale: String
        let score: Int
        let timestamp: TimeInterval
    }

    func submitScaleScore() {
        // 1. Replace with your actual Cloud Run URL
        guard let url = URL(string: "https://fastapi-leaderboard-867324319098.us-central1.run.app/submit") else {
            print("Invalid URL")
            return
        }

        // 2. Create a sample submission
        let submission = ScaleSubmission(
            student: "David Murphy",
            scale: "C Major HT",
            score: Int.random(in: 80...99),
            timestamp: Date().timeIntervalSince1970
        )

        // 3. Prepare JSON body
        guard let jsonData = try? JSONEncoder().encode(submission) else {
            print("Failed to encode JSON")
            return
        }

        // 4. Create POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // 5. Send request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error:", error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("No HTTP response")
                return
            }

            if httpResponse.statusCode == 200 {
                print("✅ Submission successful")
            } else {
                print("❌ Submission failed: \(httpResponse.statusCode)")
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response body:", responseString)
            }
        }

        task.resume()
    }

    /// Uploads a string (HTML content) to a Google Cloud Storage signed URL
    func uploadToSignedURL(signedURLString: String, htmlContent: String) {
        guard let url = URL(string: signedURLString) else {
            print("Invalid signed URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("text/html", forHTTPHeaderField: "Content-Type")
        request.httpBody = htmlContent.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Upload complete. Status code: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
            }
        }

        task.resume()
    }

    var body: some View {
        VStack {
            Text("Results").font(.title)
            HStack {
                Text("Score B+").font(.title2)
                Text("Tempo ♩=80").font(.title2)
            }

            VStack(spacing: 0) {
                // Title Bar
                HStack(spacing: 0) {
                    ForEach(Section.allCases, id: \.self) { section in
                        Button(action: {
                            selectedSection = section
                        }) {
                            Text(section.rawValue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedSection == section ? Color.blue.opacity(0.2) : Color.clear)
                                .border(Color.gray)
                        }
                    }
                }
                .background(Color.gray.opacity(0.1))
                .border(Color.gray)
                .padding()
                
                ZStack {
                    switch selectedSection {
                    case .overview:
                        VStack {
                            if let score = score {
                                VStack(spacing: 0) {
                                    if scalesModel.showStaff {
                                        ScoreView(scale: ScalesModel.shared.scale, score: score, showResults: true)
                                        HStack {
                                            VStack {
                                                HStack {
                                                    Text("   ←").foregroundColor(.red).bold().padding(.horizontal, 0)
                                                    Text("♩  Ahead  ").padding(.horizontal, 0)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                HStack {
                                                    Text("   →").foregroundColor(.red).bold().padding(.horizontal, 0)
                                                    Text("♩  Late  ").padding(.horizontal, 0)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            //.outlinedStyleView()
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.bottom, spacingVertical)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        //.background(Color.yellow.opacity(0.3))
                    case .details:
                        Text("Details Content")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.green.opacity(0.3))
                    case .settings:
                        Text("Settings Content")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.orange.opacity(0.3))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.black)
                .padding()
            }
            
            HStack {
                Spacer()
                Image("leaderboard")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                VStack {
                    HStack {
                        Button("Leader Board") {
                            openWebPage(urlString: "https://www.musicmastereducation.co.nz/ScalesAcademy/leaderboard2.html")
                        }
                        .font(.title)
                        Spacer()
                    }
                    HStack {
                        Button("Add Me To The Leader Board") {
                            submitScaleScore()
                        }
                        .font(.title)
                        Spacer()
                    }
                }
                Spacer()
                
            }
            Button("OK") {
                callback(false)
            }
            .font(.title)
            .padding()

        }
        .background(Color.white.opacity(1.0))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.blue, lineWidth: 3))
        .shadow(radius: 10)
        .onAppear {
            //if let parentScore = parentScore {
                self.score = parentScore
                //Score(scale: parentScore.getScale(), key: parentScore.key, timeSignature: parentScore.timeSignature, linesPerStaff: 5, debugOn: false)
                MIDIManager.shared.matchedNotes.applyToScore(score: score!)
            //}
        }
        .onDisappear() {
            MIDIManager.shared.matchedNotes.resetScore(score: score!)
        }
    }
}
