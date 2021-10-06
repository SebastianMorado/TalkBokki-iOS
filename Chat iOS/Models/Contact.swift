//
//  Contact.swift
//  Chat iOS iOS13
//
//  Created by Sebastian Morado on 8/28/21.
//

import Foundation

class Contact {
    var name: String = ""
    var email: String = ""
    var number: String = ""
    var color: String = ""
    var fcmToken: String = ""
    var profilePicture: String = ""
    var mostRecentMessage: Date?
    var messages: [Message]?
}
