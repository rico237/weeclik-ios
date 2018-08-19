//
//  ChoixAbonnmentsVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 15/08/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import UIKit
import LGButton

class ChoixAbonnmentsVC: UIViewController {
    
    @IBOutlet weak var testButton: LGButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        InAppPurchaseHandler.shared.fetchAvailableProducts()
        InAppPurchaseHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else{ return }
            if type == .purchased {
                let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
            }
        }
        
        
        testButton.addTarget(self, action: #selector(consumable), for: .touchUpInside)
    }
    
    @objc func consumable(){
        print("Test")
        InAppPurchaseHandler.shared.purchaseMyProduct(index: 0)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
