//
//  PushNotificationReceiver.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/6/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

class PushNotificationSender {
    
    func sendPushNotification(to token: String, title: String, body: String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body],
                                           "data" : ["user" : "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAleC2sOc:APA91bE7KwcU8TSXbFpfU3pVrFtS9PyMcY1nWMoQPypMMKLTQeVG1MKA28yWwdFKNvlbFlCy3Kbs0o-6yNH-jtz92rGvbPJYVLp19ZHPGZvvO2aTVy5yEIJcuSSg6lHUdiKntNXHI1Yj", forHTTPHeaderField: "Authorization")
        
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
    
    
}
