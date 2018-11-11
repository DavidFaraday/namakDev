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
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, SINClientDelegate, SINCallClientDelegate, SINManagedPushDelegate {
    
    
    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?


    var locationManager: CLLocationManager?
    var coordinates: CLLocationCoordinate2D?

    var _client: SINClient!
    var push: SINManagedPush!
    var callKitProvider: SINCallKitProvider!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {


//        //MARK: Realm Migrations
//        Realm.Configuration.defaultConfiguration = Realm.Configuration(
//            // bump the schema version to 1
//            schemaVersion: 1,
//            migrationBlock: { migration, oldSchemaVersion in
//                migration.enumerateObjects(ofType: DBMessage.className(), { (oldObject, newObject) in
//                    
//                    // make sure to check the version accordingly
//                    if (oldSchemaVersion < 1) {
//                        // the magic happens here: `id` is the property you specified
//                        // as your primary key on your Model
//                        newObject!["messageId"] = "id"
//                    }
//
//                })
//            }
//        )
//
        FirebaseApp.configure()
        FirestoreSettings().isPersistenceEnabled = false

        //AutoLogin
        authListener = Auth.auth().addStateDidChangeListener { auth, user in
        
            Auth.auth().removeStateDidChangeListener(self.authListener!)

            if user != nil && userDefaults.object(forKey: kCURRENTUSER) != nil {
                DispatchQueue.main.async {
                    self.goToApp()
                }
            }
        }

        self.push = Sinch.managedPush(with: .development)
        self.push.delegate = self
        self.push.setDesiredPushTypeAutomatically()

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, queue: nil, using: {
            note in
            
            let userId = note.userInfo![kUSERID] as! String
            UserDefaults.standard.set(userId, forKey: kUSERID)
            UserDefaults.standard.synchronize()
            
            self.userDidLogin(userId: userId)
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: USER_DID_LOGOUT_NOTIFICATION), object: nil, queue: nil, using: {
            note in
            
            self.userDidLogout()
        })
        
        //OneSignal
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID, handleNotificationReceived: nil, handleNotificationAction: nil, settings: [kOSSettingsKeyInAppAlerts : false])
        
        OneSignal.setLogLevel(ONE_S_LOG_LEVEL.LL_NONE, visualLevel: ONE_S_LOG_LEVEL.LL_NONE)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {

        var top = self.window?.rootViewController
        
        while (top?.presentedViewController != nil) {
            top = top?.presentedViewController
        }
        
        if top! is UITabBarController {
            setBadges(controller: top as! UITabBarController)
        }
        
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : true]) { (success) in}
        }

        locationManagerStart()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        recentBadgeHandler?.remove()
        updateCurrentUserInFirestore(withValues: [kISONLINE : false]) { (success) in
            
        }

        locationMangerStop()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        if callKitProvider != nil {
            let call = callKitProvider.currentEstablishedCall()
            
            if call != nil {
                var top = self.window?.rootViewController
                
                while (top?.presentedViewController != nil) {
                    top = top?.presentedViewController
                }
                
                
                if !(top! is CallViewController) {
                    let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
                    
                    callVC._call = call
                    
                    top?.present(callVC, animated: true, completion: nil)
                }
            }
        }
        // If there is one established call, show the callView of the current call when the App is brought to foreground.
        // This is mainly to handle the UI transition when clicking the App icon on the lockscreen CallKit UI.
        
    }
    
    

    //MARK: PushNotification functions
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        Auth.auth().setAPNSToken(deviceToken, type:AuthAPNSTokenType.sandbox)
    }
    

    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

//        if Auth.auth().canHandleNotification(userInfo){
//            return
//        }
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
        if locationManager != nil {
            locationManager!.stopUpdatingLocation()
        }
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
        UserDefaults.standard.synchronize()
        
        updateOneSignalId()
    }

    
    //MARK: Sinch Init
    func initSinchWithUserId(userId: String) {
        
        if _client == nil {
            _client = Sinch.client(withApplicationKey: kSINCHKEY, applicationSecret: kSINCHSECRET, environmentHost: "sandbox.sinch.com", userId: userId)
            
            _client.delegate = self
            _client.call()?.delegate = self
            
            _client.setSupportCalling(true)
            _client.enableManagedPushNotifications()
            _client.start()
            _client.startListeningOnActiveConnection()

            callKitProvider = SINCallKitProvider(withClient: _client)
        }
    }
    
    
    //MARK: SinManagedPushDelegate
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
        
        if pushType == "PKPushTypeVoIP" {
            let result = SINPushHelper.queryPushNotificationPayload(payload)

            if result!.isCall() {
                callKitProvider.remoteDisplayName = result!.call()?.headers[kNAME] as? String
            }

            self.handleRemoteNotification(userInfo: payload as NSDictionary)
        }
    }
    
    func handleRemoteNotification(userInfo: NSDictionary) {
        
        if _client == nil {
            if let userId = UserDefaults.standard.object(forKey: kUSERID) {
                self.initSinchWithUserId(userId: userId as! String)
            }
        }
        
        let result = self._client.relayRemotePushNotification(userInfo as? [AnyHashable : Any])

        
        if result!.isCall() && result!.call().isCallCanceled {
            self.presentMissedCallNotificationWithRemoteUserId(remoteUserId: result!.call()?.headers[kNAME] as? String ?? "Unknown")
        }

    }
    
    
    func presentMissedCallNotificationWithRemoteUserId (remoteUserId: String) {
        
        if UIApplication.shared.applicationState == .background {
            
            let center =  UNUserNotificationCenter.current()
            
            //create the content for the notification
            let content = UNMutableNotificationContent()
            content.title = "Missed call"
//            content.body = "From \(remoteUserId)"
            content.sound = UNNotificationSound.default
            
            //notification trigger can be based on time, calendar or location
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval:1, repeats: false)
            
            //create request to display
            let request = UNNotificationRequest(identifier: "ContentIdentifier", content: content, trigger: trigger)
            
            //add request to notification center
            center.add(request) { (error) in
                if error != nil {
                    print("error \(String(describing: error))")
                }
            }
        }
    }


    
    //MARK: SinchCallClientDelegates
    
    func client(_ client: SINCallClient!, willReceiveIncomingCall call: SINCall!) {

        callKitProvider.reportNewIncomingCall(call: call)
    }
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {

        var top = self.window?.rootViewController

        while (top?.presentedViewController != nil) {
            top = top?.presentedViewController
        }

        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController

        callVC._call = call

        top?.present(callVC, animated: true, completion: nil)
    }


    //MARK: SinchClient delegates
    
    func clientDidStart(_ client: SINClient!) {
        print("client did start")
        
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        print("client did fail")
    }
    
    //MARK: LOGIN LOGOUT helpers
    
    private func userDidLogin(userId: String) {
        self.push.registerUserNotificationSettings()
        self.initSinchWithUserId(userId: userId)
        self.startOneSignal()
    }

    private func userDidLogout() {
        print("did log out")
        if _client != nil {
            _client.stopListeningOnActiveConnection()
            _client.unregisterPushNotificationData()
            _client.terminate()
            _client = nil
        }
    }

    


}

