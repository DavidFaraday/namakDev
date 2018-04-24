//
//  RecentChatsTableViewCell.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit

protocol RecentChatsTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}


class RecentChatsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var messageCountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var messageCountBackground: UIView!
    
    var delegate: RecentChatsTableViewCellDelegate?
    var indexPath: IndexPath!
    
    let tapGesture = UITapGestureRecognizer()

    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        
        //setup count label background to be round
        messageCountBackground.layer.cornerRadius = messageCountBackground.frame.width / 2
        
        
        //avatar image tap
        tapGesture.addTarget(self, action: #selector(self.avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


    }
    
    //MARK: GenerateCell
    
    func generateCell(recentChat: NSDictionary, indexPath: IndexPath) {
        
        self.indexPath = indexPath
        
        self.nameLabel.text = recentChat[kWITHUSERUSERNAME] as? String
        
        let decryptedText = Encryption.decryptText(chatRoomId: recentChat[kCHATROOMID] as! String, encryptedMessage: recentChat[kLASTMESSAGE] as! String)
            
        self.lastMessageLabel.text = decryptedText
        
        self.messageCountLabel.text = recentChat[kCOUNTER] as? String
        
        //convert string to image
        if let avatarString = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarString as! String, withBlock: { (avatarImage) in
                
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            })
        }


        //set counter if available
        if recentChat[kCOUNTER] as! Int != 0 {

            self.messageCountLabel.text = "\(recentChat[kCOUNTER] as! Int)"
            self.messageCountBackground.isHidden = false
            self.messageCountLabel.isHidden = false
        } else {
            self.messageCountBackground.isHidden = true
            self.messageCountLabel.isHidden = true
            
        }
        
        var date: Date!
        
        if let created = recentChat[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)!
            }
        } else {
            date = Date()
        }
        
        
        dateLabel.text = timeElapsed(date: date!)

        
    }

    
    
    //MARK: Delegate function

    @objc func avatarTap() {
        delegate!.didTapAvatarImage(indexPath: indexPath)
    }


}
