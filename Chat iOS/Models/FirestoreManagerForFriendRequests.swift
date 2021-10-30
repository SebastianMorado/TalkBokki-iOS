//
//  FirestoreManagerForFriendRequests.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManagerForFriendRequests {
    
    let db = Firestore.firestore()
    var delegate : FriendRequestsTableViewController?
    
    var friendReqList = [FriendRequest]()
    
    func loadFriendRequests() {
        let snapshot = db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.friendRequestCollection)
            .order(by: "date", descending: false)
            .addSnapshotListener { querySnapshot, error in
                self.friendReqList = [FriendRequest]()
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    for doc in querySnapshot!.documents {
                        let data = doc.data()
                        //extract fields from data
                        
                        //create new FriendRequest object
                        let newFR = FriendRequest()
                        newFR.name = data["name"] as! String
                        newFR.email = doc.documentID
                        newFR.number = data["phone_number"] as! String
                        newFR.profilePicture = data["profile_picture"] as! String
                        newFR.date = (data["date"] as! Timestamp).dateValue()
                        self.friendReqList.append(newFR)
                        
                        DispatchQueue.main.async {
                            self.delegate?.tableView.reloadData()
                        }
                    }
                    
                }

            }
        SnapshotListeners.shared.snapshotList.append(snapshot)
    }
    
    func deleteFriendRequest(email: String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.friendRequestCollection)
            .document(email)
            .delete() { error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    UIApplication.getPresentedViewController()?.presentAlert(message: "Successfully Deleted Friend Request", title: "Success!")
                }
            }
    }
    
    func addToContacts_User(email: String, rowIndex: Int) {
        //put friend into current user's contact list
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(email)
            .setData([
                        "name": self.friendReqList[rowIndex].name,
                        "phone_number": self.friendReqList[rowIndex].number,
                        "chat_color": K.chatColors[0],
                        "isMuted": false,
                        "profile_picture": self.friendReqList[rowIndex].profilePicture],
                     merge: true
            ){ (error) in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    UIApplication.getPresentedViewController()?.presentAlert(message: "Friend Request Accepted", title: "Success!")
                    
                }
            }
        
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .getDocument { document, error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    if let data = document?.data()! {
                        let name = data["name"] as! String
                        let imageURL = data["profile_picture"] as! String
                        let phone = data["phone_number"] as! String
                        self.addToContacts_Friend(friendEmail: email, name: name, profilePicture: imageURL, number: phone)
                    }
                    self.deleteFriendRequest(email: email)
                }
            }
    }
    
    private func addToContacts_Friend(friendEmail: String, name: String, profilePicture: String, number: String) {
        //put current user into friend's contact list
        
        db.collection(K.FStore.usersCollection)
            .document(friendEmail)
            .collection(K.FStore.contactsCollection)
            .document(Auth.auth().currentUser!.email!)
            .setData([
                        "name": name,
                        "phone_number": number,
                        "isMuted": false,
                        "profile_picture": profilePicture],
                     merge: true
            ){ (error) in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                }
            }
    }
    
}
