//
//  PushNotificationReceiver.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/6/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

class PushNotificationSender {
    
    func sendPushNotification(to token: String, myEmail: String, myName: String, messageText: String, receiverEmail: String) {
        
        let urlString = "https://fcm.googleapis.com/fcm/send"
        if let apiKey = Bundle.main.infoDictionary?["CLOUD_MESSAGING_API_KEY"] as? String, apiKey != "" {
            let url = NSURL(string: urlString)!
            let paramString: [String : Any] = ["to" : token,
                                               "notification" : ["title" : myName, "body" : messageText],
                                               "data" : ["senderEmail" : myEmail, "receiverEmail": receiverEmail]
            ]
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "POST"
            request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("key=" + apiKey, forHTTPHeaderField: "Authorization")
            
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
        } else {
            print("no key :(")
        }
    }
    
    
}
