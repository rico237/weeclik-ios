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
import MessageUI
import CRNotifications
import SwiftDate

class HelperAndKeys {

    static func showAlertWithMessage(theMessage:String, title:String, viewController:UIViewController) {
        let alertViewController = UIAlertController.init(title: title, message: theMessage, preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction.init(title: "OK".localized(), style: .cancel) { (_) -> Void in
            alertViewController.dismiss(animated: true, completion: nil)
        }
        alertViewController.addAction(defaultAction)
        viewController.present(alertViewController, animated: true, completion: nil)
    }

    static func showSettingsAlert(withTitle title:String, withMessage message:String, presentFrom viewController:UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Réglages".localized(), style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {return}
            if UIApplication.shared.canOpenURL(settingsUrl) {UIApplication.shared.open(settingsUrl, completionHandler: nil)}
        }
        let cancelAction = UIAlertAction(title: "Annuler".localized(), style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        viewController.present(alertController, animated: true, completion: nil)
    }

    static func getNavigationBarColor() -> UIColor {
        return UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00)
    }

    static func getBackgroundColor() -> UIColor {
        return UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.00)
    }

    static func getServerURL() -> String {
//        return "http://172.20.10.4:1337/parse" // Localhost partage de connexion iphone 7+
//        return "http://192.168.1.30:1337/parse" // Localhost wifi maison
        return "https://weeclik-server.herokuapp.com/parse"
//        return "https://weeclik-server-dev.herokuapp.com/parse"
    }

    static func getServerAppId() -> String {
        return "JVQZMCuNYvnecPWvWFDTZa8A"
    }

    static func getLocationPreferenceKey() -> String {
        return "locationPreference"
    }

    static func getPrefFilterLocationKey() -> String {
        return "filterPreference"
    }

    static func getPaymentKey() -> String {
        return "payment_enabled"
    }

    static func getScheduleKey() -> String {
        return "shedule_key"
    }

    static func getPartageGroupKey() -> String {
        return "partage_group_key"
    }

    static func setUserDefaultsValue(value: Any, forKey key:String) {
        let use = UserDefaults.standard
        use.set(value, forKey: key)
        use.synchronize()
    }

    static func getUserDefaultsValue(forKey key: String, withExpectedType expectedType: String) -> Any? {
        let use = UserDefaults.standard; let type = expectedType.lowercased()

        if type == "bool" {
            return use.bool(forKey: key)
        } else if type == "string" {
            return use.string(forKey: key)
        }

        return nil
    }

    static func getPrefFiltreLocation() -> Bool {
        let use = UserDefaults.standard
        return use.bool(forKey: "filterPreference")
    }

    static func setPrefFiltreLocation(filtreLocation: Bool) {
        let use = UserDefaults.standard
        use.set(filtreLocation, forKey: "filterPreference")
        use.synchronize()
    }

    static func getLocationGranted() -> Bool {
        let use = UserDefaults.standard
        return use.bool(forKey: "locationPreference")
    }

    static func setLocationGranted(locationGranted: Bool) {
        let use = UserDefaults.standard
        use.set(locationGranted, forKey: "locationPreference")
        use.synchronize()
    }

    static func showNotification(type : String , title: String, message: String, delay: TimeInterval) {
        var crType : CRNotificationType
        switch type {
        case "S":
            crType = CRNotifications.success
            break
        case "E":
            crType = CRNotifications.error
            break
        default:
            crType = CRNotifications.info
            break
        }
        CRNotifications.showNotification(type: crType, title: title, message: message, dismissDelay: delay)
    }

    static func getImageForTypeCommerce(typeCommerce: String) -> UIImage {
        switch typeCommerce {
        case "Alimentaire".localized():
            return UIImage(named:"Alimentaire")!
        case "Artisanat".localized():
            return UIImage(named:"Artisanat")!
        case "Bien-être".localized():
            return UIImage(named:"Bien-etre")!
        case "Décoration".localized():
            return UIImage(named:"Decoration")!
        case "E-commerce".localized():
            return UIImage(named:"E-commerce")!
        case "Distribution".localized():
            return UIImage(named:"Distribution")!
        case "Hôtellerie".localized():
            return UIImage(named:"Hotellerie")!
        case "Immobilier".localized():
            return UIImage(named:"Immobilier")!
        case "Informatique".localized():
            return UIImage(named:"Informatique")!
        case "Métallurgie".localized():
            return UIImage(named:"Metallurgie")!
        case "Médical".localized():
            return UIImage(named:"Medical")!
        case "Nautisme".localized():
            return UIImage(named:"Nautisme")!
        case "Paramédical".localized():
            return UIImage(named:"Paramedical")!
        case "Restauration".localized():
            return UIImage(named:"Restauration")!
        case "Sécurité".localized():
            return UIImage(named:"Securite")!
        case "Textile".localized():
            return UIImage(named:"Textile")!
        case "Tourisme".localized():
            return UIImage(named:"Tourisme")!
        case "Transport".localized():
            return UIImage(named:"Transport")!
        case "Urbanisme".localized():
            return UIImage(named:"Urbanisme")!
        default:
            return UIImage(named: "Comm")!
        }
    }

    static func callNumer(phone: String) {
        if let url = URL(string: "telprompt://\(phone)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    static func visitWebsite(site: String, controller: UIViewController) {

        let alertViewController = UIAlertController.init(title: "Sortir de l'application ?".localized(), message: "Vous allez être redirigé vers le site web du commerçant.\n Et ainsi quitter l'application Weeclik.\n Voulez vous continuer ?".localized(), preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction.init(title: "OK".localized(), style: UIAlertAction.Style.default) { (_) -> Void in
            if let url = URL(string: site), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        let cancelAction = UIAlertAction.init(title: "Annuler".localized(), style: UIAlertAction.Style.destructive) {(_) -> Void in}
        alertViewController.addAction(cancelAction)
        alertViewController.addAction(defaultAction)
        controller.present(alertViewController, animated: true, completion: nil)
    }

    static func sendFeedBackOrMessageViaMail(messageToSend : String, isFeedBackMsg : Bool, commerceMail : String, controller : UIViewController) {
        let messageAdded : String
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        if !isFeedBackMsg {
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Téléchargez-la ici : http://www.google.fr/".localized()
        } else {
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Numéro de version de l'app : \(versionNumber)".localized()
        }
//                let allowedCharacters = NSCharacterSet.urlFragmentAllowed
        let finalMessage = messageToSend.appending(messageAdded)

        if MFMailComposeViewController.canSendMail() {
            let composeVC = MFMailComposeViewController()

            // Configure the fields of the interface.
            composeVC.setSubject("Demande de contact via Weeclik".localized())
            composeVC.setToRecipients([commerceMail])
            composeVC.setMessageBody(finalMessage, isHTML: true)

            composeVC.navigationBar.barTintColor = UIColor.white

            // Present the view controller modally.
            controller.present(composeVC, animated: true, completion: nil)
        } else {
            self.showAlertWithMessage(theMessage: "Il semblerait que vous n'ayez pas configuré votre boîte mail depuis votre téléphone.".localized(), title: "Erreur".localized(), viewController: controller)
        }

    }

    static func openMapForPlace(placeName : String, latitude: CLLocationDegrees, longitude:CLLocationDegrees) {

        let regionDistance:CLLocationDistance = 10000
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

    static func setSharingTime(forCommerceId : String) {
        let date = Date()
        let stringCat = forCommerceId+"_date"
        UserDefaults.standard.set(date, forKey: stringCat)
        UserDefaults.standard.synchronize()
    }

    static func getSharingTimer(forCommerceId : String) -> Date? {
        let stringCat = forCommerceId+"_date"
        let date = UserDefaults.standard.object(forKey: stringCat) as? Date
        return date
    }

    static func getSharingStringDate(objectId : String) -> String {
        let date = self.getSharingTimer(forCommerceId: objectId)
        return self.getCurrentDate(da: date)
    }

    static func canShareAgain(objectId : String) -> Bool {
        if let date = self.getSharingTimer(forCommerceId: objectId) {
            let isAfterIntervalle = Date().isAfterDate(date + 1.days, granularity: .second)
            print("isAfterIntervalle : \(isAfterIntervalle)")
            // TODO: Mettre le veritable intervalle
            if isAfterIntervalle {
                self.removeCommerce(forCommerceId: objectId)
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }

    static func removeCommerce(forCommerceId : String) {
        let stringCat = forCommerceId+"_date"
        UserDefaults.standard.removeObject(forKey: stringCat)
        UserDefaults.standard.synchronize()
    }

    static func getListOfCategories() -> [String] {
        return ["Alimentaire".localized(),"Artisanat".localized(),"Bien-être".localized(),"Décoration".localized(),"E-commerce".localized(),"Distribution".localized(),"Hôtellerie".localized(), "Immobilier".localized(),"Informatique".localized(),"Métallurgie".localized(),"Médical".localized(),"Nautisme".localized(),"Paramédical".localized(),"Restauration".localized(),"Sécurité".localized(),"Textile".localized(),"Tourisme".localized(),"Transport".localized(),"Urbanisme".localized(), "Autre".localized()]
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

    static func getCurrentDate(da : Date?) -> String {
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        // Si les tableaux est vide on l'ajoute au defaults
        let date = da == nil ? Date() : da!
        let format = DateFormatter()
        format.dateFormat = "dd/MM/yy HH:mm:ss"
        format.locale = Locale.current
        format.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        return format.string(from: date)
    }

    static func sendBugReport(message: String) {
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        print("Créer une fonction de bug report avec le detail + la version de l'app : \(versionNumber)")
    }

    // TODO: Construire une veritable requette de stats (perfection)
    static func saveStatsInDb(commerce : PFObject, user : PFUser? = nil) {
        // Il y a un compte utilisateur, on met donc a jour ses stats
        if let utilisateur = user {
            let query = PFQuery(className:"StatsPartage")
            query.whereKey("commercePartage", equalTo: commerce)
            query.whereKey("utilisateurPartageur", equalTo: utilisateur)
            query.includeKey("commercePartage")
            query.getFirstObjectInBackground { (object , error) in
                if let error = error {
                    print(error.desc)
                    if error.localizedDescription == "No results matched the query." {
                        // Aucun objet trouvé on en crée un
                        let parseObj = PFObject(className: "StatsPartage")
                        parseObj["commercePartage"] = commerce
                        parseObj["utilisateurPartageur"] = utilisateur
                        parseObj["nbrPartage"] = 1
                        parseObj["mes_partages_dates"] = [Date()]
                        parseObj.saveInBackground()
                    } else {
                        print("Error in save stat partage func - HelperAndKeys - saveStatsInDb")
                        ParseErrorCodeHandler.handleUnknownError(error: error)
                    }

                } else if let object = object {
                    let sharingObject = object
                    sharingObject.incrementKey("nbrPartage")
                    sharingObject.add(Date(), forKey: "mes_partages_dates")
                    let theCommerce = sharingObject["commercePartage"] as! PFObject
                    theCommerce.incrementKey("nombrePartages")
                    PFObject.saveAll(inBackground: [sharingObject, theCommerce])
                }
            }
        } else {
            // On met a jour les stats du commerce sans utilisateur
            let commerceQuery = PFQuery(className: "Commerce")
            commerceQuery.getObjectInBackground(withId: commerce.objectId!.description) { (comm, error) in
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
