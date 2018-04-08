//
//  Recent.swift
//  WChat
//
//  Created by David Kababyan on 13/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation

func startPrivateChat(user1: FUser, user2: FUser) -> String {
    
    let userId1 = user1.objectId as String
    let userId2 = user2.objectId as String
    
    var chatRoomId: String = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0 {
        chatRoomId = userId1 + userId2
        
    } else {
        chatRoomId = userId2 + userId1
    }
    
    let members = [userId1, userId2]
    
    createRecent(members: members, chatRoomId: chatRoomId, withUserUserId: userId2, withUserUsername: user2.firstname, type: kPRIVATE)
    
    return chatRoomId
}



func createRecent(members: [String], chatRoomId: String, withUserUserId: String, withUserUsername: String, type: String) {
    
//    for each user
    for userId in members {
        
        //check if the user has recent with that chartoom id, if no create one
        firebase.child(kRECENT_PATH).child(userId).child(chatRoomId).observeSingleEvent(of: .value, with: {
            snapshot in
            
            var create = true
            
            if snapshot.exists() {
                
                create = false
            }
            
            if create {
                
                creatRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUserId: withUserUserId, withUserUsername: withUserUsername, type: type)
            }
            
        })
        
    }
}

func creatRecentItem(userId: String, chatRoomId: String, members: [String], withUserUserId: String, withUserUsername: String, type: String) {
    
    let refernce = firebase.child(kRECENT_PATH).child(userId).child(chatRoomId)
    
    let date = dateFormatter().string(from: Date())
    
    let recent = [kRECENTID: chatRoomId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERUSERNAME: withUserUsername, kWITHUSERUSERID: withUserUserId, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type] as [String : Any]
    
    
    refernce.setValue(recent) { (error, ref) in
        
        if error != nil {
            
            print("Couldnt create recent for user \(userId): \(error!.localizedDescription)")
        }
        
    }
}


//Restart RecentChat

func restartRecentChat(recent: NSDictionary) {
    
    if (recent[kTYPE] as? String)! == kPRIVATE {
        
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: (recent[kCHATROOMID] as? String)!, withUserUserId: FUser.currentId(), withUserUsername: FUser.currentUser()!.firstname, type: kPRIVATE)

    }
    
    if (recent[kTYPE] as? String)! == kGROUP {
        
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserId: "", withUserUsername: recent[kWITHUSERUSERNAME] as! String, type: kGROUP)
    }
    
}

//delete recent

func deleteRecentChat(recentDictionary: NSDictionary) {
   
    if let recentId = recentDictionary[kRECENTID] {
        
        firebase.child(kRECENT_PATH).child(FUser.currentId()).child(recentId as! String).removeValue { (error, ref) in
            
            if error != nil {
                print("cannot delete recent \(error!.localizedDescription)")
            }
        }
    }
}

//Update RecentChat
func updateRecents(chatRoomId: String, memberIds: [String], lastMessage: String) {
    
    for memberId in memberIds {
        firebase.child(kRECENT_PATH).child(memberId).child(chatRoomId).observeSingleEvent(of: .value, with: {
            snapshot in
            
            if snapshot.exists() {
                
                let recent = snapshot.value as! NSDictionary
                updateRecentItem(recent: recent, lastMessage: lastMessage)
            }
            
        })
        
    }
}


func updateRecentItem(recent: NSDictionary, lastMessage: String) {
    
    let date = dateFormatter().string(from: Date())
    
    var counter = recent[kCOUNTER] as! Int
    
    if recent[kUSERID] as? String != FUser.currentUser()!.objectId {
        
        counter += 1
    }
    
    let values = [kLASTMESSAGE: lastMessage, kCOUNTER: counter, kDATE: date] as [String : Any]
    
    
    firebase.child(kRECENT_PATH).child(recent[kUSERID] as! String).child(recent[kRECENTID] as! String).updateChildValues(values)
}

//group

func startGroupChat(group: Group) {
    
    let chatRoomId = group.groupDictionary[kGROUPID] as! String
    
    let members = group.groupDictionary[kMEMBERS] as! [String]
    
    createRecent(members: members, chatRoomId: chatRoomId, withUserUserId: "", withUserUsername: group.groupDictionary[kNAME] as! String, type: kGROUP)
}

func createRecentsForNewMembers(group: NSDictionary) {
    
    let chatRoomId = group[kGROUPID] as! String
    //we dont want to create recent for users that left the chatroom
    let membersToPush = group[kMEMBERSTOPUSH] as! [String]

    createRecent(members: membersToPush, chatRoomId: chatRoomId, withUserUserId: "", withUserUsername: group[kNAME] as! String, type: kGROUP)
}

func updateExistingRicentsWithNewValues(group: NSDictionary) {
    
    let chatRoomId = group[kGROUPID] as! String
    let membersToPush = group[kMEMBERSTOPUSH] as! [String]
    let members = group[kMEMBERS] as! [String]

    for memberId in membersToPush {
        firebase.child(kRECENT_PATH).child(memberId).child(chatRoomId).observeSingleEvent(of: .value, with: {
            snapshot in
            
            if snapshot.exists() {
                
                let recent = snapshot.value as! NSMutableDictionary
                recent[kMEMBERSTOPUSH] = membersToPush
                recent[kMEMBERS] = members
                //for updating group name and avatar
                recent[kWITHUSERUSERNAME] = group[kNAME] as! String
                recent[kAVATAR] = group[kAVATAR] as! String
                
                updateRecet(newRecent: recent, userId: memberId)
            }
            
        })
    }
}

func updateRecet(newRecent: NSDictionary, userId: String) {
    firebase.child(kRECENT_PATH).child(userId).child(newRecent[kRECENTID] as! String).updateChildValues(newRecent as! [AnyHashable : Any])
}

