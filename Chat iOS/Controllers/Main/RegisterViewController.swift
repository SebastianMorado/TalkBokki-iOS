//
//  RegisterViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.

import UIKit
import Firebase
import Peppermint

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    let emailPredicate = EmailPredicate()
    let passwordPredicate = LengthPredicate<String>(min: 6)
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.tintColor = UIColor.link
    }
    
    @IBAction func registerPressed(_ sender: UIButton) {
        if emailTextfield.text == nil || !emailPredicate.evaluate(with: emailTextfield.text!){
            presentAlert(message: "Please input valid email")
        } else if passwordTextfield.text == nil || passwordTextfield.text!.isEmpty {
            presentAlert(message: "Please input valid password")
        } else if passwordTextfield.text != confirmPasswordTextField.text {
            presentAlert(message: "Please confirm password correctly")
        } else if !passwordPredicate.evaluate(with: passwordTextfield.text!){
            presentAlert(message: "Password must be at least 6 characters long")
        } else if let email = emailTextfield.text,
                  passwordTextfield.text != nil,
                  passwordTextfield.text == confirmPasswordTextField.text,
                  emailPredicate.evaluate(with: email){
            print("the password is \(passwordTextfield.text!.count)")
            performSegue(withIdentifier: "goToCreateProfile", sender: self)
               
        }
    }
    
    func presentAlert(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCreateProfile" {
            let destinationVC = segue.destination as! CreateProfileViewController
            destinationVC.userEmail = emailTextfield.text!
            destinationVC.userPassword = passwordTextfield.text!
        }
    }
    
}
