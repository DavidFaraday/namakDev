//
//  SettingsViewController.swift
//  WChat
//
//  Created by David Kababyan on 10/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import ProgressHUD

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var deleteAccountButtonOutlet: UIButton!

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        if FUser.currentUser() != nil {
            setupUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableHeaderView = headerView
        //to remove empty cell lines
        tableView.tableFooterView = UIView()
        if FUser.currentUser() != nil {
            setupUI()
        }
    }
    
    //MARK: TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            return 0
        }
        return 30
    }

    
    
    //MARK: IBActions
    
    @IBAction func editButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "settingsToEditProfileSeg", sender: self)
    }
    

    @IBAction func logOutButtonPressed(_ sender: Any) {
        
        FUser.logOutCurrentUser { (success) in
            
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
    
    func setupUI() {

        let currentUser = FUser.currentUser()!
        
        fullNameLabel.text = currentUser.fullname
        
        imageFromData(pictureData: currentUser.avatar) { (avatarImage) in
            
            if avatarImage != nil {
                self.avatarImageView.image = avatarImage!.circleMasked
            }
        }
    }
    
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
