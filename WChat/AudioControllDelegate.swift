//
//  AudioControllDelegate.swift
//  WChat
//
//  Created by David Kababyan on 01/05/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation

class AudioContollerDelegate: NSObject, SINAudioControllerDelegate {
    
    var muted: Bool!
    var speaker: Bool!
    
    func audioControllerMuted(_ audioController: SINAudioController!) {
        self.muted = true
    }
    
    func audioControllerUnmuted(_ audioController: SINAudioController) {
        self.muted = false
    }
    
    func audioControllerSpeakerEnabled(_ audioController: SINAudioController!) {
        self.speaker = true
    }
    
    func audioControllerSpeakerDisabled(_ audioController: SINAudioController!) {
        self.speaker = false
    }

}
