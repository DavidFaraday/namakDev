//
//  ChatsViewController.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import Firebase

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentChatsTableViewCellDelegate, UISearchResultsUpdating {

    let searchController = UISearchController(searchResultsController: nil)

    var recentListener: ListenerRegistration!
    @IBOutlet weak var tableView: UITableView!
    
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = []
    
    
    override func viewWillAppear(_ animated: Bool) {
        loadRecentChats()

        //to remove empty cell lines
        tableView.tableFooterView = UIView()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        recentListener.remove()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true

        setTableViewHeader()
    }
    
    
    

    //MARK: Tableview Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChats.count
        } else {
            return recentChats.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecentChatsTableViewCell

        cell.delegate = self
        var recentChat: NSDictionary!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            recentChat = filteredChats[indexPath.row]
        } else {
            recentChat = recentChats[indexPath.row]
        }

        
        cell.generateCell(recentChat: recentChat, indexPath: indexPath)
        
        return cell
    }

    //MARK: TableViewDelegate
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        
        var tempRecent: NSDictionary!

        if searchController.isActive && searchController.searchBar.text != "" {
            tempRecent = filteredChats[indexPath.row]
        } else {
            tempRecent = recentChats[indexPath.row]
        }

        var muteTitle = "Unmute"
        var mute = false
        
        if (tempRecent[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()) {
            muteTitle = "Mute"
            mute = true
        }
        
        let muteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: muteTitle, handler:{action, indexpath in
            
            self.updatePushMembers(recent: tempRecent, mute: mute)
        })
        
        
        muteRowAction.backgroundColor = .blue
        
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler:{action, indexpath in

            self.recentChats.remove(at: indexPath.row)
            
            deleteRecentChat(recentDictionary: tempRecent)
            
            tableView.reloadData()

        })
        
        return [deleteRowAction, muteRowAction];
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        var recent: NSDictionary!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
        } else {
            recent = recentChats[indexPath.row]
        }
        
        restartRecentChat(recent: recent)
        
        let chatVC = ChatViewController()
        
        chatVC.hidesBottomBarWhenPushed = true
        chatVC.titleName = (recent[kWITHUSERUSERNAME] as? String)!
        chatVC.memberIds = (recent[kMEMBERS] as? [String])!
        chatVC.membersToPush = (recent[kMEMBERSTOPUSH] as? [String])!
        chatVC.chatRoomId = (recent[kCHATROOMID] as? String)!
        chatVC.isGroup = (recent[kTYPE] as! String) == kGROUP
    
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    
    //MARK: IBActions
    @IBAction func newChatButtonPressed(_ sender: Any) {

        selectUserForChat(isGroup: false)
    }
    
    @objc func groupButtonPressed() {

        selectUserForChat(isGroup: true)
    }
    
    
    //MARK: LoadRecentChats
    
    func loadRecentChats() {
        
        //to be updated when changes accure
        let options = QueryListenOptions()
//        options.includeDocumentMetadataChanges(true) // in case recent changes
        options.includeQueryMetadataChanges(true) // in case recent gets deleted
        
        recentListener = reference(collectionReference: .Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener(options: options, listener: { (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
//            snapshot.documentChanges.forEach { diff in
//                if (diff.type == .added) {
//                    print("New city: \(diff.document.data()[kRECENTID])")
//                }
//                if (diff.type == .modified) {
//                    print("Modified city: \(diff.document.data()[kRECENTID])")
//                }
//                if (diff.type == .removed) {
//                    print("Removed city: \(diff.document.data()[kRECENTID])")
//                }
//            }
            self.recentChats = []
            
            if !snapshot.isEmpty {
                
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                
                for recent in sorted {
                    
                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                        
                        self.recentChats.append(recent)
                    }
                    
                    
                    //required for offline working
                    //                    reference(collectionReference: .Recent).whereField(kCHATROOMID, isEqualTo: currentRecent[kCHATROOMID] as! String).addSnapshotListener({ (snapshot, error) in
                    //
                    //                    })
                    //end of offline requirement
                }
            }
            
            self.tableView.reloadData()
        })
        
    }
    
    
    //MARK: RecentChatsTableViewCellDelegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        
        //get user and show in profile view
        let recentChat = recentChats[indexPath.row]

        if recentChat[kTYPE] as! String == kPRIVATE {

            reference(collectionReference: .User).document(recentChat[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
                
                guard let snapshot = snapshot else { return }

                if snapshot.exists {
                    let userDictionary = snapshot.data() as NSDictionary
                    
                    let tempUser = FUser(_dictionary: userDictionary)
                    
                    self.showUserProfile(user: tempUser)
                }
            }
        }
        
    }

    //MARK: Helper functions
    
    func setTableViewHeader() {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        //button
        let buttonView = UIView(frame: CGRect(x: 0, y: 5, width: tableView.frame.width, height: 35))
        let groupButton = UIButton(frame: CGRect(x: tableView.frame.width - 110, y: 10, width: 100, height: 20))
        groupButton.addTarget(self, action: #selector(self.groupButtonPressed), for: .touchUpInside)
        groupButton.setTitle("New Group", for: .normal)
        let buttonColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) //colorLiteral
        groupButton.setTitleColor(buttonColor, for: .normal)
        
        
        //line
        let lineView = UIView(frame: CGRect(x: 0, y: headerView.frame.height - 1, width: tableView.frame.width, height: 1))
        lineView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        //add subviews
        buttonView.addSubview(groupButton)
        headerView.addSubview(buttonView)
        headerView.addSubview(lineView)
        
        
        tableView.tableHeaderView = headerView
    }
    	
    func selectUserForChat(isGroup: Bool) {
        let contactsVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "contactsView") as! ContactsViewController
        
        contactsVC.isGroup = isGroup
        
        self.navigationController?.pushViewController(contactsVC, animated: true)
    }

    func showUserProfile(user: FUser) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        
        profileVC.user = user
        
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func updatePushMembers(recent: NSDictionary, mute: Bool) {
        
        var membersToPush = recent[kMEMBERSTOPUSH] as! [String]
        
        if mute {
            let index = membersToPush.index(of: FUser.currentId())!
            membersToPush.remove(at: index)
        } else {
            membersToPush.append(FUser.currentId())
        }
        
        updateExistingRicentsWithNewValues(chatRoomId: recent[kCHATROOMID] as! String, members: recent[kMEMBERS] as! [String], withValues: [kMEMBERSTOPUSH : membersToPush])
        
        Group.updateGroup(groupId: recent[kCHATROOMID] as! String, withValues: [kMEMBERSTOPUSH : membersToPush])
    }
    
   
    
    
    //MARK: search controler functions
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredChats = recentChats.filter({ (recentChat) -> Bool in
            
            return (recentChat[kWITHUSERUSERNAME] as! String).lowercased().contains(searchText.lowercased())
            
        })
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    


}
