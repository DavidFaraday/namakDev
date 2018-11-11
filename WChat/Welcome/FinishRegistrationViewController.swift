//
//  FinishRegistrationViewController.swift
//  WChat
//
//  Created by David Kababyan on 10/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ImagePicker
import ProgressHUD

class FinishRegistrationViewController: UIViewController, ImagePickerDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var surnameTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    var avatarImage: UIImage?
    var email: String!
    var password: String!
    var countryCode: String?
    
    @IBOutlet weak var avatarImageView: UIImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        avatarImageView.isUserInteractionEnabled = true
    }
    
    
    //MARK: IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        cleanTextFields()
        dismissKeyboard()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        
        dismissKeyboard()
        ProgressHUD.show("Register...")
        
        if nameTextField.text != "" && surnameTextField.text != "" && cityTextField.text != "" && countryTextField.text != "" && phoneTextField.text != "" {
            
            if countryCode != nil {
                // phone reg
                registerUser()

            } else {
                // email registration
                FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surnameTextField.text!, completion: { (error) in
    
                    if error != nil {
    
                        ProgressHUD.dismiss()
                        ProgressHUD.showError(error!.localizedDescription)
                        return
                    }
                    self.registerUser()
                })
            }
            
        } else {
            ProgressHUD.showError("All fields are required")
        }
        
    }
    
    
    @IBAction func backgroundTap(_ sender: Any) {
        dismissKeyboard()
    }
    
    @IBAction func avatarImageTap(_ sender: Any) {
        
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        
        present(imagePickerController, animated: true, completion: nil)
        
        dismissKeyboard()
    }
    

    //MARK: Helper functions
    
    func registerUser() {
        
        let fullName = nameTextField.text! + " " + surnameTextField.text!

        var tempDictionary: Dictionary = [kFIRSTNAME : nameTextField.text!, kLASTNAME: surnameTextField.text!, kFULLNAME : fullName, kCOUNTRY : countryTextField.text!, kCITY : cityTextField.text!, kPHONE : phoneTextField.text!, kCOUNTRYCODE : countryCode ?? ""] as [String : Any]
        
        
        //add avatar if available
        if avatarImage == nil {
            
            //create UIImage from Initials
            imageFromInitials(firstName: nameTextField.text!, lastName: surnameTextField.text!, withBlock: { (avatarInitials) in
                
                let avatarInitials = avatarInitials.jpegData(compressionQuality: 0.4)!

                let avatar = avatarInitials.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                tempDictionary[kAVATAR] = avatar
                
                //update user info
                self.finishRegistration(withValues: tempDictionary)
            })
            
            
        } else {
            
            let avatarData = avatarImage!.jpegData(compressionQuality: 0.3)!
            let avatar = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
            tempDictionary[kAVATAR] = avatar
            
            //update user info
            self.finishRegistration(withValues: tempDictionary)
        }

    }
    
    func finishRegistration(withValues: [String : Any]) {
        
        updateCurrentUserInFirestore(withValues: withValues) { (error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                    self.deleteUser()
                }
                return
            }
            
            //enter the application
            ProgressHUD.dismiss()
            
            self.cleanTextFields()
            self.dismissKeyboard()
            
            goToApp(fromView: self, to: "mainApplication")
        }

    }
    

    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func cleanTextFields() {
        nameTextField.text = ""
        surnameTextField.text = ""
        countryTextField.text = ""
        cityTextField.text = ""
        phoneTextField.text = ""
    }
    
    
    //MARK: ImagePicker Delegate
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage?.circleMasked
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
    }

    //MARK: Delete user in case of error
    func deleteUser() {
        
        //delete local user
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        
        //delete user object in firebase database
        reference(.User).document(FUser.currentId()).delete()
        
        FUser.deleteUser { (error) in
            goToApp(fromView: self, to: "welcome")
        }
        
    }

    


}
