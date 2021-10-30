//
//  FirestoreManagerForCreateNewMessage.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManagerForCreateNewMessage {
    
    let db = Firestore.firestore()
    var delegate : NewMessageTableViewController?
    
    var contactList = [Contact]()
    var filteredContactList = [Contact]()
    
    func loadContacts() {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .order(by: "name")
            .getDocuments { querySnapshot, error in
                self.contactList = []
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    for doc in querySnapshot!.documents {
                        let data = doc.data()
                        
                        //create new contact object
                        let newContact = Contact()
                        //extract fields from data
                        let contactName = data["name"] as! String
                        newContact.name = contactName
                        newContact.email = doc.documentID
                        newContact.number = data["phone_number"] as! String
                        newContact.profilePicture = data["profile_picture"] as! String
                        self.contactList.append(newContact)
                    }
                    DispatchQueue.main.async {
                        self.filteredContactList = self.contactList
                        self.delegate?.tableView.reloadData()
                    }
                }
            }
    }
}

