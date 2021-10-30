//
//  FirestoreManagerForContacts.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManagerForContacts {
    
    let db = Firestore.firestore()
    var delegate : ContactsTableViewController?
    
    var contactDictionary = [String: [Contact]]()
    var contactLetters = [String]()

    var filteredDictionary = [String: [Contact]]()
    var filteredLetters = [String]()
    
    //MARK: - Load All Contacts
    
    func loadContacts() {
        let snapshot = db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .order(by: "name")
            .addSnapshotListener { querySnapshot, error in
                self.contactDictionary = [String: [Contact]]()
                self.contactLetters = [String]()
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    for doc in querySnapshot!.documents {
                        let data = doc.data()
                        
                        
                        //create new contact object
                        let newContact = Contact()
                        //extract fields from data
                        let contactName = data["name"] as? String ?? ""
                        newContact.name = contactName
                        newContact.email = doc.documentID
                        newContact.number = data["phone_number"] as? String ?? ""
                        newContact.profilePicture = data["profile_picture"] as? String ?? ""
                        newContact.color = data["chat_color"] as? String ?? ""
                        newContact.fcmToken = data["fcmToken"] as? String ?? ""
                        newContact.isMuted = data["isMuted"] as? Bool ?? false
                        self.checkForUpdates(contact: newContact)
                        //
                        let firstLetter = String(contactName.first!).uppercased()
                        if !self.contactLetters.contains(firstLetter) {
                            self.contactLetters.append(firstLetter)
                        }
                        if self.contactDictionary[firstLetter] != nil {
                            self.contactDictionary[firstLetter]?.append(newContact)
                        } else {
                            self.contactDictionary[firstLetter] = [newContact]
                        }
                        
                    }
                    DispatchQueue.main.async {
                        self.filteredLetters = self.contactLetters
                        self.filteredDictionary = self.contactDictionary
                        self.delegate?.tableView.reloadData()
                    }
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
                        if imageURL != contact.profilePicture || phone != contact.number || token != contact.fcmToken || contact.color == ""  {
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
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
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
    
    //MARK: - Friend Request Functionality
    
    func getPersonalData(email: String) {
        if let myEmail = Auth.auth().currentUser?.email {
            db.collection(K.FStore.usersCollection)
                .document(myEmail)
                .getDocument { document, error in
                    if let e = error {
                        UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                    } else {
                        if let data = document?.data()! {
                            let imageURL = data["profile_picture"] as! String
                            let name = data["name"] as! String
                            let number = data["phone_number"] as! String
                            self.checkIfUserExists(email: email, imgURL: imageURL, name: name, number: number)
                        }
                    }
                }
        }
    }
    
    private func checkIfUserExists(email: String, imgURL: String, name: String, number: String) {
        db.collection(K.FStore.usersCollection)
            .document(email)
            .getDocument { document, error in
                if let doc = document, doc.exists {
                    self.checkIfYouAreAlreadyFriends(email: email, imgURL: imgURL, name: name, number: number)
                } else if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    UIApplication.getPresentedViewController()?.presentAlert(message: "There is no account registered under \(email)")
                }
            }
    }
    
    private func checkIfYouAreAlreadyFriends(email: String, imgURL: String, name: String, number: String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(email)
            .getDocument { document, error in
                if let doc = document, doc.exists {
                    UIApplication.getPresentedViewController()?.presentAlert(message: "You are already friends!")
                } else if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    self.sendFriendRequest(email: email, imgURL: imgURL, name: name, number: number)
                }
            }
    }
    
    private func sendFriendRequest(email: String, imgURL: String, name: String, number: String) {
        let currentTimestamp = Timestamp.init(date: Date())
        
        if let myEmail = Auth.auth().currentUser?.email {
            //save it to current users database
            db.collection(K.FStore.usersCollection)
                .document(email)
                .collection(K.FStore.friendRequestCollection)
                .document(myEmail)
                .setData([
                            "name": name,
                            K.FStore.dateField: currentTimestamp,
                            "phone_number": number,
                            "profile_picture": imgURL],
                         merge: true
                ) { (error) in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    UIApplication.getPresentedViewController()?.presentAlert(message: "Friend Request Sent!", title: "Success!")
                }
                    
            }
        }
    }

}
