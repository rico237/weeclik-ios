//
//  AppDelegate.swift
//  WeeClik
//
//  Created by Herrick Wolber on 19/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import FBSDKCoreKit
import ParseFacebookUtilsV4

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        parseConfiguration()
        personaliserInteface()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func parseConfiguration(){
        let configuration = ParseClientConfiguration {
            $0.applicationId = HelperAndKeys.getServerAppId()
            $0.server = HelperAndKeys.getServerURL()
        }
        Parse.initialize(with: configuration)
    }
    
    func personaliserInteface(){
        UINavigationBar.appearance().barTintColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = UIColor.white
        UIApplication.shared.statusBarStyle = .lightContent
        
        
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedStringKey.foregroundColor : UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0),
            NSAttributedStringKey.shadow : shadow,
            NSAttributedStringKey.font : UIFont(name: "BebasNeue", size: 21.0) as Any
        ]
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
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

