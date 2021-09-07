//
//  ContactsTableViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.

import UIKit
import Firebase

class ContactsTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    var contactDictionary = [String: [Contact]]()
    var contactLetters = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        title = "Contacts"

        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        loadContacts()
    }
    
    private func loadContacts() {
        db.collection(K.FStore.usersCollection).document(Auth.auth().currentUser!.email!).collection(K.FStore.contactsCollection).order(by: "name")
            .addSnapshotListener { querySnapshot, error in
                self.contactDictionary = [String: [Contact]]()
                self.contactLetters = [String]()
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
                        newContact.profilePicture = data["profile_picture"] as? String
                        
                        //
                        let firstLetter = String(contactName.first!).uppercased()
                        if !self.contactLetters.contains(firstLetter) {
                            self.contactLetters.append(firstLetter)
                        }
                        if self.contactDictionary[firstLetter] != nil {
                            self.contactDictionary[firstLetter]?.append(newContact)
                        } else {
                            self.contactDictionary[firstLetter] = [newContact]
                        }
                        
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return contactDictionary.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return contactLetters[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactDictionary[contactLetters[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath)
        cell.textLabel?.text = contactDictionary[contactLetters[indexPath.section]]![indexPath.row].name
        
        return cell
    }

}
