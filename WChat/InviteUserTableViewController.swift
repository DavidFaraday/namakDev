//
//  InviteUserTableViewController.swift
//  WChat
//
//  Created by David Kababyan on 07/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase

class InviteUserTableViewController: UITableViewController, UserTableViewCellDelegate {

    @IBOutlet weak var headerView: UIView!
    
    var allUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList: [String] = []

    var newMemberIds: [String] = []
    var currentMemberIds: [String] = []
    var group: NSDictionary!
    
    
    
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

        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonPressed))]
        self.navigationItem.rightBarButtonItem?.isEnabled = false

        loadUsers(filter: kCITY)
        
        currentMemberIds = group[kMEMBERS] as! [String]
    }

    //MARK: IBActions

    @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {
        
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
    
    @objc func doneButtonPressed() {

        updateGroup(group: group)
    }
    

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.allUsersGrouped.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // find section title
        let sectionTitle = self.sectionTitleList[section]
        
        // find users for given section title
        let users = self.allUsersGrouped[sectionTitle]
        
        // return count for users
        return users!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        let sectionTitle = self.sectionTitleList[indexPath.section]
        
        //get all users of the section
        let users = self.allUsersGrouped[sectionTitle]
        
        cell.generateCellWith(fUser: users![indexPath.row], indexPath: indexPath)
        
        cell.delegate = self
        
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return self.sectionTitleList[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.sectionTitleList
    }
    
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }

    //MARK: TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionTitle = self.sectionTitleList[indexPath.section]

        let users = self.allUsersGrouped[sectionTitle]
        
        let selectedUser = users![indexPath.row]

        
        //if the selected user is member in group, we cannot add him
        if currentMemberIds.contains(selectedUser.objectId) {
            ProgressHUD.showError("Already in group!")
            return
        }

        //checkmarks
        if let cell = tableView.cellForRow(at: indexPath) {
            
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .checkmark
            }
        }
        
        //add/remove user from array

        let selected = newMemberIds.contains(selectedUser.objectId)
        
        if selected {
            
            let objectIndex = newMemberIds.index(of: selectedUser.objectId as String)
            newMemberIds.remove(at: objectIndex!)
        } else {
            newMemberIds.append(selectedUser.objectId as String)
        }
        
        
        //if we have users selected, the button is active
        self.navigationItem.rightBarButtonItem?.isEnabled = newMemberIds.count > 0
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


    //MARK: UserTableViewCellDelegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        
        let sectionTitle = self.sectionTitleList[indexPath.section]
        
        //get all users of the section
        let users = self.allUsersGrouped[sectionTitle]
        
        profileVC.user = users![indexPath.row]
        self.navigationController?.pushViewController(profileVC, animated: true)
        
    }

    //MARK: Helper functions
    func updateGroup(group: NSDictionary) {
        
        let tempGroup = group.mutableCopy() as! NSMutableDictionary
        
        let tempMembers = group[kMEMBERS] as! [String] + newMemberIds
        let tempMembersToPush = group[kMEMBERSTOPUSH] as! [String] + newMemberIds
        
        tempGroup[kMEMBERSTOPUSH] = tempMembersToPush
        tempGroup[kMEMBERS] = tempMembers
        
        firebase.child(kGROUP_PATH).child(tempGroup[kGROUPID] as! String).setValue(tempGroup)
        
        createRecentsForNewMembers(group: tempGroup)
        updateExistingRicentsWithNewValues(group: tempGroup)
        goToGroupChat(group: tempGroup)
    }
    
    func goToGroupChat(group: NSDictionary) {
        
        let chatVC = ChatViewController()
        
        chatVC.titleName = group[kNAME] as! String
        
        chatVC.memberIds = group[kMEMBERS] as! [String]
        
        chatVC.chatRoomId = group[kGROUPID] as! String
        
        chatVC.isGroup = true
        chatVC.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(chatVC, animated: true)
    }

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

    

}