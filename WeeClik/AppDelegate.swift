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
import Compass
import Contacts
import ContactsUI
import SwiftMultiSelect
import Firebase
import SwiftyStoreKit

#if DEBUG
import DBDebugToolkit
#endif


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var postLoginRouter = Router()
    
    //Contacts store
    public static var contactStore  = CNContactStore()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        DBDebugToolkit.setup()
        #endif
        
        parseConfiguration()
        globalUiConfiguration()
        firebaseConfiguration()
        purchaseObserver()
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        
        setupRouting()

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        try? Navigator.navigate(url: url)
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func firebaseConfiguration(){
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
    }
    
    func parseConfiguration(){
        let configuration = ParseClientConfiguration {
            $0.applicationId = HelperAndKeys.getServerAppId()
            $0.server = HelperAndKeys.getServerURL()
        }
        Parse.initialize(with: configuration)
    }
    
    func purchaseObserver(){
        // see notes below for the meaning of Atomic / Non-Atomic
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            print("Purchase complete transactions")
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    print("Nothing with status : \(purchase.transaction.transactionState)")
                    break // do nothing
                @unknown default:
                    fatalError("Unknow value passed for purchaseObserver - Payment function - AppDelegate")
                }
            }
        }
        
        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
//            TEST = itms-services://?action=purchaseIntent&bundleId=com.example.app&productIdentifier=product_name
//            if PFUser.current() != nil {
//                // TODO: Handle purchase made from store
//                return true
//            }
            return false
        }
    }
    
    func globalUiConfiguration(){
        UINavigationBar.appearance().barTintColor = UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = UIColor.white
        
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        shadow.shadowOffset = CGSize(width: 0, height: 1)

        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0),
            NSAttributedString.Key.shadow : shadow,
            NSAttributedString.Key.font : UIFont(name: "BebasNeue", size: 21.0) as Any
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

extension AppDelegate {
    // Contacts functions
    
    class func getAppDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    /// Function to request access for PhoneBook
    ///
    /// - Parameter completionHandler: completionHandler description
    class func requestForAccess(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch authorizationStatus {
        case .authorized:
            completionHandler(true)
            
        case .denied, .notDetermined:
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(access)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        DispatchQueue.main.async(execute: { () -> Void in
                            print("\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings.")
                        })
                    }
                }
            })
            
        default:
            completionHandler(false)
        }
    }
    
    
    /// Function to get contacts from device
    ///
    /// - Parameters:
    ///   - keys: array of keys to get
    ///   - completionHandler: callback function, contains contacts array as parameter
    public class func getContacts(_ keys:[CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactOrganizationNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactViewController.descriptorForRequiredKeys()],completionHandler: @escaping (_ success:Bool, _ contacts: [SwiftMultiSelectItem]?) -> Void){
        
        self.requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                
                var contactsArray = [SwiftMultiSelectItem]()
                
                let contactFetchRequest = CNContactFetchRequest(keysToFetch: self.allowedContactKeys())
                
                do {
                    var row = 0
                    try self.contactStore.enumerateContacts(with: contactFetchRequest, usingBlock: { (contact, stop) -> Void in
                        
                        var username    = "\(contact.givenName) \(contact.familyName)"
                        var companyName = contact.organizationName
                        
                        if username.trimmingCharacters(in: .whitespacesAndNewlines) == "" && companyName != ""{
                            username        = companyName
                            companyName     = ""
                        }
                        
                        let item_contact = SwiftMultiSelectItem(row: row, title: username, description: companyName, image: nil, imageURL: nil, color: nil, userInfo: contact)
                        contactsArray.append(item_contact)
                        
                        row += 1
                        
                    })
                    completionHandler(true, contactsArray)
                }
                    
                    //Catching exception as enumerateContactsWithFetchRequest can throw errors
                catch let error as NSError {
                    
                    print(error.localizedDescription)
                    
                }
                
            }else{
                completionHandler(false, nil)
            }
        }
        
    }
    /// Get allowed keys
    ///
    /// - Returns: array
    class func allowedContactKeys() -> [CNKeyDescriptor]{
        
        return [
            CNContactNamePrefixKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNameSuffixKey as CNKeyDescriptor,
            //CNContactNicknameKey,
            //CNContactPhoneticGivenNameKey,
            //CNContactPhoneticMiddleNameKey,
            //CNContactPhoneticFamilyNameKey,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            //CNContactDepartmentNameKey,
            //CNContactJobTitleKey,
            //CNContactBirthdayKey,
            //CNContactNonGregorianBirthdayKey,
            //CNContactNoteKey,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            //CNContactTypeKey,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            //CNContactPostalAddressesKey,
            CNContactDatesKey as CNKeyDescriptor,
            //CNContactUrlAddressesKey,
            //CNContactRelationsKey,
            //CNContactSocialProfilesKey,
            //CNContactInstantMessageAddressesKey
        ]
        
    }
}

extension AppDelegate {
    func setupRouting() {
        // [1] Register scheme
        Navigator.scheme = "weeclik"
        
        // [2] Configure routes for Router
        postLoginRouter.routes = [
            "commerce:{commerceId}" : CommerceRoute() // ,
            //"user:{userId}": UserRoute(),
        ]
        
        // [3] Register routes you 'd like to support
        Navigator.routes = Array(postLoginRouter.routes.keys)
        
        // [4] Do the handling
        Navigator.handle = { [weak self] location in
            
            guard let selectedController = self?.window?.visibleViewController else {
                return
            }
            
            // [5] Choose the current visible controller
            let currentController = (selectedController as? UINavigationController)?.topViewController
                ?? selectedController
            
            // [6] Navigate
            self?.postLoginRouter.navigate(to: location, from: currentController)
        }
    }
}
