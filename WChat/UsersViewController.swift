//
//  UsersViewController.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import Firebase

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UserTableViewCellDelegate {

    var allUsers: [FUser] = []

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadUsers(filter: kCITY)
    }

    //MARK: TableView Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        cell.delegate = self

        cell.generateCellWith(fUser: allUsers[indexPath.row], indexPath: indexPath)
        
        return cell
    }


    
    //MARK: LoadUsers
    
    func loadUsers(filter: String) {
        
        var query: DatabaseQuery!
        
        switch filter {
        case kCITY:
            query = userRef.queryOrdered(byChild: kCITY).queryEqual(toValue: FUser.currentUser()!.city)
        case kCOUNTRY:
            query = userRef.queryOrdered(byChild: kCOUNTRY).queryEqual(toValue: FUser.currentUser()!.country)
        default:
            query = userRef.queryOrdered(byChild: kFIRSTNAME)
        }
        
        userHandler = query.observe(.value, with: { snapshot in
            
            if snapshot.exists() {

                self.allUsers = []
                
                let sortedUsersDictionary = ((snapshot.value as! NSDictionary).allValues as NSArray).sortedArray(using: [NSSortDescriptor(key: kFIRSTNAME, ascending: true)])
                
                
                for userDictionary in sortedUsersDictionary {
                    
                    let userDictionary = userDictionary as! NSDictionary
                    let fUser = FUser.init(_dictionary: userDictionary)
                    
                    if fUser.objectId != FUser.currentUser()!.objectId {
                        
                        self.allUsers.append(fUser)
                    }
                    
                }

                self.tableView.reloadData()
            }
        })
        
    }

    
    
    //MARK: IBActions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func filterSegmentChanged(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: kCOUNTRY)
        case 2:
            loadUsers(filter: "")
        default:
            return
        }
    }
    
    
    //MARK: UserTableViewCellDelegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewController

        profileVC.user = allUsers[indexPath.row]

        self.present(profileVC, animated: true, completion: nil)
    }

    
    
    
    
}
