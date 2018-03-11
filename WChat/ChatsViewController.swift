//
//  ChatsViewController.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit

class ChatsViewController: UIViewController {

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    @IBAction func showAllUsersButtonPressed(_ sender: Any) {
        
        let usersVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UsersView") as! UsersViewController

        self.present(usersVC, animated: true, completion: nil)
        
    }


}
