//  Created by Herrick Wolber on 17/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.

//
//  Can be seen in Payment storyboard (Payment.storyboard)
//

import UIKit
import StoreKit
import Parse

class PaymentVC: UIViewController, IAPHandlerDelegate {
    
    let storeProductId = "rFK3UKsB"
    var purchaseProducts = [SKProduct]()
    var parseProducts = [PFProduct]()
    var didFinishFetchProducts = false
    var didFinishPurchaseFunction = false
    
    @IBOutlet weak var legalTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "PAIEMENT"
        
        updateCGUText()
        
        InAppPurchaseHandler.shared.delegate = self
        InAppPurchaseHandler.shared.fetchAvailableProducts()
        InAppPurchaseHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else { return }
            
            switch type {
            case .purchased:
                let alertView = UIAlertController(title: "Paiement réussi", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
                break
            case .disabled:
                let alertView = UIAlertController(title: "Paiement désactivé", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
                break
            case .restored:
                let alertView = UIAlertController(title: "Paiement restauré", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
                break
            case .failed:
                let alertView = UIAlertController(title: "Paiement échoué", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
                break
            }
            
//            self.didFinishPurchaseFunction = true
        }
    }
    
    func updateCGUText(){
        let style = NSMutableParagraphStyle()
        style.alignment = .justified
        
        
        let attributedString = NSMutableAttributedString(string: legalTextView.text)
        let urlCGU = URL(string: "https://google.fr/")!
        let urlPolitique = URL(string: "https://facebook.com/")!
        
        attributedString.setAttributes([.link: urlCGU], range: NSMakeRange(607, 20))
        attributedString.setAttributes([.link: urlPolitique], range: NSMakeRange(631, 28))
        
        legalTextView.isUserInteractionEnabled = true
        legalTextView.isEditable = false
        let fullRange = NSMakeRange(0, attributedString.length)
        
        attributedString.addAttribute(NSAttributedStringKey.paragraphStyle, value: style, range: fullRange)
        attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 14), range: fullRange)
        
        legalTextView.linkTextAttributes = [
            NSAttributedStringKey.foregroundColor.rawValue: UIColor.blue,
            NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue
            ] as [String : Any]
        
        legalTextView.attributedText = attributedString
    }
    
    @IBAction func processPurchase(_ sender: Any) {
        // Purchase on a tab of PFProducts
//        InAppPurchaseHandler.shared.purchaseMyProduct(index: 0)
        
        if InAppPurchaseHandler.shared.canMakePurchases() {
            InAppPurchaseHandler.shared.purchaseMyProductById(identifier: storeProductId)
        } else {
            HelperAndKeys.showAlertWithMessage(theMessage: "Impossible d'effectué d'achat avec cet appareil", title: "Erreur lors de l'achat", viewController: self)
        }
    }
    
    @IBAction func restorePurchase(_ sender: Any) {
        InAppPurchaseHandler.shared.restorePurchase()
    }
    
    @IBAction func cancelPurchase(_ sender: Any) {
        if let navigationCntrl = self.navigationController {
            // return to product or profil
//            navigationCntrl.popToViewController(UIViewController, animated: true)
            navigationCntrl.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    // MARK : Delegate Methods
    
    func didFinishFetchAllProductFromParse(products: [PFProduct]) {
        self.parseProducts = products
        self.didFinishFetchProducts = true
    }
}
