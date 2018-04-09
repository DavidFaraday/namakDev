//
//  Group.swift
//  WChat
//
//  Created by David Kababyan on 19/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation


class Group {
    
    let groupDictionary: NSMutableDictionary
    
    init (groupId: String, subject: String, ownerId: String, members: [String], avatar: String) {
        
        groupDictionary = NSMutableDictionary(objects: [groupId, subject, ownerId, members, members, avatar], forKeys: [kGROUPID as NSCopying, kNAME as NSCopying, kOWNERID as NSCopying, kMEMBERS as NSCopying, kMEMBERSTOPUSH as NSCopying, kAVATAR as NSCopying])
    }

    func saveGroup(group: NSMutableDictionary) {
        
        let reference = firebase.child(kGROUP_PATH).child(groupDictionary[kGROUPID] as! String)
        let date = dateFormatter().string(from: Date())
        
        groupDictionary[kDATE] = date
        
        reference.setValue(groupDictionary) { (error, ref) in
            
            if error != nil {
                print("Error saving group: \(error!.localizedDescription)")
            }
        }
    }
    
    class func updateGroup(groupId: String ,withValues: [String : Any]) {
        
    firebase.child(kGROUP_PATH).child(groupId).updateChildValues(withValues)

    }
    
    
    

}
