import SwiftUI
import MessageUI

struct FeatureReportMailView: UIViewControllerRepresentable {
    var subject: String
    var body: String
    var recipientEmail: String

    @Environment(\.presentationMode) var presentationMode
    @Binding var isShowing: Bool
    @Binding var mailResult: String // New binding for the result status

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

struct FeatureReportView: View {
    @State private var isShowingMailView = false
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
    var body: some View {
        VStack(spacing: 20) {
            Button("Send us a message about an issue or a new feature") {
                isShowingMailView = true
            }
            .sheet(isPresented: $isShowingMailView) {
                FeatureReportMailView(
                    subject: "Scales Academy Report",
                    body: mailText,
                    recipientEmail: "sales@musicmastereducation.co.nz",
                    //recipientEmail: "davidmurphy1088@gmail.com",
                    isShowing: $isShowingMailView,
                    mailResult: $mailResult // Pass the mail result binding
                )
            }
            
            Text(mailResult) // Display the result of sending the mail
                .padding()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
