//
//  CallClass.swift
//  WChat
//
//  Created by David Kababyan on 20/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation


class CallN {
    
    var objectId: String
    var callerId: String
    var callerFullName: String
    var callerAvatar: String
    var withUserId: String
    var withUserFullName: String
    var withUserAvatar: String
    var status: String
    var isIncoming: Bool
    var callDate: Date
    
    init (_callerId: String, _withUserId: String, _callerFullName: String, _withUserFullName: String, _callerAvatar: String, _withUserAvatar: String) {
        
        objectId = UUID().uuidString
        callerId = _callerId
        callerFullName = _callerFullName
        callerAvatar = _callerAvatar
        withUserId = _withUserId
        withUserFullName = _withUserFullName
        withUserAvatar = _withUserAvatar
        status = ""
        isIncoming = false
        callDate = Date()
    }
    
    
    
    
    
    init(_dictionary: NSDictionary) {
        
        objectId = _dictionary[kOBJECTID] as! String
        
        if let callId = _dictionary[kCALLERID] {
            callerId = callId as! String
        } else {
            callerId = ""
        }
        if let withId = _dictionary[kWITHUSERUSERID] {
            withUserId = withId as! String
        } else {
            withUserId = ""
        }
        if let callFName = _dictionary[kCALLERFULLNAME] {
            callerFullName = callFName as! String
        } else {
            callerFullName = "Unknown"
        }
        if let callAvatar = _dictionary[kCALLERAVATAR] {
            callerAvatar = callAvatar as! String
        } else {
            callerAvatar = ""
        }
        if let withUserFName = _dictionary[kWITHUSERFULLNAME] {
            withUserFullName = withUserFName as! String
        } else {
            withUserFullName = "Unknown"
        }
        if let withAvatar = _dictionary[kWITHUSERAVATAR] {
            withUserAvatar = withAvatar as! String
        } else {
            withUserAvatar = ""
        }
        if let callStatus = _dictionary[kCALLSTATUS] {
            status = callStatus as! String
        } else {
            status = "Unknown"
        }
        if let incoming = _dictionary[kISINCOMING] {
            isIncoming = incoming as! Bool
        } else {
            isIncoming = false
        }
        
        if let date = _dictionary[kDATE] {
            if (date as! String).count != 14 {
                callDate = Date()
            } else {
                callDate = dateFormatter().date(from: date as! String)!
            }
        } else {
            callDate = Date()
        }

    }
    
    
    
    func dictionaryFromCall() -> NSDictionary {
        
        let dateString = dateFormatter().string(from: callDate)
        
        return NSDictionary(objects: [objectId, callerId, callerFullName, callerAvatar, withUserId, withUserFullName, withUserAvatar, status, isIncoming, dateString], forKeys: [kOBJECTID as NSCopying ,kCALLERID as NSCopying, kCALLERFULLNAME as NSCopying, kCALLERAVATAR as NSCopying, kWITHUSERUSERID as NSCopying, kWITHUSERFULLNAME as NSCopying, kWITHUSERAVATAR as NSCopying, kCALLSTATUS as NSCopying, kISINCOMING as NSCopying, kDATE as NSCopying])
    }
    
    
    //MARK: Save funcs
    func saveCallInBackground() {
        
        firebase.child(kCALL_PATH).child(callerId).child(objectId).setValue(dictionaryFromCall())
        firebase.child(kCALL_PATH).child(withUserId).child(objectId).setValue(dictionaryFromCall())
    }

    //MARK: Update funcs

    func updateCall(withValues: [String : Any]) {
        
        firebase.child(kCALL_PATH).child(callerId).child(objectId).updateChildValues(withValues)
        firebase.child(kCALL_PATH).child(withUserId).child(objectId).updateChildValues(withValues)
    }
    
    //MARK: Delet funcs
    
    func deleteCall() {
        
        firebase.child(kCALL_PATH).child(FUser.currentId()).child(objectId).removeValue()
    }

    
}
