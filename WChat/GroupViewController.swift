//
//  GroupViewController.swift
//  WChat
//
//  Created by David Kababyan on 06/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ImagePicker
import ProgressHUD

class GroupViewController: UIViewController, ImagePickerDelegate {

    var group: NSDictionary!
    
    @IBOutlet var iconTapGesture: UITapGestureRecognizer!
    @IBOutlet weak var cameraButtonOutlet: UIImageView!
    @IBOutlet weak var editButtonOutlet: UIButton!
    @IBOutlet weak var groupNameTextField: UITextField!
    
    var groupIcon: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cameraButtonOutlet.isUserInteractionEnabled = true
        cameraButtonOutlet.addGestureRecognizer(iconTapGesture)

        setupUI()
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Invite Users", style: .plain, target: self, action: #selector(self.inviteUsers))]

    }
    
    
    //MARK: IBActions

    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        var withValues : [String : Any]!
        
        if groupNameTextField.text != "" {
            withValues = [kNAME : groupNameTextField.text!]
        } else {
            ProgressHUD.showError("Name mast be set!")
            return
        }
        
        let avatarData = UIImageJPEGRepresentation(cameraButtonOutlet.image!, 0.7)!
        let avatarString = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        withValues = [kNAME : groupNameTextField.text!, kAVATAR : avatarString]

        Group.updateGroup(groupId: group[kGROUPID] as! String, withValues: withValues)
        
        //need to update recents of the group
        //chache with values because in recent the group name has different key
        withValues = [kWITHUSERUSERNAME : groupNameTextField.text!, kAVATAR : avatarString]

        updateExistingRicentsWithNewValues(chatRoomId: group[kGROUPID] as! String, members: group[kMEMBERS] as! [String], withValues: withValues)

        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        showIconOptions()
    }
    
    @IBAction func cameraIconTapped(_ sender: Any) {
        showIconOptions()
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        dismissKeyboard()
    }
    
    //MARK: SetupUI
    
    func setupUI() {
        
        self.title = "Group"
        
        groupNameTextField.text = group[kNAME] as? String
        
        imageFromData(pictureData: group[kAVATAR] as! String) { (avatarImage) in
            
            self.cameraButtonOutlet.image = avatarImage!.circleMasked
        }
        
    }

    
    //MARK: Helpers
    
    @objc func inviteUsers() {

        let usersVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InviteusersTableView") as! InviteUserTableViewController
        
        usersVC.group = group
        
        self.navigationController?.pushViewController(usersVC, animated: true)

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
                self.cameraButtonOutlet.image = UIImage(named: "groupIcon")
                self.editButtonOutlet.isHidden = true
            }
            
            optionMenu.addAction(resetAction)
        }
        
        
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        
        if ( UI_USER_INTERFACE_IDIOM() == .pad )
        {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
                
                currentPopoverpresentioncontroller.sourceView = editButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = editButtonOutlet.bounds
                
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        } else{
            self.present(optionMenu, animated: true, completion: nil)
            
        }
        
    }

    func dismissKeyboard() {
        self.view.endEditing(false)
    }


    //MARK: ImagePicker Delegate
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0 {
            self.groupIcon = images.first!
            self.cameraButtonOutlet.image = self.groupIcon?.circleMasked
            self.editButtonOutlet.isHidden = false
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
    }



}
