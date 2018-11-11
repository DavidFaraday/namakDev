//
//  OutgoingMessage.swift
//  WChat
//
//  Created by David Kababyan on 27/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import Firebase

class OutgoingMessage {
    
    let messageDictionary: NSMutableDictionary

    //MARK: Initializers
    //text message
    init (message: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        let date = Timestamp(date: date)
        
        messageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, date, status, type, false], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }

    //picture
    init(message: String, pictureLink: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        let date = Timestamp(date: date)

        messageDictionary = NSMutableDictionary(objects: [message, pictureLink, senderId, senderName, date, status, type, false], forKeys: [kMESSAGE as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }


    //audio
    init(message: String, audio: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        let date = Timestamp(date: date)

        messageDictionary = NSMutableDictionary(objects: [message, audio, senderId, senderName, date, status, type, false], forKeys: [kMESSAGE as NSCopying, kAUDIO as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }

    //video
    init(message: String, video: String, thumbnail: NSData, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        let date = Timestamp(date: date)

        let picThumb = thumbnail.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        messageDictionary = NSMutableDictionary(objects: [message, video, picThumb, senderId, senderName, date, status, type, false], forKeys: [kMESSAGE as NSCopying, kVIDEO as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }

    //location
    init(message: String, latitude: NSNumber, longitude: NSNumber, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        let date = Timestamp(date: date)

        messageDictionary = NSMutableDictionary(objects: [message, latitude, longitude, senderId, senderName, date, status, type, false], forKeys: [kMESSAGE as NSCopying, kLATITUDE as NSCopying, kLONGITUDE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying, kDELETED as NSCopying])
    }

    
    
    
    //MARK: SendMessage

    func sendMessage(chatRoomID: String, messageDictionary: NSMutableDictionary, memberIds: [String], membersToPush: [String]) {
        
        let messageId = UUID().uuidString //unique number
        messageDictionary[kMESSAGEID] = messageId
        
        //save Message Locally in DB
        createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomID)
        
        //save message in FB
        for memberId in memberIds {
            reference(.Message).document(memberId).collection(chatRoomID).document(messageId).setData(messageDictionary as! [String : Any])

        }
        
        updateRecents(chatRoomId: chatRoomID, lastMessage: messageDictionary[kMESSAGE] as! String)

        //send push
        var pushText = "[\(messageDictionary[kTYPE] as! String) message]"

        //check if its a text message to show the text
        if (messageDictionary[kTYPE] as! String) == kTEXT {
            pushText = Encryption.decryptText(chatRoomId: chatRoomID, encryptedMessage: messageDictionary[kMESSAGE] as! String)
        }
        
        sendPushNotification(membersToPush: membersToPush, message: pushText)
    }

    
    //MARK: DeleteMessage
    
    class func deleteMessage(withId: String, chatRoomId: String) {
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).document(withId).delete()
        
    }
    

    class func updateMessage(withId: String, chatRoomId: String, memberIds: [String]) {
        
        let readDate = Date() 
        let values = [kSTATUS : kREAD, kREADDATE : readDate] as [String : Any]
        
        for userId in memberIds {
           
            reference(.Message).document(userId).collection(chatRoomId).document(withId).getDocument { (snapshot, error) in
                
                guard let snapshot = snapshot else { return }
                
                if snapshot.exists {
                    //update read status
                    reference(.Message).document(userId).collection(chatRoomId).document(withId).updateData(values)
                    
                }
            }
        }
    }
    
    
}

