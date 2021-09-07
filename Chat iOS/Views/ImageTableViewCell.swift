//
//  ImageTableViewCell.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/3/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    
    @IBOutlet weak var imageBox: UIImageView!
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var messageBubble: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageBubble.layer.cornerRadius = 20
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        //super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        //print("The image size is \(imageBox.image?.size)")
    }
    
}
