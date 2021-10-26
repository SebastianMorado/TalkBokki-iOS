//
//  MessagesTableViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.height / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

class MessagePreviewTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var chats = [String: Contact]()
    private var chatsMostRecent = [String]()
    private var filteredChats = [String: Contact]()
    private var filteredChatsMostRecent = [String]()
    
    var refresh = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser == nil {
            UserDefaults.standard.set(false, forKey: K.UDefaults.userIsLoggedIn)
            //self.performSegue(withIdentifier: "unwindToWelcomeScreen", sender: self)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginNavController = storyboard.instantiateViewController(identifier: "rootVC")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
            return
        }
        
        
        searchBar.delegate = self

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        title = "Messages"

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        //register custom cell for messages
        tableView.register(UINib(nibName: K.cellNibName2, bundle: nil), forCellReuseIdentifier: K.cellIdentifier2)
        
        //add refresh control
        refresh.addTarget(self, action: #selector(refreshTableData(_:)), for: .valueChanged)
        tableView.refreshControl = refresh
        
        loadContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.barTintColor = nil
        self.navigationController?.navigationBar.backgroundColor = nil
    }
    
    
    @IBAction func createNewMessage(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToNewMessage", sender: self)
    }
    
    @objc private func refreshTableData(_ sender: Any) {
        // reload Contacts
        loadMessages()
    }
    
    private func loadContacts() {
        let group = DispatchGroup()
        
        let snapshot = db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .order(by: "most_recent_message", descending: true)
            .addSnapshotListener { querySnapshot, error in
                group.enter()
                self.chats = [String: Contact]()
                self.chatsMostRecent = [String]()
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    for doc in querySnapshot!.documents {
                        let data = doc.data()

                        //extract fields from data and create new contact object
                        let newContact = Contact()
                        newContact.name = data["name"] as? String ?? ""
                        newContact.number = data["phone_number"] as? String ?? ""
                        newContact.color = data["chat_color"] as? String ?? ""
                        newContact.fcmToken = data["fcmToken"] as? String ?? ""
                        newContact.email = doc.documentID
                        newContact.profilePicture = data["profile_picture"] as? String ?? ""
                        newContact.isMuted = data["isMuted"] as? Bool ?? false
                        newContact.mostRecentMessage = (data["most_recent_message"] as! Timestamp).dateValue()
                        self.checkForUpdates(contact: newContact)
                        self.chats[doc.documentID] = newContact
                        self.chatsMostRecent.append(doc.documentID)
                    }
                    
                }
                group.leave()
                
                
                group.notify(queue: DispatchQueue.global()) {
                    self.loadMessages()
                }
            }
        
        SnapshotListeners.shared.snapshotList.append(snapshot)
        
        
    }
    
    private func checkForUpdates(contact: Contact) {
        db.collection(K.FStore.usersCollection)
            .document(contact.email)
            .getDocument { document, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    if let data = document?.data()! {
                        let imageURL = data["profile_picture"] as? String ?? ""
                        let phone = data["phone_number"] as? String ?? ""
                        let token = data["fcmToken"] as? String ?? ""
                        if imageURL != contact.profilePicture || phone != contact.number || token != contact.fcmToken || contact.color == "" {
                            contact.profilePicture = imageURL
                            contact.number = phone
                            contact.fcmToken = token
                            self.updateContact(contact: contact)
                        }
                        
                    }
                }
            }
    }
    
    private func updateContact(contact: Contact) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(contact.email)
            .getDocument { document, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    document?.reference.updateData(["profile_picture" : contact.profilePicture])
                    document?.reference.updateData(["phone_number" : contact.number])
                    document?.reference.updateData(["fcmToken" : contact.fcmToken])
                    if contact.color == "" {
                        document?.reference.updateData(["chat_color" : K.chatColors[0]])
                    }
                }
            }
    }
    
    private func loadMessages() {
        let group = DispatchGroup()
        
        for (contactEmail, _) in chats {
            group.enter()
            db.collection(K.FStore.usersCollection)
                .document(Auth.auth().currentUser!.email!)
                .collection(K.FStore.contactsCollection)
                .document(contactEmail)
                .collection(K.FStore.messagesCollection)
                .order(by: "date", descending: true)
                .limit(to: 1)
                .getDocuments { querySnapshot, error in
                    
                    if let e = error {
                        print(e.localizedDescription)
                    } else {
                        let mostRecentMessage = querySnapshot!.documents[0].data()
                        let newMessage = Message()
                        newMessage.text = mostRecentMessage["text"] as! String
                        newMessage.imageURL = mostRecentMessage["image_url"] as! String
                        newMessage.senderEmail = mostRecentMessage["sender_email"] as! String
                        newMessage.wasRead = mostRecentMessage["wasRead"] as! Bool
                        newMessage.date = (mostRecentMessage["date"] as! Timestamp).dateValue()
                        
                        self.chats[contactEmail]?.messages = [newMessage]
                        
                    }
                    group.leave()
            }
        }
        group.notify(queue: DispatchQueue.global()) {
            print("reloading data now...")
            DispatchQueue.main.async {
                
                self.filteredChats = self.chats
                self.filteredChatsMostRecent = self.chatsMostRecent
                
                self.tableView.reloadData()
                self.refresh.endRefreshing()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            if let destinationVC = segue.destination as? MessageViewController, let contact = sender as? Contact {
                destinationVC.selectedContact = contact
            }
        } else if segue.identifier == "goToNewMessage" {
            if let destinationVC = segue.destination as? NewMessageTableViewController {
                destinationVC.delegate = self
            }
        }
    }

    // MARK: - Table view data source

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredChats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier2, for: indexPath) as! MessagePreviewCell
        
        if filteredChatsMostRecent.count == 0 || filteredChats.count == 0 {
            return cell
        }
        
        //set up variables for email and contact details
        let currentChatEmail = filteredChatsMostRecent[indexPath.row]
        let currentContact = filteredChats[currentChatEmail]!
        
        
        //exit if somehow messages arent loading
        guard let mostRecentMessage = currentContact.messages else { return cell }
        
        //display placeholder image text if most recent message was image
        let mostRecentMessageText = mostRecentMessage[0].text != "" ? mostRecentMessage[0].text : "[Image]"
        cell.contactName.text = currentContact.name
        
        //set up time to be displayed in preview
        let dateFormatter = DateFormatter()
        let timeDiff = Calendar.current.dateComponents([.hour], from: currentContact.mostRecentMessage!, to: Date()).hour!
        if timeDiff < 24 {
            dateFormatter.dateFormat = "h:mm a"
        } else if timeDiff < 168 {
            dateFormatter.dateFormat = "E"
        } else {
            dateFormatter.dateFormat = "MMM d"
        }

        
        let dateString = " · " + dateFormatter.string(from: currentContact.mostRecentMessage!)
        
        //add a "You: " to preview if current user sent the most recent message
        if mostRecentMessage[0].senderEmail == Auth.auth().currentUser!.email! {
            cell.messageText.text = "You: " + mostRecentMessageText + dateString
        } else {
            cell.messageText.text = mostRecentMessageText + dateString
        }
        
        //change color of label text depending if message has been read or not
        if mostRecentMessage[0].wasRead {
            cell.messageText.textColor = .gray
            cell.messageText.font = UIFont.systemFont(ofSize: cell.messageText.font!.pointSize, weight: .regular)
        } else {
            cell.messageText.font = UIFont.systemFont(ofSize: cell.messageText.font!.pointSize, weight: .semibold)
        }
        
        //set profile pic of contact to display
        let url = URL(string: currentContact.profilePicture)
        let processor = DownsamplingImageProcessor(size: cell.contactImage.bounds.size)
        cell.contactImage.kf.setImage(
            with: url,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1))
            ])
        cell.setRoundedImage()
        return cell
    }
    
    
    
    //MARK: - Table View Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let contactEmail = filteredChatsMostRecent[indexPath.row]
        let contact = filteredChats[contactEmail]
        self.performSegue(withIdentifier: "goToChat", sender: contact)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    

}

//MARK: - Search bar delegate

extension MessagePreviewTableViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //loop through each entry in Contact Dictionary using each letter of contactLetters
        if searchBar.text?.count ?? 0 > 0 {
            filterContacts(searchText: searchBar.text!)
            tableView.reloadData()
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            filteredChats = chats
            filteredChatsMostRecent = chatsMostRecent
            tableView.reloadData()
            
            //if there is no text, deselect the search bar and remove the keyboard
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
            
        } else {
            filterContacts(searchText: searchBar.text!)
            tableView.reloadData()
        }
    }
    
    
    func filterContacts(searchText: String) {
        filteredChats = [:]
        filteredChatsMostRecent = []
        filteredChats = chats.filter {
            $0.value.name.localizedStandardContains(searchText)
        }
        for (email, _) in filteredChats {
            filteredChatsMostRecent.append(email)
        }
    }
    
}
