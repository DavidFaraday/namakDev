//
//  ProfileViewController.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var fullNameLabel: UILabel!
    
    var user:FUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if user != nil {
            fullNameLabel.text = user!.fullname
        }
    }
    
    //MARK: IBActions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
}
