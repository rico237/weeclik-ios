//
//  Helper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 21/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import Foundation
import UIKit
import Parse
import MapKit
import CRNotifications
import SwiftDate

class HelperAndKeys {

    static func setUserDefaultsValue(value: Any, forKey key: String) {
        let standardUserDefaults = UserDefaults.standard
        standardUserDefaults.set(value, forKey: key)
        standardUserDefaults.synchronize()
    }

    static func getUserDefaultsValue(forKey key: String, withExpectedType expectedType: String) -> Any? {
        let standardUserDefaults = UserDefaults.standard
        let type = expectedType.lowercased()
        if type == "bool" {
            return standardUserDefaults.bool(forKey: key)
        } else if type == "string" {
            return standardUserDefaults.string(forKey: key)
        }
        return nil
    }

    static func getPrefFiltreLocation() -> Bool {
        let standardUserDefaults = UserDefaults.standard
        return standardUserDefaults.bool(forKey: Constants.UserDefaultsKeys.prefFilterLocationKey)
    }

    static func setPrefFiltreLocation(filtreLocation: Bool) {
        let standardUserDefaults = UserDefaults.standard
        standardUserDefaults.set(filtreLocation, forKey: Constants.UserDefaultsKeys.prefFilterLocationKey)
        standardUserDefaults.synchronize()
    }

    static func getLocationGranted() -> Bool {
        let standardUserDefaults = UserDefaults.standard
        return standardUserDefaults.bool(forKey: Constants.UserDefaultsKeys.locationPreferenceKey)
    }

    static func setLocationGranted(locationGranted: Bool) {
        let standardUserDefaults = UserDefaults.standard
        standardUserDefaults.set(locationGranted, forKey: Constants.UserDefaultsKeys.locationPreferenceKey)
        standardUserDefaults.synchronize()
    }

    static func showNotification(type: String, title: String, message: String, delay: TimeInterval) {
        var crType: CRNotificationType
        switch type {
        case "S":
            crType = CRNotifications.success
        case "E":
            crType = CRNotifications.error
        default:
            crType = CRNotifications.info
        }
        CRNotifications.showNotification(type: crType, title: title, message: message, dismissDelay: delay)
    }

    static func callNumer(phone: String) {
        if let url = URL(string: "telprompt://\(phone)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    static func openMapForPlace(placeName: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {

        let regionDistance: CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = placeName
        mapItem.openInMaps(launchOptions: options)
    }

    static func setSharingTime(forCommerceId: String) {
        let date = Date()
        let stringCat = forCommerceId+"_date"
        UserDefaults.standard.set(date, forKey: stringCat)
        UserDefaults.standard.synchronize()
    }

    static func getSharingTimer(forCommerceId: String) -> Date? {
        let stringCat = forCommerceId+"_date"
        let date = UserDefaults.standard.object(forKey: stringCat) as? Date
        return date
    }

    static func getSharingStringDate(objectId: String) -> String {
        let date = getSharingTimer(forCommerceId: objectId)
        return getCurrentDate(date: date)
    }

    static func canShareAgain(objectId: String) -> Bool {
        guard let date = getSharingTimer(forCommerceId: objectId) else {
            return true
        }
        let isAfterIntervalle = Date().isAfterDate(date + 7.days, granularity: .second)
        if isAfterIntervalle {
            removeCommerce(forCommerceId: objectId)
            return true
        } else {
            return false
        }
    }

    static func removeCommerce(forCommerceId: String) {
        let stringCat = forCommerceId+"_date"
        UserDefaults.standard.removeObject(forKey: stringCat)
        UserDefaults.standard.synchronize()
    }

    /// Has safe area
    ///
    /// with notch: 44.0 on iPhone X, XS, XS Max, XR.
    ///
    /// without notch: 20.0 on iPhone 8 on iOS 12+.
    ///
    static var hasSafeArea: Bool {
        guard let topPadding = UIApplication.shared.keyWindow?.safeAreaInsets.top, topPadding > 24 else {
            return false
        }
        return true
    }

    static var isPhoneX: Bool {
        return UIDevice.isIphoneX
    }

    static func getCurrentDate(date: Date?) -> String {
        guard let date = date else { return "\(Date())"}
        return getDateFormat().string(from: date)
    }
    
    private static func getDateFormat() -> DateFormatter {
        let format = DateFormatter()
        format.dateFormat = "dd/MM/yy HH:mm:ss"
        format.locale = Locale.current
        format.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        return format
    }

    static func sendBugReport(message: String) {
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        print("Créer une fonction de bug report avec le detail + la version de l'app : \(versionNumber)")
    }

    // TODO: Construire une veritable requette de stats (perfection)
    static func saveStatsInDb(commerce: PFObject, user: PFUser? = nil) {
        // Il y a un compte utilisateur, on met donc a jour ses stats
        if let user = user {
            let query = PFQuery(className: "StatsPartage")
            query.whereKey("commercePartage", equalTo: commerce)
            query.whereKey("utilisateurPartageur", equalTo: user)
            query.includeKey("commercePartage")
            query.getFirstObjectInBackground { (object, error) in
                if let error = error {
                    print(error.desc)
                    if error.code == 101 {
                        // Aucun objet trouvé on en crée un
                        let parseObj = PFObject(className: "StatsPartage")
                        parseObj["commercePartage"] = commerce
                        parseObj["utilisateurPartageur"] = user
                        parseObj["nbrPartage"] = 1
                        parseObj["mes_partages_dates"] = [Date()]
                        parseObj.saveInBackground { (_ success: Bool, error) in
                            if let _ = error {
                                
                            } else {
                                // On met a jour les stats du commerce sans utilisateur
                                let commerceQuery = PFQuery(className: "Commerce")
                                commerceQuery.getObjectInBackground(withId: commerce.objectId!) { (comm, error) in
                                    if let error = error {
                                        ParseErrorCodeHandler.handleUnknownError(error: error)
                                    } else if let comm = comm {
                                        comm.incrementKey("nombrePartages")
                                        comm.saveInBackground()
                                    }
                                }
                            }
                        }
                    } else {
                        print("Error in save stat partage func - HelperAndKeys - saveStatsInDb")
                        ParseErrorCodeHandler.handleUnknownError(error: error)
                    }

                } else if let sharingObject = object {
                    sharingObject.incrementKey("nbrPartage")
                    sharingObject.add(Date(), forKey: "mes_partages_dates")
                    if let theCommerce = sharingObject["commercePartage"] as? PFObject {
                        theCommerce.incrementKey("nombrePartages")
                        PFObject.saveAll(inBackground: [sharingObject, theCommerce])
                    } else {
                        sharingObject.saveInBackground()
                    }
                }
            }
        } else {
            // On met a jour les stats du commerce sans utilisateur
            let commerceQuery = PFQuery(className: "Commerce")
            commerceQuery.getObjectInBackground(withId: commerce.objectId!) { (comm, error) in
                if let error = error {
                    ParseErrorCodeHandler.handleUnknownError(error: error)
                } else if let comm = comm {
                    comm.incrementKey("nombrePartages")
                    comm.saveInBackground()
                }
            }
        }
    }
}
