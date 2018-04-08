//
//  GroupMemberCollectionViewCell.swift
//  WChat
//
//  Created by David Kababyan on 18/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit

protocol GroupMemberCollectionViewCellDelegate {
    func didClickDeleteButton(indexPath: IndexPath)
}

class GroupMemberCollectionViewCell: UICollectionViewCell {
    
    var indexPath: IndexPath!
    var delegate: GroupMemberCollectionViewCellDelegate?
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    func generateCell(user: FUser, indexPath: IndexPath) {
        
        self.indexPath = indexPath
        
        nameLabel.text = user.firstname
        
        //set avatar if available
        if user.avatar != "" {
            
            //convert string to image
            imageFromData(pictureData: user.avatar, withBlock: { (avatarImage) in
                
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            })
        }

    }

    //MARK: IBActions
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        delegate!.didClickDeleteButton(indexPath: indexPath)
    }
    

    
}
