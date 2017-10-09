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
        let alertViewController = UIAlertController.init(title: title, message: theMessage, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default) { (action) -> Void in}
        alertViewController.addAction(defaultAction)
        viewController.present(alertViewController, animated: true, completion: nil)
    }
    
    static func getNavigationBarColor() -> UIColor{
        return UIColor(red:0.11, green:0.69, blue:0.96, alpha:1.00)
    }
    
    static func getBackgroundColor() -> UIColor{
        return UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.00)
    }
    
    static func getServerURL() -> String{
        return "https://weeclik.herokuapp.com/parse"
//        return "http://193.70.33.55:1337/parse"
    }
    
    static func getServerAppId() -> String{
        return "JVQZMCuNYvnecPWvWFDTZa8A"
    }
    
    static func showNotification(type : String , title: String, message: String, delay: TimeInterval){
        var crType : CRNotificationType
        switch type {
        case "S":
            crType = .success
            break
        case "E":
            crType = .error
            break
        default:
            crType = .info
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
        
        let alertViewController = UIAlertController.init(title: "Sortir de l'application ?", message: "Vous allez être redirigé vers le site web du commerçant.\n Et ainsi quitter l'application Weeclik.\n Voulez vous continuer ?", preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default) { (action) -> Void in
            if let url = URL(string: site), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        let cancelAction = UIAlertAction.init(title: "Annuler", style: UIAlertActionStyle.destructive) {(action) -> Void in}
        alertViewController.addAction(cancelAction)
        alertViewController.addAction(defaultAction)
        controller.present(alertViewController, animated: true, completion: nil)
    }
    
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
            composeVC.mailComposeDelegate = self as? MFMailComposeViewControllerDelegate
            
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
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = placeName
        mapItem.openInMaps(launchOptions: options)
    }
    
    static func setSharingTime(forCommerceId : String){
        let date = Date()
        UserDefaults.standard.set(date, forKey: forCommerceId)
    }
    
    static func getSharingTimer(forCommerceId : String) -> Date? {
        let date = UserDefaults.standard.object(forKey: forCommerceId) as? Date
        return date
    }
    
    static func canShareAgain(objectId : String) -> Bool{
        
        if let date = self.getSharingTimer(forCommerceId: objectId){
            let minutes = self.minutesBetweenDates(date1: date, date2: Date())
            // TODO: Mettre le veritable intervalle
            if minutes >= 2 {
                return true
            }else{
                return false
            }
        }
        return false
    }
    
    static func minutesBetweenDates(date1: Date, date2: Date) -> Int {
        let secondsBetween = abs(Int(date1.timeIntervalSince(date2)))
        let secondsInHour = 60
        return secondsBetween / secondsInHour
    }
    
    static func getListOfCategories() -> Array<String>{
        return ["Alimentaire","Artisanat","Bien-être","Décoration","E-commerce","Distribution","Hôtellerie","Immobilier","Informatique","Métallurgie","Médical","Nautisme","Paramédical","Restauration","Sécurité","Textile","Tourisme","Transport","Urbanisme"]
    }
    
    static func handleParseError(errorCode: Int) -> String{
        switch errorCode {
        case PFErrorCode.errorConnectionFailed.rawValue :
            return "Il y a eu un problème de connexion veuillez réessayer plus tard."
        default:
            return ""
        }
    }
}
