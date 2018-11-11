//
//  PhotoAlbum.swift
//  WChat
//
//  Created by David Kababyan on 16/09/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import Photos

class PhotoLibrary: NSObject {
    
    func savePhotoToPhotoLibrary(image: UIImage) {
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(PhotoLibrary.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("error saving image: ", error.localizedDescription)
        } else {
            print("Saved!, Your image has been saved to your photos.")
        }
    }

    func saveVideoToPhotoLibrary(videoURL: URL) {
        print(videoURL)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { saved, error in
            if saved {
                print("video saved successfuly")
            } else {
                print("error saving video", error?.localizedDescription)
            }
        }
    }

}
