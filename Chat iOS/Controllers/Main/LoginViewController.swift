//
//  LoginViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.

import UIKit
import Firebase
import Peppermint

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    
    let emailPredicate = EmailPredicate()
    
    let db = Firestore.firestore()

    @IBAction func loginPressed(_ sender: UIButton) {
        if let email = emailTextfield.text,
           let password = passwordTextfield.text,
           emailPredicate.evaluate(with: email) {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.saveLoginDetails(email: email)
                }
            }
        } else if emailTextfield.text == nil || !emailPredicate.evaluate(with: emailTextfield.text!){
            presentAlert(message: "Please input valid email")
        } else if passwordTextfield.text == nil || passwordTextfield.text!.isEmpty {
            presentAlert(message: "Please input valid password")
        } 
        
    }
    
    private func saveLoginDetails(email: String) {
        db.collection("users")
            .document(email)
            .getDocument { document, error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    if let data = document?.data()! {
                        UserDefaults.standard.set(email, forKey: K.UDefaults.userEmail)
                        UserDefaults.standard.set(data["name"] as! String, forKey: K.UDefaults.userName)
                        UserDefaults.standard.set(data["profile_picture"] as! String, forKey: K.UDefaults.userURL)
                        UserDefaults.standard.set(data["phone_number"] as! String, forKey: K.UDefaults.userPhone)
                        UserDefaults.standard.set(true, forKey: K.UDefaults.userIsLoggedIn)
                        
                        self.performSegue(withIdentifier: "goToMessagesVC", sender: self)
                    }
                }
            }
    }
    
    func presentAlert(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
}
