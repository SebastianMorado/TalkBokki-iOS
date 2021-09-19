//
//  MessageCell.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import PaddingLabel

protocol hasLeftAndRightPictures {
    func setRoundedImage()
    var leftImageView: UIImageView! { get }
    var rightImageView: UIImageView! { get }
    var label: PaddingLabel! { get }
    var label2: PaddingLabel! { get }
}

class MessageCell: UITableViewCell, hasLeftAndRightPictures {
    
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var label: PaddingLabel!
    @IBOutlet weak var label2: PaddingLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        label.layer.masksToBounds = true
        label2.layer.masksToBounds = true
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
    
    override func prepareForReuse() {
        super.prepareForReuse()

        rightImageView.image = UIImage(contentsOfFile: "")
        leftImageView.image = UIImage(contentsOfFile: "")
        label.isHidden = false
        label2.isHidden = false
    }
    
}
