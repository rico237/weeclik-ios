//
//  UserDefaultsManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 06/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit

/// <#Description#>
enum UserDefaultsKeys {
    static let kGroupePartage = "listOfGroupePartage_key"
}

/// <#Description#>
class UserDefaultsManager: NSObject {
    public static let shared = UserDefaultsManager()
    private let userStandard = UserDefaults.standard
    private override init() {}

    /// <#Description#>
    /// - Parameter groupe: <#groupe description#>
    func addSharingGroup(groupe: GroupePartage) {
        var groups = self.getGroupesPartage()
        groups.append(groupe)
        userStandard.set( NSKeyedArchiver.archivedData(withRootObject: groups), forKey: UserDefaultsKeys.kGroupePartage)
    }

    /// <#Description#>
    /// - Parameter index: <#index description#>
    func removeSharingGroup(atIndex index: Int) {
        var groups = self.getGroupesPartage()
        groups.remove(at: index)
        userStandard.set( NSKeyedArchiver.archivedData(withRootObject: groups), forKey: UserDefaultsKeys.kGroupePartage)
    }

    func getGroupesPartage() -> [GroupePartage] {
        guard let encodedData = userStandard.data(forKey: UserDefaultsKeys.kGroupePartage) else {
            return []
        }
        return NSKeyedUnarchiver.unarchiveObject(with: encodedData) as! [GroupePartage]
    }
}
