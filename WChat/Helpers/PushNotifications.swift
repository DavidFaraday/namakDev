//
//  PushNotifications.swift
//  WChat
//
//  Created by David Kababyan on 09/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import OneSignal



func sendPushNotification(membersToPush: [String], message: String) {

    let updatedMembers = removeCurrentUserFromMembersArray(members: membersToPush)

    getMembersToPush(members: updatedMembers, completion: {
        usersPushIDs in
        
        let currentUser = FUser.currentUser()

        OneSignal.postNotification(["contents": ["en": "\(currentUser!.firstname) \n \(message)"], "ios_badgeType" : "Increase", "ios_badgeCount" : "1", "include_player_ids": usersPushIDs])
    })
}


func removeCurrentUserFromMembersArray(members: [String]) -> [String] {
    
    var updatedMembers: [String] = []
    
    for member in members {
        
        if member != FUser.currentId() {
            updatedMembers.append(member)
        }
    }
    
    return updatedMembers
}

func getMembersToPush(members: [String], completion: @escaping (_ usersArray: [String]) -> Void) {
    
    var pushIds: [String] = []
    var count = 0

    for memberId in members {
        reference(collectionReference: .User).document(memberId).getDocument { (snapshot, error) in
            
            guard let snapshot = snapshot else { completion(pushIds); return }
            
            if snapshot.exists {
                
                let userDictionary = snapshot.data() as! NSDictionary
                
                let fUser = FUser.init(_dictionary: userDictionary)
                
                pushIds.append(fUser.pushId!)
                count += 1
                
                if members.count == count {
                    completion(pushIds)
                }

            } else {
                completion(pushIds)
            }
            
        }
    }
}

