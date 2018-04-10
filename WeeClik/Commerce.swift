//
//  Commerce.swift
//  WeeClik
//
//  Created by Herrick Wolber on 25/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import Foundation
import UIKit
import Parse

//enum CategoryType: String{
//    case restaurants
//    case plomberie
//    case autres
//}

enum StatutType: String {
    case paid = "Paiement",
    pending = "Hors ligne - en attente de paiement",
    canceled = "Hors ligne - paiement annulé",
    error = "Erreur lors du paiement ou du renouvellement"
}

@objc(Commerce)
class Commerce: NSObject, NSCoding {
    
    var nom         : String = ""
    var statut      : String = "Hors ligne - en attente de paiement" // En ligne, Hors ligne - en attente de paiement
//    var type : CategoryType = .autres
    var type        : String = ""
    var partages    : Int = 0
    var mail        : String = ""
    var adresse     : String = ""
    var location    : PFGeoPoint? = nil
    var tel         : String = ""
    var siteWeb     : String = ""
    var promotions  : String = ""
    var descriptionO: String = ""
    
    var thumbnail  : PFFile? = nil
    
    var objectId    : String! = "-1"
    var createdAt   : Date?
    var updatedAt   : Date?
    
    var distanceFromUser : String = ""
    
    var pfObject : PFObject!
    
    required override init() {
        super.init()
    }
    
    init(withName nom: String, tel: String, mail:String, adresse:String, siteWeb:String, categorie:String, description:String, promotions:String){
        self.pfObject = PFObject(className: "Commerce")
        self.objectId = pfObject.objectId
        self.createdAt = pfObject.createdAt
        self.updatedAt = pfObject.updatedAt
        
        self.nom = nom
        self.tel = tel
        self.mail = mail
        self.adresse = adresse
        self.siteWeb = siteWeb
        self.type = categorie
        self.descriptionO = description
        self.promotions = promotions
    }
    
    init(parseObject: PFObject) {
        self.pfObject = parseObject
        
        self.nom        = parseObject["nomCommerce"] as! String
        //        self.type = CategoryType(rawValue: parseObject["typeCommerce"] as! String)!
        self.type       = parseObject["typeCommerce"] as! String
        self.partages   = parseObject["nombrePartages"] as! Int
        self.tel        = parseObject["tel"] as! String
        self.mail       = parseObject["mail"] as! String
        self.siteWeb    = parseObject["siteWeb"] as! String
        self.adresse    = parseObject["adresse"] as! String
        self.descriptionO = parseObject["description"] as! String
        self.promotions = parseObject["promotions"] as! String
        self.location   = (parseObject["position"] as! PFGeoPoint)
        
        self.objectId   = parseObject.objectId
        self.createdAt  = parseObject.createdAt
        self.updatedAt  = parseObject.updatedAt
        
        if let thumbnailObj = parseObject["thumbnailPrincipal"] as? PFObject {
            if let thumbnail = thumbnailObj["photo"] as? PFFile{
                self.thumbnail = thumbnail
            }
        }
    }
    
    override var description: String {
        get {
            return "Commerce {\n\t Nom : \(self.nom)\n\t Type : \(self.type)\n\t Partages : \(self.partages)\n\t Id : \(self.objectId)\n}";
        }
    }
    
    func getPFObject() -> PFObject {
        let object = self.pfObject ?? PFObject(className: "Commerce")
        object["nomCommerce"] = nom
        object["statutCommerce"] = statut
        object["typeCommerce"] = type
        object["nombrePartages"] = partages
        object["mail"] = mail
        object["adresse"] = adresse
        object["tel"] = tel
        object["siteWeb"] = siteWeb
        object["promotions"] = promotions
        object["description"] = descriptionO
        return object
    }
    
    // Encoding Functions
    func encode(with aCoder: NSCoder) {
        aCoder.encode(nom, forKey: "nameComm")
        aCoder.encode(statut, forKey: "statutComm")
        aCoder.encode(type, forKey: "statutComm")
        aCoder.encode(partages, forKey: "partagesComm")
        aCoder.encode(mail, forKey: "mailComm")
        aCoder.encode(adresse, forKey: "statutComm")
        aCoder.encode(tel, forKey: "telComm")
        aCoder.encode(siteWeb, forKey: "sitewebComm")
        aCoder.encode(promotions, forKey: "promotionsComm")
        aCoder.encode(descriptionO, forKey: "descriptionComm")
        aCoder.encode(objectId, forKey: "objectIdComm")
    
        // Optionnels
        if let loc = location {aCoder.encode(loc, forKey: "locationComm")}
        if let thumb = self.thumbnail  {aCoder.encode(thumb, forKey: "thumbnailComm")}
        
        if let created = createdAt {aCoder.encode(created, forKey: "createdAtComm")}
        if let updated = updatedAt {aCoder.encode(updated, forKey: "updatedAtComm")}
    }
    
    required init?(coder aDecoder: NSCoder) {
        nom = aDecoder.decodeObject (forKey: "nameComm") as! String
        statut = aDecoder.decodeObject (forKey: "statutComm") as! String
        type = aDecoder.decodeObject (forKey: "statutComm") as! String
        partages = aDecoder.decodeInteger(forKey: "partagesComm")
        mail = aDecoder.decodeObject (forKey: "mailComm") as! String
        adresse = aDecoder.decodeObject (forKey: "statutComm") as! String
        tel = aDecoder.decodeObject (forKey: "telComm") as! String
        siteWeb = aDecoder.decodeObject (forKey: "sitewebComm") as! String
        promotions = aDecoder.decodeObject (forKey: "promotionsComm") as! String
        descriptionO = aDecoder.decodeObject (forKey: "descriptionComm") as! String
        objectId = aDecoder.decodeObject (forKey: "objectIdComm") as! String
        
        // Optionnels
        if let loc = aDecoder.decodeObject(forKey: "locationComm") {self.location = loc as? PFGeoPoint}
        if let thumb = aDecoder.decodeObject(forKey: "thumbnailComm"){self.thumbnail = thumb as? PFFile}
        if let created = aDecoder.decodeObject(forKey: "createdAtComm"){self.createdAt = created as? Date}
        if let updated = aDecoder.decodeObject(forKey: "updatedAtComm"){self.updatedAt = updated as? Date}
    }
}
