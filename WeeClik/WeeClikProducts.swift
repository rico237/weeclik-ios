//
//  WeeClikProducts.swift
//  WeeClik
//
//  Created by Herrick Wolber on 02/09/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse

class WeeClikProducts: NSObject {
    var order : Int = 0
    var downloadName : String = ""
    var subtitle : String = ""
    var title : String = ""
    var price : Double = 0.0
    var isMonthly : Bool = false
    var productIdentifier : String = ""
    var icon : PFFile?
    
    var parseProduct : PFProduct? = nil
    
    required override init() {
        super.init()
    }
    
    init(withPFProduct product: PFProduct) {
        self.order = product.order as! Int
        self.downloadName = product.downloadName!
        self.subtitle = product.subtitle!
        self.title = product.title!
        self.price = product["price"] as! Double
        self.isMonthly = product["isMonthly"] as! Bool
        self.productIdentifier = product.productIdentifier!
        if let icon = product.icon{
            self.icon = icon
        }
        self.parseProduct = product
    }
    
    override public var description: String {
        get {
            return "------------------------------------------------------\nProduit :\n\tAppStore Id -> \(self.productIdentifier)\n\tDescription -> \(self.downloadName)\n\tPrix -> \(self.price)€\n\tMonthly subscription ? -> \(self.isMonthly)\n------------------------------------------------------"
        }
    }
}
