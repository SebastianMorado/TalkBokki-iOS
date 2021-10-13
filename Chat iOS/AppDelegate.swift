//
//  AppDelegate.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 06/01/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.

import UIKit
import Firebase
import IQKeyboardManagerSwift
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        let db = Firestore.firestore()
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        //IQKeyboardManager.shared.keyboardDistanceFromTextField = 0
        let pushManager = PushNotificationManager()
        pushManager.registerForPushNotifications()
        
        // Check if launched from notification
        let notificationOption = launchOptions?[.remoteNotification]
        
        let userLoginStatus = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
        let myEmail = UserDefaults.standard.string(forKey: K.UDefaults.userEmail)
        
        if userLoginStatus,
           let data = notificationOption as? [String: AnyObject],
           let receiverEmail = data["receiverEmail"] as? String,
           let senderEmail = data["senderEmail"] as? String,
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
    
        return true
    }
    
    func openMessageView(contact: Contact) {
        let storyboard = UIStoryboard(name: "Tab", bundle: nil)
        if  let tabVC = storyboard.instantiateViewController(withIdentifier: "TabVC") as? UITabBarController {
            //guard var rootViewController = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return false }
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

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

