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
    @IBOutlet weak var viewOne: UIView!
    @IBOutlet weak var viewTwo: UIView!
    
    
    
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var mobileNumberTextField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var requestButtonOutlet: UIButton!
    
    let swipeGestureLeft = UISwipeGestureRecognizer()
    let swipeGestureRight = UISwipeGestureRecognizer()

    @IBOutlet weak var pageControl: UIPageControl!
    
    var phoneNumber: String!
    var verificationId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //hide page controll
        pageControl.isHidden = true
        
        self.swipeGestureLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.swipeGestureRight.direction = UISwipeGestureRecognizer.Direction.right
        
//        self.swipeGestureLeft.addTarget(self, action: #selector(self.handleSwipeLeft(_:)))
//        self.swipeGestureRight.addTarget(self, action: #selector(self.handleSwipeRight(_:)))
        
//        self.view.addGestureRecognizer(self.swipeGestureLeft)
//        self.view.addGestureRecognizer(self.swipeGestureRight)

        countryCodeTextField.text = CountryCode().currentCode
    }
    
    //MARK: IBActions
    
    @IBAction func requestButtonPressed(_ sender: Any) {
        
        if verificationId != nil {
            registerUser()
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
    
    
    func registerUser() {
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
                    self.performSegue(withIdentifier: "welcomeToFinishReg", sender: self)

                    //go to finish reg
                }
            }
            
        } else {
            ProgressHUD.showError("Please insert the code!")
        }
    }

    //MARK: SwipeViewFunctions
        
    // increase page number on swift left
    @objc func handleSwipeLeft(_ gesture: UISwipeGestureRecognizer){
        if pageControl.currentPage < 3 {
            pageControl.currentPage += 1
            showView()
        }
    }
    
    // reduce page number on swift right
    @objc func handleSwipeRight(_ gesture: UISwipeGestureRecognizer){
        
        if pageControl.currentPage != 0 {
            pageControl.currentPage -= 1
            showView()
        }
        
    }
    
    func showView() {
        
        switch pageControl.currentPage {
        case 0:
            viewOne.isHidden = false
//            viewTwo.isHidden = true
//            loginView.isHidden = true
        case 1:
            viewOne.isHidden = true
//            viewTwo.isHidden = false
//            loginView.isHidden = true
        case 2:
            viewOne.isHidden = true
//            viewTwo.isHidden = true
//            loginView.isHidden = false
            
        default:
            print("unknow page")
        }
        
    }
    
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "welcomeToFinishReg" {
            let vc = segue.destination as! FinishRegistrationViewController
            vc.countryCode = countryCodeTextField.text
        }
    }


}
