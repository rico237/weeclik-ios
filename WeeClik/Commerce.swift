//
//  Commerce.swift
//  WeeClik
//
//  Created by Herrick Wolber on 25/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

//enum CategoryType: String{
//    case restaurants
//    case plomberie
//    case autres
//}

class Commerce: NSObject {
    var nom         : String = ""
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
    var coverPhoto : PFFile? = nil
    
    var photosCommerces : [PFObject]? = nil
    var videosCommerce  : [PFObject]? = nil
    
    var objectId    : String! = "-1"
    var createdAt   : Date?
    var updatedAt   : Date?
    
    var pfObject : PFObject!
    
    init(parseObject: PFObject) {
        pfObject = parseObject
        
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
        
        self.objectId   = parseObject.objectId
        self.createdAt  = parseObject.createdAt
        self.updatedAt  = parseObject.updatedAt
        
        if let thumbnail = parseObject["thumbnailPrincipal"] as? PFFile {
            self.thumbnail = thumbnail
        }
        
        if let cover = parseObject["coverPhoto"] as? PFFile {
            self.coverPhoto = cover
        }
        
        if let photos = parseObject["photosSlider"] as? [PFObject]{
            if photos.count != 0 {
                self.photosCommerces = photos
            }
        }
        
        if let videos = parseObject["videosCommerce"] as? [PFObject]{
            if videos.count != 0 {
                self.videosCommerce = videos
            }
        }
    }
    
    override var description: String {
        get {
            return "Commerce {\n     Nom : \(self.nom)\n     Type : \(self.type)\n     Partages : \(self.partages)\n     Id : \(self.objectId!)\n}";
        }
    }
}
