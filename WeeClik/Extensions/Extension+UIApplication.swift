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

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController

            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return topViewController(base: top)
            } else if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
}
