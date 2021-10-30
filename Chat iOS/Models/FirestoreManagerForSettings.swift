//
//  FirestoreManagerForSettings.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class FirestoreManagerForSettings {
    
    let db = Firestore.firestore()
    var delegate : SettingsViewController?
    
    func uploadImagePic(image: UIImage) {
        guard let imageData: Data = image.jpegData(compressionQuality: 0.1) else {
            print("failed to process image")
            return
        }

        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "image/jpg"

        let storageRef = Storage.storage().reference(withPath: "users/\(Auth.auth().currentUser!.email!)/Profile_Picture.jpg")

        storageRef.putData(imageData, metadata: metaDataConfig){ (metaData, error) in
            if let e = error {
                UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)

                return
            }

            storageRef.downloadURL(completion: { (url: URL?, error: Error?) in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                }
                //self.createNewUserEntry(image_url: url!.absoluteString, name: name)
                self.updateProfilePicInfo(using: url!.absoluteString)
                DispatchQueue.main.async {
                    self.delegate?.userImage.image = image
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
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    document?.reference.updateData(["profile_picture" : imageURL])
                    UserDefaults.standard.set(imageURL, forKey: K.UDefaults.userURL)
                }
            }
    }
    
    func updateName(name: String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .getDocument { document, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    document?.reference.updateData(["name" : name])
                    UserDefaults.standard.set(name, forKey: K.UDefaults.userName)
                    DispatchQueue.main.async {
                        self.delegate?.updateUI()
                    }
                }
            }
    }
    
    func updatePhoneNumber(phoneNumber: String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .getDocument { document, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    document?.reference.updateData(["phone_number" : phoneNumber])
                    UserDefaults.standard.set(phoneNumber, forKey: K.UDefaults.userPhone)
                    DispatchQueue.main.async {
                        self.delegate?.updateUI()
                    }
                }
            }
    }
    
}
