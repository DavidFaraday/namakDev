//
//  EditProfileTableViewController.swift
//  WChat
//
//  Created by David Kababyan on 23/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ImagePicker
import ProgressHUD

class EditProfileTableViewController: UITableViewController, ImagePickerDelegate {

    @IBOutlet weak var saveButtonOutlet: UIBarButtonItem!
    
    @IBOutlet var avatarTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    var avatarImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        //to remove empty cell lines
        tableView.tableFooterView = UIView()

        setupUI()
    }


    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    


    //MARK: IBActions
    
    
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        if firstNameTextField.text != "" && lastNameTextField.text != "" && emailTextField.text != "" {
            
            ProgressHUD.show("Saving...")
            //block save button
            saveButtonOutlet.isEnabled = false
            
            let fullName = firstNameTextField.text! + " " + lastNameTextField.text!

            var withValues = [kFIRSTNAME : firstNameTextField.text!, kLASTNAME : lastNameTextField.text!, kFULLNAME : fullName]

            
            //set avatar if changed
            if avatarImage != nil {
                let avatarData = UIImageJPEGRepresentation(avatarImage!, 0.7)!
                let avatarString = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                withValues[kAVATAR] = avatarString
            }
            
            updateCurrentUser(withValues: withValues, completion: { (error) in
                
                if error != nil {
                    print("couldnt update user \(error!.localizedDescription)")
                }
                
                ProgressHUD.showSuccess("Saved")
                
                self.saveButtonOutlet.isEnabled = true
                self.dismiss(animated: true, completion: nil)
            })

            
        } else {
            ProgressHUD.showError("All fields must be set!")
        }
    }
    
    
    @IBAction func avatarTapped(_ sender: Any) {

        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1

        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    
    //MARK: Helpers
    
    func setupUI() {
        
         let currentUser = FUser.currentUser()!
        
        avatarImageView.isUserInteractionEnabled = true //so that tap gesture works
        
        
        firstNameTextField.text = currentUser.firstname
        lastNameTextField.text = currentUser.lastname
        emailTextField.text = currentUser.email
        
        imageFromData(pictureData: currentUser.avatar) { (avatarImage) in
            
            if avatarImage != nil {
                self.avatarImageView.image = avatarImage!.circleMasked
            }
        }
        
    }
    
    //MARK: ImagePicker Delegate
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage!.circleMasked
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
    }

    
}
