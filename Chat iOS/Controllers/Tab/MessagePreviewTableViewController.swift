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

class MessagePreviewTableViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var refresh = UIRefreshControl()
    var fsManager = FirestoreManagerForMessagePreview()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser == nil {
            UserDefaults.standard.set(false, forKey: K.UDefaults.userIsLoggedIn)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginNavController = storyboard.instantiateViewController(identifier: "rootVC")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
            return
        }
        
        fsManager.delegate = self
        searchBar.delegate = self

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        title = "Messages"

        //register custom cell for messages
        tableView.register(UINib(nibName: K.cellNibName2, bundle: nil), forCellReuseIdentifier: K.cellIdentifier2)
        
        //add refresh control
        refresh.addTarget(self, action: #selector(refreshTableData(_:)), for: .valueChanged)
        tableView.refreshControl = refresh
        
        fsManager.loadContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.barTintColor = nil
        self.navigationController?.navigationBar.backgroundColor = nil
        fsManager.loadMessages()
    }
    
    @objc private func refreshTableData(_ sender: Any) {
        // reload Contacts
        fsManager.loadMessages()
    }
    
    @IBAction func createNewMessage(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToNewMessage", sender: self)
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
        return fsManager.filteredChats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier2, for: indexPath) as! MessagePreviewCell
        
        if fsManager.filteredChatsMostRecent.count == 0 || fsManager.filteredChats.count == 0 {
            return cell
        }
        
        //set up variables for email and contact details
        let currentChatEmail = fsManager.filteredChatsMostRecent[indexPath.row]
        let currentContact = fsManager.filteredChats[currentChatEmail]!
        
        
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
            cell.messageText.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        } else {
            cell.messageText.textColor = .black
            cell.messageText.font = UIFont.systemFont(ofSize: 13, weight: .bold)
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

        let contactEmail = fsManager.filteredChatsMostRecent[indexPath.row]
        let contact = fsManager.filteredChats[contactEmail]
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
            fsManager.filteredChats = fsManager.chats
            fsManager.filteredChatsMostRecent = fsManager.chatsMostRecent
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
        fsManager.filteredChats = [:]
        fsManager.filteredChatsMostRecent = []
        fsManager.filteredChats = fsManager.chats.filter {
            $0.value.name.localizedStandardContains(searchText)
        }
        for (email, _) in fsManager.filteredChats {
            fsManager.filteredChatsMostRecent.append(email)
        }
    }
    
}
