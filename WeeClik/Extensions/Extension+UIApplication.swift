//
//  Extension+UIApplication.swift
//  WeeClik
//
//  Created by Herrick Wolber on 24/11/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    private func applicationVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    private func applicationBuild() -> String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }
    func versionBuild() -> String {
        let version = self.applicationVersion()
        let build = self.applicationBuild()
        return "\(version)(\(build))"
    }
}
