//  Created by Herrick Wolber on 17/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.

//
//  Can be seen in Payment storyboard (Payment.storyboard)
//

import UIKit
import Parse
import SwiftyStoreKit
import SPLarkController
import SwiftDate
import SVProgressHUD

class PaymentVC: UIViewController {
    var commerceAlreadyExists = false                       // Check if we came for renewable or creation
    var currentUser = PFUser.current()                      // User making purchase
    var hasPaidForNewCommerce = false                       // Permet de savoir si on peut créer un nouveau commerce vers la BDD
    var paymentDeactivated = false                          // TEST VAR (permet de switcher la demande de paiement)
    var scheduleVal = false
    var renewingCommerceId = ""                             // ObjectId of commerce if purchase was a success || commerce that wants to be renewed
    let purchasedProductID = "abo.sans.renouvellement"      // TODO: replace (abo.sans.renouvellement.un.an)
    
    let panelController = AdminMonProfilSettingsVC(nibName: "AdminMonProfilSettingsVC", bundle: nil) // Paneau d'aministration (option de paiement etc.)
    
    @IBOutlet weak var legalTextView: UITextView!           // CGU, CGV, etc
    
    @objc func showSettingsPanel(){
        let transitionDelegate = SPLarkTransitioningDelegate()
        transitionDelegate.customHeight = 185
        panelController.transitioningDelegate = transitionDelegate
        panelController.modalPresentationStyle = .custom
        panelController.modalPresentationCapturesStatusBarAppearance = true
        self.present(panelController, animated: true, completion: nil)
    }
    
    func updateAdminUI(){
        guard let current = self.currentUser else {
            self.navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(getBackToHome(_:)))]
            return
        }
        // Recup le role de l'utilisateur (ex: admin)
        let adminRole = PFRole.query()
        adminRole?.whereKey("users", equalTo: current)
        adminRole?.findObjectsInBackground(block: { (results, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error)
            } else {
                if let results = results {
                    let roles = results as! [PFRole]
                    for role  in roles {
                        if role.name == "admin" {
                            self.navigationItem.leftBarButtonItems = [
                                UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.getBackToHome(_:))),
                                UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(self.showSettingsPanel))
                            ]
                        }
                    }
                }
            }
        })
    }
    
    @IBAction func getBackToHome(_ sender: Any) {
        if commerceAlreadyExists {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "PAIEMENT"
        
        print(self.renewingCommerceId)
        
        SVProgressHUD.setHapticsEnabled(true)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(1.5)

        updateCGUText()
        updateAdminUI() // Update UINavigationBar
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
        
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14), range: fullRange)
        
        legalTextView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.blue,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
            ] as [NSAttributedString.Key : Any]
        
        legalTextView.attributedText = attributedString
    }
    
    @IBAction func processPurchase(_ sender: Any) {
        paymentDeactivated = HelperAndKeys.getUserDefaultsValue(forKey: HelperAndKeys.getPaymentKey(), withExpectedType: "bool") as? Bool ?? false
        scheduleVal = HelperAndKeys.getUserDefaultsValue(forKey: HelperAndKeys.getScheduleKey(), withExpectedType: "bool") as? Bool ?? false
        
        print("PaymentDeactivated \(paymentDeactivated)")
        
        if !paymentDeactivated {
            // Permet de verifier si l'user a payer avant la création d'un commerce
            self.buyProduct()
        } else {
            if commerceAlreadyExists {
                self.renewCommerceEndDate()
            } else {
                self.createNewCommerce()
            }
            
        }
    }
    
    func renewCommerceEndDate(){
        let query = PFQuery(className: "Commerce")
        query.whereKey("objectId", equalTo: self.renewingCommerceId)
        query.getFirstObjectInBackground { (commerce, error) in
            if let error = error {
                print("Erreur retrieving commerce info - func renewCommerceEndDate")
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
            } else if let commerce = commerce {
                let lastEndDate = commerce["endSubscription"] as! Date
                
                if lastEndDate.isBeforeDate(Date(), granularity: .minute) {
                    // isBefore today
                    if self.scheduleVal {
                        commerce["endSubscription"] = Date() + 30.seconds
                    } else {
                        commerce["endSubscription"] = Date() + 1.years
                    }
                } else {
                    // isAfter today
                    if self.scheduleVal {
                        commerce["endSubscription"] = lastEndDate + 30.seconds
                    } else {
                        commerce["endSubscription"] = lastEndDate + 1.years
                    }
                }
                
                commerce.saveInBackground { (success, error) in
                    if success {
                        SVProgressHUD.showSuccess(withStatus: "Votre commerce a été renouvelé pour un an")
                        // Commerce crée on sauvegarde les stats
                        self.saveStatForPurchase(forUser: self.currentUser!, andCommerce: commerce)
                        self.getBackToHome(self)
                    } else if let error = error {
                        print("Erreur dans le renouvellement de l'abonnement du commerce")
                        ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
                        SVProgressHUD.showError(withStatus: "Erreur dans le renouvellement de l'abonnement du commerce")
                    }
                }
            } else {
                SVProgressHUD.showError(withStatus: "Une erreur inconnue est arrivée durant le renouvellement")
            }
        }
    }
    
    @IBAction func restorePurchase(_ sender: Any) {
        SVProgressHUD.show(withStatus: "Chargement de vos achats")
        SwiftyStoreKit.restorePurchases(atomically: false) { results in
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed: \(results.restoreFailedPurchases)")
                SVProgressHUD.showError(withStatus: "Erreur lors du chargement de vos achats")
            }
            else if results.restoredPurchases.count > 0 {
                for purchase in results.restoredPurchases {
                    // fetch content from your server, then:
                    print(purchase)
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                }
                print("Restore Success")
                SVProgressHUD.showSuccess(withStatus: "Vos achats ont été restaurés avec succès")
            }
            else {
                print("Nothing to Restore")
                SVProgressHUD.showInfo(withStatus: "Aucun achat à restaurer")
            }
        }
    }
    
    @IBAction func cancelPurchase(_ sender: Any) {
//        if let navigationCntrl = self.navigationController {
//            // return to product or profil
////            navigationCntrl.popToViewController(UIViewController, animated: true)
////            navigationCntrl.popToRootViewController(animated: true)
//            navigationCntrl.popViewController(animated: true)
//        } else {
//            self.dismiss(animated: true, completion: nil)
//        }
        self.getBackToHome(self)
    }
    
    func createNewCommerce() {
        SVProgressHUD.setStatus("Création de votre commerce")
        // TODO: faire de vrai tests pour le paiement
        // [1] Effectuer la demande de paiement
        // [2] Verifier le retour
        // [3] Si payé -> crée un commerce vide
        if let currentUser = currentUser {
            let newCommerce = PFObject(className: "Commerce")
            newCommerce["nomCommerce"] = "Nouveau Commerce"
            newCommerce["statutCommerce"] = 1
            newCommerce["nombrePartages"] = 0
            newCommerce["brouillon"] = true
            newCommerce["typeCommerce"] = "Alimentaire"
            newCommerce["adresse"] = ""
            newCommerce["promotions"] = ""
            newCommerce["photoSlider"] = []
            newCommerce["siteWeb"] = ""
            newCommerce["mail"] = ""
            newCommerce["tel"] = ""
            newCommerce["description"] = ""
            newCommerce["videos"] = []
            newCommerce["tags"] = []
            newCommerce["position"] = PFGeoPoint(latitude: 0, longitude: 0)
            newCommerce["owner"] = currentUser
            
            if scheduleVal {
                newCommerce["endSubscription"] = Date() + 30.seconds
            } else {
                newCommerce["endSubscription"] = Date() + 1.years
            }
            
            let acl = PFACL()
            acl.setReadAccess(true, forRoleWithName: "Public")
            acl.setReadAccess(true, forRoleWithName: "admin")
            acl.setReadAccess(true, for: currentUser)
            
            acl.setWriteAccess(true, forRoleWithName: "Public")
            acl.setWriteAccess(true, forRoleWithName: "admin")
            acl.setWriteAccess(true, for: currentUser)
            
            
            newCommerce.acl = acl
            
            newCommerce.saveInBackground { (success, error) in
                if let error = error {
                    HelperAndKeys.showAlertWithMessage(theMessage: error.localizedDescription, title: "Erreur création de commerce", viewController: self)
                    ParseErrorCodeHandler.handleUnknownError(error: error)
                    SVProgressHUD.dismiss()
                } else {
                    if success {
                        SVProgressHUD.showSuccess(withStatus: "Commerce crée avec succes")
                        // Commerce crée on sauvegarde les stats
                        self.saveStatForPurchase(forUser: currentUser, andCommerce: newCommerce)
                        // [4] Une fois la création faite -> afficher page de création de commerce
                        SVProgressHUD.dismiss(withDelay: 1.5) {
                            self.getBackToHome(self)
                        }
                    } else {
                        HelperAndKeys.showAlertWithMessage(theMessage: "Erreur lors de la création d'un commerce merci de prendre contact rapidement avec l'équipe WeeClik.", title: "Erreur création de commerce", viewController: self)
                        SVProgressHUD.dismiss()
                    }
                }
            }
        } else {
            HelperAndKeys.showAlertWithMessage(theMessage: "Une erreur est survenue. Vous semblez ne pas être connecté. Veuillez vous re-connecter. Puis recommencer votre achat.", title: "Problème de connexion", viewController: self)
            SVProgressHUD.dismiss()
        }
    }
    
    func saveStatForPurchase(forUser user: PFUser, andCommerce commerce: PFObject){
        
        // TODO: rendre asynchrone (findObjects in background)
        
        let stat            = PFObject(className: "StatsPurchase")
        stat["user"]        = user
        stat["commerce"]    = commerce
        
        if let queryProduct = PFProduct.query() {
            queryProduct.whereKey("productIdentifier", equalTo: self.purchasedProductID)
            
            if let product = try? queryProduct.findObjects().last as? PFProduct {
                stat["typeAbonnement"]  = product
                product.incrementKey("purchased")
                product.saveInBackground { (success, error) in
                    if let error = error {
                        ParseErrorCodeHandler.handleUnknownError(error: error)
                    }
                }
            }
        }
        
        if let queryRole = PFRole.query() {
            queryRole.whereKey("name", equalTo: "admin")
            if let adminRole = try? queryRole.findObjects().first as? PFRole {
                let acl = PFACL()
                acl.setReadAccess(true, for: adminRole)
                acl.setWriteAccess(true, for: adminRole)
                stat.acl = acl
            }
        }
        
        stat.saveInBackground { (success, error) in
            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error)
                SVProgressHUD.dismiss(withDelay: 1.5)
            }
        }
    }
    
    func buyProduct(){
        
        SVProgressHUD.show(withStatus: "Chargement du paiement")
        
        SwiftyStoreKit.retrieveProductsInfo([self.purchasedProductID]) { result in
            
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
                SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
                    
                    switch result {
                    case .success(let product):
                        // fetch content from your server, then:
                        if self.commerceAlreadyExists {
                            self.renewCommerceEndDate()
                        } else {
                            self.createNewCommerce()
                        }

                        
                        if product.needsFinishTransaction {
                            SwiftyStoreKit.finishTransaction(product.transaction)
                        }
                        print("Purchase Success: \(product)")
                        break
                    case .error(let error):
                        switch error.code {
                        case .unknown: SVProgressHUD.showError(withStatus: "Unknown error. Please contact support")
                        case .clientInvalid: SVProgressHUD.showError(withStatus: "Not allowed to make the payment")
                        case .paymentCancelled: break
                        case .paymentInvalid: SVProgressHUD.showError(withStatus: "The purchase identifier was invalid")
                        case .paymentNotAllowed: SVProgressHUD.showError(withStatus: "The device is not allowed to make the payment")
                        case .storeProductNotAvailable: SVProgressHUD.showError(withStatus: "The product is not available in the current storefront")
                        case .cloudServicePermissionDenied: SVProgressHUD.showError(withStatus: "Access to cloud service information is not allowed")
                        case .cloudServiceNetworkConnectionFailed: SVProgressHUD.showError(withStatus: "Could not connect to the network")
                        case .cloudServiceRevoked: SVProgressHUD.showError(withStatus: "User has revoked permission to use this cloud service")
                        default: SVProgressHUD.showError(withStatus: (error as NSError).localizedDescription)
                        }
                        ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: false) // TODO: change it is not a parse error
                    }
                }
            } else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
                SVProgressHUD.dismiss(withDelay: 1.5)
                // TODO: Send mail - CRITIC ERROR
            }
            else {
                print("Error: \(String(describing: result.error))")
                ParseErrorCodeHandler.handleUnknownError(error: result.error ?? NSError.init(domain: "Purchase", code: 999, userInfo: nil), withFeedBack: false) // TODO: change it is not a parse error
                SVProgressHUD.dismiss(withDelay: 1.5)
            }
        }
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "ajoutCommerce" {
//            let ajoutCommerceVC = segue.destination as! AjoutCommerceVC
//            ajoutCommerceVC.editingMode = true
//            ajoutCommerceVC.loadedFromBAAS = false
//            ajoutCommerceVC.objectIdCommerce = self.newCommerceID
//        }
//    }
    
//    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//        paymentDeactivated = HelperAndKeys.getUserDefaultsValue(forKey: HelperAndKeys.getPaymentKey(), withExpectedType: "bool") as? Bool ?? false
//        print("Identifier \(identifier) & paymentDeactivated \(paymentDeactivated)")
//
//        if !paymentDeactivated {
//            // Permet de verifier si l'user a payer avant la création d'un commerce
//            if identifier == "ajoutCommerce" {
//                buyProduct()
//                return hasPaidForNewCommerce
//            }
//        }
//
//        return true
//    }
}
