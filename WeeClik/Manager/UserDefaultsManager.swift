//
//  UserDefaultsManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 06/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit

enum UserDefaultsKeys {
    static let kGroupePartage = "listOfGroupePartage_key"
}

class UserDefaultsManager: NSObject {
    public static let shared = UserDefaultsManager()
    private let userStandard = UserDefaults.standard
    private override init(){}
    
    /*
     SHARING GROUPS
     */
    
    // Add new group
    func addSharingGroup(groupe: GroupePartage){
        var groups = self.getGroupesPartage()
        groups.append(groupe)
        userStandard.set( NSKeyedArchiver.archivedData(withRootObject: groups), forKey: UserDefaultsKeys.kGroupePartage)
    }
    
    func removeSharingGroup(atIndex index: Int) {
        var groups = self.getGroupesPartage()
        groups.remove(at: index)
        userStandard.set( NSKeyedArchiver.archivedData(withRootObject: groups), forKey: UserDefaultsKeys.kGroupePartage)
    }
    
    // Fetch all saved groups (can be empty)
    func getGroupesPartage() -> [GroupePartage] {
        guard let encodedData = userStandard.data(forKey: UserDefaultsKeys.kGroupePartage) else {
            return []
        }
        return NSKeyedUnarchiver.unarchiveObject(with: encodedData) as! [GroupePartage]
    }
}
