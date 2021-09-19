//
//  ChatViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class MessageViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    @IBOutlet weak var viewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var friendImage: UIImageView!
    
    let db = Firestore.firestore()
    private var imagePicker = UIImagePickerController()
    
    var messages : [Message] = []
    
    var selectedContact : Contact?
    
    //variable to store the image message that is tapped
    var selectedImage : UIImage?
    
    private var tabBarHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if selectedContact == nil {
            dismiss(animated: true, completion: nil)
        }
        
        title = selectedContact!.name
        
        friendImage.kf.setImage(
            with: URL(string: selectedContact!.profilePicture),
            options: [
                .processor(DownsamplingImageProcessor(size: friendImage.bounds.size)),
                .loadDiskFileSynchronously,
                .cacheOriginalImage,
                .transition(.fade(0.25))
            ]
        )
        friendImage.setRounded()
        
        imagePicker.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        messageTextfield.delegate = self
        
        tabBarHeight = tabBarController?.tabBar.frame.size.height
        
        
        tableView.register(UINib(nibName: K.cellNibName1, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        tableView.register(UINib(nibName: K.imageCellNibName, bundle: nil), forCellReuseIdentifier: K.imageCellIdentifier)
        loadMessages()
    }
    
    func loadMessages() {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(selectedContact!.email)
            .collection(K.FStore.messagesCollection)
            .order(by: "date", descending: false)
            .addSnapshotListener { querySnapshot, error in
                self.messages = []
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    for doc in querySnapshot!.documents {
                        let data = doc.data()
                        let newMessage = Message()
                        newMessage.text = data["text"] as! String
                        newMessage.imageURL = data["image_url"] as! String
                        newMessage.senderEmail = data["sender_email"] as! String
                        newMessage.wasRead = data["wasRead"] as! Bool
                        newMessage.date = (data["date"] as! Timestamp).dateValue()
                        self.messages.append(newMessage)
                        
                        
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                    }
                    //update all current messages as read
                    self.readMessages()
                }
            }
    }
    
    func readMessages() {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(selectedContact!.email)
            .collection(K.FStore.messagesCollection)
            .whereField("wasRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    for doc in snapshot!.documents {
                        print("Reading Message!")
                        doc.reference.updateData(["wasRead" : true])
                    }
                }
            }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        addMessageData(imageURL: nil)
    }
    
    func addMessageData(imageURL: String?){
        let currentTimestamp = Timestamp.init(date: Date())
        var messageText = messageTextfield.text
        
        if imageURL == nil && (messageText == nil || messageText == "") {
            return
        } else if imageURL != nil {
            messageText = "image"
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
                                K.FStore.textField: messageText ?? "image",
                                K.FStore.dateField: currentTimestamp,
                                K.FStore.imageField: imageURL ?? "",
                                K.FStore.wasReadField: true]) { (error) in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
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
                        self.presentAlert(message: e.localizedDescription)
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
                                K.FStore.imageField: imageURL ?? "",
                                K.FStore.wasReadField: false]) { (error) in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
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
                        self.presentAlert(message: e.localizedDescription)
                    } else {
                        document?.reference.updateData(["most_recent_message" : currentTimestamp])
                    }
                }
        }
        if imageURL == nil {
            messageTextfield.text = ""
        }
    }
    
    @IBAction func tapFriendImage(_ sender: UITapGestureRecognizer) {
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
                self.addMessageData(imageURL: url!.absoluteString)
                print("Successfuly uploaded image!")
            })
        }
    }
    
    @IBAction func pressCamera(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera() }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery() }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    func presentAlert(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
}

//MARK: - UITableViewDataSource

extension MessageViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier)
        cell?.imageView?.kf.cancelDownloadTask()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        //text message
        if message.imageURL == "" {
            let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
            
            //Format message from current user
            if message.senderEmail == Auth.auth().currentUser?.email {
                cell.label2.text = message.text
                setSenderImage(of: cell, fromSelf: true)
            } else {
                cell.label.text = message.text
                setSenderImage(of: cell, fromSelf: false)
            }
            
            return cell
        //image message
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: K.imageCellIdentifier, for: indexPath) as! ImageTableViewCell
            cell.imageBox.kf.indicatorType = .activity
            cell.imageBox.kf.setImage(
                with: URL(string: message.imageURL),
                options: [
                    .processor(RoundCornerImageProcessor(cornerRadius: 20)),
                    .loadDiskFileSynchronously,
                    .cacheOriginalImage,
                    .transition(.fade(0.25))
                ]
            )
            //Format message from current user
            if message.senderEmail == Auth.auth().currentUser?.email {
                //setSenderImage(of: cell, fromSelf: true)
            } else {
                //setSenderImage(of: cell, fromSelf: false)
            }
            let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(sender:)))
            cell.imageBox.addGestureRecognizer(imageTapGesture)
            
            return cell
        }
        
    }
    
    private func setSenderImage(of cell: hasLeftAndRightPictures, fromSelf: Bool) {
        if fromSelf {
            let url = URL(string: UserDefaults.standard.string(forKey: K.UDefaults.userURL)!)
            cell.rightImageView.kf.setImage(
                with: url,
                options: [
                    .loadDiskFileSynchronously,
                    .transition(.fade(0.25))
                ]
            )
            cell.label.isHidden = true
            cell.label2.layer.cornerRadius = cell.label2.frame.size.height / 5
            cell.label2.textColor = UIColor(named: K.BrandColors.purple)
            cell.label2.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
        } else {
            let url = URL(string: selectedContact!.profilePicture)
            cell.leftImageView.kf.setImage(
                with: url,
                options: [
                    .loadDiskFileSynchronously,
                    .transition(.fade(0.25))
                ]
            )
            cell.label2.isHidden = true
            cell.label.layer.cornerRadius = cell.label.frame.size.height / 5
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.backgroundColor = UIColor(named: K.BrandColors.purple)
        }
        cell.setRoundedImage()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToImageDetail" {
            let destinationVC = segue.destination as! ImageDetailViewController
            destinationVC.imageToBeDisplayed = self.selectedImage
        }
    }
    
    @objc private func imageTapped(sender: UITapGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        self.selectedImage = imageView.image
        self.performSegue(withIdentifier: "goToImageDetail", sender: self)
    }

}

//MARK: - Image Picker Delegate

extension MessageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userImage = info[.originalImage] as? UIImage {
            print("uploading image...")
            uploadImagePic(image: userImage)
        }
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have a camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}

// MARK: - UITextFieldDelegate
extension MessageViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let safeTabBarHeight = tabBarHeight {
            viewBottomConstraint.constant -= safeTabBarHeight
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if let safeTabBarHeight = tabBarHeight {
            viewBottomConstraint.constant += safeTabBarHeight
        }
    }
    
}