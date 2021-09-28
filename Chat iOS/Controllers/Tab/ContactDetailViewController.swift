//
//  ContactDetailViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/14/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

class ContactDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var phoneLabel: UITextField!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    let db = Firestore.firestore()
    
    weak var delegate : ContactsTableViewController?
    
    var selectedContact : Contact?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
        
        detailView.layer.cornerRadius = 20
        detailView.layer.masksToBounds = true
        detailView.layer.borderWidth = 5
        detailView.layer.borderColor = UIColor(named: "BrandPurple")?.cgColor
        
        if let contact = selectedContact {
            nameLabel.text = contact.name
            emailLabel.text = contact.email
            
            phoneLabel.text = contact.number
            imageView.kf.setImage(with: URL(string: contact.profilePicture))
            imageView.setRounded()
        }
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        let touch = touches.first

        if touch?.view == self.view {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func startMessage(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.delegate!.performSegue(withIdentifier: "goToChat", sender: self.selectedContact)
        }
    }
    
    @IBAction func startCall(_ sender: UIButton) {
        let phoneURL = "tel://\(phoneLabel.text!)"
        if let url = URL(string: phoneURL), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

    @IBAction func deleteFriend(_ sender: UIButton) {
        
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
            .document(self.selectedContact!.email)
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
            .document(self.selectedContact!.email)
            .collection(K.FStore.contactsCollection)
            .document(Auth.auth().currentUser!.email!)
            .delete { error in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.dismiss(animated: true, completion: nil)
                    self.delegate!.presentAlert(message: "\(self.selectedContact!.name) is now blocked", title: "Success")
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

