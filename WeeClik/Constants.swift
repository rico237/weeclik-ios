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

    // MARK: Server related
    struct Server {
        /**
         Get server API enpoint based on environment (Development / Production)
         
         - Returns: The API Endpoint
         */
        static func serverURL() -> String {
            #if DEVELOPMENT
            /// Localhost partage de connexion iphone 7+
            // return "http://172.20.10.4:1337/parse"
            /// Localhost wifi maison
            // return "http://192.168.1.30:1337/parse"
            return "https://weeclik-server-dev.herokuapp.com/parse"
            #else
            return "https://weeclik-server.herokuapp.com/parse"
            #endif
        }

        /// Application Id, needed to connect to authenticate to server
        static let serverAppId = "JVQZMCuNYvnecPWvWFDTZa8A"
    }

    // MARK: UserDefaults Keys
    struct UserDefaultsKeys {
        static let locationPreferenceKey = "locationPreference"
        static let prefFilterLocationKey = "filterPreference"
        static let paymentKey = "payment_enabled"
        static let scheduleKey = "shedule_key"
        static let partageGroupKey = "partage_group_key"
    }

    // MARK: Plists files
    struct Plist: Codable {
        /// Enum representing Type of .plist we want to fetch (.firebase || .weeclik)
        enum PlistType {
            case firebase
            case weeclik
        }

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
            var resource = ""
            switch type {
            case .weeclik:
                #if DEVELOPMENT
                resource = "Info"
                #else
                resource = "Info-DEV"
                #endif
            case .firebase:
                resource = "GoogleService-Info"
            }

            if let plist = Constants.Plist.getPlistDictionary(forName: resource) {
                return plist[key] as? T
            } else {
                return nil
            }
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
