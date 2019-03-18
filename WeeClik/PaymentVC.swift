//  Created by Herrick Wolber on 17/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.

//
//  Can be seen in Payment storyboard (Payment.storyboard)
//

import UIKit
import StoreKit
import Parse

class PaymentVC: UIViewController, IAPHandlerDelegate {
    
    let storeProductId = "8tcgW2xb3c"
    var purchaseProducts = [SKProduct]()
    var parseProducts = [PFProduct]()
    var didFinishFetchProducts = false
    
    @IBOutlet weak var legalTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "PAIEMENT"
        
        InAppPurchaseHandler.shared.delegate = self
        InAppPurchaseHandler.shared.fetchAvailableProducts()
        InAppPurchaseHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else { return }
            if type == .purchased {
                let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func processPurchase(_ sender: Any) {
//        InAppPurchaseHandler.shared.purchaseMyProduct(index: 0)
        InAppPurchaseHandler.shared.purchaseMyProductById(identifier: storeProductId)
    }
    
    @IBAction func cancelPurchase(_ sender: Any) {
        if let navigationCntrl = self.navigationController {
            // return to product or profil
//            navigationCntrl.popToViewController(UIViewController, animated: true)
            navigationCntrl.popToRootViewController(animated: true)
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // TESTER SI LE PAIEMENT OK OU PAS
        
        return true
    }
    
    // MARK : Delegate Methods
    
    func didFinishFetchAllProductFromParse(products: [PFProduct]) {
        self.parseProducts = products
        self.didFinishFetchProducts = true
    }
}
