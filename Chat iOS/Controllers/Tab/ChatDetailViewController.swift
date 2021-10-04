//
//  ChatDetailViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/23/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework

class ChatDetailViewController: UIViewController {
    
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    
    let db = Firestore.firestore()
    
    
    var delegate : MessageViewController?
    var selectedContact : Contact?
    var navBarHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topConstraint.constant = navBarHeight! + 29
        phoneButton.setTitle(selectedContact?.number, for: .normal)
        emailButton.setTitle(selectedContact?.email, for: .normal)
        
        setupColors(color: UIColor(hexString: selectedContact!.color)!)
    }
    
    private func setupColors(color: UIColor) {
        mainView.backgroundColor = color
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        let touch = touches.first

        if touch?.view == self.view {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        self.dismiss(animated: false) {
            self.delegate!.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func pressMute(_ sender: UIButton) {
    }
    
    @IBAction func pressBlock(_ sender: UIButton) {
        let alert = UIAlertController(title: "Block friend", message: "Are you sure you want to block \(selectedContact!.name)? You can always add them again in the future.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        let action = UIAlertAction(title: "Block", style: .default) { (action) in
            self.deleteFriendFromMyContact()
        }
        
        alert.addAction(cancel)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteFriendFromMyContact() {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(selectedContact!.email)
            .delete { error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.deleteMyContactFromFriend()
                }
            }
    }
    
    private func deleteMyContactFromFriend() {
        db.collection(K.FStore.usersCollection)
            .document(selectedContact!.email)
            .collection(K.FStore.contactsCollection)
            .document(Auth.auth().currentUser!.email!)
            .delete { error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.dismiss(animated: false) {
                        self.delegate!.navigationController?.popViewController(animated: true)
                    }
                }
            }
    }
    
    @IBAction func pressColor(_ sender: UIButton) {
        var newColorIndex = 0
        
        if let currentColorIndex = K.chatColors.firstIndex(of: selectedContact!.color) {
            newColorIndex = currentColorIndex + 1
            if newColorIndex >= K.chatColors.count {
                newColorIndex = 0
            }
        }
        
        let newColor = K.chatColors[newColorIndex]
        
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(selectedContact!.email)
            .getDocument { document, error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    document?.reference.updateData(["chat_color" : newColor])
                    self.selectedContact?.color = newColor
                    DispatchQueue.main.async {
                        self.setupColors(color: UIColor(hexString: newColor)!)
                        self.delegate?.setupViewColors(color: UIColor(hexString: newColor)!)
                        self.delegate?.tableView.reloadData()
                    }
                }
            }
        
    }
    
    @IBAction func pressPhone(_ sender: UIButton) {
        let phoneURL = "tel://\(phoneButton.titleLabel!.text!)"
        if let url = URL(string: phoneURL), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction func pressEmail(_ sender: UIButton) {
        let email = selectedContact!.email
        if let url = URL(string: "mailto:\(email)") {
          if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
          } else {
            UIApplication.shared.openURL(url)
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

