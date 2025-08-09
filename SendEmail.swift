
import SwiftUI
import MessageUI

private extension MFMailComposeResult {
    var description: String {
        switch self {
        case .cancelled:
            return "Cancelled"
        case .failed:
            return "Failed"
        case .saved:
            return "Saved"
        case .sent:
            return "Sent"
            
        @unknown default:
            return "I don't know what is going on ..."
        }
    }
}


struct SendMail: View {
    
    @State private var showMailComposer: Bool = false
    @State private var error: Error? = nil
    @State private var sendingResult: MFMailComposeResult? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 36) {
                if MFMailComposeViewController.canSendMail() {
                    Button(action: {
                        guard MFMailComposeViewController.canSendMail() else { return }
                        self.showMailComposer = true
                    }, label: {
                        Text("Send Email")
                    })
                    .buttonStyle(.glassProminent)
                    
                    if let error  = self.error {
                        Text(String(describing: error.localizedDescription))
                            .foregroundStyle(.red)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                                    self.error = nil
                                })
                            }
                    }
                    
                    if let sendingResult = self.sendingResult {
                        VStack(spacing: 16) {
                            Text("Mail Sending Result")
                            
                            Text(sendingResult.description)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                                        self.sendingResult = nil
                                    })
                                }

                        }
                    }
                    
                } else {
                    ContentUnavailableView("Mail Not Available", systemImage: "envelope.and.hand.raised", description: Text("Are you running on simulator?"))
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.yellow.opacity(0.1))
            .navigationTitle("Send Email")
            .sheet(isPresented: $showMailComposer, content: {
                MailComposeController(error: $error, isPresented: $showMailComposer, result: $sendingResult)
            })
        }
    }
}


private struct MailComposeController: UIViewControllerRepresentable {
    @Binding var error: (any Error)?
    @Binding var isPresented: Bool
    @Binding var result: MFMailComposeResult?
    
    var subject: String = "Hello!"
    var toRecipients: [String]? = ["itsuki.enjoy@gmail.com"]
    var ccRecipients: [String]? = nil
    var bccRecipients: [String]? = nil
    
    // (content, isHTML)
    var messageBody: (String, Bool)? = ("<h1 style=\"color:red;\">Hello from Itsuki!</h1>", true)
    
    // (Data, mimeType, fileName)
    var attachmentData: [(Data, String, String)] = [(UIImage(systemName: "heart.fill")!.pngData()!, "image/png", "heart.png")]

    var preferredSendingEmailAddress: String? = "itsuki.enjoy@gmail.com"
    
    typealias UIViewControllerType = MFMailComposeViewController

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        
        controller.setSubject(self.subject)
        controller.setToRecipients(self.toRecipients)
        controller.setCcRecipients(self.ccRecipients)
        controller.setBccRecipients(self.bccRecipients)
        
        if let messageBody {
            controller.setMessageBody(messageBody.0, isHTML: messageBody.1)
        }
        
        for attachment in self.attachmentData {
            controller.addAttachmentData(attachment.0, mimeType: attachment.1, fileName: attachment.2)
        }
        
        if let preferredSendingEmailAddress {
            controller.setPreferredSendingEmailAddress(preferredSendingEmailAddress)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
    

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposeController
        init(_ parent: MailComposeController) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
            print(#function)
            print("Result: \(String(describing: result))")
            print("Error: \(String(describing: error))")
            
            DispatchQueue.main.async {
                self.parent.error = error
                self.parent.result = result
                self.parent.isPresented = false
            }
        }
    }
}

