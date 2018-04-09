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
    
    
    createRecent(members: members, chatRoomId: chatRoomId, withUserUsername: "", type: kPRIVATE, users: [user1, user2], avatarOfGroup: nil)
    
    return chatRoomId
}



func createRecent(members: [String], chatRoomId: String, withUserUsername: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
    
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
                
                creatRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUsername: withUserUsername, type: type, users: users, avatarOfGroup: avatarOfGroup)
            }
            
        })
        
    }
}

func creatRecentItem(userId: String, chatRoomId: String, members: [String], withUserUsername: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
    
    let refernce = firebase.child(kRECENT_PATH).child(userId).child(chatRoomId)

    let date = dateFormatter().string(from: Date())

    var recent: [String : Any]!
    
    if type == kPRIVATE {
        
        var withUser: FUser?
        
        if users != nil && users!.count > 0 {
            if userId == FUser.currentId() {
                print("creating for current user")
                //we create for current user
                withUser = users!.last!
            } else {
                withUser = users!.first!
            }
        }

        
        recent = [kRECENTID: chatRoomId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERUSERNAME: withUser!.fullname, kWITHUSERUSERID: withUser!.objectId, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: withUser!.avatar] as [String : Any]
        
    } else {
        
        //group recentChat
        print("group recent pending")
        if avatarOfGroup != nil {
            recent = [kRECENTID: chatRoomId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERUSERNAME: withUserUsername, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: avatarOfGroup!] as [String : Any]
        }
    }
    
    refernce.setValue(recent)
}


//Restart RecentChat

func restartRecentChat(recent: NSDictionary) {
    
    if (recent[kTYPE] as? String)! == kPRIVATE {
        
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: (recent[kCHATROOMID] as? String)!, withUserUsername: FUser.currentUser()!.firstname, type: kPRIVATE, users: [FUser.currentUser()!], avatarOfGroup: nil)

    }
    
    if (recent[kTYPE] as? String)! == kGROUP {
        
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUsername: recent[kWITHUSERUSERNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: recent[kAVATAR] as! String)
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

//Clear counter

func clearRecentCounter(chatRoomID: String) {
    
    firebase.child(kRECENT_PATH).child(FUser.currentId()).child(chatRoomID).observeSingleEvent(of: .value, with: {
        snapshot in

        if snapshot.exists() {
            
            let recent = snapshot.value as! NSDictionary
            
            clearRecentCounterItem(recent: recent)
            
        } else {
            print("no snap")
        }
    })
}

func clearRecentCounterItem(recent: NSDictionary) {
    firebase.child(kRECENT_PATH).child(FUser.currentId()).child(recent[kRECENTID] as! String).updateChildValues([kCOUNTER : 0])
}



//group

func startGroupChat(group: Group) {
    
    let chatRoomId = group.groupDictionary[kGROUPID] as! String
    
    let members = group.groupDictionary[kMEMBERS] as! [String]
    
    createRecent(members: members, chatRoomId: chatRoomId, withUserUsername: group.groupDictionary[kNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: group.groupDictionary[kAVATAR] as? String)
}

func createRecentsForNewMembers(groupId: String, groupName: String,  membersToPush: [String], avatar: String) {
    
    createRecent(members: membersToPush, chatRoomId: groupId, withUserUsername: groupName, type: kGROUP, users: nil, avatarOfGroup: avatar)
}

func updateExistingRicentsWithNewValues(chatRoomId: String, members: [String], withValues: [String : Any]) {
    
    for memberId in members {
        firebase.child(kRECENT_PATH).child(memberId).child(chatRoomId).observeSingleEvent(of: .value, with: {
            snapshot in
            
            if snapshot.exists() {
                
                let recent = snapshot.value as! NSMutableDictionary
                
                updateRecet(recentId: recent[kRECENTID] as! String, userId: memberId, withValues: withValues)
            }
            
        })
    }
}

func updateRecet(recentId: String, userId: String, withValues: [String : Any]) {
    firebase.child(kRECENT_PATH).child(userId).child(recentId).updateChildValues(withValues)
}


