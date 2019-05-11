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

class HelperAndKeys {
    
    static func showAlertWithMessage(theMessage:String, title:String, viewController:UIViewController){
        let alertViewController = UIAlertController.init(title: title, message: theMessage, preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default) { (action) -> Void in}
        alertViewController.addAction(defaultAction)
        viewController.present(alertViewController, animated: true, completion: nil)
    }
    
    static func showSettingsAlert(withTitle title:String, withMessage message:String, presentFrom viewController:UIViewController){
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Réglages", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {return}
            if UIApplication.shared.canOpenURL(settingsUrl) {UIApplication.shared.open(settingsUrl, completionHandler: nil)}
        }
        let cancelAction = UIAlertAction(title: "Annuler", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    static func getNavigationBarColor() -> UIColor{
        return UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00)
    }
    
    static func getBackgroundColor() -> UIColor{
        return UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.00)
    }
    
    static func getServerURL() -> String{
        return "https://weeclik-server.herokuapp.com/parse"
    }
    
    static func getServerAppId() -> String{
        return "JVQZMCuNYvnecPWvWFDTZa8A"
    }
    
    static func getLocationPreferenceKey() -> String{
        return "locationPreference"
    }
    
    static func getPrefFilterLocationKey() -> String{
        return "filterPreference"
    }
    
    static func getPaymentKey() -> String {
        return "payment_enabled"
    }
    
    static func getScheduleKey() -> String {
        return "shedule_key"
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
    
    static func getPrefFiltreLocation() -> Bool{
        let use = UserDefaults.standard
        return use.bool(forKey: "filterPreference")
    }
    
    static func setPrefFiltreLocation(filtreLocation: Bool){
        let use = UserDefaults.standard
        use.set(filtreLocation, forKey: "filterPreference")
        use.synchronize()
    }
    
    static func getLocationGranted() -> Bool{
        let use = UserDefaults.standard
        return use.bool(forKey: "locationPreference")
    }
    
    static func setLocationGranted(locationGranted: Bool){
        let use = UserDefaults.standard
        use.set(locationGranted, forKey: "locationPreference")
        use.synchronize()
    }
    
    static func showNotification(type : String , title: String, message: String, delay: TimeInterval){
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
        case "Alimentaire":
            return UIImage(named:"Alimentaire")!
        case "Artisanat":
            return UIImage(named:"Artisanat")!
        case "Bien-être":
            return UIImage(named:"Bien-etre")!
        case "Décoration":
            return UIImage(named:"Decoration")!
        case "E-commerce":
            return UIImage(named:"E-commerce")!
        case "Distribution":
            return UIImage(named:"Distribution")!
        case "Hôtellerie":
            return UIImage(named:"Hotellerie")!
        case "Immobilier":
            return UIImage(named:"Immobilier")!
        case "Informatique":
            return UIImage(named:"Informatique")!
        case "Métallurgie":
            return UIImage(named:"Metallurgie")!
        case "Médical":
            return UIImage(named:"Medical")!
        case "Nautisme":
            return UIImage(named:"Nautisme")!
        case "Paramédical":
            return UIImage(named:"Paramedical")!
        case "Restauration":
            return UIImage(named:"Restauration")!
        case "Sécurité":
            return UIImage(named:"Securite")!
        case "Textile":
            return UIImage(named:"Textile")!
        case "Tourisme":
            return UIImage(named:"Tourisme")!
        case "Transport":
            return UIImage(named:"Transport")!
        case "Urbanisme":
            return UIImage(named:"Urbanisme")!
        default:
            return UIImage(named: "Comm")!
        }
    }
    
    static func callNumer(phone: String){
        if let url = URL(string: "telprompt://\(phone)"), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    static func visitWebsite(site: String, controller: UIViewController){
        
        let alertViewController = UIAlertController.init(title: "Sortir de l'application ?", message: "Vous allez être redirigé vers le site web du commerçant.\n Et ainsi quitter l'application Weeclik.\n Voulez vous continuer ?", preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default) { (action) -> Void in
            if let url = URL(string: site), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        let cancelAction = UIAlertAction.init(title: "Annuler", style: UIAlertAction.Style.destructive) {(action) -> Void in}
        alertViewController.addAction(cancelAction)
        alertViewController.addAction(defaultAction)
        controller.present(alertViewController, animated: true, completion: nil)
    }
    
    static func sendFeedBackOrMessageViaMail(messageToSend : String, isFeedBackMsg : Bool, commerceMail : String, controller : UIViewController){
        let messageAdded : String
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        if !isFeedBackMsg{
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Téléchargez-la ici : http://www.google.fr/"
        }else{
            messageAdded = "<br><br>Envoyé depuis l'application iOS Weeclik.<br><br>Numéro de version de l'app : \(versionNumber)"
        }
//                let allowedCharacters = NSCharacterSet.urlFragmentAllowed
        let finalMessage = messageToSend.appending(messageAdded)
        
        if MFMailComposeViewController.canSendMail(){
            let composeVC = MFMailComposeViewController()
            
            // Configure the fields of the interface.
            composeVC.setSubject("Demande de contact via WeeClik")
            composeVC.setToRecipients([commerceMail])
            composeVC.setMessageBody(finalMessage, isHTML: true)
            
            composeVC.navigationBar.barTintColor = UIColor.white
            
            // Present the view controller modally.
            controller.present(composeVC, animated: true, completion: nil)
        }else{
            self.showAlertWithMessage(theMessage: "Il semblerait que vous n'ayez pas configuré votre boîte mail depuis votre téléphone.", title: "Erreur", viewController: controller)
        }
        
    }
    
    static func openMapForPlace(placeName : String, latitude: CLLocationDegrees, longitude:CLLocationDegrees){
        
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
    
    static func setSharingTime(forCommerceId : String, commerceName : String){
        let date = Date()
        let stringCat = forCommerceId+"_date"
        UserDefaults.standard.set(date, forKey: stringCat)
        UserDefaults.standard.synchronize()
        sharingNotificationEnable(commerce: commerceName)
    }
    
    static func sharingNotificationEnable(commerce : String){
        
        print("Afficher Ici la fonction de notification après X temps")
    }
    
    static func getSharingTimer(forCommerceId : String) -> Date? {
        let stringCat = forCommerceId+"_date"
        let date = UserDefaults.standard.object(forKey: stringCat) as? Date
        return date
    }
    
    static func getSharingStringDate(objectId : String) -> String{
        let date = self.getSharingTimer(forCommerceId: objectId)
        return self.getCurrentDate(da: date)
    }
    
    static func canShareAgain(objectId : String) -> Bool{
        let date = self.getSharingTimer(forCommerceId: objectId)
        if date != nil {
            let timeDiff = self.minutesBetweenDates(date1: date!, date2: Date())
            // TODO: Mettre le veritable intervalle
            if timeDiff >= 1 {
                self.removeCommerce(forCommerceId: objectId)
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    static func removeCommerce(forCommerceId : String){
        let stringCat = forCommerceId+"_date"
        UserDefaults.standard.removeObject(forKey: stringCat)
        UserDefaults.standard.synchronize()
    }
    
    static func minutesBetweenDates(date1: Date, date2: Date) -> Int {
        let secondsBetween = abs(Int(date1.timeIntervalSince(date2)))
        let secondsInHour = 60
        return secondsBetween / secondsInHour
    }
    
    static func getListOfCategories() -> [String]{
        return ["Alimentaire","Artisanat","Bien-être","Décoration","E-commerce","Distribution","Hôtellerie","Immobilier","Informatique","Métallurgie","Médical","Nautisme","Paramédical","Restauration","Sécurité","Textile","Tourisme","Transport","Urbanisme"]
    }
    
    /// Has safe area
    ///
    /// with notch: 44.0 on iPhone X, XS, XS Max, XR.
    ///
    /// without notch: 20.0 on iPhone 8 on iOS 12+.
    ///
    static var hasSafeArea: Bool {
        guard #available(iOS 11.0, *), let topPadding = UIApplication.shared.keyWindow?.safeAreaInsets.top, topPadding > 24 else {
            return false
        }
        return true
    }
    
    static var isPhoneX: Bool {
        return UIDevice.isIphoneX
    }
    
    static func handleParseError(error: NSError) -> String{
        switch error.code {
        case PFErrorCode.errorConnectionFailed.rawValue :
            return "Il y a eu un problème de connexion veuillez réessayer plus tard."
        case PFErrorCode.errorInvalidSessionToken.rawValue :
            PFUser.logOut()
            return "Il y a eu un problème de connexion veuillez réessayer."
        default:
            return error.localizedDescription + " code : \(error.code)"
        }
    }
    
    static func getCurrentDate(da : Date?) -> String{
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        // Si les tableaux est vide on l'ajoute au defaults
        let date = da == nil ? Date() : da!
        let format = DateFormatter()
        format.dateFormat = "dd/MM/yy HH:mm:ss"
        format.locale = Locale.current
        format.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        return format.string(from: date)
    }
    
    static func sendBugReport(message: String){
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        print("Créer une fonction de bug report avec le detail + la version de l'app : \(versionNumber)")
    }
    
    static func logOutUser(){
        PFUser.logOut()
    }
    
    // TODO: Construire une veritable requette de stats (perfection)
    static func saveStatsInDb(commerce : PFObject, user : PFUser? = nil){
        // Il y a un compte utilisateur, on met donc a jour ses stats
        if let utilisateur = user {
            let query = PFQuery(className:"StatsPartage")
            query.whereKey("commercePartage", equalTo: commerce)
            query.includeKey("commercePartage")
            query.findObjectsInBackground { (array , error) in
                
                if array!.count > 0 {
                    let sharingObject = array![0]
                    sharingObject.incrementKey("nbrPartage")
                    let theCommerce = sharingObject["commercePartage"] as! PFObject
                    theCommerce.incrementKey("nombrePartages")
                    PFObject.saveAll(inBackground: [sharingObject, theCommerce])
                } else {
                    let parseObj = PFObject(className: "StatsPartage")
                    parseObj["commercePartage"] = commerce
                    parseObj["utilisateurPartageur"] = utilisateur
                    parseObj["nbrPartage"] = 1
                    parseObj.saveInBackground()
                }
            }
        }
        
        // On met a jour les stats du commerce
        let commerceQuery = PFQuery(className: "Commerce")
        commerceQuery.whereKey("objectId", equalTo: commerce.objectId?.description as Any)
        commerceQuery.findObjectsInBackground(block: { (commercesA, err) in
            let comm = commercesA![0]
            comm.incrementKey("nombrePartages")
            comm.saveInBackground()
        })
    }
    
    /// Validate email string
    ///
    /// - parameter email: A String that rappresent an email address
    ///
    /// - returns: A Boolean value indicating whether an email is valid.
    static func isValidEMail(_ email: String) -> Bool {
        let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
        "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-" + "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5" +
        "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" + "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
   
    
    /*
     
     LOST FUNCTIONS
     
     */
    
    
    //    static func isAppFirstLoadFinished() -> Bool{
    //        let use = UserDefaults.standard
    //        return use.bool(forKey: "isAppFirstLoad")
    //    }
    //
    //    static func setAppFirstLoadFinished(){
    //        let use = UserDefaults.standard
    //        use.set(true, forKey: "isAppFirstLoad")
    //        use.synchronize()
    //    }
    
    //    static func sendFeedBackOrMessageViaMail(messageToSend : String, isFeedBackMsg : Bool){
    //
    //        let messageAdded : String
    //
    //        if !isFeedBackMsg{
    //            messageAdded = "\n\nEnvoyé depuis l'application iOS Weeclik.\n\nTéléchargez-la ici : http://www.google.fr/"
    //        }else{
    //            messageAdded = "\n\nEnvoyé depuis l'application iOS Weeclik.\n\nNuméro de version de l'app : "
    //        }
    //
    //        let allowedCharacters = NSCharacterSet.urlFragmentAllowed
    //        let finalMessage = messageToSend.appending(messageAdded)
    //        let finalMessEncoded = finalMessage.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    //        print(finalMessEncoded!)
    //    }
}
