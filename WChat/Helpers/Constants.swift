//
//  Constants.swift
//  WChat
//
//  Created by David Kababyan on 08/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

public var recentBadgeHandler: ListenerRegistration?
let userDefaults = UserDefaults.standard

//NOTIFICATIONS
public let USER_DID_LOGIN_NOTIFICATION = "UserDidLoginNotification"
public let USER_DID_LOGOUT_NOTIFICATION = "UserDidLogoutNotification"
public let APP_STARTED_NOTIFICATION = "AppStartedNotification"



//IDS and Keys
public let kFILEREFERENCE = "gs://wchat-5c432.appspot.com"
public let kONESIGNALAPPID = "2859ef5b-4d09-4034-862c-d0a6aaae1148"
public let kSINCHKEY = "6d6bc598-3bbc-4d95-9c13-6873e697da96"
public let kSINCHSECRET = "2V/Rqg4kNkynAQs3Dqnd7g=="
public let kAPPURL = "https://itunes.apple.com/us/app/qchat/id1245294104?ls=1&mt=8"



//Firebase Headers
public let kUSER_PATH = "User"
public let kTYPINGPATH_PATH = "Typing"
public let kRECENT_PATH = "Recent"
public let kMESSAGE_PATH = "Message"
public let kGROUP_PATH = "Group"
public let kCALL_PATH = "Call"

//FUser
public let kOBJECTID = "objectId"
public let kCREATEDAT = "createdAt"
public let kUPDATEDAT = "updatedAt"
public let kEMAIL = "email"
public let kPHONE = "phone"
public let kCOUNTRYCODE = "countryCode"
public let kFACEBOOK = "facebook"
public let kLOGINMETHOD = "loginMethod"
public let kPUSHID = "pushId"
public let kFIRSTNAME = "firstname"
public let kLASTNAME = "lastname"
public let kFULLNAME = "fullname"
public let kAVATAR = "avatar"
public let kCURRENTUSER = "currentUser"
public let kISONLINE = "isOnline"
public let kVERIFICATIONCODE = "firebase_verification"
public let kCITY = "city"
public let kCOUNTRY = "country"
public let kBLOCKEDUSERID = "blockedUserId"



//
public let kBACKGROUBNDIMAGE = "backgroundImage"
public let kSHOWAVATAR = "showAvatar"
public let kSHOWMESSAGENOTIFICATION = "showMessageInPush"
public let kPASSWORDPROTECT = "passwordProtect"
public let kFIRSTRUN = "firstRun"
public let kNUMBEROFMESSAGES = 20
public let kMAXDURATION = 120.0
public let kAUDIOMAXDURATION = 120.0
public let kSUCCESS = 2

//recent
public let kCHATROOMID = "chatRoomID"
public let kUSERID = "userId"
public let kDATE = "date"
public let kPRIVATE = "private"
public let kGROUP = "group"
public let kGROUPID = "groupId"
public let kRECENTID = "recentId"
public let kMEMBERS = "members"
public let kMESSAGE = "message"
public let kMEMBERSTOPUSH = "membersToPush"
public let kDISCRIPTION = "discription"
public let kLASTMESSAGE = "lastMessage"
public let kCOUNTER = "counter"
public let kTYPE = "type"
public let kWITHUSERUSERNAME = "withUserUserName"
public let kWITHUSERUSERID = "withUserUserID"
public let kOWNERID = "ownerID"
public let kSTATUS = "status"
public let kMESSAGEID = "messageId"
public let kNAME = "name"
public let kSENDERID = "senderId"
public let kSENDERNAME = "senderName"
public let kTHUMBNAIL = "thumbnail"
public let kISDELETED = "isDeleted"

//Contacts
public let kCONTACT = "contact"
public let kCONTACTID = "contactId"

//message types
public let kPICTURE = "picture"
public let kTEXT = "text"
public let kVIDEO = "video"
public let kAUDIO = "audio"
public let kLOCATION = "location"

//coordinates
public let kLATITUDE = "latitude"
public let kLONGITUDE = "longitude"


//message status
public let kDELIVERED = "delivered"
public let kREAD = "read"
public let kREADDATE = "readDate"
public let kDELETED = "deleted"



//push
public let kDEVICEID = "deviceId"



//Call

public let kISINCOMING = "isIncoming"
public let kCALLERID = "callerId"
public let kCALLERFULLNAME = "callerFullName"
public let kCALLSTATUS = "callStatus"
public let kWITHUSERFULLNAME = "withUserFullName"
public let kCALLERAVATAR = "callerAvatar"
public let kWITHUSERAVATAR = "withUserAvatar"


//chat bubble color
//public let kINCOMINGRED = "incomingRed"
//public let kINCOMINGGREEN = "incomingGreen"
//public let kINCOMINGBLUE = "incomingBlue"
//
//public let kOUTGOINGRED = "oiutgoingRed"
//public let kOUTGOINGGREEN = "outgoingGreen"
//public let kOUTGOINGBLUE = "outgoingBlue"

//public let kIOSDEFAULTS = "iOSDefaults"
