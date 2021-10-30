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
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var muteButtonLabel: UILabel!
    
    var fsManager = FirestoreManagerForChatDetail()
    var delegate : MessageViewController?
    var isMuted: Bool?
    var selectedContact : Contact?
    var navBarHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fsManager.delegate = self
        updateMuteButton(isMuted: isMuted ?? false)
        topConstraint.constant = navBarHeight! + 29
        phoneButton.setTitle(selectedContact?.number, for: .normal)
        emailButton.setTitle(selectedContact?.email, for: .normal)
        
        mainView.backgroundColor = UIColor(hexString: selectedContact!.color)!
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
    
    func updateMuteButton(isMuted: Bool) {
        if isMuted {
            self.muteButton.setImage(UIImage(systemName: "bell.slash.circle"), for: .normal)
            self.muteButtonLabel.text = "Unmute"
        } else {
            self.muteButton.setImage(UIImage(systemName: "bell.circle"), for: .normal)
            self.muteButtonLabel.text = "Mute"
        }
    }
    
    @IBAction func pressMute(_ sender: UIButton) {
        fsManager.pressMute()
    }
    
    @IBAction func pressBlock(_ sender: UIButton) {
        let alert = UIAlertController(title: "Block friend", message: "Are you sure you want to block \(selectedContact!.name)? You can always add them again in the future.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        let action = UIAlertAction(title: "Block", style: .default) { (action) in
            self.fsManager.deleteFriendFromMyContact()
        }
        
        alert.addAction(cancel)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    func dismissAfterBlocking() {
        self.dismiss(animated: false) {
            self.delegate!.navigationController?.popViewController(animated: true)
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
        fsManager.updateColorDatabase(newColor: newColor)
    }
    
    func updateColors(newColor: String) {
        mainView.backgroundColor = UIColor(hexString: newColor)!
        delegate?.setupViewColors(color: UIColor(hexString: newColor)!)
        delegate?.tableView.reloadData()
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
    
}

