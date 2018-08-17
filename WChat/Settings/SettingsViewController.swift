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

    @IBOutlet weak var deleteAccountButtonOutlet: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    @IBOutlet weak var cleanCacheButtonOutlet: UIButton!
    @IBOutlet weak var showAvatarSwitchOutlet: UISwitch!
    var avatarSwitchStatus = false
    var firstLoad: Bool?
    
    let userDefaults = UserDefaults.standard


    override func viewDidAppear(_ animated: Bool) {
        if FUser.currentUser() != nil {
            setupUI()
        }
    }
    
    //because of bar button item bug
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintAdjustmentMode = .normal
        self.navigationController?.navigationBar.tintAdjustmentMode = .automatic
    }//end of bug fix

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true

        //to remove empty cell lines
        tableView.tableFooterView = UIView()
        
        if FUser.currentUser() != nil {
            setupUI()
            loadUserDefaults()
        }
    }
    
    //MARK: TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 1 { return 5}
        return 2
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
    
    @IBAction func cleanCacheButtonPressed(_ sender: Any) {
        
        self.cleanCache()

//        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//        let cleanPhotoes = UIAlertAction(title: NSLocalizedString("Clean Photoes", comment: ""), style: .default) { (alert: UIAlertAction!) in
//
//            self.cleanCache(kPICTURE)
//        }
//
//        let cleanVideos = UIAlertAction(title: NSLocalizedString("Clean Videos", comment: ""), style: .default) { (alert: UIAlertAction!) in
//
//            self.cleanCache(kVIDEO)
//        }
//
//        let cleanAudios = UIAlertAction(title: NSLocalizedString("Clean Audios", comment: ""), style: .default) { (alert: UIAlertAction!) in
//
//            self.cleanCache(kAUDIO)
//        }
//
//
//        let cleanAll = UIAlertAction(title: NSLocalizedString("Clean All", comment: ""), style: .default) { (alert: UIAlertAction!) in
//            self.cleanCache("all")
//        }
//
//        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (alert: UIAlertAction!) in
//
//        }
//
//        cleanPhotoes.setValue(UIImage(named: "picture"), forKey: "image")
//        cleanVideos.setValue(UIImage(named: "video"), forKey: "image")
//        cleanAudios.setValue(UIImage(named: "mic"), forKey: "image")
//        cleanAll.setValue(UIImage(named: "location"), forKey: "image")
//
//
//        optionMenu.addAction(cleanPhotoes)
//        optionMenu.addAction(cleanVideos)
//        optionMenu.addAction(cleanAudios)
//        optionMenu.addAction(cleanAll)
//        optionMenu.addAction(cancelAction)
//
//        //for iPad not to crash
//        if ( UI_USER_INTERFACE_IDIOM() == .pad )
//        {
//            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
//
//                currentPopoverpresentioncontroller.sourceView = self.cleanCacheButtonOutlet
//                currentPopoverpresentioncontroller.sourceRect = self.cleanCacheButtonOutlet.bounds
//
//
//                currentPopoverpresentioncontroller.permittedArrowDirections = .up
//                self.present(optionMenu, animated: true, completion: nil)
//            }
//        }else{
//            self.present(optionMenu, animated: true, completion: nil)
//
//        }

        
    }
    
    @IBAction func showAvatarSwitchValueChanged(_ sender: UISwitch) {

        avatarSwitchStatus = sender.isOn
        saveUserDefaults()
    }
    
    @IBAction func tellAFriendButtonPressed(_ sender: Any) {
        let text = "Hey! Lets chat on WChat \(kAPPURL)"
        
        let objectsToShare: [Any] = [text]
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        activityViewController.setValue(NSLocalizedString("Lets chat on WChat", comment: ""), forKey: "subject")
        
        self.present(activityViewController, animated: true, completion: nil)

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
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = version
        }
    }
    
    func deleteUser() {
        
        //delete local user
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        
        //delete user object in firebase database
        reference(.User).document(FUser.currentId()).delete()
        
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

    func saveUserDefaults() {
        
        userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
        userDefaults.synchronize()
    }

    
    func loadUserDefaults() {
        
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
            userDefaults.synchronize()
            
        }
        
        avatarSwitchStatus = userDefaults.bool(forKey: kSHOWAVATAR)
        showAvatarSwitchOutlet.isOn = avatarSwitchStatus
    }
    
    func cleanCache() {
        //add individual clean later on
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: getDocumentsURL().path)
            for file in files {
                try FileManager.default.removeItem(atPath: "\(getDocumentsURL().path)/\(file)")
            }
            ProgressHUD.showSuccess("Cache cleaned!")
        } catch {
            ProgressHUD.showError("couldnt clean pics")
        }
    }

}
