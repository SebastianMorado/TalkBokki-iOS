//
//  FirestoreManagerForMessage.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManagerForMessage {
    
    let db = Firestore.firestore()
    var delegate : MessageViewController?
    var selectedContact : Contact?
    let sender = PushNotificationSender()
    
    var messages : [Message] = []
    var currentRowLimit: Int = 20
    var isMuted: Bool?
    
    func checkIfMuted() {
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
                            DispatchQueue.main.async {
                                self.isMuted = isMuted
                            }
                        }
                    }
                }
            }
    }
    
    func configureSnapshotListener() {
        let snapShot = db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(selectedContact!.email)
            .collection(K.FStore.messagesCollection)
            .addSnapshotListener { querySnapshot, error in
                self.loadMessages(currentRowLimit: self.currentRowLimit, scrollTo: nil)
            }
        SnapshotListeners.shared.snapshotList.append(snapShot)
    }
    
    func loadMessages(currentRowLimit: Int, scrollTo: Int?) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(selectedContact!.email)
            .collection(K.FStore.messagesCollection)
            .order(by: "date", descending: true)
            .limit(to: currentRowLimit)
            .getDocuments { querySnapshot, error in
                self.messages = []
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    for doc in querySnapshot!.documents {
                        let data = doc.data()
                        let newMessage = Message()
                        newMessage.text = data["text"] as! String
                        newMessage.imageURL = data["image_url"] as! String
                        newMessage.senderEmail = data["sender_email"] as! String
                        newMessage.wasRead = data["wasRead"] as! Bool
                        newMessage.imageWidth = data[K.FStore.imageWidth] as! CGFloat
                        newMessage.imageHeight = data[K.FStore.imageHeight] as! CGFloat
                        newMessage.date = (data["date"] as! Timestamp).dateValue()
                        self.messages.insert(newMessage, at: 0)
                        //self.messages.append(newMessage)
                        
                        
                    }
                    DispatchQueue.main.async {
                        self.delegate?.tableView.reloadData()
                        let indexPath = IndexPath(row: scrollTo ?? self.messages.count - 1, section: 0)
                        if indexPath.row >= 0 {
                            self.delegate?.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                        }
                    }
                    //update all current messages as read
                    self.readMessages()
                }
            }
        self.delegate?.refresh.endRefreshing()
    }
    
    private func readMessages() {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(selectedContact!.email)
            .collection(K.FStore.messagesCollection)
            .whereField("wasRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    for doc in snapshot!.documents {
                        doc.reference.updateData(["wasRead" : true])
                    }
                }
            }
    }
    
    func addMessageData(imageData: [String: Any]?, messageText: String?){
        let currentTimestamp = Timestamp.init(date: Date())
        
        currentRowLimit += 1
        
        if imageData == nil && (messageText == nil || messageText == "") {
            return
        }
        
        if let messageSender = Auth.auth().currentUser?.email {
            //save it to current users database
            db.collection(K.FStore.usersCollection)
                .document(messageSender)
                .collection(K.FStore.contactsCollection)
                .document(selectedContact!.email)
                .collection(K.FStore.messagesCollection)
                .addDocument(data: [
                                K.FStore.senderField: messageSender,
                                K.FStore.textField: messageText ?? "",
                                K.FStore.dateField: currentTimestamp,
                                K.FStore.imageField: imageData?["URL"] ?? "",
                                K.FStore.imageWidth: imageData?["width"] ?? 0,
                                K.FStore.imageHeight: imageData?["height"] ?? 0,
                                K.FStore.wasReadField: true]) { (error) in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    print("Successfully saved data to \(messageSender)!")
                }
                    
            }
            db.collection(K.FStore.usersCollection)
                .document(messageSender)
                .collection(K.FStore.contactsCollection)
                .document(selectedContact!.email)
                .getDocument { document, error in
                    if let e = error {
                        UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                    } else {
                        document?.reference.updateData(["most_recent_message" : currentTimestamp])
                    }
                }
            //save it to chatting users database
            db.collection(K.FStore.usersCollection)
                .document(selectedContact!.email)
                .collection(K.FStore.contactsCollection)
                .document(messageSender)
                .collection(K.FStore.messagesCollection)
                .addDocument(data: [
                                K.FStore.senderField: messageSender,
                                K.FStore.textField: messageText ?? "image",
                                K.FStore.dateField: Timestamp.init(date: Date()),
                                K.FStore.imageField: imageData?["URL"] ?? "",
                                K.FStore.imageWidth: imageData?["width"] ?? 0,
                                K.FStore.imageHeight: imageData?["height"] ?? 0,
                                K.FStore.wasReadField: false]) { (error) in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    print("Successfully saved data to \(self.selectedContact!.email)!")
                }
                    
            }
            db.collection(K.FStore.usersCollection)
                .document(selectedContact!.email)
                .collection(K.FStore.contactsCollection)
                .document(messageSender)
                .getDocument { document, error in
                    if let e = error {
                        UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                    } else {
                        document?.reference.updateData(["most_recent_message" : currentTimestamp])
                    }
                }
        }
    
        //send push notif
        if selectedContact!.fcmToken != "", !selectedContact!.isMuted {
            let myName = UserDefaults.standard.string(forKey: K.UDefaults.userName)!
            let myEmail = Auth.auth().currentUser!.email!
            if imageData == nil {
                sender.sendPushNotification(to: selectedContact!.fcmToken, myEmail: myEmail, myName: myName, messageText: messageText!, receiverEmail: selectedContact!.email)
            } else {
                sender.sendPushNotification(to: selectedContact!.fcmToken, myEmail: myEmail, myName: myName, messageText: "[Image]", receiverEmail: selectedContact!.email)
            }
        }
        
    }
    
    func uploadImagePic(image: UIImage) {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: date)

        guard let imageData: Data = image.jpegData(compressionQuality: 0.1) else {
            print("failed to process image")
            return
        }
        
        let imageHeight = image.size.height * image.scale
        let imageWidth = image.size.width * image.scale
        var imageInfo : [String: Any] = ["height": imageHeight, "width" : imageWidth]

        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "image/jpg"

        let storageRef = Storage.storage().reference(withPath: "users/\(Auth.auth().currentUser!.email!)/contacts/\(selectedContact!.email)/messages/\(dateString).jpg")

        storageRef.putData(imageData, metadata: metaDataConfig){ (metaData, error) in
            if let error = error {
                print(error.localizedDescription)

                return
            }

            storageRef.downloadURL(completion: { (url: URL?, error: Error?) in
                if let error = error {
                    print(error.localizedDescription)
                }
                imageInfo["URL"] = url!.absoluteString
                self.addMessageData(imageData: imageInfo, messageText: "")
                print("Successfully uploaded image!")
            })
        }
    }
}
