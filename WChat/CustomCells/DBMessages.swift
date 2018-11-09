//
//  DBMessages.swift
//  WChat
//
//  Created by David Kababyan on 13/10/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import RealmSwift

class DBMessage: Object {
    
    @objc dynamic var messageId = ""
    @objc dynamic var chatRoomId = ""
    @objc dynamic var date = Date()
    @objc dynamic var senderName = ""
    @objc dynamic var senderId = ""
    @objc dynamic var readDate = Date()
    @objc dynamic var type = ""
    @objc dynamic var status = ""
    @objc dynamic var message = ""
    @objc dynamic var audio = ""
    @objc dynamic var video = ""
    @objc dynamic var picture = ""
    @objc dynamic var latitude = 0.0
    @objc dynamic var longitude = 0.0
    
    override static func primaryKey() -> String? {
        return "messageId"
    }

    
    class func dictionaryFrom(dbMessage: DBMessage) -> NSMutableDictionary {
        
        let dictionary = NSMutableDictionary(objects: [
                dbMessage.messageId,
                dbMessage.date,
                dbMessage.senderName,
                dbMessage.senderId,
                dbMessage.readDate,
                dbMessage.type,
                dbMessage.status,
                dbMessage.message],
            forKeys: [
                kMESSAGEID as NSCopying,
                kDATE as NSCopying,
                kSENDERNAME as NSCopying,
                kSENDERID as NSCopying,
                kREADDATE as NSCopying,
                kTYPE as NSCopying,
                kSTATUS as NSCopying,
                kMESSAGE as NSCopying
            ])
        
        if dbMessage.picture != "" {
            dictionary[kPICTURE] = dbMessage.picture
        }
        if dbMessage.audio != "" {
            dictionary[kAUDIO] = dbMessage.audio
        }
        if dbMessage.video != "" {
            dictionary[kVIDEO] = dbMessage.video
        }
        if dbMessage.latitude != 0.0 {
            dictionary[kLATITUDE] = dbMessage.latitude
        }
        if dbMessage.longitude != 0.0 {
            dictionary[kLONGITUDE] = dbMessage.longitude
        }

        
        return dictionary
    }
}



func insertMessagesToDB(messages: [NSDictionary], chatRoomId: String) {
    
    for messageDictionary in messages {
        
        createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
    }
}
    

    
    
//MARK: Create Message types

func createMessage(messageDictionary: NSDictionary, chatRoomId: String)  {
    
    let textMessage = DBMessage()
    
    textMessage.chatRoomId = chatRoomId

    if let messageId = messageDictionary[kMESSAGEID] as? String {
        textMessage.messageId = messageId
    }

    if let senderId = messageDictionary[kSENDERID] as? String {
        textMessage.senderId = senderId
    }
    
    if let senderName = messageDictionary[kSENDERNAME] as? String {
        textMessage.senderName = senderName
    }
    
    if let created = messageDictionary[kDATE] as? Date {
        textMessage.date = created
    }
    if let readDate = messageDictionary[kREADDATE] as? Date {
        textMessage.readDate = readDate
    }

    if let status = messageDictionary[kSTATUS] as? String {
        textMessage.status = status
    }
    
    if let type = messageDictionary[kTYPE] as? String {
        textMessage.type = type
    }

    if let message = messageDictionary[kMESSAGE] as? String {
        textMessage.message = message
    }
    
    if let pictureLink = messageDictionary[kPICTURE] as? String {
        textMessage.picture = pictureLink
    }
    
    if let videoLink = messageDictionary[kVIDEO] as? String {
        textMessage.video = videoLink
    }
    
    if let audioLink = messageDictionary[kAUDIO] as? String {
        textMessage.audio = audioLink
    }
    
    if let latitude = messageDictionary[kLATITUDE] as? Double {
        textMessage.latitude = latitude
    }
    
    if let longitude = messageDictionary[kLONGITUDE] as? Double {
        textMessage.longitude = longitude
    }


    //save in db
    saveToRealm(message: textMessage)
}


func saveToRealm(message: DBMessage) {
    let realm = try! Realm()
    do {
        try realm.write {
            realm.add(message, update: true)
        }
    } catch {
        print("Error saving real object \(error.localizedDescription)")
    }
}

func deleteMessageFromLocalDB(dbMessage: DBMessage) {
    let realm = try! Realm()
    do {
        try realm.write {
            realm.delete(dbMessage)
        }
    } catch {
        print("Error deleting real object \(error.localizedDescription)")
    }

}


    
    



