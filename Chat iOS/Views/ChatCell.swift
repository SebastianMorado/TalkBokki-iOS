//
//  ChatCell.swift
//  Flash Chat iOS13
//
//  Created by Sebastian Morado on 8/31/21.
//  Copyright © 2021 Angela Yu. All rights reserved.
//

import UIKit

class ChatCell: UITableViewCell {
    
    @IBOutlet var contactImage: UIImageView!
    @IBOutlet var contactName: UILabel!
    @IBOutlet var messageText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
