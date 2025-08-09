
import SwiftUI
import MessageUI
import UniformTypeIdentifiers
import Combine

// `import Messages` framework required if
// the app has an iMessage app extension, and we want to display our iMessage app within the message compose view
import Messages

extension Notification.Name {
    var publisher: NotificationCenter.Publisher {
        return NotificationCenter.default.publisher(for: self)
    }
}

extension MessageComposeResult {
    var description: String {
        switch self {
        case .cancelled:
            return "Cancelled"
        case .failed:
            return "Failed"
        case .sent:
            return "Sent"
        @unknown default:
            return "I don't know what is going on ..."
        }
    }
}


struct SendMessage: View {

    @State private var showMessageComposer: Bool = false
    @State private var sendingResult: MessageComposeResult? = nil
    @State private var cancellable: AnyCancellable? = nil
    @State private var canSendText = MFMessageComposeViewController.canSendText()

    var body: some View {
        NavigationStack {
            VStack(spacing: 36) {
                if self.canSendText {
                    Button(action: {
                        guard self.canSendText else { return }
                        self.showMessageComposer = true
                    }, label: {
                        Text("Send Message")
                    })
                    .buttonStyle(.glassProminent)
                    
                    if let sendingResult = self.sendingResult {
                        VStack(spacing: 16) {
                            Text("Message Sending Result")
                            
                            Text(sendingResult.description)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                                        self.sendingResult = nil
                                    })
                                }

                        }
                    }
                    
                } else {
                    ContentUnavailableView("Message Not Available", systemImage: "exclamationmark.message.fill", description: Text("Are you running on simulator?"))
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.yellow.opacity(0.1))
            .navigationTitle("Send Message")
            .sheet(isPresented: $showMessageComposer, content: {
                MessageComposeController(isPresented: $showMessageComposer, result: $sendingResult)
            })
            .onAppear {
                self.cancellable = Notification.Name.MFMessageComposeViewControllerTextMessageAvailabilityDidChange.publisher.receive(
                    on: DispatchQueue.main
                ).sink { notification in
                    // we can also retrieve the value using the MFMessageComposeViewControllerTextMessageAvailabilityKey included in The userInfo dictionary
                    // The value of this key is an NSNumber object that contains a Boolean value and matches the result of the canSendText() class method.
                    self.canSendText = MFMessageComposeViewController.canSendText()
                }

            }
        }
    }
}


struct MessageComposeController: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var result: MessageComposeResult?
    
    // initial contents of a message
    // properties cannot be changed after displaying
    var subject: String? = "Hello!"
    var recipients: [String]? = ["itsuki.enjoy@gmail.com"]
    var body: String? = "Hello from Itsuki!"
    // If the app has an iMessage app extension, we can display our iMessage app within the message compose view, just as we would in the Messages app.
    // To display the iMessage app, create and assign an MSMessage object to this property.
    // `import Messages` framework required.
    var messages: MSMessage? = nil
    
    // Disables the camera/attachment button in the message composition view.
    var disableUserAttachments: Bool = false
        
    // (Data, uti, fileName)
    var attachmentData: [(Data, String, String)] = [(UIImage(systemName: "heart.fill")!.pngData()!, UTType.png.identifier, "heart.png")]
    
    typealias UIViewControllerType = MFMessageComposeViewController

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        
        if MFMessageComposeViewController.canSendSubject() {
            controller.subject = self.subject
        }
        controller.recipients = self.recipients
        if MFMessageComposeViewController.canSendText() {
            controller.body = self.body
        }
        controller.message = self.messages
        
        if self.disableUserAttachments {
            controller.disableUserAttachments()
        }

        if MFMessageComposeViewController.canSendAttachments() {
            for attachment in self.attachmentData {
                if MFMessageComposeViewController.isSupportedAttachmentUTI(attachment.1) {
                    controller.addAttachmentData(attachment.0, typeIdentifier: attachment.1, filename: attachment.2)
                }
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
    

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeController
        init(_ parent: MessageComposeController) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            print(#function)
            print("Result: \(String(describing: result))")
            
            DispatchQueue.main.async {
                self.parent.result = result
                self.parent.isPresented = false
            }
        }
        
    }
}

