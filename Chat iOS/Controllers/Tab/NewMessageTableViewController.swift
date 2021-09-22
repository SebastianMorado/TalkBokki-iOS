//
//  NewMessageTableViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/22/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class NewMessageTableViewController: UITableViewController {

    let db = Firestore.firestore()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var delegate : MessagePreviewTableViewController?
    
    var contactList = [Contact]()
    var filteredContactList = [Contact]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        loadContacts()
        
    }
    
    private func loadContacts() {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .order(by: "name")
            .getDocuments { querySnapshot, error in
                self.contactList = []
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    for doc in querySnapshot!.documents {
                        let data = doc.data()
                        
                        //create new contact object
                        let newContact = Contact()
                        //extract fields from data
                        let contactName = data["name"] as! String
                        newContact.name = contactName
                        newContact.email = doc.documentID
                        newContact.number = data["phone_number"] as! String
                        newContact.profilePicture = data["profile_picture"] as! String
                        self.contactList.append(newContact)
                    }
                    DispatchQueue.main.async {
                        self.filteredContactList = self.contactList
                        self.tableView.reloadData()
                    }
                }
            }
    }
    
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return filteredContactList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newMessageCell", for: indexPath) as! NewMessageCell

        // Configure the cell...
        cell.cellLabel.text = filteredContactList[indexPath.row].name
        let url = URL(string: filteredContactList[indexPath.row].profilePicture)
        let processor = DownsamplingImageProcessor(size: cell.cellImage.bounds.size)
        cell.cellImage.kf.setImage(
            with: url,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.25))
            ])
        cell.setRoundedImage()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedContact = filteredContactList[indexPath.row]
        self.dismiss(animated: true) {
            self.delegate!.performSegue(withIdentifier: "goToChat", sender: selectedContact)
        }
    }


}


extension NewMessageTableViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //loop through each entry in Contact Dictionary using each letter of contactLetters
        if searchBar.text?.count ?? 0 > 0 {
            filterContacts(searchText: searchBar.text!)
            tableView.reloadData()
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            filteredContactList = contactList
            tableView.reloadData()
            
        } else {
            filterContacts(searchText: searchBar.text!)
            tableView.reloadData()
        }
    }
    
    
    func filterContacts(searchText: String) {
        filteredContactList = contactList.filter {
            $0.name.localizedStandardContains(searchText)
        }
    }
    
}
