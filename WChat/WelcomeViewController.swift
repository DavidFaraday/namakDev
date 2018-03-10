//
//  WelcomeViewController.swift
//  WChat
//
//  Created by David Kababyan on 10/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit


class WelcomeViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()


        
    }
    
    
    //MARK: IBActions
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        
        
        
    }
    

    @IBAction func backgroundTap(_ sender: Any) {
        
        self.view.endEditing(false)
        print("tap")
    }
    

    
}
