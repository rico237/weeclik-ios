//
//  SettingsBundleHelper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 01/11/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Foundation

class SettingsBundleHelper {
    struct SettingsBundleKeys {
        static let BuildVersionKey = "build_preference"
        static let AppVersionKey = "version_preference"
    }
    class func setVersionAndBuildNumber() {
        UserDefaults.standard.set(Constants.App.version ?? "Unknown".localized(), forKey: "version_preference")
        UserDefaults.standard.set(Constants.App.build ?? "Unknown".localized(), forKey: "build_preference")
    }
}
