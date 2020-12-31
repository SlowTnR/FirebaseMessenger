//
//  ChatViewController.swift
//  FirebaseMessenger
//
//  Created by Ilja Patrushev on 24.12.2020.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
        
    }()
    
    public var isNewConversation = false
    public let otherUserEmail:String
    private let conversationId: String?
    
    private var messages = [Message]()
    
    private var selfSender: Sender?  {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
        
        
    }
    

    
    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        
      
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        view.backgroundColor = .lightGray
        
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
      
        
    }
    
    private func listenForMessages(id: String, shoudScrollToBottom: Bool){
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: {[weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    
                    return
                }
                
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shoudScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                   
                }
                
            case .failure(let error):
                print("Failed to fetch messages: \(error)")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shoudScrollToBottom: true)
        }
    }
    
    
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        print("Sending  \(text)")
        
        let message = Message(sender: selfSender, messageId:messageId, sentDate: Date(), kind: .text(text))
        
        // send meessage
        if isNewConversation {
            // create convo in database
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: {[weak self] success in
                if success {
                    print("Message sent")
                    self?.isNewConversation = false
                }
                else {
                    print("Failed to send ")
                }
            })
        }
        else {
            guard let conversationId = conversationId,
                  let name = self.title else {
                return
            }
            
            // append to existing conversation data
            DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: otherUserEmail,  newMessage: message, completion: {success in
                if success {
                    print("Message sent")
                    
                    
                }
                else {
                    print("Failed to send message")
                }
            })
        }
    }
    
    private func createMessageId() -> String?{
        // date, otherUsersEmail, senderEmail, random int
        
       
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("Created message id: \(newIdentifier)")
        
        return newIdentifier
        
        
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email should be cacheed")
       // return Sender(photoURL: "", senderId: "123", displayName: "Dummy Sender")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    
}
