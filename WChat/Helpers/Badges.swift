//
//  Badges.swift
//  WChat
//
//  Created by David Kababyan on 04/05/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation


func recentBadgeCount(withBlock: @escaping (_ badgeNumber: Int) -> Void) {
    
    recentBadgeHandler = recentBadgeRef.queryOrdered(byChild: kUSERID).queryEqual(toValue: FUser.currentId()).observe(.value, with: {
        snapshot in
        
        var badge = 0
        var counter = 0
        
        if snapshot.exists() {

            let recents = (snapshot.value as! NSDictionary).allValues as Array
            
            
            for recent in recents {
                
                let currentRecent = recent as! NSDictionary
                
                badge += currentRecent[kCOUNTER] as! Int
                counter += 1
                
                if counter == recents.count {
                    
                    withBlock(badge)
                    
                }
            }
            
        } else {
            
            withBlock(badge)
        }
        
    })
    
}


//MARK: SetBadges

func setBadges(controller: UITabBarController) {
    
    recentBadgeCount { (badge) in
        
        if badge != 0 {
            
            controller
                .tabBar.items![1].badgeValue = "\(badge)"
            
        } else {
            controller.tabBar.items![1].badgeValue = nil
        }
        
    }
}
