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
    
    var objectId    : String! = "-1"
    var createdAt   : Date?
    var updatedAt   : Date?
    
    func initWithPFObject(anObject: PFObject) {
        self.nom        = anObject["nomCommerce"] as! String
//        self.type = CategoryType(rawValue: anObject["typeCommerce"] as! String)!
        self.type       = anObject["typeCommerce"] as! String
        self.partages   = anObject["nombrePartages"] as! Int
        
        self.objectId   = anObject.objectId
        self.createdAt  = anObject.createdAt
        self.updatedAt  = anObject.updatedAt
    }
    
//    override var description: String {
//        get {
//            return "";
//        }
//    }
}
