//
//  WelcomeViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.

import UIKit
import GhostTypewriter

class WelcomeViewController: UIViewController {

    @IBOutlet weak var titleLabel: TypewriterLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        titleLabel.typingTimeInterval = 0.3
        titleLabel.startTypewritingAnimation(completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    @IBAction func unwind( _ segue: UIStoryboardSegue) {
        print("back in MainViewController")
    }
    
    
    
    
}
