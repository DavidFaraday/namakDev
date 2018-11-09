//
//  ChatViewController.swift
//  WChat
//
//  Created by David Kababyan on 25/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore
import RealmSwift

class ChatViewController: JSQMessagesViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, IQAudioRecorderViewControllerDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var typingListener: ListenerRegistration?
    var updatedChatListener: ListenerRegistration?
    var newChatListener: ListenerRegistration?
    var withUserUpdateListener: ListenerRegistration?

    let legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]

    var maxMessageNumber = 0
    var minMessageNumber = 0

    var loadedMessagesCount = 0

    var typingCounter = 0

    var membersToPush: [String] = []
    var memberIds: [String] = []
    var withUsers: [FUser] = []
    var titleName: String?

    var chatRoomId: String!
    var isGroup: Bool?
    var group: NSDictionary?

    var messages: [JSQMessage] = []
    
    let realm = try! Realm()
    var allDBMessages: Results<DBMessage>!
    var notificationToken: NotificationToken?

    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    var allPictureMessages: [String] = []
    
    
    var initialLoadComplete = false

    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImagesDictionary: NSMutableDictionary?
    var showAvatars = true
    var firstLoad: Bool?


    
    var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())

    
    
    //MARK: Custom Hedears
    
    //custom header vars
//    let rightBarButtonView: UIView = {
//
//        let view = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 44))
//        return view
//    }()
    let leftBarButtonView: UIView = {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    
    let avatarButton: UIButton = {
        
        let myButton = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        
        return myButton
    }()
    let titleLabel: UILabel = {
        
        let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 14)
        
        return title
    }()
    let subTitleLabel: UILabel = {
        
        let title = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 10)
        
        return title
    }()

    override func viewDidLayoutSubviews() {
        super .viewDidLayoutSubviews()
        
        self.scrollToBottom(animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        clearRecentCounter(chatRoomId: chatRoomId)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        clearRecentCounter(chatRoomId: chatRoomId)
    }
    
//    override func viewDidLayoutSubviews() {
//        //to fix ios 12 iphone x toolbar issue
//        perform(Selector(("jsq_updateCollectionViewInsets")))
//        // end of to fix ios 12 iphone x toolbar issue
//    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        createTypingObservers()
        loadUserDefaults()

        //required to be able to delete messages
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete))

        navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]

        jsqAvatarDictionary = [ : ]

        setCustomTitle()
        
        self.senderId = FUser.currentUser()!.objectId
        self.senderDisplayName = FUser.currentUser()!.firstname

        //to fix ios 12 iphone x toolbar issue
        let constraint = perform(Selector(("toolbarBottomLayoutGuide"))).takeUnretainedValue() as! NSLayoutConstraint
        constraint.priority = UILayoutPriority(rawValue: 1000)

        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        // end of to fix ios 12 iphone x toolbar issue
        
        
        if isGroup! {
            getCurrentGroup(withId: chatRoomId)
        }

        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero

        loadMessegas()

        //Custom send buttom
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
        //change the func in toggleSendButtonEnabled of JSQ to
        //BOOL hasText = TRUE; // [self.contentView.textView hasText];

        //image message aspect fix
        //JSQMessagesViewController/Model/JSQPhotoMediaItem.m
//        imageView.contentMode = UIViewContentModeScaleAspectFill;
//        imageView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
        

    }
    
    
    //MARK: JSQMessages Data Source functions
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        
        
        if data.senderId == FUser.currentId() {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        
        return cell
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return messages[indexPath.row]
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return messages.count
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId() {
            return outgoingBubble
        } else {
            return incomingBubble
        }
        
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        if indexPath.item % 3 == 0 {
            
            let message = messages[indexPath.item]
            
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        let message = objectMessages[indexPath.row]
        
        let status: NSAttributedString!
        
        let attributedStringColor = [NSAttributedString.Key.foregroundColor : UIColor.darkGray]

        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            
            let statusString = "Read" + " " + readTimeFrom(date: message[kREADDATE] as! Date)
            status = NSAttributedString(string: statusString, attributes: attributedStringColor)
        default:
            status = NSAttributedString(string: "✔︎")
        }
        
        if indexPath.row == (messages.count - 1) {
            return status
        } else {
            return NSAttributedString(string: "")
        }
        
    }
    

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        
        let data = messages[indexPath.row]

        if data.senderId == FUser.currentId() {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {

        let message = messages[indexPath.row]

        var avatar: JSQMessageAvatarImageDataSource

        if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId) {
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        } else {
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        }

        return avatar
    }

    //MARK: JSQMesages Delegate functions
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        if text != "" {
            self.sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            updateSendButton(isSend: false)
        } else {
            let audioVC = AudioViewController(delegate_: self)
            audioVC.presentAudioRecorder(target: self)
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        

        let camera = Camera(delegate_: self)
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhotoOrVideo = UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .default) { (alert: UIAlertAction!) in
            
            camera.PresentMultyCamera(target: self, canEdit: false)
            
        }
        
        let sharePhoto = UIAlertAction(title: NSLocalizedString("Photo Library", comment: ""), style: .default) { (alert: UIAlertAction!) in
            
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        
        let shareVideo = UIAlertAction(title: NSLocalizedString("Video Library", comment: ""), style: .default) { (alert: UIAlertAction!) in
            
            camera.PresentVideoLibrary(target: self, canEdit: true)
        }
        
        
        let shareLocation = UIAlertAction(title: NSLocalizedString("Share Location", comment: ""), style: .default) { (alert: UIAlertAction!) in
            
            if self.haveAccessToUserLocation() {
                self.sendMessage(text: nil, date: Date(), picture: nil, location: kLOCATION, video: nil, audio: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (alert: UIAlertAction!) in
            
        }
        
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")

        
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(shareLocation)
        optionMenu.addAction(cancelAction)
        
        //for iPad not to crash
        if ( UI_USER_INTERFACE_IDIOM() == .pad )
        {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
                
                currentPopoverpresentioncontroller.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
            
        }
        
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        loadMoreMessages()
        self.collectionView!.reloadData()
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        
        let senderId = messages[indexPath.item].senderId
        var selectedUser: FUser?
        
        //get the owner of avatar
        if senderId == FUser.currentId() {
            
            selectedUser = FUser.currentUser()
            
        } else {
            
            for user in withUsers {
                
                if user.objectId == senderId {
                    selectedUser = user
                }
            }
        }
        
        presentUserProfile(forUser: selectedUser!)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {

        let messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        switch messageType {
        case kPICTURE:

            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQPhotoMediaItem
            
            //check if media is available
            if mediaItem.image != nil {
                let photos = IDMPhoto.photos(withImages: [mediaItem.image])
                
                let browser = IDMPhotoBrowser(photos: photos)
                
                self.present(browser!, animated: true, completion: nil)
            }

        case kLOCATION:

            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQLocationMediaItem
            
            let mapView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
            
            mapView.location = mediaItem.location
            self.navigationController?.pushViewController(mapView, animated: true)
            
        case kVIDEO:

            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! VideoMessage
            
            let player = AVPlayer(url: mediaItem.fileURL! as URL)
            let moviewPlayer = AVPlayerViewController()
            
            let session = AVAudioSession.sharedInstance()
            
            try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            
            moviewPlayer.player = player
            
            self.present(moviewPlayer, animated: true) {
                moviewPlayer.player!.play()
            }

        default:
            print("unknown message taped")
        }
    }
    
    //for multimedia messages delete option
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        
        super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
        return true
    }
   
    //dont show copy for media messages
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        if messages[indexPath.row].isMediaMessage {
            if action.description == "delete:" {
                return true
            } else {
                return false
            }
        } else {
            if action.description == "delete:" || action.description == "copy:"{
                return true
            } else {
                return false
            }
        }
        
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        
        let messageId = objectMessages[indexPath.row][kMESSAGEID] as! String
        objectMessages.remove(at: indexPath.row)
        messages.remove(at: indexPath.row)
        
        OutgoingMessage.deleteMessage(withId: messageId, chatRoomId: chatRoomId)
        
        //delete from local DB
        deleteMessageFromLocalDB(dbMessage: allDBMessages[indexPath.row])
    }


    //MARK: LoadMessages
    
    func loadMessegas() {
        
        //to update message status
        updatedChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener { (snapshot, error) in

            guard let snapshot = snapshot else { return }

            if !snapshot.isEmpty {
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .modified) {

                        self.updateMessage(messageDictionary: diff.document.data() as NSDictionary)

                    }
                }
            }
        }

        // get all messages from DB
        
        let predicate = NSPredicate(format: "chatRoomId = %@", chatRoomId)

        allDBMessages = realm.objects(DBMessage.self).filter(predicate).sorted(byKeyPath: kDATE, ascending: true)
        
        notificationToken = allDBMessages.observe({ (changes: RealmCollectionChange) in
            
            //updated message
            switch changes {
            case .update(_, let deletions, let insertions, let modifications):
                
//                for index in deletions {
//                    print("deleted object at index: \(index)")
//                }
                
                for index in insertions {
                    let insertedMessage = self.allDBMessages[index]
                    let item = DBMessage.dictionaryFrom(dbMessage: insertedMessage)
                    
                    //for adding link to pictures
                    if item[kTYPE] as! String == kPICTURE {
                        self.addNewPictureMessageLink(link: item[kPICTURE] as! String)
                    }
                    
                    if self.insertInitialLoadMessages(messageDictionary: item, shouldSaveInDB: false) {
                        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    }

                    self.finishReceivingMessage(animated: true)
                }
                
//                for index in modifications {
////                    print("modified object at index: \(index)")
//                }
                
            case .error(let error):
                print("Error on new insertion", error.localizedDescription)
            default:
                return
            }

        })

        
        //convert array of DBMessages to Array of dictionaries
        var messageDictionaries: [NSMutableDictionary] = [[:]]
        
        for mess in allDBMessages {
            messageDictionaries.append(DBMessage.dictionaryFrom(dbMessage: mess))
        }

        //remove bad messages
        self.loadedMessages = self.removeBadMessages(allMessages: messageDictionaries)

        self.insertMessages()
        self.finishReceivingMessage(animated: true)
        self.initialLoadComplete = true

        self.getPictureMessages()
        self.getAllMessagesAndSaveToDB()
        self.listenForNewChats()
    }
    
    func listenForNewChats() {
        
        var lastMessageDate = Date()
        
        if loadedMessages.count > 0 {
            //add 1 sec to last chats date
            lastMessageDate = Calendar.current.date(byAdding: .second, value: 1, to: loadedMessages.last![kDATE] as! Date)!
        }
        
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener { (snapshot, error) in

            guard let snapshot = snapshot else { return }

            if !snapshot.isEmpty {

                for diff in snapshot.documentChanges {

                    if (diff.type == .added) {
                        let item = diff.document.data() as NSDictionary
                        
                        //check if we have a sender Id
                        if let senderId = item[kSENDERID] as? String {
                            //check if its an incoming message
                            if senderId != FUser.currentId() {
                                
                                if let type = item[kTYPE] as? String {
                                    if self.legitTypes.contains(type)  {
                                        //for adding link to pictures
                                        if item[kTYPE] as! String == kPICTURE {
                                            self.addNewPictureMessageLink(link: item[kPICTURE] as! String)
                                        }
                                        
                                        createMessage(messageDictionary: item, chatRoomId: self.chatRoomId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //shouldt be needed
    func getAllMessagesAndSaveToDB() {
        
        //check if we have no messages in db, get all availale from FB and save locally
        if allDBMessages.count == 0 {
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).getDocuments { (snapshot, error) in
                
                guard let snapshot = snapshot else { return }

                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]

                for messageDictionary in sorted {
                    createMessage(messageDictionary: messageDictionary, chatRoomId: self.chatRoomId)
                }
            }
            
        }
        
    }




    //MARK: Send Message
    
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        
        var outgoingMessage: OutgoingMessage?
        let currentUser = FUser.currentUser()!
        
        //text message
        if let text = text {
            
            let encryptedText = Encryption.encryptText(chatRoomId: chatRoomId, message: text)
            
            outgoingMessage = OutgoingMessage(message: encryptedText, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        
        //send picture message
        if let pic = picture {
            
            uploadImage(image: pic, chatRoomId: chatRoomId, view: self.navigationController!.view) { (imageLink) in
                
                if imageLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: "[\(kPICTURE)]")
                    
                    outgoingMessage = OutgoingMessage(message: encryptedText, pictureLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage?.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
            }
            return
        }

        //send video
        if let video = video {
            
            let videoData = NSData(contentsOfFile: video.path!)
            
            let thumbNail = videoThumbnail(video: video)

            let dataThumbnail = thumbNail.jpegData(compressionQuality: 0.3)

            
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: self.navigationController!.view, completion: { (videoLink) in
                
                if videoLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: "[\(kVIDEO)]")
                    
                    outgoingMessage = OutgoingMessage(message: encryptedText, video: videoLink!, thumbnail: dataThumbnail! as NSData, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage?.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
            })
            
            return
        }
        
        
        //send auidio
        if let audioPath = audio {
            
            uploadAudio(audioPath: audioPath, chatRoomId: chatRoomId, view: (self.navigationController?.view)!, completion: { (audioLink) in
                
                if audioLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: "[\(kAUDIO)]")
                    
                    outgoingMessage = OutgoingMessage(message: encryptedText, audio: audioLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kAUDIO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage!.sendMessage(chatRoomID: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
            })
            return
        }

        //send location message
        if location != nil {
            
            let lat: NSNumber = NSNumber(value: appDelegate.coordinates!.latitude)
            let long: NSNumber = NSNumber(value: appDelegate.coordinates!.longitude)
            
            let encryptedText = Encryption.encryptText(chatRoomId: self.chatRoomId, message: "[\(kLOCATION)]")
            
            outgoingMessage = OutgoingMessage(message: encryptedText, latitude: lat, longitude: long, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kLOCATION)
        }




        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.sendMessage(chatRoomID: chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: memberIds, membersToPush: membersToPush)
    }


    //MARK: InsertMessages
    
    func insertMessages() {

        maxMessageNumber = loadedMessages.count - loadedMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }

        for i in minMessageNumber ..< maxMessageNumber {
            let messageDictionary = loadedMessages[i]

            insertInitialLoadMessages(messageDictionary: messageDictionary, shouldSaveInDB: false)
            loadedMessagesCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    
    func insertInitialLoadMessages(messageDictionary: NSDictionary, shouldSaveInDB: Bool) -> Bool {

        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)

        if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {

            OutgoingMessage.updateMessage(withId: messageDictionary[kMESSAGEID] as! String, chatRoomId: chatRoomId, memberIds: memberIds)
        }
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
            
            if shouldSaveInDB {
                //save the message to realm
//                createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)

            }
        }

        return isIncoming(messageDictionary: messageDictionary)
    }

    func insertNewMessage(messageDictionary: NSDictionary) {
        
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
    }
    
    //MARK: UpdateMessages
    
    func updateMessage(messageDictionary: NSDictionary) {
        
        for index in 0 ..< objectMessages.count {
            
            let temp = objectMessages[index]
            
            if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
                
                objectMessages[index] = messageDictionary
                self.collectionView!.reloadData()
            }
        }
    }



    //MARK: LoadMoreMessages
    func loadMoreMessages() {
        
        maxMessageNumber = minMessageNumber - 1
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES

        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in (minMessageNumber ... maxMessageNumber).reversed() {

            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }

    //MARK: IBActions
    
    @objc func backAction() {
        clearRecentCounter(chatRoomId: chatRoomId)
        removeListners()
        notificationToken?.invalidate()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func infoButtonPressed() {
        
        let mediaVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mediaView") as! PictureMediaCollectionViewController
        
        mediaVC.allImageLinks = allPictureMessages
        
        self.navigationController?.pushViewController(mediaVC, animated: true)
        
    }

    
    //MARK: UIImagepickerController delegate function
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        sendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        
        picker.dismiss(animated: true, completion: nil)
    }

    //MARK: IQAudioRecorder delegate
    
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        
        controller.dismiss(animated: true, completion: nil)
        self.sendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
        
    }
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        
        controller.dismiss(animated: true, completion: nil)
    }

    
    //MARK: UpdateUI
    
    func setCustomTitle() {
        
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subTitleLabel)
        
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: UIBarButtonItem.Style.plain, target: self, action: #selector (self.infoButtonPressed))
        
        self.navigationItem.rightBarButtonItem = infoButton

        
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        if isGroup! {
            avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
        } else {
            avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
        }

        getUsersFromFirestore(withIds: memberIds) { (withUsers) in
            
            self.withUsers = withUsers
            self.getAvatarImages()
            if !self.isGroup! {
                self.setUIforSingleChat(withUser: withUsers.first!)
                self.updateUserOnlineStatus()
            }
        }
    }

    func setUIforSingleChat(withUser: FUser) {
        
        imageFromData(pictureData: withUser.avatar) { (image) in
            
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        
        titleLabel.text = withUser.fullname
        
        if withUser.isOnline {
            subTitleLabel.text = NSLocalizedString("Online", comment: "")
        } else{
            subTitleLabel.text = NSLocalizedString("Offline", comment: "")
        }
        
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)

    }
    
    func setUIforGroupChat() {

        imageFromData(pictureData: group![kAVATAR] as! String) { (image) in
            
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        
        titleLabel.text = titleName
        subTitleLabel.text = ""

    }


    
    //MARK: Custom send button
    
    override func textViewDidChange(_ textView: UITextView) {
        
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
    }

    func updateSendButton(isSend: Bool) {

        if isSend {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        } else {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }

    
    
    
    //MARK: Typing indicator
    
    func createTypingObservers() {

        typingListener = reference(.Typing).document(chatRoomId).addSnapshotListener { (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if snapshot.exists {
                
                for data in snapshot.data()! {
                    if data.key != FUser.currentId() {
                        
                        let typing = data.value as! Bool
                        self.showTypingIndicator = typing

                        if typing {
                            self.scrollToBottom(animated: true)
                        }
                    }
                }
                
            } else {
                //create typing othervise it will crash on updated
                reference(.Typing).document(self.chatRoomId).setData([FUser.currentId() : false])
            }
            
        }
        
    }
    
    
    func typingIndicatorStart() {
        
        typingCounter += 1
        typingIndicatorSave(typing: true)
        
        self.perform(#selector(self.typingIndicatorStop), with: nil, afterDelay: 2.0)
    }
    
    @objc func typingIndicatorStop() {
        
        typingCounter -= 1
        
        if typingCounter == 0 {
            typingIndicatorSave(typing: false)
        }
    }
    
    func typingIndicatorSave(typing: Bool) {
        reference(.Typing).document(chatRoomId).updateData([FUser.currentId() : typing])
    }

    //MARK: UITextViewDelegate

    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        typingIndicatorStart()
        return true
    }

    
    //MARK: Helpers
    func addNewPictureMessageLink(link: String) {
        allPictureMessages.append(link)
    }
    
    func getPictureMessages() {
        
        allPictureMessages = []
        
        for message in loadedMessages {

            if let type = message[kTYPE] as? String  {
                if type == kPICTURE {
                    //add to array
                    allPictureMessages.append(message[kPICTURE] as! String)
                }
            }
        }
    }
    
    func removeListners() {
        if typingListener != nil {
            typingListener!.remove()
        }
        if newChatListener != nil {
            newChatListener!.remove()
        }
        if updatedChatListener != nil {
            updatedChatListener!.remove()
        }
        if withUserUpdateListener != nil {
            withUserUpdateListener!.remove()
        }
    }
    
    
    func getCurrentGroup(withId: String) {
        reference(.Group).document(withId).getDocument { (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
        
        
            if snapshot.exists {
                self.group = snapshot.data() as! NSDictionary
                self.setUIforGroupChat()
            }
        }
    }

    
    @objc func showUserProfile() {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        
        profileVC.user = withUsers.first!
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func presentUserProfile(forUser: FUser) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        
        profileVC.user = forUser
        
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    @objc func showGroup() {
        
        let groupVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "groupView") as! GroupViewController

        groupVC.group = group!
        self.navigationController?.pushViewController(groupVC, animated: true)
    }
    
    func removeBadMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
        
        var tempMessages = allMessages
        
        for message in tempMessages {

            if message[kTYPE] != nil  {
                if !self.legitTypes.contains(message[kTYPE] as! String) {

                    //remove the message from array if its bad message
                    tempMessages.remove(at: tempMessages.index(of: message)!)
                }
            } else {
                tempMessages.remove(at: tempMessages.index(of: message)!)
            }
        }
        return tempMessages
    }


    func isIncoming(messageDictionary: NSDictionary) -> Bool {
        
        if FUser.currentUser()!.objectId == messageDictionary[kSENDERID] as! String {
            return false
        } else {
            return true
        }
    }

    func readTimeFrom(date: Date) -> String {
        
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "HH:mm"
        
        return currentDateFormater.string(from: date)
    }
    
    func loadUserDefaults() {
        
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad! {
            
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(showAvatars, forKey: kSHOWAVATAR)
            
            userDefaults.synchronize()
        }
        
        showAvatars = userDefaults.bool(forKey: kSHOWAVATAR)
        checkForBackgroundColor()
    }
    
    func checkForBackgroundColor() {
        
        if userDefaults.object(forKey: kBACKGROUBNDIMAGE) != nil {
            self.collectionView.backgroundColor = .clear
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
            imageView.image = UIImage(named: userDefaults.object(forKey: kBACKGROUBNDIMAGE) as! String)!
            imageView.contentMode = .scaleAspectFill

            self.view.insertSubview(imageView, at: 0)
        }
    }


    
    //MARK: Location access
    
    func haveAccessToUserLocation() -> Bool {
        
        if appDelegate.locationManager != nil {
            return true
        } else {

            ProgressHUD.showError(NSLocalizedString("Please give access to location in Settings.", comment: ""))
            return false
        }
    }

    
    //MARK: GetUserAvatars
    
    func getAvatarImages() {
        
        if showAvatars {
            
            //change the size of avatar from 0
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)

            //get avatar of current user
            avatarImageFrom(fUser: FUser.currentUser()!)
            
            //get avatars of other users
            for user in withUsers {
                avatarImageFrom(fUser: user)
            }
            
//            createAvatars(avatars: avatarImagesDictionary)
        }
    }

    func avatarImageFrom(fUser: FUser) {
        
        if fUser.avatar != "" {
            
            dataImageFromString(pictureString: fUser.avatar, withBlock: { (imageData) in
                
                //stop if we have no image data
                if imageData == nil {
                    return
                }
                
                if self.avatarImagesDictionary != nil {
                    //update avatar if we had one already
                    self.avatarImagesDictionary!.removeObject(forKey: fUser.objectId)
                    self.avatarImagesDictionary!.setObject(imageData!, forKey: fUser.objectId as NSCopying)
                } else {
                    self.avatarImagesDictionary = [fUser.objectId : imageData!]
                }
                
                
                self.createJSQAvatars(avatarDictionary: self.avatarImagesDictionary)

            })
        }
    }
    
    func createJSQAvatars(avatarDictionary: NSMutableDictionary?) {
        
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        
        if avatarDictionary != nil {
            
            for userId in memberIds {
                
                if let avatarImageData = avatarDictionary![userId] {
                    
                    let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImageData as! Data), diameter: 70)
                    
                    self.jsqAvatarDictionary!.setValue(jsqAvatar, forKey: userId)
                } else {
                    self.jsqAvatarDictionary!.setValue(defaultAvatar, forKey: userId)
                }
                
            }
            
            self.collectionView.reloadData()
        }
        
    }


    //MARK: UpdateUserOnlineStatus
    
    func updateUserOnlineStatus() {
        
        if !isGroup! {
            let withUser = withUsers.first!

            withUserUpdateListener = reference(.User).document(withUser.objectId).addSnapshotListener { (snapshot, error) in
                
                guard let snapshot = snapshot else {  return }
                
                if snapshot.exists {
                    
                    let withUser = FUser(_dictionary: snapshot.data() as! NSDictionary)
                    self.setUIforSingleChat(withUser: withUser)
                }
            }

        }
    }
}

extension JSQMessagesInputToolbar {
    
    override open func didMoveToWindow() {
        
        super.didMoveToWindow()
        
        guard let window = window else { return }
        
        if #available(iOS 11.0, *) {
            
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            
            bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
            
        }
        
    }
    
}


