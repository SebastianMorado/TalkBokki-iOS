//
//  FirestoreManagerForLogin.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/30/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManagerForLogIn {
    let db = Firestore.firestore()
    
    func saveLoginDetails(email: String) {
        db.collection("users")
            .document(email)
            .getDocument { document, error in
                if let e = error {
                    UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
                } else {
                    if let data = document?.data()! {
                        UserDefaults.standard.set(email, forKey: K.UDefaults.userEmail)
                        UserDefaults.standard.set(data["name"] as! String, forKey: K.UDefaults.userName)
                        UserDefaults.standard.set(data["profile_picture"] as! String, forKey: K.UDefaults.userURL)
                        UserDefaults.standard.set(data["phone_number"] as! String, forKey: K.UDefaults.userPhone)
                        UserDefaults.standard.set(true, forKey: K.UDefaults.userIsLoggedIn)

                        let storyboard = UIStoryboard(name: "Tab", bundle: nil)
                        let mainTabBarController = storyboard.instantiateViewController(identifier: "TabVC")
                        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
                    }
                }
            }
    }
    
    //uploads profile picture to firebase storage server
    func uploadImagePic(image: UIImage, name: String, phone: String) {
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
                self.createNewUserEntry(image_url: url!.absoluteString, name: name, phone: phone)
            })
        }
    }
    
    //creates a firestore data entry for the new user
    func createNewUserEntry(image_url: String, name: String, phone: String){
        if let newUserEmail = Auth.auth().currentUser?.email {
            db.collection("users")
                .document(newUserEmail)
                .setData([
                            "name": name,
                            "profile_picture": image_url,
                            "phone_number": phone], completion: { error in
                    if let e = error {
                        UIApplication.getPresentedViewController()?.presentAlert(message: e.localizedDescription)
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
    
    
}
