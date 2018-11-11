//
//  Recent.swift
//  WChat
//
//  Created by David Kababyan on 13/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import Firebase

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
    
    var tempMembers = members
    
    //check if the user has recent with that chartoom id, if no create one
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else { return }
        
        
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                
                let currentRecent = recent.data() as NSDictionary
                
                //check if recent has userId
                if let curretUserId = currentRecent[kUSERID] {
                    
                    //if the member has recent, remove it from array
                    if tempMembers.contains(curretUserId as! String) {
                        tempMembers.remove(at: tempMembers.index(of: curretUserId as! String)!)
                    }
                    
                }
            }
        }
        
        //create recents for remaining users
        for userId in tempMembers {
            creatRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUsername: withUserUsername, type: type, users: users, avatarOfGroup: avatarOfGroup)
        }
    }
 
}

func creatRecentItem(userId: String, chatRoomId: String, members: [String], withUserUsername: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
    
    let refernce = reference(.Recent).document()

    let recentId = refernce.documentID

    let date = Timestamp(date: Date())

    var recent: [String : Any]!
    
    if type == kPRIVATE {
        
        var withUser: FUser?
        
        if users != nil && users!.count > 0 {
            if userId == FUser.currentId() {

                //we create for current user
                withUser = users!.last!
            } else {
                withUser = users!.first!
            }
        }

        
        recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERUSERNAME: withUser!.fullname, kWITHUSERUSERID: withUser!.objectId, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: withUser!.avatar] as [String : Any]
        
    } else {
        
        //group recentChat
        if avatarOfGroup != nil {
            recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERUSERNAME: withUserUsername, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: avatarOfGroup!] as [String : Any]
        }
    }
    
    refernce.setData(recent)
}


//Restart RecentChat

func restartRecentChat(recent: NSDictionary) {
    
    if (recent[kTYPE] as? String)! == kPRIVATE {
        
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: (recent[kCHATROOMID] as? String)!, withUserUsername: FUser.currentUser()!.firstname, type: kPRIVATE, users: [FUser.currentUser()!], avatarOfGroup: nil)

    }
    
    if (recent[kTYPE] as? String)! == kGROUP {
        
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUsername: recent[kWITHUSERUSERNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: recent[kAVATAR] as? String)
    }
    
}

//delete recent

func deleteRecentChat(recentDictionary: NSDictionary) {
   
    if let recentId = recentDictionary[kRECENTID] {
        
        reference(.Recent).document(recentId as! String).delete()
        
    }
}

//Update RecentChat
func updateRecents(chatRoomId: String, lastMessage: String) {
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                
                updateRecentItem(recent: recent.data() as NSDictionary, lastMessage: lastMessage)
            }

        }
    }
}


func updateRecentItem(recent: NSDictionary, lastMessage: String) {

    
    let date = Timestamp(date: Date())

    var counter = recent[kCOUNTER] as! Int
    
    if recent[kUSERID] as? String != FUser.currentUser()!.objectId {
        
        counter += 1
    }
    
    let values = [kLASTMESSAGE: lastMessage, kCOUNTER: counter, kDATE: date] as [String : Any]
    
    reference(.Recent).document(recent[kRECENTID] as! String).updateData(values)
}

//Clear counter

func clearRecentCounter(chatRoomId: String) {
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                
                let currentRecent = recent.data() as NSDictionary

                if currentRecent[kUSERID] as? String == FUser.currentUser()!.objectId {
                    
                    clearRecentCounterItem(recent: currentRecent)
                }
            }
            
        }

    }

}

func clearRecentCounterItem(recent: NSDictionary) {
    reference(.Recent).document(recent[kRECENTID] as! String).updateData([kCOUNTER : 0])
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
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                
                let recent = recent.data() as NSDictionary
                updateRecet(recentId: recent[kRECENTID] as! String, withValues: withValues)
            }

        }
    }
}

func updateRecet(recentId: String, withValues: [String : Any]) {
    
    reference(.Recent).document(recentId).updateData(withValues)
}


//Blocking users

func blockUser(userToBlock: FUser) {
    
    let userId1 = FUser.currentId()
    let userId2 = userToBlock.objectId
    
    var chatRoomId: String = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0 {
        chatRoomId = userId1 + userId2
    } else {
        chatRoomId = userId2 + userId1
    }
 
    getRecentsFor(chatRoomId: chatRoomId)
}

func getRecentsFor(chatRoomId: String) {
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let recent = recent.data() as NSDictionary
                deleteRecentChat(recentDictionary: recent)
            }
        }
    }
}

