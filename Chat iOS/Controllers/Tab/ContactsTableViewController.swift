//
//  ContactsTableViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 8/28/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.

import UIKit
import Firebase
import Kingfisher
import Peppermint

class ContactsTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var contactDictionary = [String: [Contact]]()
    var contactLetters = [String]()

    var filteredDictionary = [String: [Contact]]()
    var filteredLetters = [String]()
    
    private let emailPredicate = EmailPredicate()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        self.definesPresentationContext = true
        title = "Contacts"
        
        
        loadContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func addNewContact(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Find a Friend", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Add Friend", style: .default, handler: { _ in
            self.addFriend() }))

        alert.addAction(UIAlertAction(title: "Check Friend Requests", style: .default, handler: { action in
            self.performSegue(withIdentifier: "goToFriendRequests", sender: self)
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    func addFriend() {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add Friend", message: "", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            if let text = textField.text, self.emailPredicate.evaluate(with: text), text != Auth.auth().currentUser?.email {
                self.getPersonalData(email: text)
            } else {
                self.presentAlert(message: "Please input valid email")
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Email"
            textField = alertTextField
        }
        
        alert.addAction(cancel)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func getPersonalData(email: String) {
        if let myEmail = Auth.auth().currentUser?.email {
            db.collection(K.FStore.usersCollection)
                .document(myEmail)
                .getDocument { document, error in
                    if let e = error {
                        print(e.localizedDescription)
                    } else {
                        if let data = document?.data()! {
                            let imageURL = data["profile_picture"] as! String
                            let name = data["name"] as! String
                            let number = data["phone_number"] as! String
                            self.checkIfUserExists(email: email, imgURL: imageURL, name: name, number: number)
                        }
                    }
                }
        }
    }
    
    private func checkIfUserExists(email: String, imgURL: String, name: String, number: String) {
        db.collection(K.FStore.usersCollection)
            .document(email)
            .getDocument { document, error in
                if let doc = document, doc.exists {
                    self.checkIfYouAreAlreadyFriends(email: email, imgURL: imgURL, name: name, number: number)
                } else if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.presentAlert(message: "There is no account registered under \(email)")
                }
            }
    }
    
    private func checkIfYouAreAlreadyFriends(email: String, imgURL: String, name: String, number: String) {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .document(email)
            .getDocument { document, error in
                if let doc = document, doc.exists {
                    self.presentAlert(message: "You are already friends!")
                } else if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.sendFriendRequest(email: email, imgURL: imgURL, name: name, number: number)
                }
            }
    }
    
    private func sendFriendRequest(email: String, imgURL: String, name: String, number: String) {
        let currentTimestamp = Timestamp.init(date: Date())
        
        if let myEmail = Auth.auth().currentUser?.email {
            //save it to current users database
            db.collection(K.FStore.usersCollection)
                .document(email)
                .collection(K.FStore.friendRequestCollection)
                .document(myEmail)
                .setData([
                            "name": name,
                            K.FStore.dateField: currentTimestamp,
                            "phone_number": number,
                            "profile_picture": imgURL],
                         merge: true
                ) { (error) in
                if let e = error {
                    self.presentAlert(message: e.localizedDescription)
                } else {
                    self.presentAlert(message: "Friend Request Sent!", title: "Success!")
                }
                    
            }
        }
    }
    
    private func loadContacts() {
        db.collection(K.FStore.usersCollection)
            .document(Auth.auth().currentUser!.email!)
            .collection(K.FStore.contactsCollection)
            .order(by: "name")
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
                        newContact.number = data["phone_number"] as! String
                        newContact.profilePicture = data["profile_picture"] as! String
                        self.checkForUpdates(contact: newContact)
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
                        self.filteredLetters = self.contactLetters
                        self.filteredDictionary = self.contactDictionary
                        self.tableView.reloadData()
                    }
                }
            }
    }
    
    private func checkForUpdates(contact: Contact) {
        db.collection(K.FStore.usersCollection)
            .document(contact.email)
            .getDocument { document, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    if let data = document?.data()! {
                        let imageURL = data["profile_picture"] as! String
                        let name = data["name"] as! String
                        let phone = data["phone_number"] as! String
                        if imageURL != contact.profilePicture || name != contact.name || phone != contact.number {
                            contact.profilePicture = imageURL
                            contact.name = name
                            contact.number = phone
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
                    document?.reference.updateData(["name" : contact.name])
                    document?.reference.updateData(["phone_number" : contact.number])
                }
            }
    }
    
    func presentAlert(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return filteredDictionary.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filteredLetters[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDictionary[filteredLetters[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsCell
        cell.cellLabel.text = filteredDictionary[filteredLetters[indexPath.section]]![indexPath.row].name
        let url = URL(string: filteredDictionary[filteredLetters[indexPath.section]]![indexPath.row].profilePicture)
        let processor = DownsamplingImageProcessor(size: cell.cellImage.bounds.size)
        cell.cellImage.kf.setImage(
            with: url,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1))
            ])
        cell.setRoundedImage()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedContact = filteredDictionary[filteredLetters[indexPath.section]]![indexPath.row]
        self.performSegue(withIdentifier: "goToContactDetail", sender: selectedContact)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToContactDetail" {
            if let destinationVC = segue.destination as? ContactDetailViewController, let selectedContact = sender as? Contact {
                destinationVC.selectedContact = selectedContact
                destinationVC.delegate = self
            }

        } else if segue.identifier == "goToChat" {
            if let destinationVC = segue.destination as? MessageViewController, let contact = sender as? Contact {
                destinationVC.selectedContact = contact
            } else {
                print("whoops!")
            }
            
        }
    }

}

//MARK: - Search Bar Delegate

extension ContactsTableViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //loop through each entry in Contact Dictionary using each letter of contactLetters
        if searchBar.text?.count ?? 0 > 0 {
            filterContacts(searchText: searchBar.text!)
            tableView.reloadData()
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            filteredDictionary = contactDictionary
            filteredLetters = contactLetters
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
        filteredDictionary = [:]
        filteredLetters = []
        for (letter, contactArrayForLetter) in contactDictionary {
            let newContactArrayForLetter : [Contact] = contactArrayForLetter.filter { contact in
                return contact.name.localizedStandardContains(searchText)
            }
            if newContactArrayForLetter.count > 0 {
                filteredLetters.append(letter)
                filteredDictionary[letter] = newContactArrayForLetter
            }
        }
    }
}
