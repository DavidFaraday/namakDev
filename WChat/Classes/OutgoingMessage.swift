//
//  OutgoingMessage.swift
//  WChat
//
//  Created by David Kababyan on 27/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation

class OutgoingMessage {
    
    let message_ref = firebase.child(kMESSAGE_PATH)

    let messageDictionary: NSMutableDictionary

    //MARK: Initializers
    //text message
    init (message: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date), status, type, false], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }

    //picture
    init(message: String, pictureData: NSData, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        let pic = pictureData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        messageDictionary = NSMutableDictionary(objects: [message, pic, senderId, senderName, dateFormatter().string(from: date), status, type, false], forKeys: [kMESSAGE as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }


    //audio
    init(message: String, audio: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, audio, senderId, senderName, dateFormatter().string(from: date), status, type, false], forKeys: [kMESSAGE as NSCopying, kAUDIO as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }

    //video
    init(message: String, video: String, thumbnail: NSData, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        let picThumb = thumbnail.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        messageDictionary = NSMutableDictionary(objects: [message, video, picThumb, senderId, senderName, dateFormatter().string(from: date), status, type, false], forKeys: [kMESSAGE as NSCopying, kVIDEO as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }

    //location
    init(message: String, latitude: NSNumber, longitude: NSNumber, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, latitude, longitude, senderId, senderName, dateFormatter().string(from: date), status, type, false], forKeys: [kMESSAGE as NSCopying, kLATITUDE as NSCopying, kLONGITUDE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }

    
    
    
    //MARK: SendMessage

    func sendMessage(chatRoomID: String, messageDictionary: NSMutableDictionary, memberIds: [String], membersToPush: [String]) {
        
        let messageId = UUID().uuidString //unique number
        
        for memberId in memberIds {
            let messagePath = message_ref.child(memberId).child(chatRoomID).child(messageId)
            
            messageDictionary[kMESSAGEID] = messageId

            messagePath.setValue(messageDictionary)
        }
        
        updateRecents(chatRoomId: chatRoomID, memberIds: memberIds, lastMessage: messageDictionary[kMESSAGE] as! String)

        //send push
        let pushText = "[\(messageDictionary[kTYPE] as! String) message]"
        
        sendPushNotification(membersToPush: membersToPush, message: pushText)
    }

    
    //MARK: DeleteMessage
    
    class func deleteMessage(withId: String, chatRoomId: String) {
        
        let values = [kDELETED : true]
        firebase.child(kMESSAGE_PATH).child(FUser.currentId()).child(chatRoomId).child(withId).updateChildValues(values)
    }

    class func updateMessage(withId: String, chatRoomId: String, memberIds: [String]) {
        
        let readDate = dateFormatter().string(from: Date())
        let values = [kSTATUS : kREAD, kREADDATE : readDate]
        
        for userId in memberIds {
            firebase.child(kMESSAGE_PATH).child(userId).child(chatRoomId).child(withId).updateChildValues(values)
            
        }
    }
    
    
}

