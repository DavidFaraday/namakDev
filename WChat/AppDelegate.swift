//
//  AppDelegate.swift
//  WChat
//
//  Created by David Kababyan on 08/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        
        FirebaseApp.configure()
        
        //AutoLogin
        authListener = Auth.auth().addStateDidChangeListener { auth, user in
            
            Auth.auth().removeStateDidChangeListener(self.authListener!)

            if user != nil {
                
                if userDefaults.object(forKey: kCURRENTUSER) != nil {
                    DispatchQueue.main.async {
                        
                        self.goToApp()
                    }
                }
            }
        }

        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }


    //MARK: Go To App
    
    func goToApp() {        

        //post user did login notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.window?.rootViewController = mainView
    }

}

