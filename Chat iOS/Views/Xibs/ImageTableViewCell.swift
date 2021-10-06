//
//  ImageTableViewCell.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/3/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var time2: UILabel!
    @IBOutlet weak var imageBox: UIImageView!
    @IBOutlet weak var imageBox2: UIImageView!
    
    @IBOutlet weak var heightImageBox: NSLayoutConstraint!
    @IBOutlet weak var heightImageBox2: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    
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
    
    internal var aspectConstraint2 : NSLayoutConstraint? {
        didSet {
            if oldValue != nil {
                imageBox2.removeConstraint(oldValue!)
            }
            if aspectConstraint2 != nil {
                imageBox2.addConstraint(aspectConstraint2!)
            }
        }
    }
    

    override func prepareForReuse() {
        super.prepareForReuse()
        aspectConstraint = nil
        aspectConstraint2 = nil
        
        imageBox.isHidden = false
        imageBox2.isHidden = false
        
        time.isHidden = false
        time2.isHidden = false
        heightImageBox.constant = 500
        heightImageBox2.constant = 500
        leadingConstraint.constant = 200
        trailingConstraint.constant = 200
        
    }

    func prepareCellDimensions(aspect: CGFloat, fromSelf: Bool) {

        let margin = UIScreen.main.bounds.width / 3
        
        let tempWidth = UIScreen.main.bounds.width - margin - 10
        
        heightImageBox2.constant = tempWidth / aspect
        heightImageBox.constant = tempWidth / aspect
        
        if fromSelf {
            let constraint = NSLayoutConstraint(item: imageBox2!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: imageBox2!, attribute: NSLayoutConstraint.Attribute.height, multiplier: aspect, constant: 0.0)
            constraint.priority = UILayoutPriority(rawValue: 999)
            
            aspectConstraint2 = constraint
            leadingConstraint.constant = margin
            
            
            
        } else {
            let constraint = NSLayoutConstraint(item: imageBox!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: imageBox!, attribute: NSLayoutConstraint.Attribute.height, multiplier: aspect, constant: 0.0)
            constraint.priority = UILayoutPriority(rawValue: 999)
            
            aspectConstraint = constraint
            trailingConstraint.constant = margin
        }

    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {

    }
    
    override func updateConstraints() {
        super.updateConstraints()
    }

    
}
