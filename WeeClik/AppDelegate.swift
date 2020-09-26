//
//  AppDelegate.swift
//  WeeClik
//
//  Created by Herrick Wolber on 19/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import Compass
import Firebase
import SwiftyStoreKit
import Analytics
import Bugsnag

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var postLoginRouter = Router()

    // MARK: Lifecycle functions
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Log.all.debug("Environment \(Constants.App.debugBuildVersion)")
        
        // Server conf (bdd + storage + auth)
        parseConfiguration()
        
        // Init of Segment
        _ = AnalyticsManager.shared
        
        // Navigation bar & UI conf
        globalUiConfiguration()
        
        // Firebase conf = Analytics + Performance
        firebaseConfiguration()
        
        // StoreKit observer for In App Purchase (IAP)
        purchaseObserver()
        
        // External URL Routing to commerce detail
        setupRouting()
        
        // Bugsnag crash analytics
        Bugsnag.start(withApiKey: "78b012fa8081d3e9451b6a2302302ee8")
        
        // Clear all user defaults
//        resetUserDefaults()
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        try? Navigator.navigate(url: url)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // Use for iOS Settings App
        SettingsBundleHelper.setVersionAndBuildNumber()
//        AppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

// MARK: Libs/Plugins init/config.
extension AppDelegate {
    func firebaseConfiguration() {
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
    }

    func parseConfiguration() {
        let configuration = ParseClientConfiguration {
            $0.applicationId = Constants.Server.serverAppId
            $0.server = Constants.Server.serverURL
        }
        Parse.initialize(with: configuration)
        Log.all.debug("Parse server URL: \(Constants.Server.serverURL)")
    }

    func purchaseObserver() {
        // see notes below for the meaning of Atomic / Non-Atomic
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            Log.all.info("Purchase complete transactions")
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    Log.all.error("Nothing with status : \(purchase.transaction.transactionState)")
                @unknown default:
                    Log.all.error("Unknow value passed for purchaseObserver - Payment function - AppDelegate")
                }
            }
        }

        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
//            TEST = itms-services://?action=purchaseIntent&bundleId=com.example.app&productIdentifier=product_name
//            if PFUser.current() != nil {
//                Handle purchase made from store
//                return true
//            }
            return false
        }
    }
}

// MARK: UI Tests Confs
extension AppDelegate {
    func testUIConfiguration() {
        var arguments = ProcessInfo.processInfo.arguments
        arguments.removeFirst()
        Log.console.verbose("App launching with the following arguments: \(arguments)")

        // Always clear the defaults first
        if arguments.contains("ResetDefaults") {
            resetUserDefaults()
        }

        for argument in arguments {
            switch argument {
            case "NoAnimations":
                UIView.setAnimationsEnabled(false)
            case "UserHasRegistered":
                PFUser.logInWithUsername(inBackground: "toto@toto.com", password: "toto") { (user, _) in
                    if let user = user {
                        Log.console.verbose( "User \(user) is logged" )
                    }
                }
            default:
                break
            }
        }
    }
}

// MARK: Customization functions
extension AppDelegate {
    func globalUiConfiguration() {
        UINavigationBar.appearance().barTintColor = UIColor(red: 0.11, green: 0.69, blue: 0.96, alpha: 1.00)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = UIColor.white

        let shadow = NSShadow()
        shadow.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        shadow.shadowOffset = CGSize(width: 0, height: 1)

        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0),
            NSAttributedString.Key.shadow: shadow,
            NSAttributedString.Key.font: UIFont(name: "BebasNeue", size: 21.0) as Any
        ]
    }
}

// MARK: Routing functions
extension AppDelegate {
    func setupRouting() {
        // [1] Register scheme
        Navigator.scheme = "weeclik"

        // [2] Configure routes for Router
        postLoginRouter.routes = [
            "commerce:{commerceId}": CommerceRoute() // ,
            //"user:{userId}": UserRoute(),
        ]

        // [3] Register routes you 'd like to support
        Navigator.routes = Array(postLoginRouter.routes.keys)

        // [4] Do the handling
        Navigator.handle = { [weak self] location in
            guard let selectedController = self?.window?.visibleViewController else {return}

            // [5] Choose the current visible controller
            let currentController = (selectedController as? UINavigationController)?.topViewController
                ?? selectedController

            // [6] Navigate
            self?.postLoginRouter.navigate(to: location, from: currentController)
        }
    }
}

// MARK: Allow rotation on certain viewControllers
// https://medium.com/@sunnyleeyun/swift-100-days-project-24-portrait-landscape-how-to-allow-rotate-in-one-vc-d717678301c1
extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let rootViewController = self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController) {
            if (rootViewController.responds(to: Selector(("canRotate")))) {
                // Unlock landscape view orientations for this view controller
                return .allButUpsideDown
            }
        }
        // Only allow portrait (standard behaviour)
        return .portrait
    }
    /// Return the controller currently being presented
    private func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController? {
        guard rootViewController != nil else {return  nil}
        if (rootViewController.isKind(of: UITabBarController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UITabBarController).selectedViewController)
        } else if (rootViewController.isKind(of: UINavigationController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UINavigationController).visibleViewController)
        } else if (rootViewController.presentedViewController != nil) {
            return topViewControllerWithRootViewController(rootViewController: rootViewController.presentedViewController)
        }
        return rootViewController
    }
}

// MARK: UserDefaults Management
extension AppDelegate {
    /// Clear UserDefaults folder (used only for dev purpose)
    func resetUserDefaults() {
        Log.all.error("REMOVE BEFORE BUILDING FOR PROD")
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
}
