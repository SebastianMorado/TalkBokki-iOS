//
//  FirestoreManagerForContactDetail.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManagerForContactDetail {
    
    let db = Firestore.firestore()
    var delegate : ContactDetailViewController?
    
    func editNewNameinDatabase(newName : String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(delegate!.selectedContact!.email)
            .getDocument { document, error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        self.delegate?.nameLabel.text = newName
                    }
                    self.delegate?.selectedContact?.name = newName
                    document?.reference.updateData(["name" : newName])
                }
            }
        
    }
    
    func deleteFriendFromMyContact() {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(delegate!.selectedContact!.email)
            .delete { error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    self.deleteMyContactFromFriend()
                }
            }
    }
    
    private func deleteMyContactFromFriend() {
        db.collection(K.FStore.usersCollection)
            .document(delegate!.selectedContact!.email)
            .collection(K.FStore.contactsCollection)
            .document(Auth.auth().currentUser!.email!)
            .delete { error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    self.delegate?.dismissAfterBlocking()
                }
            }
    }
    
}
