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

    @IBAction func loginPressed(_ sender: UIButton) {
        if let email = emailTextfield.text,
           let password = passwordTextfield.text,
           emailPredicate.evaluate(with: email) {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.performSegue(withIdentifier: "goToMessagesVC", sender: self)
                }
            }
        } else if emailTextfield.text == nil || !emailPredicate.evaluate(with: emailTextfield.text!){
            presentAlert(message: "Please input valid email")
        } else if passwordTextfield.text == nil || passwordTextfield.text!.isEmpty {
            presentAlert(message: "Please input valid password")
        } 
        
    }
    
    func presentAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
}
