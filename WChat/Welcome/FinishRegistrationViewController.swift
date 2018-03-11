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
    
    @IBOutlet weak var avatarImageView: UIImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        avatarImageView.isUserInteractionEnabled = true
    }
    
    
    //MARK: IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        cleanTextFields()
        dismissKeyboard()
        
        //delete locally
        UserDefaults.standard.removeObject(forKey: kPUSHID)
        UserDefaults.standard.removeObject(forKey: kCURRENTUSER)
        UserDefaults.standard.synchronize()
        
        //delete user object
        firebase.child(kUSER_PATH).child(FUser.currentId()).removeValue()
        
        FUser.deleteUser { (error) in
            
            if error != nil {
                
                DispatchQueue.main.async {
                    ProgressHUD.showError("Couldnt Quit")
                }
                
                return
            }
            
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        
        dismissKeyboard()
        ProgressHUD.show("Register...")
        
        if nameTextField.text != "" && surnameTextField.text != "" && cityTextField.text != "" && countryTextField.text != "" && phoneTextField.text != "" {
            
            FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surnameTextField.text!, completion: { (error) in
                
                if error != nil {
                    
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error!.localizedDescription)
                    return
                }
                
                self.registerUser()
                
            })
            
            
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

        var tempDictionary: Dictionary = [kFULLNAME : fullName, kCOUNTRY : countryTextField.text!, kCITY : cityTextField.text!, kPHONE : phoneTextField.text!] as [String : Any]
        
        
        //add avatar if available
        if avatarImage == nil {
            
            //create UIImage from Initials
            imageFromInitials(firstName: nameTextField.text!, lastName: surnameTextField.text!, withBlock: { (avatarInitials) in
                
                let avatarInitials = UIImageJPEGRepresentation(avatarInitials, 0.7)!
                let avatar = avatarInitials.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                tempDictionary[kAVATAR] = avatar
                
                //update user info
                self.finishRegistration(withValues: tempDictionary)
            })
            
            
        } else {
            
            let avatarData = UIImageJPEGRepresentation(avatarImage!, 0.7)!
            let avatar = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
            tempDictionary[kAVATAR] = avatar
            
            //update user info
            self.finishRegistration(withValues: tempDictionary)
        }

    }
    
    func finishRegistration(withValues: [String : Any]) {
        
        updateCurrentUser(withValues: withValues, completion: { (error) in
            
            if error != nil {
            
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                }
                
                return
            }
            
            //enter the application
            self.goToApp()
        })
    }
    

    func goToApp() {
        
        ProgressHUD.dismiss()

        cleanTextFields()
        dismissKeyboard()
        
        //post user did login notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
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


}