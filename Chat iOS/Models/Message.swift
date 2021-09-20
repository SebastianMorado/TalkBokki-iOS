//
//  Message.swift
//  Chat iOS iOS13
//
//  Created by Sebastian Morado on 4/23/21.
//

import UIKit

class Message {
    var senderEmail: String = ""
    var text: String = ""
    var imageURL: String = ""
    var imageHeight: CGFloat = 0
    var imageWidth: CGFloat = 0
    var wasRead: Bool = false
    var date: Date = Date()
}
