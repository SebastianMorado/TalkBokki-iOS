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
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var delegate : MessagePreviewTableViewController?
    var fsManager = FirestoreManagerForCreateNewMessage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fsManager.delegate = self
        searchBar.delegate = self
        
        fsManager.loadContacts()
        
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return fsManager.filteredContactList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newMessageCell", for: indexPath) as! NewMessageCell

        // Configure the cell...
        cell.cellLabel.text = fsManager.filteredContactList[indexPath.row].name
        let url = URL(string: fsManager.filteredContactList[indexPath.row].profilePicture)
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
        
        let selectedContact = fsManager.filteredContactList[indexPath.row]
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
            fsManager.filteredContactList = fsManager.contactList
            tableView.reloadData()
            
        } else {
            filterContacts(searchText: searchBar.text!)
            tableView.reloadData()
        }
    }
    
    
    func filterContacts(searchText: String) {
        fsManager.filteredContactList = fsManager.contactList.filter {
            $0.name.localizedStandardContains(searchText)
        }
    }
    
}
