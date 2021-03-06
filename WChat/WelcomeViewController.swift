//
//  WelcomeViewController.swift
//  WChat
//
//  Created by David Kababyan on 10/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    //MARK: IBActions
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            
            loginUser()
            
        } else {
            ProgressHUD.showError("Email or Password is missing")
        }
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        
        dismissKeyboard()

        //check if user has inputed data
        if emailTextField.text != "" && passwordTextField.text != "" && repeatPasswordTextField.text != "" {
            
            //check if passwords match
            if passwordTextField.text == repeatPasswordTextField.text {
                
                registerUser()
                
            } else {
                ProgressHUD.showError("Passwords dont match")
            }
            
        } else {
            ProgressHUD.showError("All fields are required")
        }
        
    }
    

    @IBAction func backgroundTap(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    //MARK: Helper functions
    
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func cleanTextFields() {
        emailTextField.text = ""
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
    }

    func loginUser() {
        
        FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) { (error) in
            
            //error handeling
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            
            self.goToApp()
        }
    }
    
    func registerUser() {
        
        FUser.registerUserWith(email: emailTextField.text!, password: passwordTextField.text!, firstName: "", lastName: "") { (error) in
            
            if error != nil {
                
                DispatchQueue.main.async {
                    ProgressHUD.showError(error?.localizedDescription)
                }
                
                return
            }
            
            self.cleanTextFields()
            self.dismissKeyboard()
            self.performSegue(withIdentifier: "welcomeToFinishReg", sender: self)
        }
        
    }
    
    
    
    
    func goToApp() {
        
        cleanTextFields()
        dismissKeyboard()
        
        //post user did login notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
    }

    

    
}
