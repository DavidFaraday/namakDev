//
//  Downloader.swift
//  WChat
//
//  Created by David Kababyan on 31/03/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD
import AVFoundation
import ProgressHUD
import Photos

let storage = Storage.storage()


//image
func uploadImage(image: UIImage, chatRoomId: String, view: UIView, completion: @escaping (_ imageLink: String?) -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let videoFileName = "PictureMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".jpg"
    
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
    
    let imageDate = image.jpegData(compressionQuality: 0.5)
    
    var task : StorageUploadTask!
    

    
    task = storageRef.putData(imageDate!, metadata: nil, completion: {
        metadata, error in
        
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil {
            
            print("error uploading image \(error!.localizedDescription)")
            ProgressHUD.showError(error!.localizedDescription)
            
            return
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            completion(downloadUrl.absoluteString)
        })

    })
    
    task.observe(StorageTaskStatus.progress, handler: {
        snapshot in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float( (snapshot.progress?.totalUnitCount)!)
        
    })
}

func downloadImage(imageUrl: String, completion: @escaping (_ image: UIImage?) -> Void) {
    
    let imageURL = NSURL(string: imageUrl)
    
    let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    //
    if fileExistsAtPath(path: imageFileName) {
        
        if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(filename: imageFileName)) {
            completion(contentsOfFile)
        } else {
            print("couldnt generate image")
            completion(nil)
        }
        
    } else {
        
        let dowloadQueue = DispatchQueue(label: "imageDownloadQueue")
        
        dowloadQueue.async {
            
            let data = NSData(contentsOf: imageURL! as URL)
            
            if data != nil {
                
                var docURL = getDocumentsURL()
                
                docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                
                data!.write(to: docURL, atomically: true)
                
                let imageToReturn = UIImage(data: data! as Data)
               
                DispatchQueue.main.async {
                    completion(imageToReturn!)
                }
                
            } else {
                DispatchQueue.main.async {
                    print("No image in database")
                    completion(nil!)
                }
            }
        }
    }
}


//video
func uploadVideo(video: NSData, chatRoomId: String, view: UIView, completion: @escaping (_ videoLink: String?) -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let videoFileName = "VideoMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".mov"
    
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
    
    
    var task : StorageUploadTask!
    
    task = storageRef.putData(video as Data, metadata: nil, completion: {
        metadata, error in
        
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil {
            
            print("error uploading video \(error!.localizedDescription)")
            ProgressHUD.showError(error!.localizedDescription)
            
            return
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            completion(downloadUrl.absoluteString)
        })

    })
    
    task.observe(StorageTaskStatus.progress, handler: {
        snapshot in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float( (snapshot.progress?.totalUnitCount)!)
        
    })
}

func downloadVideo(videoUrl: String, completion: @escaping (_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
    
    let videoURL = NSURL(string: videoUrl)
    
    let videoFileName = (videoUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    
    if fileExistsAtPath(path: videoFileName) {
        
        completion(true, videoFileName)
        
    } else {
        
        let dowloadQueue = DispatchQueue(label: "videoDownloadQueue")
        
        dowloadQueue.async {
            
            let data = NSData(contentsOf: videoURL! as URL)
            
            if data != nil {
                
                var docURL = getDocumentsURL()
                
                docURL = docURL.appendingPathComponent(videoFileName, isDirectory: false)
                
                data!.write(to: docURL, atomically: true)
                
                DispatchQueue.main.async {
                    
                    completion(true, videoFileName)
                }
                
            } else {
                ProgressHUD.showError("No Video in database")
            }
        }
    }
}




func videoThumbnail(video: NSURL) -> UIImage {
    
    let asset = AVURLAsset(url: video as URL, options: nil)
    
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    
    var image: CGImage?
    
    do {
        image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
    }
    catch let error as NSError {
        print(error.localizedDescription)
    }
    
    let thumbnail = UIImage(cgImage: image!)
    
    return thumbnail
}


//Audio
func uploadAudio(audioPath: String, chatRoomId: String, view: UIView, completion: @escaping (_ audioLink: String?) -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let audio = NSData(contentsOfFile: audioPath)

    let audioFileName = "AudioMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".m4a"

    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(audioFileName)
    
    
    var task : StorageUploadTask!
    
    task = storageRef.putData(audio! as Data, metadata: nil, completion: {
        metadata, error in
        
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil {
            print("error uploading audio \(String(describing: error?.localizedDescription))")
            return
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            completion(downloadUrl.absoluteString)
        })
        
    })
    
    task.observe(StorageTaskStatus.progress, handler: {
        snapshot in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float( (snapshot.progress?.totalUnitCount)!)
        
    })
}

func downloadAudio(audioUrl: String, completion: @escaping (_ audioFileName: String) -> Void) {
    
    let audiURL = NSURL(string: audioUrl)
    let audioFileName = (audioUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    if fileExistsAtPath(path: audioFileName) {
        
        completion(audioFileName)
    } else {
        
        //start downloading
        
        let downloadQueue = DispatchQueue(label: "audioDownload")
        
        downloadQueue.async {
            
            let data = NSData(contentsOf:  audiURL! as URL)
            
            if data != nil {
                
                var docURL = getDocumentsURL()
                
                docURL = docURL.appendingPathComponent(audioFileName, isDirectory: false)
                
                data!.write(to: docURL, atomically: true)
                
                DispatchQueue.main.async {
                    
                    completion(audioFileName)
                }
                
            } else {
                print("no audio at link")
            }
        }
    }
}


//Helpers
func fileInDocumentsDirectory(filename: String) -> String {
    
    let fileURL = getDocumentsURL().appendingPathComponent(filename)
    return fileURL.path
}

func getDocumentsURL() -> URL {
    
    let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    
    return documentURL!
}

func fileExistsAtPath(path: String) -> Bool {
    
    var doesExist = false
    
    let filePath = fileInDocumentsDirectory(filename: path)
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: filePath) {
        doesExist = true
    } else {
        doesExist = false
    }
    
    return doesExist
}


//photo library funcs

func addImage(image: UIImage, toAlbum album: PHAssetCollection, completion: ((_ status: Bool, _ identifier: String?) -> Void)?) {
    
    var localIdentifier: String?
    
    PHPhotoLibrary.shared().performChanges({
        let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
        let assetPlaceholder = assetRequest.placeholderForCreatedAsset
        let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
        albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)

        localIdentifier = assetPlaceholder?.localIdentifier

    }) { (status, error) in
        completion?(status, localIdentifier)
    }
    
}




