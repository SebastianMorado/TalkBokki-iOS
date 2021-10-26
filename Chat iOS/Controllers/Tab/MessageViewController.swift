//
//  MessageViewController.swift
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
    @IBOutlet weak var messageTextfield: UITextView!
    @IBOutlet weak var viewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var textfieldView: UIView!
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var nameViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewHeight: NSLayoutConstraint!
    
    var refresh = UIRefreshControl()
    
    let db = Firestore.firestore()
    let sender = PushNotificationSender()
    private var imagePicker = UIImagePickerController()
    
    var messages : [Message] = []
    var currentRowLimit: Int = 20
    
    var selectedContact : Contact?
    
    //variable to store the image message that is tapped
    var selectedImage : UIImage?
    
    private var tabBarHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser == nil {
            UserDefaults.standard.set(false, forKey: K.UDefaults.userIsLoggedIn)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginNavController = storyboard.instantiateViewController(identifier: "rootVC")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
        }
        
        
        
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.navigationBar.layoutIfNeeded()
        if selectedContact == nil {
            dismiss(animated: true, completion: nil)
        }
        
        
        setupViewUI()
        setupViewColors(color: UIColor(hexString: selectedContact!.color)!)
        
        imagePicker.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        messageTextfield.delegate = self
        
        //tableView.register(UINib(nibName: K.cellNibName1, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        tableView.register(UINib(nibName: K.cellNibName3, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        tableView.register(UINib(nibName: K.imageCellNibName, bundle: nil), forCellReuseIdentifier: K.imageCellIdentifier)
        
        refresh.addTarget(self, action: #selector(refreshTableData(_:)), for: .valueChanged)
        tableView.refreshControl = refresh
        
        configureSnapshotListener()
    }
    
    private func setupViewUI() {
        self.navigationController?.navigationBar.tintColor = .white
        //Display name of contact
        nameButton.setTitle(selectedContact!.name, for: .normal)
        nameButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
        
        // Create the image view for contact's profile picture
        let image = UIImageView()
        image.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        image.contentMode = UIView.ContentMode.scaleAspectFit
        image.setRounded()

        image.kf.setImage(
            with: URL(string: selectedContact!.profilePicture),
            options: [
                .processor(DownsamplingImageProcessor(size: CGSize(width: 40, height: 40)) |> RoundCornerImageProcessor(cornerRadius: 20) ),
                .loadDiskFileSynchronously,
                .cacheOriginalImage,
                .transition(.fade(0.25))
            ])

        //set navigation title to image view
        self.navigationItem.titleView = image
        
        //put placeholder text into textView
        messageTextfield.textColor = .lightGray
        messageTextfield.text = "Write a message..."
        messageTextfield.selectedTextRange = messageTextfield.textRange(from: messageTextfield.beginningOfDocument, to: messageTextfield.beginningOfDocument)
        
        //store tabBarHeight to fix height bug with IQKeyboardManager
        tabBarHeight = tabBarController?.tabBar.frame.size.height
    }
    
    func setupViewColors(color: UIColor) {
        view.backgroundColor = color
        nameView.backgroundColor = color
        textfieldView.backgroundColor = color
    }
    
    @objc private func refreshTableData(_ sender: Any) {
        // reload Contacts
        currentRowLimit += 10
        loadMessages(currentRowLimit: currentRowLimit, scrollTo: 0)
    }
    
    
    //MARK: - Chat and Firebase Functionality
    
    private func configureSnapshotListener() {
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
    
    private func loadMessages(currentRowLimit: Int, scrollTo: Int?) {
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
                    print(e.localizedDescription)
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
                        self.tableView.reloadData()
                        let indexPath = IndexPath(row: scrollTo ?? self.messages.count - 1, section: 0)
                        if indexPath.row >= 0 {
                            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                        }
                    }
                    //update all current messages as read
                    self.readMessages()
                }
            }
        self.refresh.endRefreshing()
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
        addMessageData(imageData: nil)
    }
    
    private func addMessageData(imageData: [String: Any]?){
        let currentTimestamp = Timestamp.init(date: Date())
        var messageText = messageTextfield.text
        
        currentRowLimit += 1
        
        if imageData == nil && (messageText == nil || messageText == "") {
            return
        } else if imageData != nil {
            messageText = ""
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
                                K.FStore.imageField: imageData?["URL"] ?? "",
                                K.FStore.imageWidth: imageData?["width"] ?? 0,
                                K.FStore.imageHeight: imageData?["height"] ?? 0,
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
        if imageData == nil {
            messageTextfield.text = ""
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
    
    private func uploadImagePic(image: UIImage) {
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
                self.addMessageData(imageData: imageInfo)
                print("Successfuly uploaded image!")
            })
        }
    }
    
    //MARK: - Extra Functionality
    
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
    
    @IBAction func callFriend(_ sender: UIBarButtonItem) {
        let phoneURL = "tel://\(selectedContact!.number)"
        if let url = URL(string: phoneURL), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    

    
    @IBAction func pressChatName(_ sender: UIButton) {
        performSegue(withIdentifier: "goToChatDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToImageDetail" {
            let destinationVC = segue.destination as! ImageDetailViewController
            destinationVC.imageToBeDisplayed = self.selectedImage
        } else if segue.identifier == "goToChatDetail" {
            let destinationVC = segue.destination as! ChatDetailViewController
            destinationVC.selectedContact = self.selectedContact
            destinationVC.navBarHeight = self.navigationController?.navigationBar.frame.height
            destinationVC.delegate = self
        }
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
            let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell2
            //Format message from current user
            if message.senderEmail == Auth.auth().currentUser?.email {
                setCellDataText(of: cell, fromSelf: true, message: message.text, time: message.date)
            } else {
                
                setCellDataText(of: cell, fromSelf: false, message: message.text, time: message.date)
            }
            return cell
            
        //image message
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: K.imageCellIdentifier, for: indexPath) as! ImageTableViewCell
            
            let aspect = message.imageWidth / message.imageHeight
            //Format message from current user
            if message.senderEmail == Auth.auth().currentUser?.email {
                cell.prepareCellDimensions(aspect: aspect, fromSelf: true)
                setCellDataImage(of: cell, imageURL: message.imageURL, aspect: aspect, time: message.date, fromSelf: true)
            } else {
                cell.prepareCellDimensions(aspect: aspect, fromSelf: false)
                setCellDataImage(of: cell, imageURL: message.imageURL, aspect: aspect, time: message.date, fromSelf: false)
            }
            
            return cell
        }
        
    }
    
    private func setCellDataText(of cell: MessageCell2, fromSelf: Bool, message: String, time: Date) {
        
        //set up time to be displayed beside message
        let dateFormatter = DateFormatter()
        let timeDiff = Calendar.current.dateComponents([.hour], from: time, to: Date()).hour!
        if timeDiff < 24 {
            dateFormatter.dateFormat = "h:mm a"
        } else {
            dateFormatter.dateFormat = "MMM d, h:mm a"
        }
        let dateString = dateFormatter.string(from: time)
        
        
        if fromSelf {
            cell.label.isHidden = true
            cell.time.isHidden = true
            //cell.label2.text = message
//            if let attributedTitle = cell.label2.attributedTitle(for: .normal) {
//                let mutableAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)
//                mutableAttributedTitle.replaceCharacters(in: NSMakeRange(0, mutableAttributedTitle.length), with: message)
//                cell.label2.setAttributedTitle(mutableAttributedTitle, for: .normal)
//            }
            cell.label2.setTitle(message, for: .normal)
            cell.label2.sizeToFit()
            cell.time2.text = dateString
            cell.label2.layer.cornerRadius = 10
            //cell.label2.textColor = UIColor.black
            cell.label2.backgroundColor = UIColor(named: K.BrandColors.cyan)
        } else {

            cell.label2.isHidden = true
            cell.time2.isHidden = true
            //cell.label.text = message
//            if let attributedTitle = cell.label.attributedTitle(for: .normal) {
//                let mutableAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)
//                mutableAttributedTitle.replaceCharacters(in: NSMakeRange(0, mutableAttributedTitle.length), with: message)
//                cell.label.setAttributedTitle(mutableAttributedTitle, for: .normal)
//            }
            cell.label.setTitle(message, for: .normal)
            cell.label.sizeToFit()
            cell.time.text = dateString
            cell.label.layer.cornerRadius = 10
            //cell.label.textColor = UIColor(named: K.BrandColors.lavender)
            cell.label.tintColor = .white
            cell.label.backgroundColor = UIColor(hexString: selectedContact!.color)
        }
    }
    
    private func setCellDataImage(of cell: ImageTableViewCell, imageURL: String, aspect: CGFloat, time: Date, fromSelf: Bool) {
        //set up time to be displayed beside message
        let dateFormatter = DateFormatter()
        let timeDiff = Calendar.current.dateComponents([.hour], from: time, to: Date()).hour!
        if timeDiff < 24 {
            dateFormatter.dateFormat = "h:mm a"
        } else {
            dateFormatter.dateFormat = "MMM d, h:mm a"
        }
        let dateString = dateFormatter.string(from: time)

        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(sender:)))
        
        if fromSelf {
            //let size = CGSize(width: cell.imageBox2.bounds.width, height: cell.imageBox2.bounds.width / aspect)
            let cornerRadius = 0.05 * min(cell.imageBox2.bounds.width, cell.imageBox2.bounds.width / aspect)
            
            cell.imageBox2.kf.indicatorType = .activity
            cell.imageBox2.kf.setImage(
                with: URL(string: imageURL),
                options: [
                    .processor(RoundCornerImageProcessor(cornerRadius: cornerRadius)),
                    .loadDiskFileSynchronously,
                    .cacheOriginalImage,
                    .transition(.fade(0.25))
                ]) { result, error in
                    cell.layoutIfNeeded()
                }
            cell.time.isHidden = true
            cell.imageBox.isHidden = true
            cell.time2.text = dateString
            cell.imageBox2.addGestureRecognizer(imageTapGesture)
        } else {
            //let size = CGSize(width: cell.imageBox.bounds.width, height: cell.imageBox.bounds.width / aspect)
            let cornerRadius = 0.05 * min(cell.imageBox.bounds.width, cell.imageBox.bounds.width / aspect)
            
            cell.imageBox.kf.indicatorType = .activity
            cell.imageBox.kf.setImage(
                with: URL(string: imageURL),
                options: [
                    .processor(RoundCornerImageProcessor(cornerRadius: cornerRadius)),
                    .loadDiskFileSynchronously,
                    .cacheOriginalImage,
                    .transition(.fade(0.25))
                ]) { result, error in
                    cell.layoutIfNeeded()
                }
            cell.time2.isHidden = true
            cell.imageBox2.isHidden = true
            cell.time.text = dateString
            cell.imageBox.addGestureRecognizer(imageTapGesture)
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
    
    private func openGallery() {
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
    
    private func openCamera() {
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
extension MessageViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.3) {
            self.navigationItem.titleView?.alpha = 0
            self.navigationController?.navigationBar.isHidden = true
        }
//        if messageTextfield.text == "Write a message..." {
//            messageTextfield.text = nil
//            messageTextfield.textColor = .black
//        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.5) {
            self.navigationItem.titleView?.alpha = 1
            self.navigationController?.navigationBar.isHidden = false
        }
        if messageTextfield.text.isEmpty || messageTextfield.text == "" {
            messageTextfield.textColor = .lightGray
            messageTextfield.text = "Write a message..."
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText : String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        

        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {

            textView.text = "Write a message..."
            textView.textColor = UIColor.lightGray

            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }

        // Else if the text view's placeholder is showing and the
        // length of the replacement string is greater than 0, set
        // the text color to black then set its text to the
        // replacement string
         else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            textView.textColor = UIColor.black
            textView.text = text
        }

        // For every other case, the text should change with the usual
        // behavior...
        else {
            return true
        }
        
        let newText = textView.text
        textView.text = nil
        textView.text = newText

        // ...otherwise return false since the updates have already
        // been made
        
        return false
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }

}
