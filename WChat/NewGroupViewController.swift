//
//  NewGroupViewController.swift
//  WChat
//
//  Created by David Kababyan on 18/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class NewGroupViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, GroupMemberCollectionViewCellDelegate, ImagePickerDelegate {

    
    @IBOutlet weak var editAvatarButtonOutlet: UIButton!
    @IBOutlet var iconTapGesture: UITapGestureRecognizer!
    @IBOutlet weak var groupIconImageView: UIImageView!
    @IBOutlet weak var groupSubjectTextField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var participantsLabel: UILabel!
    
    var memberIds: [String] = []
    var allMembers: [FUser] = []
    var groupIcon: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never

        groupIconImageView.isUserInteractionEnabled = true
        groupIconImageView.addGestureRecognizer(iconTapGesture)
        
        updateParticipantsLabel()

    }

    override func viewWillLayoutSubviews() {
        collectionView.collectionViewLayout.invalidateLayout()
    }


    //MARK: CallectionViewData Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return allMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! GroupMemberCollectionViewCell
        
        cell.delegate = self
        cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
        
        return cell
    }

    
    //MARK: IBActions
    
    @objc func createButtonPressed(_ sender: Any) {
        
        if groupSubjectTextField.text != "" {
            
            //add current user to group mambers
            memberIds.append(FUser.currentId())
            
            //defaultAvatar
            let avatarData = UIImageJPEGRepresentation(UIImage(named: "groupIcon")!, 0.7)!
            var avatar = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))

            //chage avatar if we have one
            if groupIcon != nil {
                
                let avatarData = UIImageJPEGRepresentation(groupIcon!, 0.7)!
                avatar = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            }
            
            let groupId = UUID().uuidString //unique number
            
            let group = Group(groupId: groupId, subject: groupSubjectTextField.text!, ownerId: FUser.currentId(), members: memberIds, avatar: avatar)
        
            group.saveGroup(group: group.groupDictionary)
            
            //when done, create group recent and go to chat
            startGroupChat(group: group)
            
            let chatVC = ChatViewController()
            
            chatVC.titleName = group.groupDictionary[kNAME] as! String
            
            chatVC.memberIds = group.groupDictionary[kMEMBERS] as! [String]
            chatVC.membersToPush = group.groupDictionary[kMEMBERS] as! [String]
            
            chatVC.chatRoomId = groupId
            
            chatVC.isGroup = true
            chatVC.hidesBottomBarWhenPushed = true
            
            self.navigationController?.pushViewController(chatVC, animated: true)
            
        } else {
            ProgressHUD.showError("Subject is required")
        }
    }
    
    @IBAction func backgroundTap(_ sender: Any) {
        dismissKeyboard()
    }
    
    @IBAction func editGroupIconButtonPressed(_ sender: Any) {
        
        showIconOptions()
    }
    
    @IBAction func groupIconTaped(_ sender: UITapGestureRecognizer) {
        
        showIconOptions()
    }
    
    
    //MARK: GroupMemberCollectionViewCellDelegate
    
    func didClickDeleteButton(indexPath: IndexPath) {
        
        allMembers.remove(at: indexPath.row)
        memberIds.remove(at: indexPath.row)
        
        collectionView.reloadData()
        updateParticipantsLabel()
    }

    //MARK: Helpers
    
    func updateParticipantsLabel() {
        participantsLabel.text = "PARTICIPANTS: \(allMembers.count)"
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.createButtonPressed))]

        self.navigationItem.rightBarButtonItem?.isEnabled = allMembers.count > 0
    }
    
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func showIconOptions() {
        
        let optionMenu = UIAlertController(title: "Choose Group Icon", message: nil, preferredStyle: .actionSheet)
        
        
        let takePhotoAction = UIAlertAction(title: "Take/Choose Photo", style: .default) { (alert: UIAlertAction!) in
            
            let imagePickerController = ImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.imageLimit = 1
            
            self.present(imagePickerController, animated: true, completion: nil)
            
            self.dismissKeyboard()

        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        
        //show reset only if user has an icon
        if groupIcon != nil {
            
            let resetAction = UIAlertAction(title: "Reset", style: .destructive) { (alert: UIAlertAction!) in
                
                self.groupIcon = nil
                self.groupIconImageView.image = UIImage(named: "cameraIcon")
                self.editAvatarButtonOutlet.isHidden = true
            }
            
            optionMenu.addAction(resetAction)
        }
        
        
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        
        if ( UI_USER_INTERFACE_IDIOM() == .pad )
        {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
                
                currentPopoverpresentioncontroller.sourceView = editAvatarButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = editAvatarButtonOutlet.bounds
                
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
            
        }
        
    }

    
    //MARK: ImagePicker Delegate
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0 {
            self.groupIcon = images.first!
            self.groupIconImageView.image = self.groupIcon?.circleMasked
            self.editAvatarButtonOutlet.isHidden = false
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
    }


    
}
