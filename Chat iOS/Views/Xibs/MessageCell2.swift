//
//  MessageCell.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

class MessageCell2: UITableViewCell {
    

    @IBOutlet weak var label: UIButton!
    @IBOutlet weak var label2: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var time2: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        label.layer.masksToBounds = true
        label2.layer.masksToBounds = true
        label.contentEdgeInsets = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 7)
        label2.contentEdgeInsets = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 7)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        label.isHidden = false
        label2.isHidden = false
        time.isHidden = false
        time2.isHidden = false
        label.layer.cornerRadius = 0
        label2.layer.cornerRadius = 0
    }
    
}
