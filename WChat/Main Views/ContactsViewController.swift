//
//  ContactsTableViewController.swift
//  WChat
//
//  Created by David Kababyan on 08/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import Contacts
import FirebaseFirestore
import ProgressHUD

class ContactsViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate, UserTableViewCellDelegate {
    
    var users: [FUser] = []
    var matchedUsers: [FUser] = []
    var filteredMatchedUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList: [String] = []

    
    @IBOutlet weak var noUsersLabel: UILabel!
    
    var isGroup = false
    var memberIdsOfGroupChat: [String] = []
    var membersOfGroupChat: [FUser] = []

    
    @IBOutlet weak var tableView: UITableView!
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //to remove empty cell lines
        tableView.tableFooterView = UIView()

        //because of bar button item bug
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintAdjustmentMode = .normal
        self.navigationController?.navigationBar.tintAdjustmentMode = .automatic
        //end of bug fix
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Contacts"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        getContactsOfCurrentUser()
        setupButtons()
    }

    
    //MARK: TableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return self.allUsersGrouped.count
        }
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredMatchedUsers.count
        } else {
            // find section title
            let sectionTitle = self.sectionTitleList[section]

            // find users for given section title
            let users = self.allUsersGrouped[sectionTitle]
            
            // return count for users
            return users!.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UserTableViewCell
        
        var user: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            
            let sectionTitle = self.sectionTitleList[indexPath.section]
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]

            user = users![indexPath.row]
        }
        
        cell.delegate = self
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            return self.sectionTitleList[section]
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return self.sectionTitleList
        }
    }
    
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }

    //MARK: TableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)

        let sectionTitle = self.sectionTitleList[indexPath.section]

        let userToChat: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            userToChat = filteredMatchedUsers[indexPath.row]
        } else {
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]

            userToChat = users![indexPath.row]
        }
        
        if !isGroup {

            if !checkBlockedStatus(withUser: userToChat) {
                let chatVC = ChatViewController()
                
                chatVC.titleName = userToChat.firstname
                
                chatVC.memberIds = [FUser.currentId(), userToChat.objectId]
                chatVC.membersToPush = [FUser.currentId(), userToChat.objectId]
                chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
                
                chatVC.isGroup = false
                chatVC.hidesBottomBarWhenPushed = true
                
                self.navigationController?.pushViewController(chatVC, animated: true)

            } else {
                //user has blocked us
                ProgressHUD.showError("This user is not available for chat")
            }
        } else {
            
            //checkmarks
            if let cell = tableView.cellForRow(at: indexPath) {
                
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                } else {
                    cell.accessoryType = .checkmark
                }
            }

            //add/remove user from array
            
            let selected = memberIdsOfGroupChat.contains(userToChat.objectId as String)
            
            if selected {
                
                let objectIndex = memberIdsOfGroupChat.index(of: userToChat.objectId as String)
                memberIdsOfGroupChat.remove(at: objectIndex!)
                membersOfGroupChat.remove(at: objectIndex!)
                
            } else {
                
                memberIdsOfGroupChat.append(userToChat.objectId as String)
                membersOfGroupChat.append(userToChat)
            }

            //if we have users selected, the button is active
            self.navigationItem.rightBarButtonItem?.isEnabled = memberIdsOfGroupChat.count > 0

        }
    }
    
    
    
    //MARK: IBActions
    
    
    @objc func inviteUsersButtonPressed() {
        
        let text = "Hey! Lets chat on WChat \(kAPPURL)"
        
        let objectsToShare: [Any] = [text]
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        activityViewController.setValue(NSLocalizedString("Lets chat on WChat", comment: ""), forKey: "subject")
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func searchNearByButtonPressed() {

        let usersVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "usersTableView") as! UsersTableViewController
        
        self.navigationController?.pushViewController(usersVC, animated: true)

    }
    
    @objc func nextButtonPressed() {
        
        let newGroupVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "newGroupView") as! NewGroupViewController
        
        newGroupVC.memberIds = memberIdsOfGroupChat
        newGroupVC.allMembers = membersOfGroupChat
        
        self.navigationController?.pushViewController(newGroupVC, animated: true)
    }

    
    //MARK: LoadUsers
    
    func getContactsOfCurrentUser() {

        if FUser.currentUser()!.contacts.count > 0 {
            getUsersFromFirestore(withIds: FUser.currentUser()!.contacts) { (currentContacts) in
                
                self.matchedUsers = currentContacts
                self.splitDataInToSection()
                self.lookForNewUsersInBackground()
            }
        } else {
            self.lookForNewUsersInBackground()
        }
    }
    
    
    
    func lookForNewUsersInBackground() {
        
        //to limit the load of users, need to get only the users from my country (update the code later), better to compare current users phone numbers to server and download users that match and not download all and compare the current user contacts
        print("search in \(FUser.currentUser()?.country)")
        reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).getDocuments { (snapshot, error) in
            
            guard let snapshot = snapshot else {
                return
            }
            
            if !snapshot.isEmpty {
                
                self.users.removeAll()
                
                for userDictionary in snapshot.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)

                    if fUser.objectId != FUser.currentId() && !FUser.currentUser()!.contacts.contains(fUser.objectId) {

                        self.users.append(fUser)
                    }
                }
            }
            
            self.compareUsers()
        }
        
    }

    func compareUsers() {
        
        var usersContacts = FUser.currentUser()!.contacts
        
        for user in users {

            if user.phoneNumber != "" {
                
                let contact = searchForContactUsingPhoneNumber(phoneNumber: user.phoneNumber)

                //if we have a match, we add to our array to display them
                if contact.count > 0 {
                    //add to contacts array

                    matchedUsers.append(user)
                    usersContacts.append(user.objectId)
                }
            }
        }
        
        //save in background
        updateCurrentUserInFirestore(withValues: [kCONTACT : usersContacts]) { (error) in
            print("updated contacts")
        }

        
        updateInformationLabel()
        self.splitDataInToSection()
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

    
    //MARK: Helpers
    
    func setupButtons() {
        
        if isGroup {
            let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(self.nextButtonPressed))
            self.navigationItem.rightBarButtonItem = nextButton
            self.navigationItem.rightBarButtonItems!.first!.isEnabled = false
        } else {
            
            let inviteButton = UIBarButtonItem(image: UIImage(named: "invite"), style: .plain, target: self, action: #selector(self.inviteUsersButtonPressed))
            let searchBarButton = UIBarButtonItem(image: UIImage(named: "nearMe"), style: .plain, target: self, action: #selector(self.searchNearByButtonPressed))
            
            self.navigationItem.rightBarButtonItems = [inviteButton, searchBarButton]
        }
        
    }
    
    func updateInformationLabel() {

        if matchedUsers.count > 0 {
            noUsersLabel.isHidden = true
        } else {
            noUsersLabel.isHidden = false
        }
    }
    
    
    fileprivate func splitDataInToSection() {
        
        //sort array
        matchedUsers = matchedUsers.sorted(by: { $0.firstname < $1.firstname })

        // set section title "" at initial
        var sectionTitle: String = ""
        
        // iterate all records from array
        for i in 0..<self.matchedUsers.count {
            
            // get current record
            let currentUser = self.matchedUsers[i]
            
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
                if !sectionTitleList.contains(sectionTitle) {
                    self.sectionTitleList.append(sectionTitle)
                }
            }
            
            // add record to the section
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
        tableView.reloadData()
    }

    
    //MARK: UserTableViewCellDelegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        
        var user: FUser!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
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
