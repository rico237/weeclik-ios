//
//  UserDefaultsManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 06/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

// swiftlint:disable force_cast
import UIKit

/// Different keys of local data
private enum UserDefaultsKeys {
    static let kGroupePartage = "listOfGroupePartage_key"
    static let kUserPreferences = "UserPreferences_key"
}

/// Class managing local storage of data
final class UserDefaultsManager: NSObject {
    public static let shared = UserDefaultsManager()
    private static let userStandard = UserDefaults.standard
    private override init() {}
}

// MARK: User preferences
extension UserDefaultsManager {
    struct UserPreferences {
        // RGPD
        static var rgpd: Bool {
            get { userStandard.bool(forKey: UserDefaultsKeys.kUserPreferences) }
            set { userStandard.set(newValue, forKey: UserDefaultsKeys.kUserPreferences) }
        }
    }
}

// MARK: Groupe partage
extension UserDefaultsManager {
    /// <#Description#>
    /// - Parameter groupe: <#groupe description#>
    func addSharingGroup(groupe: GroupePartage) {
        var groups = self.getGroupesPartage()
        groups.append(groupe)
        UserDefaultsManager.userStandard.set( NSKeyedArchiver.archivedData(withRootObject: groups), forKey: UserDefaultsKeys.kGroupePartage)
    }

    /// <#Description#>
    /// - Parameter index: <#index description#>
    func removeSharingGroup(atIndex index: Int) {
        var groups = self.getGroupesPartage()
        groups.remove(at: index)
        UserDefaultsManager.userStandard.set( NSKeyedArchiver.archivedData(withRootObject: groups), forKey: UserDefaultsKeys.kGroupePartage)
    }

    func getGroupesPartage() -> [GroupePartage] {
        guard let encodedData = UserDefaultsManager.userStandard.data(forKey: UserDefaultsKeys.kGroupePartage) else {
            return []
        }
        return NSKeyedUnarchiver.unarchiveObject(with: encodedData) as! [GroupePartage]
    }
}
