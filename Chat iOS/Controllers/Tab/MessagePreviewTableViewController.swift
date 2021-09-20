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
    var refresh = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("LOAD")

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
        loadMessages()
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

                        //extract fields from data and create new contact object
                        let newContact = Contact()
                        newContact.name = data["name"] as! String
                        newContact.number = data["phone_number"] as! String
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
        }
    }

    // MARK: - Table view data source

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier2, for: indexPath) as! MessagePreviewCell
        
        if chatsMostRecent.count == 0 || chats.count == 0 {
            return cell
        }
        
        let currentChatEmail = chatsMostRecent[indexPath.row]
        let currentContact = chats[currentChatEmail]!
        guard let mostRecentMessage = currentContact.messages else { return cell }
        
        let mostRecentMessageText = mostRecentMessage[0].text != "" ? mostRecentMessage[0].text : "[Image]"
        cell.contactName.text = currentContact.name
        if mostRecentMessage[0].senderEmail == Auth.auth().currentUser!.email! {
            cell.messageText.text = "You: " + mostRecentMessageText
        } else {
            cell.messageText.text = mostRecentMessageText
        }
        //change color of label text depending if message has been read or not
        if mostRecentMessage[0].wasRead {
            cell.messageText.textColor = .gray
        } else {
            cell.messageText.font = UIFont.systemFont(ofSize: cell.messageText.font!.pointSize, weight: .semibold)
        }
        
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

        let contactEmail = chatsMostRecent[indexPath.row]
        let contact = chats[contactEmail]
        self.performSegue(withIdentifier: "goToChat", sender: contact)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    

}

//MARK: - Search bar delegate

extension MessagePreviewTableViewController: UISearchBarDelegate {
    
}
