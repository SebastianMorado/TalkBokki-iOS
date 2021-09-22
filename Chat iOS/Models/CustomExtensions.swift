//
//  CustomExtensions.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/22/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

extension UIView {
    
    func addBottomBorder(color: UIColor, width: CGFloat) {
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = color.cgColor
        bottomBorder.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        self.layer.addSublayer(bottomBorder)
    }
}
