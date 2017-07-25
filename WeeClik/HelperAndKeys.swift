//
//  Helper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 21/07/2017.
//  Copyright © 2017 Herrick Wolber. All rights reserved.
//

import Foundation
import UIKit

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
}
