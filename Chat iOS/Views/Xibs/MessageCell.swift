//
//  MessageCell.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import PaddingLabel

class MessageCell: UITableViewCell {
    

    @IBOutlet weak var label: PaddingLabel!
    @IBOutlet weak var label2: PaddingLabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var time2: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        label.layer.masksToBounds = true
        label2.layer.masksToBounds = true
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
    }
    
}
