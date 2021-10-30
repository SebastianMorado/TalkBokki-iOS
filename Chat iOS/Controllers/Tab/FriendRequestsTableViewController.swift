//
//  FriendRequestsTableViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/10/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class FriendRequestsTableViewController: UITableViewController {
    
    let fsManager = FirestoreManagerForFriendRequests()

    override func viewDidLoad() {
        super.viewDidLoad()
        fsManager.delegate = self
        fsManager.loadFriendRequests()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return fsManager.friendReqList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendRequestCell", for: indexPath) as! FriendRequestCell

        cell.cellEmail.text = fsManager.friendReqList[indexPath.row].email
        cell.cellName.text = fsManager.friendReqList[indexPath.row].name
        let url = URL(string: fsManager.friendReqList[indexPath.row].profilePicture)
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
    
    //MARK: - Table View Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alert = UIAlertController(title: "Accept Friend Request from \(fsManager.friendReqList[indexPath.row].name)?", message: "", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in }
        
        let add = UIAlertAction(title: "Add", style: .default) { (action) in
            self.fsManager.addToContacts_User(email: self.fsManager.friendReqList[indexPath.row].email, rowIndex: indexPath.row)
        }
        
        let remove = UIAlertAction(title: "Remove", style: .default) { (action) in
            self.fsManager.deleteFriendRequest(email: self.fsManager.friendReqList[indexPath.row].email)
        }
        
        alert.addAction(cancel)
        alert.addAction(add)
        alert.addAction(remove)
        
        present(alert, animated: true, completion: nil)
    }

}
