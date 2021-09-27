//
//  ChatDetailViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/23/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

class ChatDetailViewController: UIViewController {
    
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    
    var delegate : MessageViewController?
    var selectedContact : Contact?
    var navBarHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topConstraint.constant = navBarHeight! + 29
        phoneButton.setTitle(selectedContact?.number, for: .normal)
        emailButton.setTitle(selectedContact?.email, for: .normal)
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
    }
    
    @IBAction func pressColor(_ sender: UIButton) {
    }
    
    @IBAction func pressPhone(_ sender: UIButton) {
    }
    
    @IBAction func pressEmail(_ sender: UIButton) {
    }
}
