//
//  CallViewController.swift
//  WChat
//
//  Created by David Kababyan on 28/04/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import UIKit

class CallViewController: UIViewController, SINCallDelegate {

    @IBOutlet weak var userNameLable: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var muteButtonOutlet: UIButton!
    @IBOutlet weak var speakerButtonOutlet: UIButton!
    
    
    @IBOutlet weak var answerButtonOutlet: UIButton!
    @IBOutlet weak var endCallButtonOutlet: UIButton!
    @IBOutlet weak var declineButtonOutlet: UIButton!
    
    var speaker = false
    var muted = false
    var durationTimer: Timer! = nil
    var _call: SINCall!
    
    var callAnswered = false
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    
    
    override func viewWillAppear(_ animated: Bool) {
        

        userNameLable.text = "Unknown"
        
        let id = _call.remoteUserId
        
        getUsersFromFirestore(withIds: [id!]) { (allUsers) in
            if allUsers.count > 0 {
                let user = allUsers.first!
                
                self.userNameLable.text = user.fullname
                
                imageFromData(pictureData: user.avatar, withBlock: {
                    image in
                    self.avatarImageView.image = image!.circleMasked
                })
                
            }

        }
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _call.delegate = self
        
        if _call.direction == SINCallDirection.incoming {
            
            setCallStatusText(text: "")
            
            // Enter from CallKit lock screen
            if (UIApplication.shared.delegate as! AppDelegate).callKitProvider.callExist(callId: _call.callId) {
                
                callAnswered = true
//                if _call.state == SINCallState.established {
//                }
            }
            
            showButtons()
            
//            audioController().startPlayingSoundFile(self.pathForSound(soundName: "incoming"), loop: true)
            
        } else {
            
            callAnswered = true
            setCallStatusText(text: "Calling...")
            showButtons()
        }

    }

    
    func audioController() -> SINAudioController {
        return appDelegate._client.audioController()
    }
    
    func setCall(call: SINCall) {
        _call = call
        _call.delegate = self
    }

    
    //MARK: IBActions
    
    @IBAction func muteButtonPressed(_ sender: Any) {
        
        if muted {
            muted = false
            audioController().unmute()
            
            muteButtonOutlet.setImage(UIImage(named: "mute"), for: .normal)
            
        } else {
            muted = true
            audioController().mute()
            muteButtonOutlet.setImage(UIImage(named: "muteSelected"), for: .normal)
        }
    }
    
    @IBAction func speakerButtonPressed(_ sender: Any) {
        if !speaker {
            speaker = true
            audioController().enableSpeaker()
            
            speakerButtonOutlet.setImage(UIImage(named: "speakerSelected"), for: .normal)
            
        } else {
            speaker = false
            audioController().disableSpeaker()
            
            speakerButtonOutlet.setImage(UIImage(named: "speaker"), for: .normal)
        }
    }
    
    @IBAction func answerButtonPressed(_ sender: Any) {
        callAnswered = true
        showButtons()
        audioController().stopPlayingSoundFile()
        _call.answer()
    }
    
    @IBAction func handUpButtonPressed(_ sender: Any) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func declineButtonPressed(_ sender: Any) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: SINCallDelegate
    func callDidProgress(_ call: SINCall!) {
        
        setCallStatusText(text: "Ringing...")
//        audioController().startPlayingSoundFile(pathForSound(soundName: "ringback"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        
        startCallDurationTimer()
        
        showButtons()
        audioController().stopPlayingSoundFile()
    }
    
    func callDidEnd(_ call: SINCall!) {
        
        audioController().stopPlayingSoundFile()
        stopCallDurationTimer()
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: HelperFunction
    
    func pathForSound(soundName: String) -> String {
        return Bundle.main.path(forResource: soundName, ofType: "wav")!
    }
    
    //MARK: UIupdates
    
    func setCallStatusText(text: String) {
        statusLabel.text = text
    }
    
    func showButtons() {
        
        if callAnswered {
            declineButtonOutlet.isHidden = true
            endCallButtonOutlet.isHidden = false
            answerButtonOutlet.isHidden = true
            muteButtonOutlet.isHidden = false
            speakerButtonOutlet.isHidden = false
        } else {
            declineButtonOutlet.isHidden = false
            endCallButtonOutlet.isHidden = true
            answerButtonOutlet.isHidden = false
            muteButtonOutlet.isHidden = true
            speakerButtonOutlet.isHidden = true
        }
    }

    
    //MARK: Timer
    
    @objc func onDurationTimer() {
        
        let duration = Date().timeIntervalSince(_call.details.establishedTime)
        updateTimerLabel(seconds: Int(duration))
    }
    
    func updateTimerLabel(seconds: Int) {
        
        let min = String(format: "%02d", (seconds / 60))
        let sec = String(format: "%02d", (seconds % 60))
        
        setCallStatusText(text: "\(min) : \(sec)")
    }
    
    func startCallDurationTimer() {
        
        self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.onDurationTimer), userInfo: nil, repeats: true)
    }
    
    func stopCallDurationTimer() {
        
        if durationTimer != nil {
            
            durationTimer.invalidate()
            durationTimer = nil
        }
    }

}
