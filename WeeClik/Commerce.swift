//
//  Commerce.swift
//  WeeClik
//
//  Created by Herrick Wolber on 25/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import Parse

@objc(Commerce)
public class Commerce: NSObject, NSCoding {
    static let PurchaseNotification = "WeeclikProductsPurchaseNotification"
    
    // Custom properties
    var nom: String             = ""
    var statut: StatutType      = .unknown
    var type: String            = ""
    var partages: Int           = 0
    var mail: String            = ""
    var adresse: String         = ""
    var tel: String             = ""
    var siteWeb: String         = ""
    var promotions: String      = ""
    var descriptionO: String    = ""
    var brouillon: Bool         = true
    var owner: PFUser?
    var location: PFGeoPoint?
    
    var distanceFromUser: String = ""
//    var type : CategoryType = .autres
    
    // More complex data
    var thumbnail: PFFileObject?
    var pfObject: PFObject!
    
    // Parse read-only data
    var objectId: String! = "-1"
    var createdAt: Date?
    var updatedAt: Date?

    required override public init() {super.init()}

    init(withName nom: String, tel: String, mail: String, adresse: String, siteWeb: String, categorie: String, description: String, promotions: String, owner: PFUser) {
        self.pfObject     = PFObject(className: "Commerce")
        self.objectId     = pfObject.objectId
        self.createdAt    = pfObject.createdAt
        self.updatedAt    = pfObject.updatedAt
        self.nom          = nom
        self.tel          = tel
        self.mail         = mail
        self.adresse      = adresse
        self.siteWeb      = siteWeb
        self.type         = categorie
        self.descriptionO = description
        self.promotions   = promotions
        self.owner        = owner
    }

    @objc
    init(parseObject: PFObject) {
        self.pfObject = parseObject

        if let nom          = parseObject["nomCommerce"] as? String {self.nom = nom}
        //        self.type = CategoryType(rawValue: parseObject["typeCommerce"] as! String)!
        if let type         = parseObject["typeCommerce"] as? String {self.type = type}
        if let partages     = parseObject["nombrePartages"] as? Int {self.partages = partages}
        if let tel          = parseObject["tel"] as? String {self.tel = tel}
        if let mail         = parseObject["mail"] as? String {self.mail = mail}
        if let siteWeb      = parseObject["siteWeb"] as? String {self.siteWeb = siteWeb}
        if let adresse      = parseObject["adresse"] as? String {self.adresse = adresse}
        if let descriptionO = parseObject["description"] as? String {self.descriptionO = descriptionO}
        if let brouillon    = parseObject["brouillon"] as? Bool {self.brouillon = brouillon}
        if let promotions   = parseObject["promotions"] as? String {self.promotions = promotions}

        if let statutP      = parseObject["statutCommerce"] {self.statut = StatutType(rawValue: statutP as! Int)!}
        if let position     = parseObject["position"] as? PFGeoPoint {self.location = position}
        if let owner        = parseObject["owner"] as? PFUser {self.owner = owner}

        if let thumbnailObj = parseObject["thumbnailPrincipal"] as? PFObject,
           let thumbnail    = thumbnailObj["photo"] as? PFFileObject {
            self.thumbnail  = thumbnail
        }

        self.objectId   = parseObject.objectId
        self.createdAt  = parseObject.createdAt
        self.updatedAt  = parseObject.updatedAt
    }

    convenience init? (objectId: String) {
        let query = PFQuery(className: "Commerce")
        query.whereKey("objectId", equalTo: objectId)
        query.includeKeys(["thumbnailPrincipal"])
        let parseCommerce = query.getFirstObjectInBackground()
        parseCommerce.waitUntilFinished()
        if let commerce = parseCommerce.result {
            self.init(parseObject: commerce)
        } else {
            return nil
        }
    }

    override public var description: String {
        return """
                Commerce { \
                    \tNom : \(self.nom) \
                    \tType : \(self.type)\
                    \t Partages : \(self.partages) \
                    \tId : \(String(describing: self.objectId)) \
                }
               """
    }

    func getPFObject(objectId: String, fromBaas: Bool, completion:((_ parseObject: PFObject?, _ error: Error?) -> Void)? = nil) {
        let object = pfObject ?? PFObject(className: "Commerce")

        if fromBaas {
            let commerceQuery = PFQuery(className: "Commerce")
            commerceQuery.getFirstObjectInBackground { (object, error) in
                guard let object = object else {
                    if let error = error {
                        ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: false)
                        completion?(nil, error)
                    }
                    return
                }
                // Object exist
                completion?(object, nil)
            }
        } else {
            object["nomCommerce"]    = nom
            object["statutCommerce"] = statut.rawValue
            object["typeCommerce"]   = type
            object["nombrePartages"] = partages
            object["mail"]           = mail
            object["adresse"]        = adresse
            object["tel"]            = tel
            object["siteWeb"]        = siteWeb
            object["promotions"]     = promotions
            object["description"]    = descriptionO
            object["brouillon"]      = brouillon
            object["owner"]          = owner
            completion?(object, nil)
        }
    }

    func updateLocation(latitude: Double, longitude: Double) {
        guard let object = self.pfObject else { return }
        object["position"] = PFGeoPoint(latitude: latitude, longitude: longitude)
        object.saveInBackground()
    }

    // Encoding Functions
    public func encode(with aCoder: NSCoder) {
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
        aCoder.encode(brouillon, forKey: "brouillon")
        aCoder.encode(objectId, forKey: "objectIdComm")

        // Optionnels
        if let location = location {aCoder.encode(location, forKey: "locationComm")}
        if let thumb    = thumbnail {aCoder.encode(thumb, forKey: "thumbnailComm")}
        if let created  = createdAt {aCoder.encode(created, forKey: "createdAtComm")}
        if let updated  = updatedAt {aCoder.encode(updated, forKey: "updatedAtComm")}
        if let owner    = owner {aCoder.encode(owner, forKey: "owner")}
    }

    required public init?(coder aDecoder: NSCoder) {
        nom             = aDecoder.decodeObject(forKey: "nameComm") as! String
        statut          = StatutType(rawValue: aDecoder.decodeObject(forKey: "statutComm") as! Int)!
        type            = aDecoder.decodeObject(forKey: "statutComm") as! String
        partages        = aDecoder.decodeInteger(forKey: "partagesComm")
        mail            = aDecoder.decodeObject(forKey: "mailComm") as! String
        adresse         = aDecoder.decodeObject(forKey: "statutComm") as! String
        tel             = aDecoder.decodeObject(forKey: "telComm") as! String
        siteWeb         = aDecoder.decodeObject(forKey: "sitewebComm") as! String
        promotions      = aDecoder.decodeObject(forKey: "promotionsComm") as! String
        descriptionO    = aDecoder.decodeObject(forKey: "descriptionComm") as! String
        brouillon       = aDecoder.decodeBool(forKey: "brouillon")
        objectId        = (aDecoder.decodeObject(forKey: "objectIdComm") as! String)

        // Optionnels
        if let location = aDecoder.decodeObject(forKey: "locationComm") {self.location = location as? PFGeoPoint}
        if let thumb    = aDecoder.decodeObject(forKey: "thumbnailComm") {self.thumbnail = thumb as? PFFileObject}
        if let created  = aDecoder.decodeObject(forKey: "createdAtComm") {self.createdAt = created as? Date}
        if let updated  = aDecoder.decodeObject(forKey: "updatedAtComm") {self.updatedAt = updated as? Date}
        if let ownerP   = aDecoder.decodeObject(forKey: "owner") {self.owner = ownerP as? PFUser}
    }
}

public enum StatutType: Int {
    case pending = 0,
    paid = 1,
    canceled = 2,
    error = 3,
    unknown = 4

    func label() -> String {
        switch self {
        case .paid :
            return "En ligne".localized()
        case .pending :
            return "Hors ligne - en attente de paiement".localized()
        case .canceled :
            return "Hors ligne - paiement annulé".localized()
        case .error :
            return "Erreur lors du paiement ou du renouvellement".localized()
        case .unknown :
            return "Statut inconnu".localized()
        }
    }

    var description: String {
        return label()
    }
}

extension Commerce {
    func calculDistanceEntreDeuxPoints(location: CLLocation?) -> String {
        guard let location = location else {return "--"}
        let distance = PFGeoPoint(location: location).distanceInKilometers(to: self.location)

        if distance < 1 {
            distanceFromUser = "\(Int(distance * 1000)) m"
        } else {
            distanceFromUser = "\(Int(distance)) Km"
        }
        return distanceFromUser
    }
}
