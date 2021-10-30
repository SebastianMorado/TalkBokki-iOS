//
//  FirestoreManagerForMessagePreview.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManagerForMessagePreview {
    
    let db = Firestore.firestore()
    
    var delegate : MessagePreviewTableViewController?
    
    var chats = [String: Contact]()
    var chatsMostRecent = [String]()
    var filteredChats = [String: Contact]()
    var filteredChatsMostRecent = [String]()
    
    func loadContacts() {
        let group = DispatchGroup()
        
        let snapshot = db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .order(by: "most_recent_message", descending: true)
            .addSnapshotListener { querySnapshot, error in
                group.enter()
                self.chats = [String: Contact]()
                self.chatsMostRecent = [String]()
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    for doc in querySnapshot!.documents {
                        let data = doc.data()

                        //extract fields from data and create new contact object
                        let newContact = Contact()
                        newContact.name = data["name"] as? String ?? ""
                        newContact.number = data["phone_number"] as? String ?? ""
                        newContact.color = data["chat_color"] as? String ?? ""
                        newContact.fcmToken = data["fcmToken"] as? String ?? ""
                        newContact.email = doc.documentID
                        newContact.profilePicture = data["profile_picture"] as? String ?? ""
                        newContact.isMuted = data["isMuted"] as? Bool ?? false
                        newContact.mostRecentMessage = (data["most_recent_message"] as! Timestamp).dateValue()
                        print("\(newContact.name): isMuted:\(newContact.isMuted)")
                        self.checkForUpdates(contact: newContact)
                        self.chats[doc.documentID] = newContact
                        self.chatsMostRecent.append(doc.documentID)
                    }
                    
                }
                group.leave()
                
                
                group.notify(queue: DispatchQueue.global()) {
                    self.loadMessages()
                }
            }
        
        SnapshotListeners.shared.snapshotList.append(snapshot)
        
        
    }
    
    private func checkForUpdates(contact: Contact) {
        db.collection(K.FStore.usersCollection)
            .document(contact.email)
            .getDocument { document, error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    if let data = document?.data()! {
                        let imageURL = data["profile_picture"] as? String ?? ""
                        let phone = data["phone_number"] as? String ?? ""
                        let token = data["fcmToken"] as? String ?? ""
                        if imageURL != contact.profilePicture || phone != contact.number || token != contact.fcmToken || contact.color == "" {
                            contact.profilePicture = imageURL
                            contact.number = phone
                            contact.fcmToken = token
                            self.updateContact(contact: contact)
                        }
                        
                    }
                }
            }
    }
    
    private func updateContact(contact: Contact) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(contact.email)
            .getDocument { document, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    document?.reference.updateData(["profile_picture" : contact.profilePicture])
                    document?.reference.updateData(["phone_number" : contact.number])
                    document?.reference.updateData(["fcmToken" : contact.fcmToken])
                    if contact.color == "" {
                        document?.reference.updateData(["chat_color" : K.chatColors[0]])
                    }
                }
            }
    }
    
    func loadMessages() {
        let group = DispatchGroup()
        
        for (contactEmail, _) in chats {
            group.enter()
            db.collection(K.FStore.usersCollection)
                .document(Auth.auth().currentUser!.email!)
                .collection(K.FStore.contactsCollection)
                .document(contactEmail)
                .collection(K.FStore.messagesCollection)
                .order(by: "date", descending: true)
                .limit(to: 1)
                .getDocuments { querySnapshot, error in
                    
                    if let e = error {
                        print(e.localizedDescription)
                    } else {
                        let mostRecentMessage = querySnapshot!.documents[0].data()
                        let newMessage = Message()
                        newMessage.text = mostRecentMessage["text"] as! String
                        newMessage.imageURL = mostRecentMessage["image_url"] as! String
                        newMessage.senderEmail = mostRecentMessage["sender_email"] as! String
                        newMessage.wasRead = mostRecentMessage["wasRead"] as! Bool
                        newMessage.date = (mostRecentMessage["date"] as! Timestamp).dateValue()
                        
                        self.chats[contactEmail]?.messages = [newMessage]
                        
                    }
                    group.leave()
            }
        }
        group.notify(queue: DispatchQueue.global()) {
            print("reloading data now...")
            DispatchQueue.main.async {
                
                self.filteredChats = self.chats
                self.filteredChatsMostRecent = self.chatsMostRecent
                
                self.delegate?.tableView.reloadData()
                self.delegate?.refresh.endRefreshing()
            }
        }
    }
    
}
