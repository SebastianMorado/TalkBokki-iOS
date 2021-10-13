//
//  SettingsViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/8/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Kingfisher
import Firebase
import FirebaseStorage

class SettingsViewController: UIViewController {

    let db = Firestore.firestore()
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var userNumber: UILabel!
    
    private var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
        
        userImage.contentMode = .scaleAspectFill
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func updateUI() {
        if let name = UserDefaults.standard.string(forKey: K.UDefaults.userName),
           let image = UserDefaults.standard.string(forKey: K.UDefaults.userURL),
           let phone = UserDefaults.standard.string(forKey: K.UDefaults.userPhone) {
            self.userEmail.text = Auth.auth().currentUser!.email!
            self.userName.text = name
            self.userImage.kf.setImage(with: URL(string: image))
            self.userNumber.text = phone
        } else {
            do {
                UserDefaults.standard.set(false, forKey: K.UDefaults.userIsLoggedIn)
                self.performSegue(withIdentifier: "unwindToWelcomeScreen", sender: self)
                presentAlert(message: "Please log back in")
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
                print(signOutError.localizedDescription)
            }
        }
    }
    
    @IBAction func changeImage(_ sender: UIButton) {
        let alert = UIAlertController(title: "Update Profile Picture", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera() }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery() }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadImagePic(image: UIImage) {
        guard let imageData: Data = image.jpegData(compressionQuality: 0.1) else {
            print("failed to process image")
            return
        }

        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "image/jpg"

        let storageRef = Storage.storage().reference(withPath: "users/\(Auth.auth().currentUser!.email!)/Profile_Picture.jpg")

        storageRef.putData(imageData, metadata: metaDataConfig){ (metaData, error) in
            if let error = error {
                print(error.localizedDescription)

                return
            }

            storageRef.downloadURL(completion: { (url: URL?, error: Error?) in
                if let error = error {
                    print(error.localizedDescription)
                }
                //self.createNewUserEntry(image_url: url!.absoluteString, name: name)
                self.updateProfilePicInfo(using: url!.absoluteString)
                DispatchQueue.main.async {
                    self.userImage.image = image
                }
                print(url!.absoluteString) // <- Download URL
            })
        }
    }
    
    func updateProfilePicInfo(using imageURL: String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .getDocument { document, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    document?.reference.updateData(["profile_picture" : imageURL])
                    UserDefaults.standard.set(imageURL, forKey: K.UDefaults.userURL)
                }
            }
    }
    
    @IBAction func changeName(_ sender: UIButton) {
        var textField = UITextField()
        let userName = UserDefaults.standard.string(forKey: K.UDefaults.userName) ?? "None"
        
        let alert = UIAlertController(title: "Update name", message: "Current name: \(userName)", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        let action = UIAlertAction(title: "Save", style: .default) { (action) in
            self.db.collection(K.FStore.usersCollection)
                .document(Auth.auth().currentUser!.email!)
                .getDocument { document, error in
                    if let e = error {
                        print(e.localizedDescription)
                    } else {
                        document?.reference.updateData(["name" : textField.text ?? userName])
                        UserDefaults.standard.set(textField.text ?? userName, forKey: K.UDefaults.userName)
                        DispatchQueue.main.async {
                            self.updateUI()
                        }
                    }
                }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "New name"
            textField = alertTextField
        }
        alert.addAction(cancel)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func changePhoneNumber(_ sender: UIButton) {
        
        var textField = UITextField()
        let phoneNumber = UserDefaults.standard.string(forKey: K.UDefaults.userPhone) ?? "None"
        
        let alert = UIAlertController(title: "Update phone number", message: "Current number: \(phoneNumber)", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        let action = UIAlertAction(title: "Save", style: .default) { (action) in
            self.db.collection(K.FStore.usersCollection)
                .document(Auth.auth().currentUser!.email!)
                .getDocument { document, error in
                    if let e = error {
                        print(e.localizedDescription)
                    } else {
                        document?.reference.updateData(["phone_number" : textField.text ?? phoneNumber])
                        UserDefaults.standard.set(textField.text ?? phoneNumber, forKey: K.UDefaults.userPhone)
                        DispatchQueue.main.async {
                            self.updateUI()
                        }
                    }
                }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "New phone number"
            textField = alertTextField
        }
        alert.addAction(cancel)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func pressNotifications(_ sender: UIButton) {
        if let bundle = Bundle.main.bundleIdentifier,
            let settings = URL(string: UIApplication.openSettingsURLString + bundle) {
            if UIApplication.shared.canOpenURL(settings) {
                UIApplication.shared.open(settings)
            }
        }
    }
    
    @IBAction func changePassword(_ sender: UIButton) {
        performSegue(withIdentifier: "goToChangePassword", sender: self)
    }
    
    @IBAction func logOut(_ sender: UIButton) {
        let alert = UIAlertController(title: "Are you sure you want to log out?", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Yes", style: .default) { alert in
            do {
                for snapshot in SnapshotListeners.shared.snapshotList {
                    snapshot.remove()
                }
                UserDefaults.standard.set(false, forKey: K.UDefaults.userIsLoggedIn)
                //self.performSegue(withIdentifier: "unwindToWelcomeScreen", sender: self)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginNavController = storyboard.instantiateViewController(identifier: "rootVC")
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
                
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
                print(signOutError.localizedDescription)
            }
        })

        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    func presentAlert(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChangePassword" {
            if let destinationVC = segue.destination as? ChangePasswordViewController {
                destinationVC.delegate = self
            }
        }
    }
}

//MARK: - Image Picker Delegate

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let newImage = info[.editedImage] as? UIImage {
            uploadImagePic(image: newImage)
        }
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            imagePicker.allowsEditing = true
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
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have a camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
