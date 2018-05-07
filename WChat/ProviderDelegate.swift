//
//  ProviderDelegate.swift
//  WChat
//
//  Created by David Kababyan on 01/05/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import CallKit

class ProviderDelegate: NSObject, CXProviderDelegate {
    
//    fileprivate let callManager: CallManager
    fileprivate let provider: CXProvider
    
    static var providerConfiguration: CXProviderConfiguration {
        
        let providerConfiguration = CXProviderConfiguration(localizedName: "WChat")
        
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]
        
        return providerConfiguration
    }
    
    
    override init() {
        
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        
        super.init()
        
        provider.setDelegate(self, queue: nil)
    }
    
    
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        
        //You prepare a call update for the system, which will contain all the relevant call metadata.
        
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = hasVideo
        
        //Invoking reportIncomingCall(with:update:completion) on the provider will notify the system of the incoming call.
        
        provider.reportNewIncomingCall(with: uuid, update: update, completion: {
            error in
            
            //The completion handler will be called once the system processes the call. If there were no errors, you create a Call instance, and add it to the list of calls via the CallManager.
            if error == nil {
//                let call = Call(uuid: uuid, handle: handle)
//                self.callManager.add(call: call)
            }
            
            completion?(error as NSError?)
        })
        
    }
    
    //MARK: CXProviderDelegate
    
    func providerDidReset(_ provider: CXProvider) {
//        stopAudio()
//
//        for call in callManager.calls {
//
//            call.end()
//        }
//
//        callManager.removeAllCalls()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("answered")
        //You’ll start by getting a reference from the call manager, corresponding to the UUID of the call to answer.
        
//        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
//            action.fail()
//            return
//        }
        
        //It is the app’s responsibility to configure the audio session for the call. The system will take care of activating the session at an elevated priority.
        
//        configureAudioSession()
        
        //By invoking answer(), you’ll indicate that the call is now active.
//        call.answer()
        
        //When processing an action, it’s important to either fail or fulfill it. If there were no errors during the process, you can call fulfill() to indicate success.
        action.fulfill()
        
    }
    
    
    //Once the system activates the provider’s audio session, the delegate is notified. This is your chance to begin processing the call’s audio.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        //        startAudio()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        
        //You start by getting a reference to the call from the call manager.
        
//        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
//            action.fail()
//            return
//        }
        
        //As the call is about to end, it’s time to stop processing the call’s audio.
//        stopAudio()
//
//        call.end()
        
        action.fulfill()
        
//        callManager.remove(call: call)
        
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        
//        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
//            action.fail()
//            return
//        }
//
//        call.state = action.isOnHold ? .held : .active
//
//        if call.state == .held {
//            stopAudio()
//        } else {
//            startAudio()
//        }
        
        action.fulfill()
    }
    
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("started call")
//        let call = Call(uuid: action.callUUID, outgoing: true, handle: action.handle.value)
        
        //After creating a Call with the call’s UUID from the call manager, you’ll have to configure the app’s audio session. Just as with incoming calls, your responsibility at this point is only configuration. The actual processing will start later, when the provider(_:didActivate) delegate method is invoked.
//        configureAudioSession()
        
        //The delegate will monitor the call’s lifecycle. It will initially report that the outgoing call has started connecting. When the call is finally connected, the provider delegate will report that as well.
        
//        call.connectedStateChanged = {
//            [weak self, weak call] in
//
//            guard let strongSelf = self, let call = call else { return }
//
//            if call.connectedState == .pending {
//                strongSelf.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
//            }else if call.connectedState == .complete {
//                strongSelf.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
//            }
//        }
        
        //Calling start() on the call will trigger its lifecycle changes. Upon a successful connection, the call can be marked as fulfilled.
        
//        call.start { [weak self, weak call] success in
//            guard let strongSelf = self, let call = call else { return }
//            
//            if success {
//                action.fulfill()
//                strongSelf.callManager.add(call: call)
//            }else {
//                action.fail()
//            }
//        }
    }
    
    
    
    
}
