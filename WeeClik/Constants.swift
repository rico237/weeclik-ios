//
//  Constants.swift
//  WeeClik
//
//  Created by Herrick Wolber on 23/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Foundation

/**
 * Store all constants (API, AppId, Keys, etc.)
 *
 * Should be separated by type (Server related, UserDefaults keys, etc.)
 * - author: Herrick Wolber
 */
struct Constants {
    
    // MARK: App info related
    struct App {
        static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        static let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        
        static let debugBuildVersion = """
        version: \(Constants.App.version ?? "Unknown")\
        (\(Constants.App.build ?? "Unknown"))
        """
        
        static let readableBuildVersion = "v\(Constants.App.version ?? "0")(\(Constants.App.build ?? "0"))"
    }

    // MARK: Server related
    struct Server {
        /**
         Get server API enpoint based on environment (Development / Production)
         
         - Returns: The API Endpoint
         */
        static let serverURL = "\(ConfigurationManager.shared.api.baseURL)\(ConfigurationManager.shared.endPoints.server)"
        
        /**
         Get dashboard enpoint based on environment (Development / Production)
         
         - Returns: The dashboard Endpoint
         */
        static let dashboardURL = "\(ConfigurationManager.shared.api.baseURL)\(ConfigurationManager.shared.endPoints.dashboard)"
        
        static let sharingURL = "\(ConfigurationManager.shared.api.baseURL)\(ConfigurationManager.shared.endPoints.share)"
        
        /**
        Get base URL (Development / Production)
        
        - Returns: Base URL
        */
        static var baseURL: String {
            // Localhost partage de connexion iphone
            // return "http://172.20.10.4:1337"
            // Localhost wifi maison
            // return "http://192.168.1.30:1337"
            return ConfigurationManager.shared.api.baseURL
        }

        /// Application Id, needed to connect to authenticate to server
        static let serverAppId = ConfigurationManager.shared.api.appId
    }
    
    struct WebApp {
        static var url: String {
            return ConfigurationManager.shared.api.webapp + "/"
        }
        static var sharingUrl: String {
            return ConfigurationManager.shared.api.webapp + ConfigurationManager.shared.endPoints.commerce
        }
    }

    // MARK: UserDefaults Keys
    struct UserDefaultsKeys {
        static let locationPreferenceKey = "locationPreference"
        static let prefFilterLocationKey = "filterPreference"
        static let paymentKey = "payment_enabled"
        static let scheduleKey = "shedule_key"
        static let partageGroupKey = "partage_group_key"
    }
}

extension Constants {
    struct MessageString {
        static func partageMessage(commerceObject: Commerce) -> String {
            return """
                Salut, j'ai aimé « \(commerceObject.nom) », \
                avec www.weeclik.com bénéficiez de remises.
                Voir le détail du commerce ici :
                    \(WebApp.sharingUrl)/\(commerceObject.objectId!)
                """.localized()
        }
    }
}

extension Constants {
    /// Enum representing Type of .plist we want to fetch (.firebase || .weeclik)
    enum PlistType {
        case firebase
        case weeclik
    }
    
    // MARK: Plists files
    struct Plist: Codable {
        /**
         Get object T stored in .plist files.

         Usage :
         ```
         let databaseURL: String = Constants.Plist.getDataForKey(key: "DATABASE_URL", type: .firebase) ?? "Not found"
         ```

         - Parameter key: Dictionarry's key to access value.
         - Parameter type: The type of .plist you wish to access, Default = .weeclik.

         - Returns: Object of type T stored for the corresponding key.
         */
        static func getDataForKey<T>(key: String, type: PlistType = .weeclik) -> T? {
            switch type {
            case .weeclik:
                if let plist = Constants.Plist.getPlistDictionary(forName: "Info") { return plist[key] as? T }
            case .firebase:
                if let plist = Constants.Plist.getPlistDictionary(forName: "GoogleService-Info") { return plist[key] as? T }
            }
            return nil
        }

        /**
         Generic function to fetch a .plist file based on it's name
         
         - Parameter name: The name of the .plist file
         
         - Returns: The content of .plist file as NSDictionnary or nil
         */
        private static func getPlistDictionary(forName name: String) -> NSDictionary? {
            if let path  = Bundle.main.path(forResource: name, ofType: "plist"), let dictionary = NSDictionary(contentsOfFile: path) {
                return dictionary
            }
            return nil
        }
    }
}
