//
//  PicturesCollectionViewCell.swift
//  WChat
//
//  Created by David Kababyan on 19/05/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit

class PicturesCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    func generateCell(image: UIImage) {
        
        self.imageView.image = image
    }

    
}
