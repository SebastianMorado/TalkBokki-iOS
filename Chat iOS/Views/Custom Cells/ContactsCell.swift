//
//  ContactsCell.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/10/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

class ContactsCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    
    func setRoundedImage(){
        let radius = cellImage.frame.width / 2
        cellImage.layer.cornerRadius = radius
        cellImage.layer.masksToBounds = true
    }
    
}
