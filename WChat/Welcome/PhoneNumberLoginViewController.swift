//
//  PhoneNumberLoginViewController.swift
//  WChat
//
//  Created by David Kababyan on 04/05/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseAuth

class PhoneNumberLoginViewController: UIViewController {

    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var emailLoginView: UIView!
    @IBOutlet weak var loginSegmentedControlOutlet: UISegmentedControl!
    @IBOutlet weak var logoView: UIImageView!
    
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var mobileNumberTextField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var requestButtonOutlet: UIButton!
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    @IBOutlet weak var loginButtonOutlet: UIButton!
    
    @IBOutlet weak var signUpButtonOutlet: UIButton!
    
    var phoneNumber: String!
    var verificationId: String?
    var showingLogin = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //move phone login out of screen
        self.loginView.frame.origin.x = AnimationManager.screenBounds.maxX + 10
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        animateLogoIn()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        countryCodeTextField.text = CountryCode().currentCode
    }
    
    override func viewDidLayoutSubviews() {
        animateViewIn(view: loginSegmentedControlOutlet.selectedSegmentIndex)
    }
    
    //MARK: IBActions
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        dismissKeyboard()

        if showingLogin {
            //login
            if emailTextField.text != "" && passwordTextField.text != "" {
                loginUser()
            } else {
                ProgressHUD.showError("Email or Password is missing")
            }
            
        } else {
            //registering
            //check if user has inputed data
            if emailTextField.text != "" && passwordTextField.text != "" && repeatPasswordTextField.text != "" {
                
                //check if passwords match
                if passwordTextField.text == repeatPasswordTextField.text {
                    registerUserWithEmail()
                } else {
                    ProgressHUD.showError("Passwords dont match")
                }
                
            } else {
                ProgressHUD.showError("All fields are required")
            }
        }
    }
    
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        
        if loginSegmentedControlOutlet.selectedSegmentIndex == 0 {
            showingLogin = !showingLogin

            var signUpButtonTitle = "Dont have an account? Sign Up"
            var loginButtonTitle = "Login"

            UIView.animate(withDuration: 0.5) {
                if self.showingLogin {
                    signUpButtonTitle = "Dont have an account? Sign Up"
                    loginButtonTitle = "Login"
                    self.repeatPasswordTextField.isHidden = true
                    
                } else {
                    signUpButtonTitle = "I have account, Login"
                    loginButtonTitle = "Register"
                    self.repeatPasswordTextField.isHidden = false
                }
                
                self.signUpButtonOutlet.setTitle(signUpButtonTitle, for: .normal)
                self.loginButtonOutlet.setTitle(loginButtonTitle, for: .normal)
            }

        }
    }
    
    
    @IBAction func loginOptionSegmentValueChanged(_ sender: UISegmentedControl) {
        animateViewIn(view: sender.selectedSegmentIndex)
    }
    

    @IBAction func requestButtonPressed(_ sender: Any) {
        
        if verificationId != nil {
            registerUserWithPhone()
            return
        }
        
        if mobileNumberTextField.text != "" &&  countryCodeTextField.text != "" {
            
            PhoneAuthProvider.provider().verifyPhoneNumber(countryCodeTextField.text! + mobileNumberTextField.text!, uiDelegate: nil) { (_verificationId, error) in
                
                if error != nil {
                    ProgressHUD.showError(error!.localizedDescription)
                    return
                }
                
                self.verificationId = _verificationId
                self.updateUI()
            }

        } else {
            ProgressHUD.showError("Phone number is required!")
        }
        
    }
    
    //MARK: Helpers

    func updateUI() {
        
        requestButtonOutlet.setTitle("Submit", for: .normal)
        phoneNumber = countryCodeTextField.text! + mobileNumberTextField.text!
        
        countryCodeTextField.isEnabled = false
        mobileNumberTextField.isEnabled = false
        mobileNumberTextField.placeholder = mobileNumberTextField.text!
        mobileNumberTextField.text = ""
        
        codeTextField.isHidden = false
        
        
    }
    
    
    func registerUserWithPhone() {
        if codeTextField.text != "" && verificationId != nil {

            FUser.registerUserWith(phoneNumber: phoneNumber, verificationCode: codeTextField.text!, verificationId: verificationId!) { (error, shouldLogin) in
                
                if error != nil {
                    ProgressHUD.showError(error!.localizedDescription)
                    return
                }
                
                if shouldLogin {
                    
                    ProgressHUD.dismiss()

                    //go to app
                    goToApp(fromView: self, to: "mainApplication")

                } else {
                    //go to finish reg
                    self.performSegue(withIdentifier: "welcomeToFinishReg", sender: self)
                }
            }
            
        } else {
            ProgressHUD.showError("Please insert the code!")
        }
    }

    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "welcomeToFinishReg" {
            
            let vc = segue.destination as! FinishRegistrationViewController
            
            if loginSegmentedControlOutlet.selectedSegmentIndex == 0 {
                vc.password = passwordTextField.text!
                vc.email = emailTextField.text!
            } else {
                vc.countryCode = countryCodeTextField.text
            }
        }
    }

    //MARK: Animations
    
    func animateViewIn(view: Int) {
        
        UIView.animate(withDuration: 0.5) {
            switch view {
            case 0:
                self.emailLoginView.frame.origin.x = AnimationManager.screenBounds.minX + 16
                self.loginView.frame.origin.x = AnimationManager.screenBounds.maxX + 10
                self.signUpButtonOutlet.isEnabled = true
            case 1:
                self.loginView.frame.origin.x = AnimationManager.screenBounds.minX + 16
                self.emailLoginView.frame.origin.x = AnimationManager.screenBounds.minX - (self.emailLoginView.frame.width + 10)
                self.signUpButtonOutlet.isEnabled = false
            default:
                return
            }
        }
    }

    func animateLogoIn() {
        //autorevers works only with repeat
        
        UIView.animate(withDuration: 1.5, delay: 0.75, options: [.curveEaseInOut], animations: {
            
            self.logoView.alpha = 1
            self.logoView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2) //20% larger, Affin is for scale, rotation check the docs
            
        }) { (completion) in
        }
    }

}


extension PhoneNumberLoginViewController {
    
    //email login
    
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
        
        ProgressHUD.show("Login...")
        
        FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) { (error) in
            
            //error handeling
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            
            ProgressHUD.dismiss()
            
            self.cleanTextFields()
            self.dismissKeyboard()
            
            //post user did login notification
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
            
            goToApp(fromView: self, to: "mainApplication")
        }
    }
    
    func registerUserWithEmail() {

        self.performSegue(withIdentifier: "welcomeToFinishReg", sender: self)
        self.cleanTextFields()
        self.dismissKeyboard()
    }

    

}
