//
//  UsersTableViewController.swift
//  WChat
//
//  Created by David Kababyan on 25/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class UsersTableViewController: UITableViewController, UserTableViewCellDelegate, UISearchResultsUpdating {

    @IBOutlet weak var headerView: UIView!
    
    
    var allUsers: [FUser] = []
    var filteredUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList: [String] = []
    
    let searchController = UISearchController(searchResultsController: nil)

    
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
        userRef.removeObserver(withHandle: userHandler)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Users"
        tableView.tableHeaderView = headerView
        //to remove empty cell lines
        tableView.tableFooterView = UIView()
        
        clearsSelectionOnViewWillAppear = true

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true


        loadUsers(filter: kCITY)
    }
    

    //MARK: IBActions
    
    
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

    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return self.allUsersGrouped.count
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUsers.count
        } else {
            // find section title
            let sectionTitle = self.sectionTitleList[section]
            
            // find users for given section title
            let users = self.allUsersGrouped[sectionTitle]
            
            // return count for users
            return users!.count
        }

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        var user: FUser

        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            
            let sectionTitle = self.sectionTitleList[indexPath.section]
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]
            
            user = users![indexPath.row]
        }

        
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        
        cell.delegate = self
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            return self.sectionTitleList[section]
        }
        
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return self.sectionTitleList
        }
    }
    
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }

    //MARK: TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionTitle = self.sectionTitleList[indexPath.section]

        let userToChat: FUser

        if searchController.isActive && searchController.searchBar.text != "" {
            userToChat = filteredUsers[indexPath.row]
        } else {
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]
            
            userToChat = users![indexPath.row]
        }

        
        let chatVC = ChatViewController()
        
        chatVC.titleName = userToChat.firstname
        
        chatVC.membersToPush = [FUser.currentId(), userToChat.objectId]
        chatVC.memberIds = [FUser.currentId(), userToChat.objectId]
        chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
        
        chatVC.isGroup = false
        chatVC.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(chatVC, animated: true)

    }



    
    //MARK: Helper functions

    fileprivate func splitDataInToSection() {

        // set section title "" at initial
        var sectionTitle: String = ""
        
        // iterate all records from array
        for i in 0..<self.allUsers.count {
            
            // get current record
            let currentUser = self.allUsers[i]

            // find first character from current record
            let firstChar = currentUser.firstname.first!
            
            // convert first character into string
            let firstCharString = "\(firstChar)"
            
            // if first character not match with past section title then create new section
            if firstCharString != sectionTitle {
                
                // set new title for section
                sectionTitle = firstCharString
                
                // add new section having key as section title and value as empty array of string
                self.allUsersGrouped[sectionTitle] = []
                
                // append title within section title list
                self.sectionTitleList.append(sectionTitle)
            }
            
            // add record to the section
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
        
    }


    //MARK: LoadUsers
    
    func loadUsers(filter: String) {
        
        ProgressHUD.show()
        
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
                self.sectionTitleList = []
                self.allUsersGrouped = [:]
                
                let sortedUsersDictionary = ((snapshot.value as! NSDictionary).allValues as NSArray).sortedArray(using: [NSSortDescriptor(key: kFIRSTNAME, ascending: true)])
                
                
                for userDictionary in sortedUsersDictionary {
                    
                    let userDictionary = userDictionary as! NSDictionary
                    let fUser = FUser.init(_dictionary: userDictionary)
                    
                    if fUser.objectId != FUser.currentId() {
                        
                        self.allUsers.append(fUser)
                    }
                    
                }
                
                ProgressHUD.dismiss()
                self.splitDataInToSection()
                self.tableView.reloadData()
            }
        })
        
    }
    
    //MARK: search controler functions
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredUsers = allUsers.filter({ (user) -> Bool in
            
            return user.firstname.lowercased().contains(searchText.lowercased())
            
        })
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    


    //MARK: UserTableViewCellDelegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        
        var user: FUser!

        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        
        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)
    }


}
