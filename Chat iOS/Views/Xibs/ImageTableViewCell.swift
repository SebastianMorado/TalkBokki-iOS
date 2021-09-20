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
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    internal var aspectConstraint : NSLayoutConstraint? {
        didSet {
            if oldValue != nil {
                imageBox.removeConstraint(oldValue!)
            }
            if aspectConstraint != nil {
                imageBox.addConstraint(aspectConstraint!)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        aspectConstraint = nil
        leadingConstraint.constant = 10
        trailingConstraint.constant = 10
    }

    func prepareCellDimensions(width: CGFloat, height: CGFloat, fromSelf: Bool) {

        let aspect = width / height

        let constraint = NSLayoutConstraint(item: imageBox!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: imageBox!, attribute: NSLayoutConstraint.Attribute.height, multiplier: aspect, constant: 0.0)
        constraint.priority = UILayoutPriority(rawValue: 999)

        aspectConstraint = constraint
        
        let margin = UIScreen.main.bounds.width / 3
        
        if fromSelf {
            //Make constraints
            leadingConstraint.constant = margin
        } else {
            trailingConstraint.constant = margin
        }

    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        //super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        //print("The image size is \(imageBox.image?.size)")
    }
    

    
}
