//
//  ProfileViewController.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD

class ProfileViewController: UITableViewController {
    
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    
    @IBOutlet weak var messageButtonOutlet: UIButton!
    @IBOutlet weak var callButtonOutlet: UIButton!
    @IBOutlet weak var blockButtonOutlet: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

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

        if !checkBlockedStatus(withUser: user!) {
            callUser()
            
            let currentUser = FUser.currentUser()!
            
            let call = CallN(_callerId: currentUser.objectId, _withUserId: user!.objectId, _callerFullName: currentUser.fullname, _withUserFullName: user!.fullname, _callerAvatar: "", _withUserAvatar: "")
            
            call.saveCallInBackground()
        } else {
            ProgressHUD.showError("User is not available for call!")
        }
    }
    
    @IBAction func chatButtonPressed(_ sender: Any) {
        
        let userToChat = user!

        if !checkBlockedStatus(withUser: userToChat) {
            
            let chatVC = ChatViewController()
            
            chatVC.titleName = userToChat.firstname
            
            chatVC.membersToPush = [FUser.currentId(), userToChat.objectId]
            chatVC.memberIds = [FUser.currentId(), userToChat.objectId]
            chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
            
            chatVC.isGroup = false
            chatVC.hidesBottomBarWhenPushed = true
            
            self.navigationController?.pushViewController(chatVC, animated: true)

        } else {
            //user has blocked us
            ProgressHUD.showError("This user is not available for chat")
        }
    }
    
    @IBAction func blockButtonPressed(_ sender: Any) {
        
        var currentUserBlockedIds = FUser.currentUser()!.blockedUsers
        
        if currentUserBlockedIds.contains(user!.objectId) {
            currentUserBlockedIds.remove(at: currentUserBlockedIds.index(of: user!.objectId)!)
        } else {
            currentUserBlockedIds.append(user!.objectId)
        }
        
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : currentUserBlockedIds]) { (error) in
            
            if error != nil {
                print("error blocking \(error!.localizedDescription)")
            }
            
            self.updateBlockedStatus()
        }

        //delete recent chats
        blockUser(userToBlock: user!)
    }
    
    //MARK: CallFunctions
    func callClient() -> SINCallClient {
        return appDelegate._client.call()
    }
    
    func callUser() {
        
        let userToCallId = user!.objectId
        let call = callClient().callUser(withId: userToCallId, headers: [kNAME : FUser.currentUser()!.fullname])

        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController

        callVC._call = call

        self.present(callVC, animated: true, completion: nil)
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
