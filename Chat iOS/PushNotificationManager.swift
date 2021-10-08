//
//  PushNotificationManager.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/5/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    let db = Firestore.firestore()
    
    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
        if let user = Auth.auth().currentUser {
            updateFirestorePushTokenIfNeeded(userID: user.email!)
        }
        
    }
    
    func updateFirestorePushTokenIfNeeded(userID: String) {
        if let token = Messaging.messaging().fcmToken {
            let usersRef = Firestore.firestore().collection("users").document(userID)
            usersRef.setData(["fcmToken": token], merge: true)
        }
    }
    
//    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
//        print(remoteMessage.appData)
//    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let user = Auth.auth().currentUser {
            updateFirestorePushTokenIfNeeded(userID: user.email!)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userLoginStatus = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
        let myEmail = UserDefaults.standard.string(forKey: K.UDefaults.userEmail)
        
        if userLoginStatus,
           let receiverEmail = response.notification.request.content.userInfo["receiverEmail"] as? String,
           let senderEmail = response.notification.request.content.userInfo["senderEmail"] as? String,
           myEmail == receiverEmail {
            db.collection(K.FStore.usersCollection)
                .document(myEmail!)
                .collection(K.FStore.contactsCollection)
                .document(senderEmail)
                .getDocument { document, error in
                    if let e = error {
                        print(e)
                        return
                    } else {
                        if let data = document?.data(),
                           let imageURL = data["profile_picture"] as? String,
                           let name = data["name"] as? String,
                           let phone = data["phone_number"] as? String,
                           let color = data["chat_color"] as? String {
                            let currentContact = Contact()
                            currentContact.email = senderEmail
                            currentContact.name = name
                            currentContact.number = phone
                            currentContact.profilePicture = imageURL
                            currentContact.color = color
                            DispatchQueue.main.async {
                                self.openMessageView(contact: currentContact)
                            }
                            
                            
                        }
                    }
                }
        }
        // tell the app that we have finished processing the user’s action / response
        completionHandler()
    }
    
    func openMessageView(contact: Contact) {
        let storyboard = UIStoryboard(name: "Tab", bundle: nil)
        if  let tabVC = storyboard.instantiateViewController(withIdentifier: "TabVC") as? UITabBarController {
            guard let window = UIApplication.shared.keyWindow else { return }
            window.rootViewController = tabVC
            
            //push specific message view in
            if let navigation = tabVC.viewControllers?[0] as? UINavigationController,
               let messageViewController = storyboard.instantiateViewController(withIdentifier: "MessageVC") as? MessageViewController {
                messageViewController.selectedContact = contact
                navigation.pushViewController(messageViewController, animated: true)
            }
            window.makeKeyAndVisible()
        }
    }
    
}
