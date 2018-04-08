//
//  AudioViewController.swift
//  WChat
//
//  Created by David Kababyan on 01/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import IQAudioRecorderController

//need to change IQAudioFiles if want to start recording straight away
class AudioViewController {
    
    var delegate: IQAudioRecorderViewControllerDelegate
    
    init(delegate_: IQAudioRecorderViewControllerDelegate) {
        delegate = delegate_
    }
    
    func presentAudioRecorder(target: UIViewController) {
        
        let controller = IQAudioRecorderViewController()
        
        controller.delegate = delegate
        controller.title = "Recorder"
        controller.maximumRecordDuration = kAUDIOMAXDURATION
        controller.allowCropping = true
        target.presentBlurredAudioRecorderViewControllerAnimated(controller)
    }
    
}
