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
    
    let fsManager = FirestoreManagerForContactDetail()
    weak var delegate : ContactsTableViewController?
    
    var selectedContact : Contact?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fsManager.delegate = self
        
        self.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
        detailView.layer.cornerRadius = 20
        detailView.layer.masksToBounds = true
        
        if let contact = selectedContact {
            nameLabel.text = contact.name
            emailLabel.text = contact.email
            
            phoneLabel.text = contact.number
            imageView.kf.setImage(with: URL(string: contact.profilePicture))
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

    @IBAction func editFriendInfo(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Edit Friend Info", message: nil, preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        let edit = UIAlertAction(title: "Edit name", style: .default) { (action) in
            self.editFriendName()
        }
        
        let block = UIAlertAction(title: "Block", style: .default) { (action) in
            self.blockFriend()
        }
        
        alert.addAction(cancel)
        alert.addAction(edit)
        alert.addAction(block)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func editFriendName() {
        var textField = UITextField()
        let alert = UIAlertController(title: "Edit name for \(selectedContact!.name)", message: "", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        let action = UIAlertAction(title: "Confirm", style: .default) { (action) in
            if let text = textField.text, text.count > 0 {
                self.fsManager.editNewNameinDatabase(newName: text)
            } else {
                self.presentAlert(message: "Please input valid name")
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "New Name"
            textField = alertTextField
        }
        
        alert.addAction(cancel)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    private func blockFriend() {
        let alert = UIAlertController(title: "Block Friend", message: "Are you sure you want to block \(selectedContact!.name)? You can always add them again in the future.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        let block = UIAlertAction(title: "Block", style: .default) { (action) in
            self.fsManager.deleteFriendFromMyContact()
        }
        
        alert.addAction(cancel)
        alert.addAction(block)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    func dismissAfterBlocking() {
        dismiss(animated: true, completion: nil)
        delegate!.presentAlert(message: "\(self.selectedContact!.name) is now blocked", title: "Success")
    }
    
}

