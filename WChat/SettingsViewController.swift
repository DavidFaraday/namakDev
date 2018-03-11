//
//  SettingsViewController.swift
//  WChat
//
//  Created by David Kababyan on 10/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD

class SettingsViewController: UIViewController {

    @IBOutlet weak var deleteAccountButtonOutlet: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.text = FUser.currentUser()?.fullname
    }
    
    
    //MARK: IBActions

    @IBAction func logOutButtonPressed(_ sender: Any) {
        
        FUser.logOutCurrentUser { (success) in
            
            print("logged out")
            self.showLoginView()
        }
        
    }
    
    @IBAction func deleteAccountButtonPressed(_ sender: Any) {
        
        //show warning
        let optionMenu = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete the account?", preferredStyle: .actionSheet)
        
        let deletAction = UIAlertAction(title: "Delete", style: .destructive) { (alert: UIAlertAction!) in
            
            self.deleteUser()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        
        optionMenu.addAction(deletAction)
        optionMenu.addAction(cancelAction)
        
        if ( UI_USER_INTERFACE_IDIOM() == .pad )
        {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{

                currentPopoverpresentioncontroller.sourceView = deleteAccountButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = deleteAccountButtonOutlet.bounds


                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
            
        }
    }
    
    //MARK: Helpers
    
    func deleteUser() {
        
        //delete local user
        UserDefaults.standard.removeObject(forKey: kPUSHID)
        UserDefaults.standard.removeObject(forKey: kCURRENTUSER)
        UserDefaults.standard.synchronize()
        
        //delete user object in firebase database
        firebase.child(kUSER_PATH).child(FUser.currentId()).removeValue()
        
        FUser.deleteUser { (error) in
            
            if error != nil {
                
                DispatchQueue.main.async {
                    ProgressHUD.showError("Couldnt Delete the user")
                }
                
                return
            }
            
            self.showLoginView()
        }

    }
    
    func showLoginView() {
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcome")
        
        self.present(mainView, animated: true, completion: nil)
    }

    
}
