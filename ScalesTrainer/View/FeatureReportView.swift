import SwiftUI
import MessageUI

struct FeatureReportMailView: UIViewControllerRepresentable {
    var subject: String
    var body: String
    var recipientEmail: String
    var attachLogFile:Bool
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var isShowing: Bool
    @Binding var mailResult: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        guard MFMailComposeViewController.canSendMail() else {
            mailResult = "Mail services are not available"
            isShowing = false
            return MFMailComposeViewController() // or handle gracefully
        }
        
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = context.coordinator
        mailComposeVC.setToRecipients([recipientEmail])
        mailComposeVC.setSubject(subject)
        mailComposeVC.setMessageBody(body, isHTML: false)
        if attachLogFile {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                do {
                    let logFileURL = documentsDirectory.appendingPathComponent("app_log.txt")
                    let logFileData = try Data(contentsOf: logFileURL)
                    mailComposeVC.addAttachmentData(logFileData, mimeType: "text/plain", fileName: "app_log.txt")
                } catch {
                    AppLogger.shared.reportError(AppLogger.shared, "Error reading log file to send:\(error)")
                }
            }
        }
        return mailComposeVC
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: FeatureReportMailView

        init(_ parent: FeatureReportMailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.isShowing = false
            switch result {
            case .cancelled:
                parent.mailResult = "Mail was canceled by the user."
            case .saved:
                parent.mailResult = "Mail was saved as a draft."
            case .sent:
                parent.mailResult = "Mail was sent successfully."
            case .failed:
                parent.mailResult = "Mail failed to send. Error: \(error?.localizedDescription ?? "Unknown error")."
            @unknown default:
                parent.mailResult = "An unknown result occurred."
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.parent.isShowing = false
            }
            controller.dismiss(animated: true)
        }
    }
}

struct MailSupportView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Unable to Send Email")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text("It seems your device is not configured to send emails. Here are some steps you can follow to fix this issue:")
                .font(.body)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("1. Check Email Account Configuration")
                    .font(.headline)
                Text("Go to the Settings app, open 'Mail', and ensure you have an email account set up under 'Accounts'.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("2. Enable Email Sending")
                    .font(.headline)
                Text("Ensure your email account supports sending emails and is not restricted (e.g., by parental controls or device management settings).")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("3. Internet Connection")
                    .font(.headline)
                Text("Make sure your device has an active internet connection. Without internet, emails cannot be sent.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("4. Restart the Device")
                    .font(.headline)
                Text("Sometimes, restarting your device can resolve issues related to email configurations.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            Text("If the issue persists, try opening the Mail app and attempting to send an email manually. This can provide additional error messages to help troubleshoot the problem.")
                .font(.body)
                .foregroundColor(.blue)
        }
        .padding()
    }
}

struct FeatureReportView: View {
    @State private var isShowingMailView = false
    @State private var isShowingMailTheLogView = false
    @State private var mailResult = "The mail sent status will appear here."
    let mailText = 
    "This email can be used to report problems or new feature ideas in Scales Academy.\n\n" +
    "⏺ Please ensure that your device can reliably send email.\n\n" +
    "⏺ When reporting an issue please clearly describe:\n" +
    "  - which feature you are using\n" +
    "  - a detailed description of the issue\n" +
    "  - whether the issue always occurs or only in some cases\n\n" +
    "⏺ When suggesting a new feature idea (or a suggested change to an existing feature) please describe the feature or the change required. Also describe why the feature would be valuable to teachers or students.\n\n" +
    "😊 Thanks in advance for your email. We very much appreciate you taking the time to help us with the development of Scales Academy."
    
    func writeLogToFile() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let logFileURL = documentsDirectory.appendingPathComponent("app_log.txt")
        var logContent = "Log file\n\n"
        for line in AppLogger.shared.loggedMsgs {
            logContent += line.getLogEvent() + "\n"
        }
        do {
            try logContent.write(to: logFileURL, atomically: true, encoding: .utf8)
            print("Log successfully written to \(logFileURL.path)")
        } catch {
            print("Failed to write log to file: \(error.localizedDescription)")
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            if MFMailComposeViewController.canSendMail() {
                Button("Send us a message about an issue or a new feature") {
                    isShowingMailView = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .sheet(isPresented: $isShowingMailView) {
                    FeatureReportMailView(
                        subject: "Scales Academy Report",
                        body: mailText,
                        recipientEmail: "sales@musicmastereducation.co.nz",
                        attachLogFile: false,
                        //recipientEmail: "davidmurphy1088@gmail.com",
                        isShowing: $isShowingMailView,
                        mailResult: $mailResult // Pass the mail result binding
                    )
                }
                
                Button("Send us the app's log file") {
                    writeLogToFile()
                    isShowingMailTheLogView = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .sheet(isPresented: $isShowingMailTheLogView) {
                    FeatureReportMailView(
                        subject: "Scales Academy Report Log Attachment",
                        body: mailText,
                        recipientEmail: "davidmurphy1088@gmail.com",
                        attachLogFile: true,
                        isShowing: $isShowingMailTheLogView,
                        mailResult: $mailResult
                    )
                }
                
                Text(mailResult) // Display the result of sending the mail
                    .padding()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            else {
                MailSupportView()
            }

        }
        .padding()
    }
}

