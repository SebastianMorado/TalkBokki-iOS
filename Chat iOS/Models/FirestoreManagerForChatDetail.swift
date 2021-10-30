//
//  FirestoreManagerForChatDetail.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManagerForChatDetail {
    
    let db = Firestore.firestore()
    var delegate : ChatDetailViewController?
    
    func pressMute() {
        db.collection(K.FStore.usersCollection)
            .document(delegate!.selectedContact!.email)
            .collection(K.FStore.contactsCollection)
            .document(Auth.auth().currentUser!.email!)
            .getDocument { document, error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    if let data = document?.data() {
                        if let isMuted = data["isMuted"] as? Bool {
                            
                            document?.reference.updateData(["isMuted" : !isMuted])
                            self.delegate?.isMuted = !isMuted
                            DispatchQueue.main.async {
                                self.delegate?.updateMuteButton(isMuted: !isMuted)
                            }
                        } else {
                            document?.reference.setData(["isMuted" : false], merge: true)
                        }
                        
                    }
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
                    DispatchQueue.main.async {
                        self.delegate?.dismissAfterBlocking()
                    }
                }
            }
    }
    
    func updateColorDatabase(newColor: String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(delegate!.selectedContact!.email)
            .getDocument { document, error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    document?.reference.updateData(["chat_color" : newColor])
                    self.delegate?.selectedContact?.color = newColor
                    DispatchQueue.main.async {
                        self.delegate?.updateColors(newColor: newColor)
                    }
                }
            }
    }
    
}
