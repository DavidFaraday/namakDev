//
//  ContactsTableViewController.swift
//  WChat
//
//  Created by David Kababyan on 08/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import ProgressHUD

class ContactsTableViewController: UITableViewController, UISearchResultsUpdating {
    

    var users: [FUser] = []
    var matchedUsers: [FUser] = []
    var filteredMatchedUsers: [FUser] = []

    let searchController = UISearchController(searchResultsController: nil)

    
    lazy var contacts: [CNContact] = {
        
        let contactStore = CNContactStore()
        
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey] as [Any]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try     contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        return results
    }()

    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
        userRef.removeObserver(withHandle: userHandler)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsetsMake(-self.searchController.searchBar.frame.size.height, 0, 0, 0);
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        

        loadUsers()
    }

    
    //MARK: TableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            
            return filteredMatchedUsers.count
        } else {
            return matchedUsers.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UserTableViewCell
        
        var user: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            user = matchedUsers[indexPath.row]
        }
        
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        
        return cell
    }

    //MARK: TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)

        let userToChat: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            userToChat = filteredMatchedUsers[indexPath.row]
        } else {
            userToChat = matchedUsers[indexPath.row]
        }
        

        let chatVC = ChatViewController()
        
        chatVC.titleName = userToChat.firstname
        
        chatVC.memberIds = [FUser.currentId(), userToChat.objectId]
        chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
        
        chatVC.isGroup = false
        chatVC.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    //show/hide table search bar
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {

        let offset = self.tableView.contentOffset
        let barHeight = self.searchController.searchBar.frame.size.height
        
        if (offset.y <= barHeight/2.0) {
            self.tableView.contentInset = UIEdgeInsets.zero
            
        } else {
            self.tableView.contentInset = UIEdgeInsetsMake(-barHeight, 0, 0, 0);
        }
        
        self.tableView.contentOffset = offset
    }

    
    
    //MARK: IBActions
    @IBAction func inviteUsersButtonPressed(_ sender: Any) {
        
        let text = "Hey! Lets chat on WChat \(kAPPURL)"
        
        let objectsToShare: [Any] = [text]
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        activityViewController.setValue(NSLocalizedString("Lets chat on WChat", comment: ""), forKey: "subject")
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    //MARK: LoadUsers
    func loadUsers() {
        
        ProgressHUD.show()
        
        let query = userRef.queryOrdered(byChild: kFIRSTNAME)
        
        userHandler = query.observe(.value, with: { snapshot in
            
            if snapshot.exists() {
                
                self.matchedUsers = []
                self.users.removeAll()

                let sortedUsersDictionary = ((snapshot.value as! NSDictionary).allValues as NSArray).sortedArray(using: [NSSortDescriptor(key: kFIRSTNAME, ascending: true)])
                
                
                for userDictionary in sortedUsersDictionary {
                    
                    let userDictionary = userDictionary as! NSDictionary
                    let fUser = FUser.init(_dictionary: userDictionary)
                    
                    if fUser.objectId != FUser.currentId() {
                        
                        self.users.append(fUser)
                    }
                    
                }
                
                ProgressHUD.dismiss()
                self.tableView.reloadData()
            }
            ProgressHUD.dismiss()
            self.compareUsers()
        })
    }

    func compareUsers() {
        
        for user in users {
            
            if user.phoneNumber != "" {
                
                let contact = searchForContactUsingPhoneNumber(phoneNumber: user.phoneNumber)

                //if we have a match, we add to our array to display them
                if contact.count > 0 {
                    matchedUsers.append(user)
                    self.tableView.reloadData()
                }
                
            }
        }
    }

    
    //MARK: Contacts
    
    func searchForContactUsingPhoneNumber(phoneNumber: String) -> [CNContact] {
        
        var result: [CNContact] = []
        
        //go through all contacts
        for contact in self.contacts {
            
            if !contact.phoneNumbers.isEmpty {
                
                //get the digits only of the phone number and replace + with 00
                let phoneNumberToCompareAgainst = updatePhoneNumber(phoneNumber: phoneNumber, replacePlusSign: true)
                
                //go through every number of each contac
                for phoneNumber in contact.phoneNumbers {
                    
                    let fulMobNumVar  = phoneNumber.value
                    let countryCode = fulMobNumVar.value(forKey: "countryCode") as? String
                    let phoneNumber = fulMobNumVar.value(forKey: "digits") as? String
                    
                    let contactNumber = removeCountryCode(countryCodeLetters: countryCode!, fullPhoneNumber: phoneNumber!)
                    
                    //compare phoneNumber of contact with given user's phone number
                    if contactNumber == phoneNumberToCompareAgainst {
                        result.append(contact)
                    }
                    
                }
            }
        }
        
        return result
    }


    func updatePhoneNumber(phoneNumber: String, replacePlusSign: Bool) -> String {
        
        if replacePlusSign {
            return phoneNumber.replacingOccurrences(of: "+", with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
            
        } else {
            return phoneNumber.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        }
    }
    
    
    func removeCountryCode(countryCodeLetters: String, fullPhoneNumber: String) -> String {
        
        let countryCode = CountryCode()
        
        let countryCodeToRemove = countryCode.codeDictionaryShort[countryCodeLetters.uppercased()]
        
        //remove + from country code
        let updatedCode = updatePhoneNumber(phoneNumber: countryCodeToRemove!, replacePlusSign: true)
        
        //remove countryCode
        let replacedNUmber = fullPhoneNumber.replacingOccurrences(of: updatedCode, with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        
        
        //        print("Code \(countryCodeLetters)")
        //        print("full number \(fullPhoneNumber)")
        //        print("code to remove \(updatedCode)")
        //        print("clean number is \(replacedNUmber)")
        
        return replacedNUmber
    }


    
    
    
    
    //MARK: search controler functions
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredMatchedUsers = matchedUsers.filter({ (user) -> Bool in
            
            return user.firstname.lowercased().contains(searchText.lowercased())
            
        })
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }

    
    
    
    
    
    
}
