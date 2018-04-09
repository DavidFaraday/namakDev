//
//  ProfileViewController.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit


class ProfileViewController: UITableViewController {

    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    
    @IBOutlet weak var messageButtonOutlet: UIButton!
    @IBOutlet weak var callButtonOutlet: UIButton!
    @IBOutlet weak var blockButtonOutlet: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    
    var user:FUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    //MARK: TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
         return 30
    }
    
    
    
    //MARK: IBActions
    
    @IBAction func callButtonPressed(_ sender: Any) {
        print("call")
    }
    
    @IBAction func chatButtonPressed(_ sender: Any) {
        
        let userToChat = user!
        
        let chatVC = ChatViewController()
        
        chatVC.titleName = userToChat.firstname
        
        chatVC.membersToPush = [FUser.currentId(), userToChat.objectId]
        chatVC.memberIds = [FUser.currentId(), userToChat.objectId]
        chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
        
        chatVC.isGroup = false
        chatVC.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    @IBAction func blockButtonPressed(_ sender: Any) {
        
        var currentUserBlockedIds = FUser.currentUser()!.blockedUsers
        
        if currentUserBlockedIds.contains(user!.objectId) {
            currentUserBlockedIds.remove(at: currentUserBlockedIds.index(of: user!.objectId)!)
        } else {
            currentUserBlockedIds.append(user!.objectId)
        }
        
        updateCurrentUser(withValues: [kBLOCKEDUSERID : currentUserBlockedIds]) { (error) in
            
            if error != nil {
                print("error blocking \(error!.localizedDescription)")
            }
            
            self.updateBlockedStatus()
        }

    }
    
    
    //MARK: Helpers
    
    func setupUI() {
        if user != nil {
            
            self.title = "Profile"
            
            fullNameLabel.text = user!.fullname
            phoneNumberLabel.text = user!.phoneNumber
            
            updateBlockedStatus()
            
            imageFromData(pictureData: user!.avatar, withBlock: { (avatarImage) in
                
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            })

        }
    }
    
    func updateBlockedStatus() {
        
        if user!.objectId != FUser.currentId() {
            blockButtonOutlet.isHidden = false
            messageButtonOutlet.isHidden = false
            callButtonOutlet.isHidden = false
        } else {
            blockButtonOutlet.isHidden = true
            messageButtonOutlet.isHidden = true
            callButtonOutlet.isHidden = true
        }
        
        if FUser.currentUser()!.blockedUsers.contains(user!.objectId) {
            blockButtonOutlet.setTitle("Unblock User", for: .normal)
        } else {
            blockButtonOutlet.setTitle("Block User", for: .normal)
        }
    }

    
}
