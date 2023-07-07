//
//  MailView.swift
//  Study Sets
//
//  Created by Richard Witherspoon on 7/28/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import MessageUI


public struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    
    let recipients: [String]?
    let ccRecipients: [String]?
    let bccRecipients: [String]?
    let preferredSendingEmailAddress: String?
    let subject: String?
    let message: Message?
    let attachments: [Attachment]?
    let result: (Result<MFMailComposeResult, Error>)->Void
    
    public struct Message {
        let message: String
        let isHTML: Bool
        
        public init(message: String, isHTML: Bool) {
            self.message = message
            self.isHTML = isHTML
        }
    }
    
    public struct Attachment {
        let data: Data
        let mimeType: String
        let fileName: String
        
        public init(data: Data, mimeType: String, fileName: String) {
            self.data = data
            self.mimeType = mimeType
            self.fileName = fileName
        }
    }
    
    public init(
        recipients: [String]?,
        ccRecipients: [String]? = nil,
        bccRecipients: [String]? = nil,
        preferredSendingEmailAddress: String? = nil,
        subject: String?,
        message: Message?,
        attachments: [Attachment]?,
        result: @escaping (Result<MFMailComposeResult, Error>)->Void
    ){
        self.recipients = recipients
        self.ccRecipients = ccRecipients
        self.bccRecipients = bccRecipients
        self.preferredSendingEmailAddress = preferredSendingEmailAddress
        self.subject = subject
        self.message = message
        self.attachments = attachments
        self.result = result
    }
    
    
    public final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        var result: (Result<MFMailComposeResult, Error>)->Void
        
        init(presentation: Binding<PresentationMode>,
             result: @escaping (Result<MFMailComposeResult, Error>)->Void){
            _presentation = presentation
            self.result = result
        }
        
        public func mailComposeController(_ controller: MFMailComposeViewController,
                                          didFinishWith result: MFMailComposeResult,
                                          error: Error?) {
            defer {
                $presentation.wrappedValue.dismiss()
            }
            
            if let error {
                self.result(.failure(error))
            } else {
                self.result(.success(result))
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation, result: result)
    }
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setCcRecipients(ccRecipients)
        vc.setBccRecipients(bccRecipients)
        
        if let subject {
            vc.setSubject(subject)
        }
        
        if let preferredSendingEmailAddress {
            vc.setPreferredSendingEmailAddress(preferredSendingEmailAddress)
        }
        
        if let message {
            vc.setMessageBody(message.message, isHTML: message.isHTML)
        }
        
        if let attachments {
            for attachment in attachments {
                vc.addAttachmentData(attachment.data,
                                     mimeType: attachment.mimeType,
                                     fileName: attachment.fileName)
            }
        }
        
        return vc
    }
    
    public func updateUIViewController(
        _ uiViewController: MFMailComposeViewController,
        context: UIViewControllerRepresentableContext<MailView>
    ) { }
}


//struct MailView_Previews: PreviewProvider {
//    static var previews: some View {
//        MailView(recipients: nil,
//                 subject: "Feedback",
//                 message: nil,
//                 attachments: nil){ result in
//            
//        }
//    }
//}
