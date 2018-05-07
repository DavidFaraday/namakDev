//
//  CallTableViewCell.swift
//  WChat
//
//  Created by David Kababyan on 21/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit

class CallTableViewCell: UITableViewCell {

    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()


    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func generateCellWith(call: CallN) {
        
        
        dateLabel.text = formatCallTime(date: call.callDate)

        callStatusLabel.text = ""
        
        if call.callerId == FUser.currentId() {
            callStatusLabel.text = "outgoing"
            fullNameLabel.text = call.withUserFullName
            
            //set avatar if available
            if call.withUserAvatar != "" {
                
                //convert string to image
                imageFromData(pictureData: call.withUserAvatar, withBlock: { (avatarImage) in
                    
                    if avatarImage != nil {
                        self.avatarImageView.image = avatarImage!.circleMasked
                    }
                })
            }


        } else {
            callStatusLabel.text = "incoming"
            fullNameLabel.text = call.callerFullName
            
            //set avatar if available
            if call.callerAvatar != "" {
                
                //convert string to image
                imageFromData(pictureData: call.callerAvatar, withBlock: { (avatarImage) in
                    
                    if avatarImage != nil {
                        self.avatarImageView.image = avatarImage!.circleMasked
                    }
                })
            }
        }


        
    }


}
