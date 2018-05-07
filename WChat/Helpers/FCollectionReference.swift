//
//  FCollectionReference.swift
//  WChat
//
//  Created by David Kababyan on 06/05/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import FirebaseFirestore


enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}


func reference(collectionReference: FCollectionReference) -> CollectionReference{
    return Firestore.firestore().collection(collectionReference.rawValue)
}

extension DocumentChange {
    
    func description() -> String {
        var changeType = ""
        
        switch (self.type) {
        case .added:
        changeType = "Add"
        break;
        case .removed:
        changeType = "Delete"
        break;
        case .modified:
        changeType = "Change"
        break;
        }
        
        return changeType
    }

}
