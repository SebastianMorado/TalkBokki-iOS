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
    
    let fsManager = FirestoreManagerForContacts()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let emailPredicate = EmailPredicate()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fsManager.delegate = self
        searchBar.delegate = self
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        self.definesPresentationContext = true
        title = "Contacts"
        
        
        fsManager.loadContacts()
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
                self.fsManager.getPersonalData(email: text)
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
    

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fsManager.filteredDictionary.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fsManager.filteredLetters[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fsManager.filteredDictionary[fsManager.filteredLetters[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsCell
        cell.cellLabel.text = fsManager.filteredDictionary[fsManager.filteredLetters[indexPath.section]]![indexPath.row].name
        let url = URL(string: fsManager.filteredDictionary[fsManager.filteredLetters[indexPath.section]]![indexPath.row].profilePicture)
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
        
        let selectedContact = fsManager.filteredDictionary[fsManager.filteredLetters[indexPath.section]]![indexPath.row]
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
            fsManager.filteredDictionary = fsManager.contactDictionary
            fsManager.filteredLetters = fsManager.contactLetters
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
        fsManager.filteredDictionary = [:]
        fsManager.filteredLetters = []
        for (letter, contactArrayForLetter) in fsManager.contactDictionary {
            let newContactArrayForLetter : [Contact] = contactArrayForLetter.filter { contact in
                return contact.name.localizedStandardContains(searchText)
            }
            if newContactArrayForLetter.count > 0 {
                fsManager.filteredLetters.append(letter)
                fsManager.filteredDictionary[letter] = newContactArrayForLetter
            }
        }
    }
}
