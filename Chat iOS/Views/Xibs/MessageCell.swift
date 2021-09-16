//
//  MessageCell.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

protocol hasLeftAndRightPictures {
    func setRoundedImage()
    var leftImageView: UIImageView! { get }
    var rightImageView: UIImageView! { get }
}

class MessageCell: UITableViewCell, hasLeftAndRightPictures {
    
    @IBOutlet weak var messageBubble: UIView!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageBubble.layer.cornerRadius = messageBubble.frame.size.height / 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setRoundedImage(){
        let radius = rightImageView.frame.width / 2
        rightImageView.layer.cornerRadius = radius
        rightImageView.layer.masksToBounds = true
        leftImageView.layer.cornerRadius = radius
        leftImageView.layer.masksToBounds = true
    }
    
}
