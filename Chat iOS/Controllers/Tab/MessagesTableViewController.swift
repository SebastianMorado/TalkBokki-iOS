//
//  MessagesTableViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase

extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

class MessagesTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var chats = [String: Contact]()
    private var chatsMostRecent = [String]()
    var selectedContactEmail : String = ""
    var selectedContactName : String = ""
    var refresh = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

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
    
    @IBAction func createNewMessage(_ sender: UIBarButtonItem) {
        
    }
    
    @objc private func refreshTableData(_ sender: Any) {
        // reload Contacts
        loadContacts()
    }
    
    private func loadContacts() {
        let group = DispatchGroup()
        
        db.collection(K.FStore.usersCollection)
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
                        //extract fields from data
                        
                        //create new contact object
                        let newContact = Contact()
                        newContact.name = data["name"] as! String
                        newContact.email = doc.documentID
                        newContact.profilePicture = data["profile_picture"] as! String
                        newContact.mostRecentMessage = (data["most_recent_message"] as! Timestamp).dateValue()
                        self.chats[doc.documentID] = newContact
                        self.chatsMostRecent.append(doc.documentID)
                    }
                    
                }
                group.leave()
                
                
                group.notify(queue: DispatchQueue.global()) {
                    self.loadMessages()
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
                .getDocuments { querySnapshot, error in
                    
                    var messages = [Message]()
                    if let e = error {
                        print(e.localizedDescription)
                    } else {
                        for doc in querySnapshot!.documents {
                            let data = doc.data()
                            let newMessage = Message()
                            newMessage.text = data["text"] as! String
                            newMessage.imageURL = data["image_url"] as! String
                            newMessage.senderEmail = data["sender_email"] as! String
                            newMessage.date = (data["date"] as! Timestamp).dateValue()
                            messages.append(newMessage)
                        }
                        self.chats[contactEmail]?.messages = messages
                        
                    }
                    group.leave()
            }
        }
        group.notify(queue: DispatchQueue.global()) {
            print("reloading data now...")
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refresh.endRefreshing()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            let destinationVC = segue.destination as! ChatViewController
            destinationVC.selectedContactEmail = selectedContactEmail
            destinationVC.selectedContactName = selectedContactName
        }
    }

    // MARK: - Table view data source

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier2, for: indexPath) as! ChatCell
        let currentChatEmail = chatsMostRecent[indexPath.row]
        cell.contactName.text = chats[currentChatEmail]!.name
        cell.messageText.text = chats[currentChatEmail]!.messages![0].text
        return cell
    }
    
    
    
    //MARK: - Table View Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedContactEmail = chatsMostRecent[indexPath.row]
        selectedContactName = chats[selectedContactEmail]!.name
        self.performSegue(withIdentifier: "goToChat", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    

}

//MARK: - Search bar delegate

extension MessagesTableViewController: UISearchBarDelegate {
    
}
