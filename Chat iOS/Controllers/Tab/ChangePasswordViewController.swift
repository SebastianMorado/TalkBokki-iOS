//
//  ChangePasswordViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/27/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase
import Peppermint

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var stackView1: UIStackView!
    @IBOutlet weak var stackView2: UIStackView!
    @IBOutlet weak var saveView: UIView!
    @IBOutlet weak var forgotPasswordView: UIView!
    
    let passwordPredicate = LengthPredicate<String>(min: 6)
    
    var delegate : SettingsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveView.layer.borderWidth = 0.5
        saveView.layer.borderColor = UIColor.init(named: K.BrandColors.red)?.cgColor
        forgotPasswordView.layer.borderWidth = 0.5
        forgotPasswordView.layer.borderColor = UIColor.init(named: K.BrandColors.red)?.cgColor
    
    }
    
    @IBAction func pressSave(_ sender: UIButton) {
        
        //perform some checks
        if let oldPassword = oldPasswordTextField.text, let newPassword = newPasswordTextField.text {
            if !passwordPredicate.evaluate(with: oldPassword), !passwordPredicate.evaluate(with: newPassword) {
                self.presentAlert(message: "Password must be at least 6 characters long")
                return
            }
        } else {
            self.presentAlert(message: "Please fill in the required fields")
            return
        }
        
        
        let user = Auth.auth().currentUser
        let credential = EmailAuthProvider.credential(withEmail: Auth.auth().currentUser!.email!, password: oldPasswordTextField.text!)

        // Prompt the user to re-provide their sign-in credentials
        user?.reauthenticate(with: credential, completion: { result, error in
            if let error = error {
                self.presentAlert(message: error.localizedDescription)
              } else {
                self.changePassword()
              }
        })
    }
    
    func changePassword() {
        Auth.auth().currentUser?.updatePassword(to: newPasswordTextField.text!) { (error) in
            if let e = error {
                self.presentAlert(message: e.localizedDescription)
            } else {
                self.delegate!.navigationController?.popViewController(animated: true)
                self.delegate!.presentAlert(message: "Successfully changed password!", title: "Success!")
            }
        }
    }
    

    @IBAction func pressForgotPassword(_ sender: UIButton) {
        let alert = UIAlertController(title: "Forgot password?", message: "We will send a password reset link to your email account", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.resetPassword()
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    func resetPassword(){
        Auth.auth().sendPasswordReset(withEmail: Auth.auth().currentUser!.email!) { error in
            if let e = error {
                self.presentAlert(message: e.localizedDescription)
            } else {
                self.delegate!.navigationController?.popViewController(animated: true)
                self.delegate!.presentAlert(message: "Sent a link to your email!", title: "Success!")
            }
        }
    }
    
    private func presentAlert(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}
