//
//  UserTableViewCell.swift
//  WChat
//
//  Created by David Kababyan on 11/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    var delegate: UserTableViewCellDelegate?
    var indexPath: IndexPath!
    
    let tapGesture = UITapGestureRecognizer()

    
    override func awakeFromNib() {
        super.awakeFromNib()

        //avatar image tap
        tapGesture.addTarget(self, action: #selector(self.avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    
    func generateCellWith(fUser: FUser, indexPath: IndexPath) {
        
        self.indexPath = indexPath
        
        self.fullNameLabel.text = fUser.fullname
        
        //set avatar if available
        if fUser.avatar != "" {
            
            //convert string to image
            imageFromData(pictureData: fUser.avatar, withBlock: { (avatarImage) in
                
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            })
        }
        
    }
    
    
    @objc func avatarTap() {
        delegate!.didTapAvatarImage(indexPath: indexPath)
    }


}
