//
//  FriendRequestsTableViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/10/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class FriendRequestsTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    var friendReqList = [FriendRequest]()

    override func viewDidLoad() {
        super.viewDidLoad()

        loadFriendRequests()
    }
    
    private func loadFriendRequests() {
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
                            self.tableView.reloadData()
                        }
                    }
                    
                }

            }
        SnapshotListeners.shared.snapshotList.append(snapshot)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return friendReqList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendRequestCell", for: indexPath) as! FriendRequestCell

        cell.cellEmail.text = friendReqList[indexPath.row].email
        cell.cellName.text = friendReqList[indexPath.row].name
        let url = URL(string: friendReqList[indexPath.row].profilePicture)
        let processor = DownsamplingImageProcessor(size: cell.cellImage.bounds.size)
        cell.cellImage.kf.setImage(
            with: url,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1))
            ])
        cell.setRoundedImage()

        return cell
    }
    
    //MARK: - Table View Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alert = UIAlertController(title: "Accept Friend Request from \(friendReqList[indexPath.row].name)?", message: "", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        let add = UIAlertAction(title: "Add", style: .default) { (action) in
            self.addToContacts_User(email: self.friendReqList[indexPath.row].email, rowIndex: indexPath.row)
        }
        
        let remove = UIAlertAction(title: "Remove", style: .default) { (action) in
            self.deleteFriendRequest(email: self.friendReqList[indexPath.row].email)
        }
        
        alert.addAction(cancel)
        alert.addAction(add)
        alert.addAction(remove)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteFriendRequest(email: String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.friendRequestCollection)
            .document(email)
            .delete() { error in
                if let error = error {
                    self.presentAlert(message: error.localizedDescription)
                } else {
                    self.presentAlert(message: "Successfully Deleted Friend Request", title: "Success!")
                }
            }
    }
    
    private func addToContacts_User(email: String, rowIndex: Int) {
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
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.presentAlert(message: "Friend Request Accepted", title: "Success!")
                    
                }
            }
        
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .getDocument { document, error in
                if let error = error {
                    self.presentAlert(message: error.localizedDescription)
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
                    self.presentAlert(message: e.localizedDescription)
                }
            }
    }
    
    private func presentAlert(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

  

}
