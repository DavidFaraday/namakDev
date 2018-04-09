//
//  ChatsViewController.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import Firebase

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentChatsTableViewCellDelegate {

    let searchController = UISearchController(searchResultsController: nil)

    @IBOutlet weak var tableView: UITableView!
    
    var recentChats: [NSDictionary] = []
    
    override func viewWillAppear(_ animated: Bool) {
        
        //to remove empty cell lines
        tableView.tableFooterView = UIView()

        tableView.contentInset = UIEdgeInsetsMake(-self.searchController.searchBar.frame.size.height, 0, 0, 0);
        loadRecentChats()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTableViewHeader()
    }
    
    
    

    //MARK: Tableview Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return recentChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecentChatsTableViewCell

        cell.delegate = self
        cell.generateCell(recentChat: recentChats[indexPath.row], indexPath: indexPath)
        
        return cell
    }

    //MARK: TableViewDelegate
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let tempRecent = self.recentChats[indexPath.row]

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
        
        let recent = recentChats[indexPath.row]
        
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
    
    //show/hide table search bar
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
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
    @IBAction func newChatButtonPressed(_ sender: Any) {
        
        selectUserForChat(isGroup: false)
    }
    
    @objc func groupButtonPressed() {

        selectUserForChat(isGroup: true)
    }
    
    
    //MARK: LoadRecentChats
    
    func loadRecentChats() {
        
    firebase.child(kRECENT_PATH).child(FUser.currentId()).observe(.value, with: {
            snapshot in
            
            self.recentChats.removeAll()
            
            if snapshot.exists() {
                
                let sorted = ((snapshot.value as! NSDictionary).allValues as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)])
                
                for recent in sorted {
                    
                    let currentRecent = recent as! NSDictionary
                    
                    if currentRecent[kLASTMESSAGE] as! String != "" {
                        
                        self.recentChats.append(currentRecent)
                    }
                    
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

            firebase.child(kUSER_PATH).child(recentChat[kWITHUSERUSERID] as! String).observeSingleEvent(of: .value, with: {
                snapshot in

                if snapshot.exists() {
                    
                    let userDictionary = snapshot.value as! NSDictionary

                    let tempUser = FUser(_dictionary: userDictionary)
                    
                    self.showUserProfile(user: tempUser)
                }
                
            })
        }
        
    }

    //MARK: Helper functions
    
    func setTableViewHeader() {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 90))
        
        //button
        let buttonVview = UIView(frame: CGRect(x: 0, y: 55, width: tableView.frame.width, height: 35))
        let groupButton = UIButton(frame: CGRect(x: tableView.frame.width - 110, y: 10, width: 100, height: 20))
        groupButton.addTarget(self, action: #selector(self.groupButtonPressed), for: .touchUpInside)
        groupButton.setTitle("New Group", for: .normal)
        let buttonColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) //colorLiteral
        groupButton.setTitleColor(buttonColor, for: .normal)
        
        
        //line
        let lineView = UIView(frame: CGRect(x: 0, y: headerView.frame.height - 1, width: tableView.frame.width, height: 1))
        lineView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        //add subviews
        buttonVview.addSubview(groupButton)
        headerView.addSubview(searchController.searchBar)
        headerView.addSubview(buttonVview)
        headerView.addSubview(lineView)
        
        
        tableView.tableHeaderView = headerView
    }
    
    func selectUserForChat(isGroup: Bool) {
        let usersVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "usersTableView") as! UsersTableViewController
        
        usersVC.isGroup = isGroup
        
        self.navigationController?.pushViewController(usersVC, animated: true)
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

}
