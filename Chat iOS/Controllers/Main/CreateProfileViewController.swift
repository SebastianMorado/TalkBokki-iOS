//
//  CreateProfileViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.

import UIKit
import Firebase
import Peppermint
import FirebaseStorage


class CreateProfileViewController: UIViewController {

    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var phoneLabel: UITextField!
    
    let db = Firestore.firestore()
    
    private var imagePicker = UIImagePickerController()
    var userEmail : String = ""
    var userPassword : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        // Do any additional setup after loading the view.
    }

    @IBAction func confirmPressed(_ sender: UIButton) {
        if let name = nameLabel.text,
           nameLabel.text != "",
           let userImage = imageView.image,
           let phone = phoneLabel.text,
           phoneLabel.text != "" {
            
            Auth.auth().createUser(withEmail: userEmail, password: userPassword) { authResult, error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.uploadImagePic(image: userImage, name: name, phone: phone)
                }
            }
        } else {
            presentAlert(message: "Please fill out all fields")
        }
    }
    
    @IBAction func imagePressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera() }))

        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery() }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    //uploads profile picture to firebase storage server
    private func uploadImagePic(image: UIImage, name: String, phone: String) {
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
                self.createNewUserEntry(image_url: url!.absoluteString, name: name, phone: phone)
                print(url!.absoluteString) // <- Download URL
            })
        }
    }
    
    //creates a firestore data entry for the new user
    private func createNewUserEntry(image_url: String, name: String, phone: String){
        if let newUserEmail = Auth.auth().currentUser?.email {
            db.collection("users")
                .document(newUserEmail)
                .setData([
                            "name": name,
                            "profile_picture": image_url,
                            "phone_number": phone], completion: { error in
                    if let e = error {
                        self.presentAlert(message: e.localizedDescription)
                    } else {
                        print("Successfully saved data!")
                        self.saveLoginDetails(email: newUserEmail, name: name, profilePictureURL: image_url, phone: phone)
                        
                        let storyboard = UIStoryboard(name: "Tab", bundle: nil)
                        let mainTabBarController = storyboard.instantiateViewController(identifier: "TabVC")
                        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
                    }
                })
        }
        
        
    }
    
    private func saveLoginDetails(email: String, name: String, profilePictureURL: String, phone: String) {
        UserDefaults.standard.set(email, forKey: K.UDefaults.userEmail)
        UserDefaults.standard.set(name, forKey: K.UDefaults.userName)
        UserDefaults.standard.set(profilePictureURL, forKey: K.UDefaults.userURL)
        UserDefaults.standard.set(phone, forKey: K.UDefaults.userPhone)
        UserDefaults.standard.set(true, forKey: K.UDefaults.userIsLoggedIn)
    }
    
    func presentAlert(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - Image Picker Delegate

extension CreateProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userImage = info[.editedImage] as? UIImage {
            imageView.image = userImage
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
