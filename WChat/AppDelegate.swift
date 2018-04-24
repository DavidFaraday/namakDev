//
//  AppDelegate.swift
//  WChat
//
//  Created by David Kababyan on 08/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?

    var locationManager: CLLocationManager?
    var coordinates: CLLocationCoordinate2D?

    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true

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

        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, queue: nil, using: {
            note in
            
            let userId = note.userInfo!["userId"] as! String
            UserDefaults.standard.set(userId, forKey: "userId")
            UserDefaults.standard.synchronize()
            
            userDidLogin(userId: userId)
        })
        
        func userDidLogin(userId: String) {
            
//            self.push.registerUserNotificationSettings()
//            self.initSinchWithUserId(userId: userId)
            self.startOneSignal()
        }


        
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID, handleNotificationReceived: nil, handleNotificationAction: nil, settings: [kOSSettingsKeyInAppAlerts : false])
        
        
        
        OneSignal.setLogLevel(ONE_S_LOG_LEVEL.LL_NONE, visualLevel: ONE_S_LOG_LEVEL.LL_NONE)

        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        locationManagerStart()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        locationMangerStop()
    }

    
    //MARK: Location Manager
    func locationManagerStart() {
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager!.requestWhenInUseAuthorization()
        }
        
        locationManager!.startUpdatingLocation()
    }
    
    func locationMangerStop() {
        locationManager!.stopUpdatingLocation()
    }

    //MARK: Location ManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("failed to get location")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
            break
        case .authorizedAlways:
            manager.startUpdatingLocation()
            break
        case .restricted:
            // restricted by e.g. parental controls. User can't enable Location Services
            break
        case .denied:
            locationManager = nil
            print("denied location")
            // user denied your app access to Location Services, but can grant access from Settings.app
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinates = locations.last!.coordinate
    }
    



    //MARK: Go To App
    
    func goToApp() {        

        //post user did login notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.window?.rootViewController = mainView
    }
    
    
    //MARK: OneSignal
    
    func startOneSignal() {
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        
        let userID = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        
        if pushToken != nil {
            if let playerID = userID {
                UserDefaults.standard.setValue(playerID, forKey: kPUSHID)
            } else {
                UserDefaults.standard.removeObject(forKey: kPUSHID)
            }
        }
        
        updateOneSignalId()
    }


}

